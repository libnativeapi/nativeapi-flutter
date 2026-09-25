//! The page: the window and display lists, event tracking, the app bar, the
//! tabs, the feedback banner and the Events tab. The Canvas and Actions tabs
//! live in `canvas.rs` and `actions.rs`.

use std::cell::Cell;
use std::collections::VecDeque;
use std::rc::Rc;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use gpui::prelude::*;
use gpui::{
    anchored, deferred, div, point, px, AnyElement, Bounds, Context, Corner, FontWeight, Hsla,
    Pixels, SharedString, Size, Task, Window,
};
use nativeapi::display::Display;
use nativeapi::display_manager::DisplayManager;
use nativeapi::window::{Window as NativeWindow, WindowEvent, WindowId};
use nativeapi::window_manager::WindowManager;
use nativeapi_gpui::observe_window_events;

use crate::ui::{self, color};

const MAX_LOG_ENTRIES: usize = 200;

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Tab {
    Canvas,
    Actions,
    Events,
}

pub struct LogEntry {
    time: String,
    message: String,
    color: Hsla,
    /// Keeps a stream of events (a window being dragged or resized) on one
    /// line: an entry replaces the newest one when it carries the same tag.
    replace_tag: Option<String>,
}

/// What an action reports back: a line in the feedback banner and/or the log.
#[derive(Default)]
pub struct Outcome {
    feedback: Option<String>,
    log: Option<(String, Hsla)>,
}

impl Outcome {
    pub fn feedback(message: impl Into<String>) -> Self {
        Self {
            feedback: Some(message.into()),
            log: None,
        }
    }

    pub fn log(message: impl Into<String>, color: u32) -> Self {
        Self::default().and_log(message, color)
    }

    pub fn and_log(mut self, message: impl Into<String>, tint: u32) -> Self {
        self.log = Some((message.into(), color(tint)));
        self
    }
}

pub struct WindowExample {
    pub(crate) windows: Vec<NativeWindow>,
    pub(crate) displays: Vec<Display>,
    pub(crate) selected: Option<WindowId>,
    /// This example's own window; `None` where nativeapi cannot reach GPUI's
    /// windows (Linux).
    own_window: Option<NativeWindow>,
    pub(crate) tab: Tab,
    log: VecDeque<LogEntry>,
    feedback: Option<SharedString>,
    feedback_timer: Option<Task<()>>,
    menu_open: bool,
    /// Zoom of the canvas, on top of the scale that fits it (1.0 = fit).
    pub(crate) zoom: f32,
    /// Size of the canvas' drawing area, measured at layout.
    pub(crate) canvas_size: Rc<Cell<Size<Pixels>>>,
    /// Bounds of the opacity slider's track, measured at layout.
    pub(crate) opacity_track: Rc<Cell<Bounds<Pixels>>>,
    pub(crate) dragging_opacity: bool,
}

impl WindowExample {
    pub fn new(own_window: Option<NativeWindow>, cx: &mut Context<Self>) -> Self {
        observe_window_events(cx, Self::on_window_event).detach();

        // The window properties have no change events of their own: poll.
        cx.spawn(async move |this, cx| loop {
            cx.background_executor()
                .timer(Duration::from_millis(500))
                .await;
            if this.update(cx, |this, cx| this.update_windows(cx)).is_err() {
                break;
            }
        })
        .detach();

        Self {
            windows: WindowManager::get_all(),
            displays: DisplayManager::get_all(),
            selected: None,
            own_window,
            tab: Tab::Canvas,
            log: VecDeque::new(),
            feedback: None,
            feedback_timer: None,
            menu_open: false,
            zoom: 1.0,
            canvas_size: Rc::default(),
            opacity_track: Rc::default(),
            dragging_opacity: false,
        }
    }

    // -----------------------------------------------------------------------
    // Tracking
    // -----------------------------------------------------------------------

    fn on_window_event(&mut self, event: WindowEvent, cx: &mut Context<Self>) {
        let (message, replace_tag) = match event {
            WindowEvent::Focused { window_id } => (format!("Window #{window_id} focused"), None),
            WindowEvent::Blurred { window_id } => (format!("Window #{window_id} blurred"), None),
            WindowEvent::Minimized { window_id } => {
                (format!("Window #{window_id} minimized"), None)
            }
            WindowEvent::Maximized { window_id } => {
                (format!("Window #{window_id} maximized"), None)
            }
            WindowEvent::Restored { window_id } => (format!("Window #{window_id} restored"), None),
            WindowEvent::Created { window_id } => {
                (format!("Window #{window_id} created (first shown)"), None)
            }
            WindowEvent::Closed { window_id } => (format!("Window #{window_id} closed"), None),
            WindowEvent::Moved {
                window_id,
                new_position: p,
            } => (
                format!(
                    "Window #{window_id} moved to {}, {}",
                    p.x.round(),
                    p.y.round()
                ),
                Some(format!("moved-{window_id}")),
            ),
            WindowEvent::Resized {
                window_id,
                new_size: s,
            } => (
                format!(
                    "Window #{window_id} resized to {} x {}",
                    s.width.round(),
                    s.height.round()
                ),
                Some(format!("resized-{window_id}")),
            ),
        };
        let streamed = replace_tag.is_some();
        self.add_log(message, ui::black87(), replace_tag);
        if !streamed {
            self.update_windows(cx);
        }
        cx.notify();
    }

    pub(crate) fn update_windows(&mut self, cx: &mut Context<Self>) {
        self.windows = WindowManager::get_all();
        if let Some(id) = self.selected {
            if !self.windows.iter().any(|w| w.id() == id) {
                self.selected = None;
            }
        }
        cx.notify();
    }

    fn add_log(&mut self, message: String, color: Hsla, replace_tag: Option<String>) {
        if replace_tag.is_some()
            && self.log.front().and_then(|e| e.replace_tag.as_ref()) == replace_tag.as_ref()
        {
            self.log.pop_front();
        }
        self.log.push_front(LogEntry {
            time: timestamp(),
            message,
            color,
            replace_tag,
        });
        self.log.truncate(MAX_LOG_ENTRIES);
    }

    pub(crate) fn selected_window(&self) -> Option<&NativeWindow> {
        let id = self.selected?;
        self.windows.iter().find(|w| w.id() == id)
    }

    pub(crate) fn select_window(&mut self, id: WindowId, cx: &mut Context<Self>) {
        self.selected = Some(id);
        self.tab = Tab::Actions;
        cx.notify();
    }

    // -----------------------------------------------------------------------
    // Actions
    // -----------------------------------------------------------------------

    /// Runs `f` on a GPUI task rather than in the event handler: a window
    /// call can resize or move the window synchronously, and GPUI can only
    /// take note of that when it is not in the middle of an update.
    pub(crate) fn run(&mut self, cx: &mut Context<Self>, f: impl FnOnce() -> Outcome + 'static) {
        cx.spawn(async move |this, cx| {
            let outcome = f();
            let _ = this.update(cx, |this, cx| {
                this.report(outcome, cx);
                this.update_windows(cx);
            });
        })
        .detach();
    }

    /// Runs `f` on the window `id`; see [`Self::run`].
    pub(crate) fn act(
        &mut self,
        id: WindowId,
        cx: &mut Context<Self>,
        f: impl FnOnce(&NativeWindow) -> Outcome + 'static,
    ) {
        self.run(cx, move || match WindowManager::get(id) {
            Some(window) => f(&window),
            None => Outcome::default(),
        });
    }

    fn act_on_all(&mut self, cx: &mut Context<Self>, f: fn(&NativeWindow), outcome: Outcome) {
        let ids: Vec<WindowId> = self.windows.iter().map(|w| w.id()).collect();
        self.run(cx, move || {
            for window in ids.into_iter().filter_map(WindowManager::get) {
                f(&window);
            }
            outcome
        });
    }

    fn report(&mut self, outcome: Outcome, cx: &mut Context<Self>) {
        if let Some((message, color)) = outcome.log {
            self.add_log(message, color, None);
        }
        if let Some(message) = outcome.feedback {
            self.feedback = Some(message.into());
            self.feedback_timer = Some(cx.spawn(async move |this, cx| {
                cx.background_executor().timer(Duration::from_secs(3)).await;
                let _ = this.update(cx, |this, cx| {
                    this.feedback = None;
                    cx.notify();
                });
            }));
        }
        cx.notify();
    }

    // -----------------------------------------------------------------------
    // App bar, tabs, banner
    // -----------------------------------------------------------------------

    fn app_bar(&self, cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .flex()
            .items_center()
            .h(px(56.))
            .px_4()
            .gap_2()
            .child(
                div()
                    .text_size(px(22.))
                    .text_color(color(ui::ON_SURFACE))
                    .child("Window Manager"),
            )
            .when(!self.windows.is_empty(), |this| {
                this.child(
                    div()
                        .px_2()
                        .py_1()
                        .rounded(px(12.))
                        .bg(color(ui::PRIMARY_CONTAINER))
                        .text_size(px(12.))
                        .font_weight(FontWeight::BOLD)
                        .text_color(color(ui::ON_PRIMARY_CONTAINER))
                        .child(self.windows.len().to_string()),
                )
            })
            .child(div().flex_1())
            .child(
                ui::text_button("menu", "⋯")
                    .text_size(px(18.))
                    .text_color(color(ui::ON_SURFACE_VARIANT))
                    .on_click(cx.listener(|this, _, _, cx| {
                        this.menu_open = true;
                        cx.notify();
                    })),
            )
            .child(
                ui::text_button("refresh", "↻ Refresh")
                    .text_color(color(ui::ON_SURFACE_VARIANT))
                    .on_click(cx.listener(|this, _, _, cx| this.update_windows(cx))),
            )
    }

    fn menu(&self, window: &Window, cx: &mut Context<Self>) -> impl IntoElement {
        let item = |id: &'static str, label: &'static str| {
            div()
                .id(id)
                .px_4()
                .py_2()
                .text_size(px(14.))
                .cursor_pointer()
                .hover(|style| style.bg(color(ui::PRIMARY).opacity(0.08)))
                .child(label)
        };
        let close = |this: &mut Self| this.menu_open = false;
        deferred(
            anchored()
                .anchor(Corner::TopRight)
                .position(point(window.viewport_size().width - px(8.), px(48.)))
                .snap_to_window()
                .child(
                    div()
                        .id("menu-popup")
                        .occlude()
                        .w(px(200.))
                        .py_2()
                        .rounded(px(4.))
                        .bg(color(ui::CARD))
                        .shadow_lg()
                        .text_color(color(ui::ON_SURFACE))
                        .on_mouse_down_out(cx.listener(move |this, _, _, cx| {
                            close(this);
                            cx.notify();
                        }))
                        .child(item("minimize-all", "Minimize All").on_click(cx.listener(
                            move |this, _, _, cx| {
                                close(this);
                                this.act_on_all(
                                    cx,
                                    NativeWindow::minimize,
                                    Outcome::feedback("Minimized all windows")
                                        .and_log("Action: minimize all windows", ui::ORANGE),
                                );
                            },
                        )))
                        .child(item("restore-all", "Restore All").on_click(cx.listener(
                            move |this, _, _, cx| {
                                close(this);
                                this.act_on_all(
                                    cx,
                                    NativeWindow::restore,
                                    Outcome::feedback("Restored all windows")
                                        .and_log("Action: restore all windows", ui::TEAL),
                                );
                            },
                        )))
                        .child(item("show-all", "Show All").on_click(cx.listener(
                            move |this, _, _, cx| {
                                close(this);
                                this.act_on_all(
                                    cx,
                                    NativeWindow::show,
                                    Outcome::feedback("Showed all windows")
                                        .and_log("Action: show all windows", ui::GREEN),
                                );
                            },
                        )))
                        .child(item("hide-all", "Hide All").on_click(cx.listener(
                            move |this, _, _, cx| {
                                close(this);
                                this.act_on_all(
                                    cx,
                                    NativeWindow::hide,
                                    Outcome::feedback("Hidden all windows")
                                        .and_log("Action: hide all windows", ui::GREY),
                                );
                            },
                        ))),
                ),
        )
        .with_priority(1)
    }

    fn tab_bar(&self, cx: &mut Context<Self>) -> impl IntoElement {
        let tab = |id: &'static str, label: &'static str, tab: Tab| {
            let selected = self.tab == tab;
            div()
                .id(id)
                .flex_1()
                .flex()
                .flex_col()
                .items_center()
                .cursor_pointer()
                .hover(|style| style.bg(color(ui::PRIMARY).opacity(0.04)))
                .child(
                    div()
                        .py_3()
                        .text_size(px(14.))
                        .font_weight(FontWeight::MEDIUM)
                        .text_color(color(if selected {
                            ui::PRIMARY
                        } else {
                            ui::ON_SURFACE_VARIANT
                        }))
                        .child(label),
                )
                .child(
                    div()
                        .h(px(3.))
                        .w(px(64.))
                        .rounded_t(px(3.))
                        .when(selected, |this| this.bg(color(ui::PRIMARY))),
                )
                .on_click(cx.listener(move |this, _, _, cx| {
                    this.tab = tab;
                    cx.notify();
                }))
        };
        div()
            .flex()
            .border_b_1()
            .border_color(color(ui::OUTLINE_VARIANT))
            .child(tab("tab-canvas", "Canvas", Tab::Canvas))
            .child(tab("tab-actions", "Actions", Tab::Actions))
            .child(tab("tab-events", "Events", Tab::Events))
    }

    fn banner(&self, message: SharedString, cx: &mut Context<Self>) -> impl IntoElement {
        let tint = color(ui::GREEN);
        div()
            .flex()
            .items_center()
            .gap_2()
            .px_4()
            .py_2()
            .bg(tint.opacity(0.12))
            .child(div().text_color(tint).child("✓"))
            .child(
                div()
                    .flex_1()
                    .font_weight(FontWeight::SEMIBOLD)
                    .text_color(tint.opacity(0.9))
                    .child(message),
            )
            .child(
                ui::text_button("dismiss", "Dismiss").on_click(cx.listener(|this, _, _, cx| {
                    this.feedback = None;
                    cx.notify();
                })),
            )
    }

    fn empty_state(&self) -> impl IntoElement {
        let hint = if self.own_window.is_some() {
            "Open or create a window\nto begin exploring the API."
        } else {
            "Needs macOS or Windows:\nnativeapi cannot reach GPUI's windows here."
        };
        div()
            .size_full()
            .flex()
            .items_center()
            .justify_center()
            .child(
                ui::card()
                    .p_8()
                    .flex()
                    .flex_col()
                    .items_center()
                    .gap_2()
                    .child(
                        div()
                            .text_size(px(22.))
                            .font_weight(FontWeight::BOLD)
                            .child("No windows found"),
                    )
                    .child(
                        div()
                            .text_center()
                            .text_color(color(ui::GREY_600))
                            .children(hint.lines().map(|line| div().child(line))),
                    ),
            )
    }

    // -----------------------------------------------------------------------
    // Events tab
    // -----------------------------------------------------------------------

    fn events_tab(&self, cx: &mut Context<Self>) -> AnyElement {
        if self.log.is_empty() {
            return div()
                .size_full()
                .flex()
                .flex_col()
                .items_center()
                .justify_center()
                .text_color(color(ui::GREY_600))
                .child("No events yet.")
                .child("Interact with windows to see events appear.")
                .into_any_element();
        }
        div()
            .size_full()
            .flex()
            .flex_col()
            .child(
                div()
                    .flex()
                    .items_center()
                    .px_3()
                    .pt_2()
                    .pb_1()
                    .child(
                        div()
                            .flex_1()
                            .text_size(px(14.))
                            .font_weight(FontWeight::BOLD)
                            .child(format!("Event Log ({})", self.log.len())),
                    )
                    .child(ui::text_button("clear-log", "Clear").on_click(cx.listener(
                        |this, _, _, cx| {
                            this.log.clear();
                            cx.notify();
                        },
                    ))),
            )
            .child(div().h(px(1.)).bg(color(ui::OUTLINE_VARIANT)))
            .child(
                div()
                    .id("event-log")
                    .flex_1()
                    .min_h_0()
                    .overflow_y_scroll()
                    .px_2()
                    .py_1()
                    .children(self.log.iter().map(|entry| {
                        div()
                            .flex()
                            .items_start()
                            .py(px(2.))
                            .child(
                                div()
                                    .w(px(72.))
                                    .flex_none()
                                    .font_family(ui::MONOSPACE)
                                    .text_size(px(11.))
                                    .text_color(color(ui::GREY_500))
                                    .child(entry.time.clone()),
                            )
                            .child(
                                div()
                                    .flex_none()
                                    .size(px(8.))
                                    .mt(px(5.))
                                    .mr_2()
                                    .rounded_full()
                                    .bg(entry.color),
                            )
                            .child(
                                div()
                                    .flex_1()
                                    .font_family(ui::MONOSPACE)
                                    .text_size(px(13.))
                                    .text_color(entry.color)
                                    .child(entry.message.clone()),
                            )
                    })),
            )
            .into_any_element()
    }
}

impl Render for WindowExample {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let body = if self.windows.is_empty() {
            self.empty_state().into_any_element()
        } else {
            let content = match self.tab {
                Tab::Canvas => self.canvas_tab(window, cx),
                Tab::Actions => self.actions_tab(cx),
                Tab::Events => self.events_tab(cx),
            };
            div()
                .size_full()
                .flex()
                .flex_col()
                .when_some(self.feedback.clone(), |this, message| {
                    this.child(self.banner(message, cx))
                })
                .child(div().flex_1().min_h_0().child(content))
                .into_any_element()
        };
        div()
            .size_full()
            .flex()
            .flex_col()
            .bg(color(ui::BACKGROUND))
            .text_color(color(ui::ON_SURFACE))
            .text_size(px(14.))
            .child(self.app_bar(cx))
            .child(self.tab_bar(cx))
            .child(div().flex_1().min_h_0().child(body))
            .when(self.menu_open, |this| this.child(self.menu(window, cx)))
    }
}

/// `mm:ss.mmm` of the current time.
fn timestamp() -> String {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default();
    let secs = now.as_secs();
    format!(
        "{:02}:{:02}.{:03}",
        secs / 60 % 60,
        secs % 60,
        now.subsec_millis()
    )
}
