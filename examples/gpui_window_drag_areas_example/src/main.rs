//! Window drag areas example — custom window chrome in GPUI: a coloured bar
//! that moves the window (`Window::start_dragging`, double click maximizes and
//! restores) and eight inset resize handles (`Window::start_resizing`).
//!
//! The GPUI counterpart of `flutter_window_drag_areas_example`, built on
//! nativeapi_gpui's `DragToMoveArea` and `DragToResizeArea` — the elements
//! mirroring nativeapi_flutter's widgets of the same names.
//!
//! Usage:
//!   cargo run   # in examples/gpui_window_drag_areas_example

use std::rc::Rc;

use gpui::prelude::*;
use gpui::{
    div, px, rgb, rgba, size, App, Application, Bounds, Edges, TitlebarOptions, Window,
    WindowBounds, WindowOptions,
};
use nativeapi::window::{ResizeEdge, TitleBarStyle, Window as NativeWindow};
use nativeapi_gpui::{DragToMoveArea, DragToResizeArea, WindowExt};

/// Thickness of the resize handles and their distance from the window edge.
///
/// The handles are inset so that they are clearly the app's, not the native
/// window frame's. A GUI test presses in the middle of these bands; keep the
/// numbers in sync with it (they match the Flutter example's).
const RESIZE_EDGE_SIZE: f32 = 12.;
const RESIZE_EDGE_INSET: f32 = 16.;
/// Height of the move bar, at the top of the panel inside the handles.
const MOVE_BAR_HEIGHT: f32 = 44.;

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
            let native = window.native_window().map(Rc::new);
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
            })
        })
        .expect("failed to open the window");
        cx.activate(true);
    });
}

struct DragAreasView {
    native: Option<Rc<NativeWindow>>,
    clicks: usize,
    limited: bool,
}

impl Render for DragAreasView {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let viewport = window.viewport_size();

        let mut move_bar = DragToMoveArea::new("move-bar");
        let mut resize_area = DragToResizeArea::new("resize-area");
        if let Some(native) = &self.native {
            move_bar = move_bar.window(native.clone());
            resize_area = resize_area.window(native.clone());
        }
        let move_bar = move_bar
            .h(px(MOVE_BAR_HEIGHT))
            .flex_none()
            .flex()
            .items_center()
            .justify_center()
            .bg(rgb(PRIMARY_CONTAINER))
            .child("Drag here to move");

        let content = div()
            .size_full()
            .flex()
            .flex_col()
            .bg(rgb(SURFACE))
            .child(move_bar)
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

        resize_area
            .resize_edge_size(px(RESIZE_EDGE_SIZE))
            .resize_edge_margin(Edges::all(px(RESIZE_EDGE_INSET)))
            .resize_edge_color(rgba(RESIZE_EDGE_COLOR))
            .enabled_edges(if self.limited {
                LIMITED_EDGES.to_vec()
            } else {
                ALL_EDGES.to_vec()
            })
            .bg(rgb(SURFACE_CONTAINER_HIGHEST))
            .text_color(rgb(ON_SURFACE))
            .text_sm()
            .p(px(RESIZE_EDGE_INSET + RESIZE_EDGE_SIZE))
            .child(content)
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
