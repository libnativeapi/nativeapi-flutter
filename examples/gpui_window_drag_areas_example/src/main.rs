//! Window drag areas example — custom window chrome in GPUI: a coloured bar
//! that moves the window (`Window::start_dragging`, double click maximizes and
//! restores) and eight inset resize handles (`Window::start_resizing`).
//!
//! The GPUI counterpart of `flutter_window_drag_areas_example`, doing from
//! GPUI mouse handlers what nativeapi_flutter's `DragToMoveArea` and
//! `DragToResizeArea` do from gesture callbacks.
//!
//! Usage:
//!   cargo run   # in examples/gpui_window_drag_areas_example

mod native;

use std::rc::Rc;

use gpui::prelude::*;
use gpui::{
    div, px, rgb, rgba, size, App, Application, Bounds, CursorStyle, MouseButton, MouseDownEvent,
    MouseMoveEvent, Pixels, SharedString, TitlebarOptions, Window, WindowBounds, WindowOptions,
};
use nativeapi::window::{ResizeEdge, TitleBarStyle, Window as NativeWindow};

use crate::native::native_window_of;

/// Thickness of the resize handles and their distance from the window edge.
///
/// The handles are inset so that they are clearly the app's, not the native
/// window frame's. A GUI test presses in the middle of these bands; keep the
/// numbers in sync with it (they match the Flutter example's).
const RESIZE_EDGE_SIZE: f32 = 12.;
const RESIZE_EDGE_INSET: f32 = 16.;
/// Height of the move bar, at the top of the panel inside the handles.
const MOVE_BAR_HEIGHT: f32 = 44.;
/// How far the pointer travels with the button down before a press becomes a
/// drag, like a pan gesture starting.
const DRAG_SLOP: f32 = 2.;

// Material 3 colours of the Flutter example's indigo-seeded light theme.
const SURFACE_CONTAINER_HIGHEST: u32 = 0xe3e1ec;
const SURFACE: u32 = 0xfbf8ff;
const PRIMARY_CONTAINER: u32 = 0xdee0ff;
const PRIMARY: u32 = 0x4f5b92;
const ON_PRIMARY: u32 = 0xffffff;
const ON_SURFACE: u32 = 0x1b1b21;
const OUTLINE: u32 = 0x767680;
/// `primary` at 25% opacity: the tint of the resize handles.
const RESIZE_EDGE_COLOR: u32 = 0x4f5b9240;

const ALL_EDGES: [ResizeEdge; 8] = [
    ResizeEdge::TopLeft,
    ResizeEdge::Top,
    ResizeEdge::TopRight,
    ResizeEdge::Left,
    ResizeEdge::Right,
    ResizeEdge::BottomLeft,
    ResizeEdge::Bottom,
    ResizeEdge::BottomRight,
];
const LIMITED_EDGES: [ResizeEdge; 3] = [
    ResizeEdge::Right,
    ResizeEdge::Bottom,
    ResizeEdge::BottomRight,
];

fn main() {
    Application::new().run(|cx: &mut App| {
        let options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds::centered(
                None,
                size(px(720.), px(480.)),
                cx,
            ))),
            titlebar: Some(TitlebarOptions {
                title: Some("nativeapi · Drag areas".into()),
                // Content under the title bar, so hiding it keeps the size.
                appears_transparent: true,
                traffic_light_position: None,
            }),
            window_min_size: Some(size(px(480.), px(320.))),
            ..Default::default()
        };
        cx.open_window(options, |window, cx| {
            let native = native_window_of(window).map(Rc::new);
            // Custom chrome: no native title bar or buttons, so moving and
            // resizing is left to the two drag areas.
            if let Some(native) = &native {
                native.set_title_bar_style(TitleBarStyle::Hidden);
            }
            window.on_window_should_close(cx, |_, cx| {
                cx.quit();
                true
            });
            cx.new(|_| DragAreasView {
                native,
                clicks: 0,
                limited: false,
                pressed: None,
            })
        })
        .expect("failed to open the window");
        cx.activate(true);
    });
}

/// What a press will start once the pointer moves.
#[derive(Clone, Copy)]
enum Target {
    Move,
    Resize(ResizeEdge),
}

struct DragAreasView {
    native: Option<Rc<NativeWindow>>,
    clicks: usize,
    limited: bool,
    /// A press on the bar or on a handle that has not turned into a drag yet.
    pressed: Option<(Target, gpui::Point<Pixels>)>,
}

impl DragAreasView {
    /// Runs `f` on the native window once the current event has been handled.
    ///
    /// Both calls track the mouse until the button is released (resizing in a
    /// nested event loop on macOS, a modal size/move loop on Windows) and
    /// move or resize the window meanwhile. Inside a GPUI event handler, GPUI
    /// cannot take the resulting resize events (its app state is borrowed) and
    /// the content would not follow; from a task, it can.
    fn with_native(&self, cx: &mut Context<Self>, f: impl FnOnce(&NativeWindow) + 'static) {
        let Some(native) = self.native.clone() else {
            return;
        };
        cx.spawn(async move |_, _| f(&native)).detach();
    }

    fn press(&mut self, target: Target, event: &MouseDownEvent) {
        self.pressed = Some((target, event.position));
    }

    /// The first move with the button down starts the native drag, like a
    /// pan gesture starts `DragToMoveArea` / `DragToResizeArea`.
    fn mouse_move(&mut self, event: &MouseMoveEvent, cx: &mut Context<Self>) {
        let Some((target, from)) = self.pressed else {
            return;
        };
        if event.pressed_button != Some(MouseButton::Left) {
            self.pressed = None;
            return;
        }
        let delta = event.position - from;
        if f32::from(delta.x).hypot(f32::from(delta.y)) < DRAG_SLOP {
            return;
        }
        self.pressed = None;
        match target {
            Target::Move => self.with_native(cx, |native| native.start_dragging()),
            Target::Resize(edge) => self.with_native(cx, move |native| native.start_resizing(edge)),
        }
    }

    fn toggle_maximized(&mut self, cx: &mut Context<Self>) {
        self.pressed = None;
        self.with_native(cx, |native| {
            if native.is_maximized() {
                native.unmaximize();
            } else {
                native.maximize();
            }
        });
    }

    fn move_bar(&self, cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .id("move-bar")
            .h(px(MOVE_BAR_HEIGHT))
            .flex_none()
            .flex()
            .items_center()
            .justify_center()
            .bg(rgb(PRIMARY_CONTAINER))
            .child("Drag here to move")
            .on_mouse_down(
                MouseButton::Left,
                cx.listener(|this, event: &MouseDownEvent, _, cx| {
                    if event.click_count >= 2 {
                        this.toggle_maximized(cx);
                    } else {
                        this.press(Target::Move, event);
                    }
                }),
            )
    }

    /// The eight handles over the edges and corners of the area inset by
    /// `RESIZE_EDGE_INSET` from the window, as `DragToResizeArea` lays them out.
    fn resize_handles(
        &self,
        viewport: gpui::Size<Pixels>,
        cx: &mut Context<Self>,
    ) -> Vec<gpui::AnyElement> {
        let inset = RESIZE_EDGE_INSET;
        let w = (f32::from(viewport.width) - 2. * inset).max(0.);
        let h = (f32::from(viewport.height) - 2. * inset).max(0.);
        let x = RESIZE_EDGE_SIZE.min(w / 2.);
        let y = RESIZE_EDGE_SIZE.min(h / 2.);
        let enabled: &[ResizeEdge] = if self.limited {
            &LIMITED_EDGES
        } else {
            &ALL_EDGES
        };
        enabled
            .iter()
            .map(|&edge| {
                let (left, top, width, height) = match edge {
                    ResizeEdge::TopLeft => (0., 0., x, y),
                    ResizeEdge::Top => (x, 0., w - 2. * x, y),
                    ResizeEdge::TopRight => (w - x, 0., x, y),
                    ResizeEdge::Left => (0., y, x, h - 2. * y),
                    ResizeEdge::Right => (w - x, y, x, h - 2. * y),
                    ResizeEdge::BottomLeft => (0., h - y, x, y),
                    ResizeEdge::Bottom => (x, h - y, w - 2. * x, y),
                    ResizeEdge::BottomRight => (w - x, h - y, x, y),
                };
                div()
                    .id(SharedString::from(format!("resize-{edge:?}")))
                    .absolute()
                    .left(px(inset + left))
                    .top(px(inset + top))
                    .w(px(width))
                    .h(px(height))
                    .bg(rgba(RESIZE_EDGE_COLOR))
                    .cursor(cursor_for(edge))
                    .on_mouse_down(
                        MouseButton::Left,
                        cx.listener(move |this, event: &MouseDownEvent, _, cx| {
                            this.press(Target::Resize(edge), event);
                            cx.stop_propagation();
                        }),
                    )
                    .into_any_element()
            })
            .collect()
    }
}

impl Render for DragAreasView {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let viewport = window.viewport_size();
        let content = div()
            .size_full()
            .flex()
            .flex_col()
            .bg(rgb(SURFACE))
            .child(self.move_bar(cx))
            .child(
                div()
                    .flex_1()
                    .flex()
                    .flex_col()
                    .items_center()
                    .justify_center()
                    .gap_3()
                    .child(div().text_lg().child(format!(
                        "Size: {} x {}",
                        f32::from(viewport.width).round(),
                        f32::from(viewport.height).round()
                    )))
                    .child("Double-click the bar to maximize, drag the tinted frame to resize.")
                    // The middle of the resize area lets the pointer through.
                    .child(format!("Clicks: {}", self.clicks))
                    .child(button("plus-one", "+1", true).on_click(cx.listener(
                        |this, _, _, cx| {
                            this.clicks += 1;
                            cx.notify();
                        },
                    )))
                    .child(
                        button(
                            "edges",
                            if self.limited {
                                "Edges: right and bottom"
                            } else {
                                "Edges: all"
                            },
                            false,
                        )
                        .on_click(cx.listener(|this, _, _, cx| {
                            this.limited = !this.limited;
                            cx.notify();
                        })),
                    ),
            );

        div()
            .id("root")
            .relative()
            .size_full()
            .bg(rgb(SURFACE_CONTAINER_HIGHEST))
            .text_color(rgb(ON_SURFACE))
            .text_sm()
            .p(px(RESIZE_EDGE_INSET + RESIZE_EDGE_SIZE))
            .on_mouse_move(
                cx.listener(|this, event: &MouseMoveEvent, _, cx| this.mouse_move(event, cx)),
            )
            .on_mouse_up(
                MouseButton::Left,
                cx.listener(|this, _, _, _| this.pressed = None),
            )
            .on_mouse_up_out(
                MouseButton::Left,
                cx.listener(|this, _, _, _| this.pressed = None),
            )
            .child(content)
            .children(self.resize_handles(viewport, cx))
    }
}

fn cursor_for(edge: ResizeEdge) -> CursorStyle {
    match edge {
        ResizeEdge::Top => CursorStyle::ResizeUp,
        ResizeEdge::Bottom => CursorStyle::ResizeDown,
        ResizeEdge::Left => CursorStyle::ResizeLeft,
        ResizeEdge::Right => CursorStyle::ResizeRight,
        ResizeEdge::TopLeft | ResizeEdge::BottomRight => CursorStyle::ResizeUpLeftDownRight,
        ResizeEdge::TopRight | ResizeEdge::BottomLeft => CursorStyle::ResizeUpRightDownLeft,
    }
}

/// A filled (`FilledButton`) or outlined (`OutlinedButton`) Material button.
fn button(id: &'static str, label: &'static str, filled: bool) -> gpui::Stateful<gpui::Div> {
    let button = div()
        .id(id)
        .px_6()
        .py_2p5()
        .rounded_full()
        .cursor_pointer()
        .child(label);
    if filled {
        button
            .bg(rgb(PRIMARY))
            .text_color(rgb(ON_PRIMARY))
            .hover(|this| this.opacity(0.9))
    } else {
        button
            .border_1()
            .border_color(rgb(OUTLINE))
            .text_color(rgb(PRIMARY))
            .hover(|this| this.bg(rgba(0x4f5b9214)))
    }
}
