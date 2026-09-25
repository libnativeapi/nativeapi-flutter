//! Which panel is docked where, which panels float, and the drag gesture that
//! moves them between the two. Knows nothing about what a panel shows.

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use gpui::{
    point, px, size, AnyView, AnyWindowHandle, App, AppContext, Bounds, Context, Entity, Pixels,
    TitlebarOptions, WindowBounds, WindowOptions,
};
use nativeapi::geometry::{Point, Rectangle};
use nativeapi::window::Window as NativeWindow;
use nativeapi::window_drag_session::{WindowDragEvent, WindowDragSession};
use nativeapi::window_manager::WindowManager;

use crate::native::{contains, content_offset, to_screen};
use crate::views::FloatingView;
use nativeapi_gpui::{observe_drag_session, WindowExt};

/// How far the cursor has to travel from the press before a panel pops out.
const POP_OUT_DISTANCE: f64 = 8.0;

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum PanelId {
    Inspector,
    Stopwatch,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum SlotId {
    Sidebar,
    Bottom,
}

impl SlotId {
    pub const ALL: [SlotId; 2] = [SlotId::Sidebar, SlotId::Bottom];
}

/// Slot rectangles in the main window's content coordinates, written by the
/// main window every time it lays out.
pub type SlotRects = Rc<RefCell<HashMap<SlotId, Bounds<Pixels>>>>;

pub struct Panel {
    pub title: &'static str,
    /// The panel's content. The same entity is rendered by whichever window
    /// shows the panel, so its state survives every move.
    pub body: AnyView,
    pub moves: usize,
}

struct Floating {
    handle: AnyWindowHandle,
    native: Option<NativeWindow>,
}

enum Gesture {
    /// Pressed on a docked panel's header; not yet far enough to pop out.
    Pressed {
        panel: PanelId,
        slot: SlotId,
        /// Screen position of the press.
        press: Point,
        /// Press position inside the slot.
        offset: Point,
    },
    /// A floating window follows the cursor.
    Moving { panel: PanelId },
}

/// A docked panel leaving its slot mid-drag: the window to open for it.
struct PopOut {
    panel: PanelId,
    /// Screen rectangle for the new window's content.
    rect: Rectangle,
    /// Where the cursor holds the panel, inside that content.
    offset: Point,
}

pub struct Detach {
    panels: HashMap<PanelId, Panel>,
    dock: HashMap<SlotId, Option<PanelId>>,
    floating: HashMap<PanelId, Floating>,
    main: Option<NativeWindow>,
    slot_rects: SlotRects,
    /// The empty slot a dragged panel would dock into on release.
    highlight: Option<SlotId>,
    session: Option<Rc<WindowDragSession>>,
    gesture: Option<Gesture>,
}

impl Detach {
    pub fn new(inspector: AnyView, stopwatch: AnyView, cx: &mut Context<Self>) -> Self {
        let panels = HashMap::from([
            (
                PanelId::Inspector,
                Panel {
                    title: "Inspector",
                    body: inspector,
                    moves: 0,
                },
            ),
            (
                PanelId::Stopwatch,
                Panel {
                    title: "Stopwatch",
                    body: stopwatch,
                    moves: 0,
                },
            ),
        ]);
        let dock = HashMap::from([
            (SlotId::Sidebar, Some(PanelId::Inspector)),
            (SlotId::Bottom, Some(PanelId::Stopwatch)),
        ]);

        let session = if cfg!(any(target_os = "macos", target_os = "windows")) {
            WindowDragSession::new().map(Rc::new)
        } else {
            None
        };
        if let Some(session) = &session {
            observe_drag_session(session, cx, |this, event, cx| {
                let Some(pop_out) = this.on_drag(event, cx) else {
                    return;
                };
                // Deferred past this update: opening a window draws it once,
                // and drawing reads this entity.
                let this = cx.entity();
                cx.defer(move |cx| {
                    open_floating(&this, pop_out.panel, &pop_out.rect, cx);
                    this.update(cx, |this, cx| {
                        this.follow(pop_out.panel, &pop_out.offset, cx)
                    });
                });
            })
            .detach();
        }

        Self {
            panels,
            dock,
            floating: HashMap::new(),
            main: None,
            slot_rects: SlotRects::default(),
            highlight: None,
            session,
            gesture: None,
        }
    }

    pub fn set_main_window(&mut self, window: Option<NativeWindow>) {
        self.main = window;
    }

    pub fn slot_rects(&self) -> SlotRects {
        self.slot_rects.clone()
    }

    pub fn panel(&self, panel: PanelId) -> &Panel {
        &self.panels[&panel]
    }

    pub fn docked(&self, slot: SlotId) -> Option<PanelId> {
        self.dock[&slot]
    }

    pub fn highlight(&self) -> Option<SlotId> {
        self.highlight
    }

    pub fn can_drag(&self) -> bool {
        self.session.is_some()
    }

    fn slot_of(&self, panel: PanelId) -> Option<SlotId> {
        SlotId::ALL
            .into_iter()
            .find(|slot| self.dock[slot] == Some(panel))
    }

    fn slot_screen_rect(&self, slot: SlotId) -> Option<Rectangle> {
        let rect = *self.slot_rects.borrow().get(&slot)?;
        Some(to_screen(self.main.as_ref()?, rect))
    }

    // -----------------------------------------------------------------------
    // Requests from the UI
    // -----------------------------------------------------------------------

    /// A press on a panel header, in content coordinates of the pressed window.
    pub fn press_header(&mut self, panel: PanelId, position: gpui::Point<Pixels>) {
        let Some(session) = &self.session else {
            return;
        };
        if self.gesture.is_some() {
            return;
        }
        let (x, y) = (f64::from(position.x), f64::from(position.y));

        if let Some(floating) = self.floating.get(&panel) {
            let Some(native) = &floating.native else {
                return;
            };
            let inset = content_offset(native);
            let anchor = Point {
                x: inset.x + x,
                y: inset.y + y,
            };
            if session.start(Some(native), &anchor) {
                self.gesture = Some(Gesture::Moving { panel });
            }
            return;
        }

        let Some(slot) = self.slot_of(panel) else {
            return;
        };
        let (Some(rect), Some(main)) = (self.slot_rects.borrow().get(&slot).copied(), &self.main)
        else {
            return;
        };
        let content = main.content_bounds();
        // Follow the pointer without moving anything until it travels far enough.
        if session.start(None, &Point { x: 0.0, y: 0.0 }) {
            self.gesture = Some(Gesture::Pressed {
                panel,
                slot,
                press: Point {
                    x: content.x + x,
                    y: content.y + y,
                },
                offset: Point {
                    x: x - f64::from(rect.origin.x),
                    y: y - f64::from(rect.origin.y),
                },
            });
        }
    }

    /// Takes a docked panel out of its slot for the "Pop out" button: the
    /// screen rectangle for its window, beside the main window.
    pub fn undock_beside(&mut self, panel: PanelId, cx: &mut Context<Self>) -> Option<Rectangle> {
        if self.gesture.is_some() {
            return None;
        }
        let slot = self.slot_of(panel)?;
        let rect = self.slot_screen_rect(slot)?;
        let frame = self.main.as_ref()?.bounds();
        self.dock.insert(slot, None);
        self.panels.get_mut(&panel)?.moves += 1;
        cx.notify();
        Some(Rectangle {
            x: frame.x + frame.width + 16.0,
            ..rect
        })
    }

    /// Docks a floating panel into `slot`, or into the first empty slot.
    pub fn dock_panel(&mut self, panel: PanelId, slot: Option<SlotId>, cx: &mut Context<Self>) {
        let target = slot.or_else(|| {
            SlotId::ALL
                .into_iter()
                .find(|slot| self.dock[slot].is_none())
        });
        let Some(target) = target.filter(|slot| self.dock[slot].is_none()) else {
            return;
        };
        let Some(floating) = self.floating.remove(&panel) else {
            return;
        };
        self.dock.insert(target, Some(panel));
        self.panels.get_mut(&panel).unwrap().moves += 1;
        // Closed after the current update: the caller may be running inside
        // that very window.
        let handle = floating.handle;
        drop(floating.native);
        cx.defer(move |cx| {
            let _ = handle.update(cx, |_, window, _| window.remove_window());
        });
        if let Some(main) = &self.main {
            main.focus();
        }
        cx.notify();
    }

    // -----------------------------------------------------------------------
    // The drag gesture
    // -----------------------------------------------------------------------

    fn on_drag(&mut self, event: WindowDragEvent, cx: &mut Context<Self>) -> Option<PopOut> {
        let (moved, released, cursor) = match event {
            WindowDragEvent::Moved {
                cursor_position, ..
            } => (true, false, cursor_position),
            WindowDragEvent::Ended {
                cursor_position, ..
            } => (false, true, cursor_position),
            WindowDragEvent::Cancelled {
                cursor_position, ..
            } => (false, false, cursor_position),
        };

        match self.gesture.take()? {
            Gesture::Pressed {
                panel,
                slot,
                press,
                offset,
            } => {
                if !moved {
                    return None; // A click, not a drag.
                }
                let distance = (cursor.x - press.x).hypot(cursor.y - press.y);
                if distance < POP_OUT_DISTANCE {
                    self.gesture = Some(Gesture::Pressed {
                        panel,
                        slot,
                        press,
                        offset,
                    });
                    return None;
                }
                // Where the panel sat, shifted by how far the cursor has travelled.
                let slot_rect = self.slot_screen_rect(slot)?;
                self.dock.insert(slot, None);
                self.panels.get_mut(&panel)?.moves += 1;
                cx.notify();
                Some(PopOut {
                    panel,
                    rect: Rectangle {
                        x: slot_rect.x + cursor.x - press.x,
                        y: slot_rect.y + cursor.y - press.y,
                        ..slot_rect
                    },
                    offset,
                })
            }
            Gesture::Moving { panel } => {
                if moved {
                    self.gesture = Some(Gesture::Moving { panel });
                    self.update_highlight(panel, &cursor, cx);
                } else {
                    self.finish_move(panel, released, cx);
                }
                None
            }
        }
    }

    /// Hands the running drag over to a panel's freshly opened window.
    fn follow(&mut self, panel: PanelId, offset: &Point, cx: &mut Context<Self>) {
        let (
            Some(session),
            Some(Floating {
                native: Some(native),
                ..
            }),
        ) = (&self.session, self.floating.get(&panel))
        else {
            return;
        };
        let inset = content_offset(native);
        let anchor = Point {
            x: inset.x + offset.x,
            y: inset.y + offset.y,
        };
        // Released while the window was being created: it stays where it is.
        if session.is_active() && session.start(Some(native), &anchor) {
            self.gesture = Some(Gesture::Moving { panel });
        }
        cx.notify();
    }

    /// Highlights the empty slot under the cursor, looking through the dragged window.
    fn update_highlight(&mut self, panel: PanelId, cursor: &Point, cx: &mut Context<Self>) {
        let Some(dragged) = self.floating.get(&panel).and_then(|f| f.native.as_ref()) else {
            return;
        };
        let main_id = self.main.as_ref().map(|main| main.id());
        let below = WindowManager::get_window_at_point(cursor, dragged.id());
        let next = if below.map(|window| window.id()) == main_id {
            SlotId::ALL.into_iter().find(|&slot| {
                self.dock[&slot].is_none()
                    && self
                        .slot_screen_rect(slot)
                        .is_some_and(|rect| contains(&rect, cursor))
            })
        } else {
            None
        };
        if next != self.highlight {
            self.highlight = next;
            dragged.set_opacity(if next.is_some() { 0.6 } else { 1.0 });
            cx.notify();
        }
    }

    fn finish_move(&mut self, panel: PanelId, released: bool, cx: &mut Context<Self>) {
        let target = self.highlight.take().filter(|_| released);
        let native = self.floating.get(&panel).and_then(|f| f.native.as_ref());
        if let Some(native) = native {
            native.set_opacity(1.0);
        }
        match target {
            Some(slot) => self.dock_panel(panel, Some(slot), cx),
            None => {
                // The press that started a tear-off went to the main window,
                // which the release brings back to the front; the panel stays
                // on top.
                if let Some(native) = native {
                    native.focus();
                }
                cx.notify();
            }
        }
    }
}

/// Opens a floating window whose content covers `rect` on screen.
pub fn open_floating(this: &Entity<Detach>, panel: PanelId, rect: &Rectangle, cx: &mut App) {
    let title = this.read(cx).panel(panel).title;
    let options = WindowOptions {
        window_bounds: Some(WindowBounds::Windowed(Bounds::new(
            point(px(rect.x as f32), px(rect.y as f32)),
            size(px(rect.width as f32), px(rect.height as f32)),
        ))),
        titlebar: Some(TitlebarOptions {
            title: Some(title.into()),
            ..Default::default()
        }),
        is_minimizable: false,
        ..Default::default()
    };
    let mut native = None;
    let opened = cx.open_window(options, |window, cx| {
        native = window.native_window();
        // Closing a floating window docks its panel back instead.
        let detach = this.clone();
        window.on_window_should_close(cx, move |_, cx| {
            detach.update(cx, |detach, cx| detach.dock_panel(panel, None, cx));
            false
        });
        cx.new(|cx| FloatingView::new(this.clone(), panel, cx))
    });
    let Ok(handle) = opened else {
        return;
    };
    // GPUI places the window frame; put the content exactly over `rect`.
    if let Some(native) = &native {
        native.set_content_bounds(rect);
    }
    this.update(cx, |detach, cx| {
        detach.floating.insert(
            panel,
            Floating {
                handle: handle.into(),
                native,
            },
        );
        cx.notify();
    });
}
