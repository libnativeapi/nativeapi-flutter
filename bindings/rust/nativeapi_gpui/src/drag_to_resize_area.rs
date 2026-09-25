use std::rc::Rc;

use gpui::{
    canvas, div, prelude::*, px, App, CursorStyle, DispatchPhase, Div, ElementId, Entity, Hsla,
    MouseButton, MouseDownEvent, MouseMoveEvent, MouseUpEvent, Pixels, Point, StyleRefinement,
    Window,
};
use nativeapi::window::{ResizeEdge, Window as NativeWindow};

use crate::window::{defer_native, WindowExt};

/// How far the pointer has to move with the button down before a press turns
/// into a native drag.
const DRAG_SLOP: f32 = 2.0;

const ALL_EDGES: [ResizeEdge; 8] = [
    ResizeEdge::Top,
    ResizeEdge::Left,
    ResizeEdge::Right,
    ResizeEdge::Bottom,
    ResizeEdge::TopLeft,
    ResizeEdge::TopRight,
    ResizeEdge::BottomLeft,
    ResizeEdge::BottomRight,
];

/// Resize handles along the edges and corners of its content — the GPUI
/// counterpart of `nativeapi_flutter`'s `DragToResizeArea`, for windows with
/// custom chrome.
///
/// The handles lie on top of the content, `resize_edge_size` wide, inset by
/// `resize_edge_margin`; the rest of the content receives the pointer as
/// usual. The area fills its parent.
///
/// ```ignore
/// DragToResizeArea::new("resize").resize_edge_size(px(6.)).child(content)
/// ```
#[derive(IntoElement)]
pub struct DragToResizeArea {
    id: ElementId,
    window: Option<Rc<NativeWindow>>,
    resize_edge_size: Pixels,
    resize_edge_color: Hsla,
    resize_edge_margin: gpui::Edges<Pixels>,
    enabled_edges: Vec<ResizeEdge>,
    base: Div,
}

impl DragToResizeArea {
    pub fn new(id: impl Into<ElementId>) -> Self {
        Self {
            id: id.into(),
            window: None,
            resize_edge_size: px(8.0),
            resize_edge_color: gpui::transparent_black(),
            resize_edge_margin: gpui::Edges::default(),
            enabled_edges: ALL_EDGES.to_vec(),
            base: div(),
        }
    }

    /// The window to resize. Defaults to the window the area is drawn in.
    pub fn window(mut self, window: Rc<NativeWindow>) -> Self {
        self.window = Some(window);
        self
    }

    /// Width of the handles (8 px by default).
    pub fn resize_edge_size(mut self, size: Pixels) -> Self {
        self.resize_edge_size = size;
        self
    }

    /// Color the handles are painted with (transparent by default).
    pub fn resize_edge_color(mut self, color: impl Into<Hsla>) -> Self {
        self.resize_edge_color = color.into();
        self
    }

    /// Insets the handles from the area's edges (none by default).
    pub fn resize_edge_margin(mut self, margin: gpui::Edges<Pixels>) -> Self {
        self.resize_edge_margin = margin;
        self
    }

    /// Only these edges get a handle (all eight by default).
    pub fn enabled_edges(mut self, edges: impl IntoIterator<Item = ResizeEdge>) -> Self {
        self.enabled_edges = edges.into_iter().collect();
        self
    }
}

impl ParentElement for DragToResizeArea {
    fn extend(&mut self, elements: impl IntoIterator<Item = gpui::AnyElement>) {
        self.base.extend(elements);
    }
}

impl Styled for DragToResizeArea {
    fn style(&mut self) -> &mut StyleRefinement {
        self.base.style()
    }
}

impl RenderOnce for DragToResizeArea {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let pressed = window.use_keyed_state(self.id.clone(), cx, |_, _| {
            None::<(ResizeEdge, Point<Pixels>)>
        });
        let (s, m) = (self.resize_edge_size, self.resize_edge_margin);
        let handles: Vec<_> = self
            .enabled_edges
            .iter()
            .map(|&edge| {
                let handle = div()
                    .id(ElementId::NamedInteger(
                        "nativeapi-resize-edge".into(),
                        edge as u64,
                    ))
                    .absolute()
                    .bg(self.resize_edge_color)
                    .cursor(cursor_for(edge));
                // Edges run between the corners; corners are s × s squares.
                let handle = match edge {
                    ResizeEdge::TopLeft => handle.left(m.left).top(m.top).size(s),
                    ResizeEdge::Top => handle.left(m.left + s).right(m.right + s).top(m.top).h(s),
                    ResizeEdge::TopRight => handle.right(m.right).top(m.top).size(s),
                    ResizeEdge::Left => {
                        handle.left(m.left).top(m.top + s).bottom(m.bottom + s).w(s)
                    }
                    ResizeEdge::Right => handle
                        .right(m.right)
                        .top(m.top + s)
                        .bottom(m.bottom + s)
                        .w(s),
                    ResizeEdge::BottomLeft => handle.left(m.left).bottom(m.bottom).size(s),
                    ResizeEdge::Bottom => handle
                        .left(m.left + s)
                        .right(m.right + s)
                        .bottom(m.bottom)
                        .h(s),
                    ResizeEdge::BottomRight => handle.right(m.right).bottom(m.bottom).size(s),
                };
                let pressed = pressed.clone();
                handle.on_mouse_down(MouseButton::Left, move |event: &MouseDownEvent, _, cx| {
                    pressed.update(cx, |pressed, _| *pressed = Some((edge, event.position)));
                    cx.stop_propagation();
                })
            })
            .collect();
        let target = self.window;
        let tracker = track_press(pressed, move |edge, window, cx| {
            if let Some(native) = resolve(&target, window) {
                defer_native(cx, move || native.start_resizing(edge));
            }
        });
        self.base
            .relative()
            .size_full()
            .children(handles)
            .child(tracker)
    }
}

/// The window to act on: the given one, or the one the element is drawn in.
pub(crate) fn resolve(
    explicit: &Option<Rc<NativeWindow>>,
    window: &Window,
) -> Option<Rc<NativeWindow>> {
    explicit
        .clone()
        .or_else(|| window.native_window().map(Rc::new))
}

/// A press stored in `pressed` (with the press position last) turns into
/// `on_drag` once the pointer moves `DRAG_SLOP` with the button down, wherever
/// the pointer is; releasing the button first forgets it.
pub(crate) trait Press: Clone + 'static {
    type Payload: Copy + 'static;
    fn position(&self) -> Point<Pixels>;
    fn payload(&self) -> Self::Payload;
}

impl Press for Point<Pixels> {
    type Payload = ();
    fn position(&self) -> Point<Pixels> {
        *self
    }
    fn payload(&self) {}
}

impl Press for (ResizeEdge, Point<Pixels>) {
    type Payload = ResizeEdge;
    fn position(&self) -> Point<Pixels> {
        self.1
    }
    fn payload(&self) -> ResizeEdge {
        self.0
    }
}

pub(crate) fn track_press<P: Press>(
    pressed: Entity<Option<P>>,
    on_drag: impl Fn(P::Payload, &mut Window, &mut App) + 'static,
) -> impl IntoElement {
    canvas(
        |_, _, _| {},
        move |_, _, window, _| {
            let moved = pressed.clone();
            window.on_mouse_event(move |event: &MouseMoveEvent, phase, window, cx| {
                if phase != DispatchPhase::Bubble {
                    return;
                }
                let Some(press) = moved.read(cx).clone() else {
                    return;
                };
                if event.pressed_button != Some(MouseButton::Left) {
                    moved.update(cx, |pressed, _| *pressed = None);
                    return;
                }
                let delta = event.position - press.position();
                if f32::from(delta.x).hypot(f32::from(delta.y)) < DRAG_SLOP {
                    return;
                }
                moved.update(cx, |pressed, _| *pressed = None);
                on_drag(press.payload(), window, cx);
            });
            window.on_mouse_event(move |_: &MouseUpEvent, phase, _, cx| {
                if phase == DispatchPhase::Bubble {
                    pressed.update(cx, |pressed, _| *pressed = None);
                }
            });
        },
    )
    .absolute()
    .size_0()
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
