use std::rc::Rc;

use gpui::{
    div, prelude::*, App, Div, ElementId, MouseButton, MouseDownEvent, Pixels, StyleRefinement,
    Window,
};
use nativeapi::window::Window as NativeWindow;

use crate::drag_to_resize_area::{resolve, track_press};
use crate::window::defer_native;

/// Moves the window when dragged, and maximizes or restores it on a double
/// click — the GPUI counterpart of `nativeapi_flutter`'s `DragToMoveArea`.
///
/// The drag starts once the pointer has moved a couple of pixels with the
/// button down, so a click inside stays a click. Put it under a custom title
/// bar, typically with the native one hidden
/// (`set_title_bar_style(TitleBarStyle::Hidden)`).
///
/// ```ignore
/// DragToMoveArea::new("title-bar").h(px(44.)).child("My app")
/// ```
#[derive(IntoElement)]
pub struct DragToMoveArea {
    id: ElementId,
    window: Option<Rc<NativeWindow>>,
    base: Div,
}

impl DragToMoveArea {
    pub fn new(id: impl Into<ElementId>) -> Self {
        Self {
            id: id.into(),
            window: None,
            base: div(),
        }
    }

    /// The window to move. Defaults to the window the area is drawn in.
    pub fn window(mut self, window: Rc<NativeWindow>) -> Self {
        self.window = Some(window);
        self
    }
}

impl ParentElement for DragToMoveArea {
    fn extend(&mut self, elements: impl IntoIterator<Item = gpui::AnyElement>) {
        self.base.extend(elements);
    }
}

impl Styled for DragToMoveArea {
    fn style(&mut self) -> &mut StyleRefinement {
        self.base.style()
    }
}

impl RenderOnce for DragToMoveArea {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let pressed =
            window.use_keyed_state(self.id.clone(), cx, |_, _| None::<gpui::Point<Pixels>>);
        let target = self.window;
        let on_drag = {
            let target = target.clone();
            move |window: &mut Window, cx: &mut App| {
                if let Some(native) = resolve(&target, window) {
                    defer_native(cx, move || native.start_dragging());
                }
            }
        };
        self.base
            .id(self.id)
            .on_mouse_down(MouseButton::Left, {
                let pressed = pressed.clone();
                move |event: &MouseDownEvent, window, cx| {
                    if event.click_count >= 2 {
                        pressed.update(cx, |pressed, _| *pressed = None);
                        if let Some(native) = resolve(&target, window) {
                            defer_native(cx, move || {
                                if native.is_maximized() {
                                    native.unmaximize();
                                } else {
                                    native.maximize();
                                }
                            });
                        }
                    } else {
                        pressed.update(cx, |pressed, _| *pressed = Some(event.position));
                    }
                }
            })
            .child(track_press(pressed, move |_, window, cx| {
                on_drag(window, cx)
            }))
    }
}
