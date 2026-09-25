//! The two windows: the 480 × 680 control window with the gallery and the
//! shadow controls, and the shaped preview.

use std::sync::Arc;

use gpui::prelude::*;
use gpui::{
    canvas, div, img, linear_color_stop, linear_gradient, px, rgb, rgba, App, Context,
    DispatchPhase, Entity, FocusHandle, FontWeight, KeyDownEvent, MouseButton, MouseDownEvent,
    MouseMoveEvent, MouseUpEvent, Pixels, RenderImage, SharedString, Window,
};

use crate::art::{paint_art, thumbnail, ShapeLook};
use crate::geometry::DemoShape;
use crate::palette::Palette;
use crate::playground::{Playground, ShadowParams, SHADOW_COLORS, SHADOW_PRESETS};
use crate::widgets::{caption, chip, hint, mono, option_row, paint_slider};

const THUMBNAIL: f64 = 46.0;

// ---------------------------------------------------------------------------
// Shadow sliders
// ---------------------------------------------------------------------------

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Slider {
    Opacity,
    Blur,
    Horizontal,
    Vertical,
}

impl Slider {
    const ALL: [Slider; 4] = [
        Slider::Opacity,
        Slider::Blur,
        Slider::Horizontal,
        Slider::Vertical,
    ];

    fn label(self) -> &'static str {
        match self {
            Slider::Opacity => "Opacity",
            Slider::Blur => "Blur radius",
            Slider::Horizontal => "Horizontal",
            Slider::Vertical => "Vertical",
        }
    }

    /// Minimum, maximum and step.
    fn range(self) -> (f64, f64, f64) {
        match self {
            Slider::Opacity => (0.0, 1.0, 0.01),
            Slider::Blur => (0.0, 64.0, 1.0),
            Slider::Horizontal | Slider::Vertical => (-64.0, 64.0, 1.0),
        }
    }

    fn get(self, shadow: &ShadowParams) -> f64 {
        match self {
            Slider::Opacity => shadow.opacity,
            Slider::Blur => shadow.blur,
            Slider::Horizontal => shadow.x,
            Slider::Vertical => shadow.y,
        }
    }

    fn display(self, value: f64) -> String {
        match self {
            Slider::Opacity => format!("{}%", (value * 100.0).round()),
            _ => format!("{} px", value.round()),
        }
    }

    /// Snaps to the step and clamps, then stores the value.
    fn set(self, playground: &Entity<Playground>, value: f64, cx: &mut App) {
        let (min, max, step) = self.range();
        // Divide by the steps per unit (100, 1) so 30 % is exactly 0.3.
        let value = (min + ((value - min) / step).round() / (1.0 / step).round()).clamp(min, max);
        playground.update(cx, |p, cx| {
            p.change_shadow(
                |shadow| match self {
                    Slider::Opacity => shadow.opacity = value,
                    Slider::Blur => shadow.blur = value,
                    Slider::Horizontal => shadow.x = value,
                    Slider::Vertical => shadow.y = value,
                },
                cx,
            )
        });
    }

    /// The value under the pointer at `x` in a slider laid out at `bounds`.
    fn value_at(self, bounds: gpui::Bounds<Pixels>, x: Pixels) -> f64 {
        let (min, max, _) = self.range();
        let width = f64::from(bounds.size.width) - 14.0;
        if width <= 0.0 {
            return min;
        }
        let fraction = ((f64::from(x - bounds.origin.x) - 7.0) / width).clamp(0.0, 1.0);
        min + fraction * (max - min)
    }
}

// ---------------------------------------------------------------------------
// Control window
// ---------------------------------------------------------------------------

pub struct ControlsView {
    playground: Entity<Playground>,
    thumbnails: Vec<Arc<RenderImage>>,
    slider_focus: Vec<FocusHandle>,
    dragging: Option<Slider>,
}

impl ControlsView {
    pub fn new(
        playground: Entity<Playground>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> Self {
        cx.observe(&playground, |_, _, cx| cx.notify()).detach();
        cx.observe_window_appearance(window, |_, _, cx| cx.notify())
            .detach();
        // Rendered once at 3× so they stay sharp on any display.
        let thumbnails = DemoShape::ALL
            .iter()
            .map(|&shape| thumbnail(shape, THUMBNAIL, 3.0))
            .collect();
        Self {
            playground,
            thumbnails,
            slider_focus: Slider::ALL.iter().map(|_| cx.focus_handle()).collect(),
            dragging: None,
        }
    }

    fn shape_card(&self, index: usize, p: &Palette, cx: &Context<Self>) -> impl IntoElement {
        let shape = DemoShape::ALL[index];
        let state = self.playground.read(cx);
        let selected = !state.rectangle_restored && state.shape == shape;
        let playground = self.playground.clone();
        div()
            .id(("shape", index))
            .flex_1()
            .h_full()
            .flex()
            .flex_col()
            .items_center()
            .justify_center()
            .gap(px(5.))
            .rounded(px(12.))
            .border_1()
            .border_color(rgba(if selected { p.accent } else { p.border }))
            .bg(rgba(if selected {
                p.accent_surface
            } else {
                p.surface
            }))
            .cursor_pointer()
            .on_click(move |_, _, cx| {
                playground.update(cx, |p, cx| p.select_shape(shape, cx));
            })
            .child(img(self.thumbnails[index].clone()).size(px(THUMBNAIL as f32)))
            .child(
                div()
                    .text_size(px(11.))
                    .text_color(rgba(if selected { p.accent } else { p.text }))
                    .when(selected, |this| this.font_weight(FontWeight::SEMIBOLD))
                    .child(shape.name()),
            )
    }

    fn gallery(&self, p: &Palette, cx: &Context<Self>) -> impl IntoElement {
        div()
            .size_full()
            .flex()
            .flex_col()
            .px(px(12.))
            .children((0..3).map(|row| {
                div().flex_1().pb(px(8.)).child(
                    div()
                        .size_full()
                        .flex()
                        .gap(px(8.))
                        .children((0..4).map(|col| self.shape_card(row * 4 + col, p, cx))),
                )
            }))
    }

    fn slider_row(
        &self,
        index: usize,
        p: &'static Palette,
        window: &Window,
        cx: &Context<Self>,
    ) -> impl IntoElement {
        let slider = Slider::ALL[index];
        let (min, max, step) = slider.range();
        let value = slider.get(&self.playground.read(cx).shadow);
        let fraction = ((value - min) / (max - min)).clamp(0.0, 1.0);
        let focus = self.slider_focus[index].clone();
        let focused = focus.is_focused(window);
        let view = cx.entity();
        let playground = self.playground.clone();

        let on_key = {
            let playground = playground.clone();
            move |event: &KeyDownEvent, _: &mut Window, cx: &mut App| {
                let value = slider.get(&playground.read(cx).shadow);
                let next = match event.keystroke.key.as_str() {
                    "left" | "down" => value - step,
                    "right" | "up" => value + step,
                    "home" => min,
                    "end" => max,
                    _ => return,
                };
                slider.set(&playground, next, cx);
                cx.stop_propagation();
            }
        };

        div()
            .flex()
            .items_center()
            .px(px(10.))
            .py(px(4.))
            .border_b_1()
            .border_color(rgba(p.border))
            .child(
                div()
                    .w(px(76.))
                    .flex_none()
                    .text_size(px(11.))
                    .text_color(rgba(p.muted))
                    .child(slider.label()),
            )
            .child(
                div()
                    .flex_1()
                    .h(px(28.))
                    .cursor_pointer()
                    .track_focus(&focus)
                    .on_key_down(on_key)
                    .child(
                        canvas(
                            |_, _, _| {},
                            move |bounds, _, window, _| {
                                paint_slider(bounds, fraction, focused, p, window);
                                // Pointer handling: press to jump, drag
                                // anywhere while the button is held.
                                let (view_down, view_move, view_up) =
                                    (view.clone(), view.clone(), view);
                                let (playground_down, playground_move) =
                                    (playground.clone(), playground);
                                window.on_mouse_event(
                                    move |event: &MouseDownEvent, phase, window, cx| {
                                        if phase != DispatchPhase::Bubble
                                            || event.button != MouseButton::Left
                                            || !bounds.contains(&event.position)
                                        {
                                            return;
                                        }
                                        window.focus(&focus);
                                        view_down.update(cx, |v, _| v.dragging = Some(slider));
                                        let value = slider.value_at(bounds, event.position.x);
                                        slider.set(&playground_down, value, cx);
                                        cx.stop_propagation();
                                    },
                                );
                                window.on_mouse_event(
                                    move |event: &MouseMoveEvent, phase, _, cx| {
                                        if phase != DispatchPhase::Bubble
                                            || event.pressed_button != Some(MouseButton::Left)
                                            || view_move.read(cx).dragging != Some(slider)
                                        {
                                            return;
                                        }
                                        let value = slider.value_at(bounds, event.position.x);
                                        slider.set(&playground_move, value, cx);
                                    },
                                );
                                window.on_mouse_event(move |_: &MouseUpEvent, phase, _, cx| {
                                    if phase == DispatchPhase::Bubble
                                        && view_up.read(cx).dragging == Some(slider)
                                    {
                                        view_up.update(cx, |v, _| v.dragging = None);
                                    }
                                });
                            },
                        )
                        .size_full(),
                    ),
            )
            .child(
                div()
                    .w(px(52.))
                    .flex_none()
                    .flex()
                    .justify_end()
                    .child(mono(slider.display(value), p.muted)),
            )
    }

    fn shadow_controls(
        &self,
        p: &'static Palette,
        window: &Window,
        cx: &Context<Self>,
    ) -> impl IntoElement {
        let state = self.playground.read(cx);
        let enabled = state.shadow_enabled;
        let playground = &self.playground;

        let toggle = |id: &'static str, label: &'static str, on: bool| {
            // Only the chip that changes the state is enabled.
            let active = on != enabled;
            let playground = playground.clone();
            chip(id, label, !active, active, p)
                .when(active, |this| {
                    this.on_click(move |_, _, cx| {
                        playground.update(cx, |p, cx| p.toggle_shadow(cx))
                    })
                })
                .into_any_element()
        };
        let colors = SHADOW_COLORS
            .iter()
            .map(|&(name, color)| {
                let playground = playground.clone();
                chip(
                    SharedString::from(format!("color-{name}")),
                    name,
                    state.shadow.color == color,
                    true,
                    p,
                )
                .on_click(move |_, _, cx| {
                    playground.update(cx, |p, cx| p.change_shadow(|s| s.color = color, cx))
                })
                .into_any_element()
            })
            .collect();
        let reset = {
            let playground = playground.clone();
            chip("reset-shadow", "Reset shadow parameters", false, true, p)
                .on_click(move |_, _, cx| {
                    playground.update(cx, |p, cx| p.reset_shadow_parameters(cx))
                })
                .into_any_element()
        };

        div()
            .w_full()
            .flex()
            .flex_col()
            .child(option_row(
                "Shadow",
                p,
                vec![
                    toggle("shadow-on", "On", true),
                    toggle("shadow-off", "Off", false),
                    hint("Contour shadow", p).into_any_element(),
                ],
            ))
            .child(option_row("Color", p, colors))
            .children((0..Slider::ALL.len()).map(|i| self.slider_row(i, p, window, cx)))
            .child(option_row("Defaults", p, vec![reset]))
            .when(!enabled, |this| {
                this.child(
                    div()
                        .p(px(10.))
                        .child(hint("Shadow hidden. Changes appear when enabled.", p)),
                )
            })
            .when_some(state.shadow_error.clone(), |this, error| {
                this.child(div().p(px(10.)).text_color(rgba(p.danger)).child(error))
            })
    }
}

impl Render for ControlsView {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let p = Palette::of(window);
        let state = self.playground.read(cx);
        let editing = state.editing_shadow;
        let look = ShapeLook::of(state.shape);
        let preset = state.selected_shadow_preset();
        let to_size = state.to_size as u32;
        let (status, status_color) = match &state.shadow_error {
            Some(error) => (error.clone(), p.danger),
            None => (state.status.clone(), p.muted),
        };
        let playground = self.playground.clone();
        let action = |id: &'static str,
                      label: &'static str,
                      run: fn(&mut Playground, &mut Context<Playground>)| {
            let playground = playground.clone();
            chip(id, label, false, true, p)
                .on_click(move |_, _, cx| playground.update(cx, run))
                .into_any_element()
        };
        let toggle_editing = |id: &'static str, label: &'static str, selected: bool| {
            let playground = playground.clone();
            chip(id, label, selected, true, p).on_click(move |_, _, cx| {
                playground.update(cx, |p, cx| {
                    p.editing_shadow = !p.editing_shadow;
                    cx.notify();
                })
            })
        };

        let header = div()
            .h(px(48.))
            .flex_none()
            .flex()
            .items_center()
            .px(px(16.))
            .bg(linear_gradient(
                90.,
                linear_color_stop(rgb(0x201C45), 0.),
                linear_color_stop(rgb(look.colors[0]), 1.),
            ))
            .child(
                div()
                    .text_size(px(19.))
                    .font_weight(FontWeight::BOLD)
                    .text_color(rgb(0xFFFFFF))
                    .child("Outside the box."),
            )
            .child(div().flex_1())
            .child(
                div()
                    .text_size(px(9.))
                    .text_color(rgb(0xDDD5FF))
                    .child("SHAPE PLAYGROUND"),
            );

        let section = div()
            .flex()
            .items_center()
            .pt(px(12.))
            .pb(px(8.))
            .px(px(14.))
            .child(caption(if editing {
                "CUSTOM SHADOW"
            } else {
                "SHAPE COLLECTION"
            }))
            .child(div().flex_1())
            .child(if editing {
                toggle_editing("done", "Done", true).into_any_element()
            } else {
                mono(format!("{} silhouettes", DemoShape::ALL.len()), p.muted).into_any_element()
            });

        let body = div().flex_1().min_h_0().child(if editing {
            div()
                .size_full()
                .flex()
                .flex_col()
                .justify_center()
                .child(self.shadow_controls(p, window, cx))
                .into_any_element()
        } else {
            self.gallery(p, cx).into_any_element()
        });

        let presets = div().flex().px(px(12.)).pb(px(12.)).children(
            std::iter::once("None")
                .chain(SHADOW_PRESETS.iter().map(|preset| preset.0))
                .map(|name| {
                    let playground = playground.clone();
                    div().flex_1().px(px(3.)).child(
                        chip(
                            SharedString::from(format!("preset-{name}")),
                            name,
                            preset == name,
                            true,
                            p,
                        )
                        .on_click(move |_, _, cx| {
                            playground.update(cx, |p, cx| p.select_shadow_preset(name, cx))
                        }),
                    )
                }),
        );

        div()
            .size_full()
            .flex()
            .flex_col()
            .bg(rgba(p.background))
            .text_size(px(12.))
            .line_height(px(15.6))
            .text_color(rgba(p.text))
            .child(header)
            .child(section)
            .child(body)
            .when(!editing, |this| {
                this.child(option_row(
                    "Window",
                    p,
                    vec![
                        action("apply", "Apply shape", |p, cx| p.select_shape(p.shape, cx)),
                        action(
                            "restore",
                            "Restore rectangle",
                            Playground::restore_rectangle,
                        ),
                    ],
                ))
                .child(option_row(
                    "Size",
                    p,
                    vec![
                        action("toggle-size", "Toggle size", Playground::toggle_size),
                        mono(format!("{to_size} × {to_size} · 450 ms"), p.muted).into_any_element(),
                    ],
                ))
            })
            .child(
                div()
                    .flex()
                    .items_center()
                    .gap(px(8.))
                    .pt(px(10.))
                    .pb(px(6.))
                    .px(px(14.))
                    .child(caption("SHADOW"))
                    .child(mono(preset, p.muted))
                    .child(div().flex_1())
                    .child(toggle_editing(
                        "adjust",
                        if editing {
                            "Back to shapes"
                        } else {
                            "Adjust…"
                        },
                        editing,
                    )),
            )
            .child(presets)
            .child(
                div()
                    .w_full()
                    .px(px(12.))
                    .py(px(8.))
                    .bg(rgba(p.surface))
                    .border_t_1()
                    .border_color(rgba(p.border))
                    .child(mono(status, status_color).line_clamp(2)),
            )
    }
}

// ---------------------------------------------------------------------------
// Preview window
// ---------------------------------------------------------------------------

pub struct PreviewView {
    playground: Entity<Playground>,
}

impl PreviewView {
    pub fn new(playground: Entity<Playground>, cx: &mut Context<Self>) -> Self {
        cx.observe(&playground, |_, _, cx| cx.notify()).detach();
        Self { playground }
    }
}

impl Render for PreviewView {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let state = self.playground.read(cx);
        let side = px(state.size as f32);
        let look = ShapeLook::of(state.shape);
        let title = if state.rectangle_restored {
            "rectangle"
        } else {
            state.shape.name()
        };
        let count = state.count;
        let (drag, tap) = (self.playground.clone(), self.playground.clone());

        let content = div()
            .size_full()
            .flex()
            .flex_col()
            .items_center()
            .justify_center()
            .child(
                div()
                    .p(px(10.))
                    .cursor_grab()
                    .text_size(px(10.))
                    .text_color(rgba(0xFFFFFFDD))
                    .on_mouse_down(MouseButton::Left, move |_, _, cx| {
                        if let Some(window) = drag.read(cx).preview_window() {
                            window.start_dragging();
                        }
                    })
                    .child("⠿  DRAG ME"),
            )
            .child(
                div()
                    .text_size(px(29.))
                    .line_height(px(37.7))
                    .font_weight(FontWeight::BOLD)
                    .child(title),
            )
            .child(
                div()
                    .id("tap")
                    .mt(px(10.))
                    .px(px(18.))
                    .py(px(9.))
                    .rounded(px(30.))
                    .bg(rgba(0xFFFFFF30))
                    .border_1()
                    .border_color(rgba(0xFFFFFF70))
                    .cursor_pointer()
                    .font_weight(FontWeight::SEMIBOLD)
                    .on_click(move |_, _, cx| {
                        tap.update(cx, |p, cx| {
                            p.count += 1;
                            cx.notify();
                        })
                    })
                    .child(format!("Tap · {count}")),
            )
            .child(
                div()
                    .mt(px(10.))
                    .text_size(px(9.))
                    .text_color(rgba(0xFFFFFFCC))
                    .child(look.name.to_uppercase()),
            );

        // The content keeps its own size at the top-left corner; the window
        // around it may be larger while a resize animates, and stays clear.
        div().size_full().child(
            div()
                .relative()
                .size(side)
                .text_size(px(12.))
                .text_color(rgb(0xFFFFFF))
                .child(
                    canvas(
                        |_, _, _| {},
                        move |bounds, _, window, _| paint_art(bounds, &look, window),
                    )
                    .absolute()
                    .size_full(),
                )
                .child(content),
        )
    }
}
