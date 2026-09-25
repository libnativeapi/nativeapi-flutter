//! What both windows show, and everything done to the native windows.
//!
//! Both windows run in one process and render from this one entity: that is
//! all the "communication between windows" there is.

use std::rc::Rc;

use gpui::{AnyWindowHandle, Context};
use nativeapi::color::Color;
use nativeapi::geometry::{Point, Size};
use nativeapi::window::{TitleBarStyle, Window as NativeWindow, WindowEvent};
use nativeapi_gpui::{defer_native, observe_window_events, NativeSubscription};

/// Content size of the main window.
pub const MAIN_SIZE: (f64, f64) = (720.0, 520.0);
/// Size of the toolbar window.
pub const TOOLBAR_SIZE: (f64, f64) = (380.0, 64.0);
/// How far the toolbar floats above the top edge of the main window.
pub const GAP: f64 = 10.0;

pub const SWATCHES: [u32; 4] = [0x3f51b5, 0x009688, 0xff9800, 0xe91e63];

/// The two native windows, cheap to hand to a task.
#[derive(Clone)]
struct Natives {
    main: Rc<NativeWindow>,
    toolbar: Rc<NativeWindow>,
}

pub struct Toolbar {
    pub color: u32,
    pub stamps: usize,
    pub attached: bool,
    pub toolbar_visible: bool,
    pub log: Vec<String>,
    natives: Option<Natives>,
    toolbar_handle: Option<AnyWindowHandle>,
    events: Option<NativeSubscription>,
    closing: bool,
}

impl Toolbar {
    pub fn new(_: &mut Context<Self>) -> Self {
        Self {
            color: SWATCHES[0],
            stamps: 0,
            attached: false,
            toolbar_visible: true,
            log: Vec::new(),
            natives: None,
            toolbar_handle: None,
            events: None,
            closing: false,
        }
    }

    pub fn available(&self) -> bool {
        self.natives.is_some()
    }

    pub fn pick(&mut self, color: u32, cx: &mut Context<Self>) {
        self.color = color;
        cx.notify();
    }

    pub fn stamp(&mut self, cx: &mut Context<Self>) {
        self.stamps += 1;
        cx.notify();
    }

    fn note(&mut self, message: String, cx: &mut Context<Self>) {
        eprintln!("[floating_toolbar] {message}");
        self.log.insert(0, message);
        self.log.truncate(40);
        cx.notify();
    }

    /// Takes the two windows once they are open, dresses the toolbar, attaches
    /// it and starts following the main window.
    pub fn set_windows(
        &mut self,
        main: Option<NativeWindow>,
        toolbar: Option<NativeWindow>,
        toolbar_handle: AnyWindowHandle,
        cx: &mut Context<Self>,
    ) {
        self.toolbar_handle = Some(toolbar_handle);
        let (Some(main), Some(toolbar)) = (main, toolbar) else {
            // nativeapi cannot reach GPUI's windows here (Linux); GPUI has
            // shown the toolbar where it put it.
            self.note(
                "nativeapi cannot reach the windows on this platform".into(),
                cx,
            );
            return;
        };
        let natives = Natives {
            main: Rc::new(main),
            toolbar: Rc::new(toolbar),
        };
        self.natives = Some(natives.clone());

        self.events = Some(observe_window_events(cx, Self::on_window_event));
        cx.spawn(async move |this, cx| {
            // Everything that makes a window a floating toolbar. Done here,
            // outside any GPUI update: these calls resize and move the window,
            // and GPUI only hears about that when no update is running.
            let toolbar = &natives.toolbar;
            toolbar.set_title_bar_style(TitleBarStyle::Hidden);
            toolbar.set_background_color(&Color {
                r: 0,
                g: 0,
                b: 0,
                a: 0,
            });
            toolbar.set_has_shadow(false);
            toolbar.set_resizable(false);
            toolbar.set_movable(false);
            toolbar.set_visible_in_taskbar(false);
            toolbar.set_content_size(&Size {
                width: TOOLBAR_SIZE.0,
                height: TOOLBAR_SIZE.1,
            });
            let attached = attach(&natives);
            toolbar.show_inactive();
            let _ = this.update(cx, |this, cx| this.attached_changed(attached, cx));
        })
        .detach();
    }

    fn attached_changed(&mut self, attached: bool, cx: &mut Context<Self>) {
        self.attached = attached;
        self.note(
            if attached {
                "Toolbar attached to the main window"
            } else {
                "setParentWindow failed"
            }
            .into(),
            cx,
        );
    }

    /// Runs `f` on the native windows from a task, then `then` on this model:
    /// see `set_windows` for why the native calls wait for a task.
    fn with_natives<R: 'static>(
        &self,
        cx: &mut Context<Self>,
        f: impl FnOnce(&Natives) -> R + 'static,
        then: impl FnOnce(&mut Self, R, &mut Context<Self>) + 'static,
    ) {
        let Some(natives) = self.natives.clone() else {
            return;
        };
        cx.spawn(async move |this, cx| {
            let result = f(&natives);
            let _ = this.update(cx, |this, cx| then(this, result, cx));
        })
        .detach();
    }

    pub fn set_attached(&mut self, attach_it: bool, cx: &mut Context<Self>) {
        if attach_it {
            self.with_natives(cx, attach, Self::attached_changed);
        } else {
            self.with_natives(
                cx,
                |natives| {
                    natives.toolbar.set_parent_window(None);
                },
                |this, _, cx| {
                    this.attached = false;
                    this.note("Toolbar detached: it no longer follows".into(), cx);
                },
            );
        }
    }

    pub fn set_toolbar_visible(&mut self, visible: bool, cx: &mut Context<Self>) {
        let attached = self.attached;
        self.with_natives(
            cx,
            move |natives| {
                if visible {
                    if attached {
                        place_toolbar(natives);
                    }
                    natives.toolbar.show_inactive();
                } else {
                    natives.toolbar.hide();
                }
            },
            move |this, _, cx| {
                this.toolbar_visible = visible;
                this.note(
                    if visible {
                        "Toolbar shown"
                    } else {
                        "Toolbar hidden"
                    }
                    .into(),
                    cx,
                );
            },
        );
    }

    fn on_window_event(&mut self, event: WindowEvent, cx: &mut Context<Self>) {
        let Some(natives) = self.natives.clone().filter(|_| !self.closing) else {
            return;
        };
        let main_id = natives.main.id();
        let toolbar_id = natives.toolbar.id();
        let name = |id| {
            if id == main_id {
                "main".to_string()
            } else if id == toolbar_id {
                "toolbar".to_string()
            } else {
                format!("#{id}")
            }
        };
        let follow = match event {
            WindowEvent::Moved { window_id, .. }
            | WindowEvent::Resized { window_id, .. }
            | WindowEvent::Restored { window_id } => window_id == main_id && self.attached,
            _ => false,
        };
        if follow {
            // Moving a window from inside an update would keep GPUI from
            // hearing about it.
            let natives = natives.clone();
            defer_native(cx, move || place_toolbar(&natives));
        }
        let message = match event {
            WindowEvent::Created { window_id } => format!("created: {}", name(window_id)),
            WindowEvent::Closed { window_id } => format!("closed: {}", name(window_id)),
            WindowEvent::Minimized { window_id } => format!("minimized: {}", name(window_id)),
            WindowEvent::Restored { window_id } => format!("restored: {}", name(window_id)),
            _ => return,
        };
        self.note(message, cx);
    }

    /// Children first, then the parent: what closing a parent does to its
    /// children differs between platforms, closing them yourself does not.
    pub fn close_everything(&mut self, cx: &mut Context<Self>) {
        if self.closing {
            return;
        }
        self.closing = true;
        self.events = None;
        if let Some(natives) = self.natives.take() {
            natives.toolbar.set_parent_window(None);
        }
        if let Some(handle) = self.toolbar_handle.take() {
            cx.defer(move |cx| {
                let _ = handle.update(cx, |_, window, _| window.remove_window());
            });
        }
    }
}

fn attach(natives: &Natives) -> bool {
    let ok = natives.toolbar.set_parent_window(Some(&natives.main));
    if ok {
        place_toolbar(natives);
    }
    ok
}

/// Centres the toolbar above the main window.
///
/// On macOS a child window already moves with its parent; elsewhere this is
/// what makes it follow. It also keeps the toolbar centred when the main
/// window is resized, which no platform does by itself.
fn place_toolbar(natives: &Natives) {
    let frame = natives.main.bounds();
    let size = natives.toolbar.bounds();
    natives.toolbar.set_position(&Point {
        x: frame.x + (frame.width - size.width) / 2.0,
        y: frame.y - size.height - GAP,
    });
}
