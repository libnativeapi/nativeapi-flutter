//! The Canvas tab: every display and window drawn to scale, and a quick-info
//! panel for the selected window.

use gpui::prelude::*;
use gpui::{
    canvas, div, linear_color_stop, linear_gradient, px, relative, AnyElement, Context, Div,
    FontWeight, Hsla, SharedString, Window,
};
use nativeapi::display::Display;
use nativeapi::geometry::Rectangle;
use nativeapi::window::{Window as NativeWindow, WindowId};

use crate::example::{Outcome, Tab, WindowExample};
use crate::ui::{self, color};

const MIN_ZOOM: f32 = 0.5;
const MAX_ZOOM: f32 = 5.0;
const ZOOM_STEP: f32 = 1.3;
/// Padding around everything drawn, in screen points.
const WORLD_PADDING: f64 = 50.0;

impl WindowExample {
    pub(crate) fn canvas_tab(&mut self, window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let narrow = window.viewport_size().width < px(600.);
        let info = self
            .selected_window()
            .map(|selected| self.quick_info(selected, cx).into_any_element());
        div()
            .size_full()
            .flex()
            .when(narrow, |this| this.flex_col())
            .child(
                div()
                    .flex_1()
                    .min_w_0()
                    .min_h_0()
                    .child(self.window_canvas(cx)),
            )
            // 3 : 2, as the Flutter example's flex factors.
            .when_some(info, |this, info| {
                this.child(
                    div()
                        .flex_none()
                        .when(narrow, |this| this.w_full().h(relative(0.4)))
                        .when(!narrow, |this| this.h_full().w(relative(0.4)))
                        .child(info),
                )
            })
            .into_any_element()
    }

    // -----------------------------------------------------------------------
    // The canvas
    // -----------------------------------------------------------------------

    fn window_canvas(&self, cx: &mut Context<Self>) -> impl IntoElement {
        let measured = self.canvas_size.clone();
        let content = match world_bounds(&self.displays, &self.windows) {
            None => div()
                .size_full()
                .flex()
                .items_center()
                .justify_center()
                .child("No displays or windows available")
                .into_any_element(),
            Some(world) => {
                let area = measured.get();
                let fit = (f64::from(area.width) / world.width)
                    .min(f64::from(area.height) / world.height)
                    * 0.9;
                let fit = fit.max(0.01);
                let view = View {
                    world,
                    fit,
                    zoom: self.zoom as f64,
                };
                div()
                    .relative()
                    .flex_none()
                    .w(px((view.world.width * view.scale()) as f32))
                    .h(px((view.world.height * view.scale()) as f32))
                    .children(self.displays.iter().map(|d| display_shape(d, &view)))
                    .children(
                        self.windows
                            .iter()
                            .filter_map(|w| self.window_shape(w, &view, cx)),
                    )
                    .into_any_element()
            }
        };

        let zoom_button = |id: &'static str, label: &'static str| {
            div()
                .id(id)
                .size(px(36.))
                .flex()
                .items_center()
                .justify_center()
                .cursor_pointer()
                .text_size(px(18.))
                .hover(|style| style.bg(gpui::black().opacity(0.06)))
                .child(label)
        };

        div().size_full().p_3().child(
            ui::card()
                .relative()
                .size_full()
                .overflow_hidden()
                .bg(linear_gradient(
                    135.,
                    linear_color_stop(color(ui::GREY_100), 0.),
                    linear_color_stop(color(ui::GREY_200), 1.),
                ))
                .child(
                    div().size_full().p_4().child(
                        div()
                            .relative()
                            .size_full()
                            // Measures the drawing area; the next frame
                            // fits the drawing to it.
                            .child(
                                canvas(
                                    move |bounds, window, _| {
                                        if measured.get() != bounds.size {
                                            measured.set(bounds.size);
                                            window.on_next_frame(|window, _| window.refresh());
                                        }
                                    },
                                    |_, _, _, _| {},
                                )
                                .absolute()
                                .size_full(),
                            )
                            .child(
                                div()
                                    .id("canvas-scroll")
                                    .size_full()
                                    .overflow_scroll()
                                    .child(content),
                            ),
                    ),
                )
                // Zoom controls.
                .child(
                    div()
                        .absolute()
                        .top_2()
                        .right_2()
                        .flex()
                        .flex_col()
                        .rounded(px(8.))
                        .bg(gpui::white().opacity(0.95))
                        .shadow_sm()
                        .child(zoom_button("zoom-in", "+").on_click(cx.listener(
                            |this, _, _, cx| {
                                this.zoom = (this.zoom * ZOOM_STEP).clamp(MIN_ZOOM, MAX_ZOOM);
                                cx.notify();
                            },
                        )))
                        .child(div().h(px(1.)).bg(color(ui::OUTLINE_VARIANT)))
                        .child(zoom_button("zoom-out", "−").on_click(cx.listener(
                            |this, _, _, cx| {
                                this.zoom = (this.zoom / ZOOM_STEP).clamp(MIN_ZOOM, MAX_ZOOM);
                                cx.notify();
                            },
                        )))
                        .child(div().h(px(1.)).bg(color(ui::OUTLINE_VARIANT)))
                        .child(zoom_button("zoom-fit", "⤢").on_click(cx.listener(
                            |this, _, _, cx| {
                                this.zoom = 1.0;
                                cx.notify();
                            },
                        ))),
                )
                // Scale indicator.
                .child(
                    div()
                        .absolute()
                        .bottom_2()
                        .left_2()
                        .px_2()
                        .py_1()
                        .rounded(px(4.))
                        .bg(gpui::black().opacity(0.6))
                        .text_color(gpui::white())
                        .text_size(px(12.))
                        .font_weight(FontWeight::BOLD)
                        .child(format!("{:.0}%", self.zoom * 100.)),
                ),
        )
    }

    fn window_shape(
        &self,
        window: &NativeWindow,
        view: &View,
        cx: &mut Context<Self>,
    ) -> Option<AnyElement> {
        let wb = window.bounds();
        let cb = window.content_bounds();
        let id = window.id();
        let scale = view.scale();

        let left = (wb.x - view.world.x) * scale;
        let top = (wb.y - view.world.y) * scale;
        let (w, h) = (wb.width * scale, wb.height * scale);
        let (world_w, world_h) = (view.world.width * scale, view.world.height * scale);
        if left + w < 0. || top + h < 0. || left > world_w || top > world_h {
            return None;
        }
        let c_left = (cb.x - wb.x) * scale;
        let c_top = (cb.y - wb.y) * scale;
        let (c_w, c_h) = (cb.width * scale, cb.height * scale);

        let selected = self.selected == Some(id);
        let accent = color(if selected {
            ui::INDIGO
        } else {
            ui::DEEP_ORANGE
        });
        let title_bar = view.sized(28., 12., 28.);
        let green = color(ui::GREEN);

        let title = window
            .title()
            .filter(|t| !t.is_empty())
            .unwrap_or_else(|| format!("Window #{id}"));

        Some(
            div()
                .id(("canvas-window", id))
                .absolute()
                .left(px(left as f32))
                .top(px(top as f32))
                .w(px(w as f32))
                .h(px(h as f32))
                .bg(accent.opacity(0.08))
                .when(selected, |this| this.border_2())
                .when(!selected, |this| this.border_1())
                .border_color(accent)
                .cursor_pointer()
                .on_click(cx.listener(move |this, _, _, cx| this.select_window(id, cx)))
                // Title bar.
                .child(
                    div()
                        .absolute()
                        .top_0()
                        .left_0()
                        .right_0()
                        .h(px(title_bar))
                        .flex()
                        .items_center()
                        .px(px(view.sized(6., 3., 6.)))
                        .bg(accent.opacity(0.25))
                        .border_b_1()
                        .border_color(accent)
                        .overflow_hidden()
                        .child(
                            div()
                                .text_size(px(view.sized(9., 6., 9.)))
                                .font_weight(FontWeight::BOLD)
                                .text_color(accent)
                                .whitespace_nowrap()
                                .text_ellipsis()
                                .child(title),
                        ),
                )
                // Content bounds.
                .child(
                    div()
                        .absolute()
                        .left(px(c_left as f32))
                        .top(px(c_top as f32))
                        .w(px(c_w as f32))
                        .h(px(c_h as f32))
                        .border_1()
                        .border_color(green.opacity(0.6))
                        .bg(green.opacity(0.04))
                        .flex()
                        .items_center()
                        .justify_center()
                        .text_size(px(view.sized(7., 5., 9.)))
                        .font_weight(FontWeight::BOLD)
                        .text_color(color(ui::GREEN_700))
                        .child("Content"),
                )
                // Frame size and position.
                .child(
                    label(
                        format!("{}×{}", wb.width as i64, wb.height as i64),
                        Some(format!("({}, {})", wb.x as i64, wb.y as i64)),
                        accent,
                        view,
                    )
                    .absolute()
                    .left(px(4.))
                    .top(px(title_bar + 4.)),
                )
                // Content size.
                .child(
                    label(
                        format!("{}×{}", cb.width as i64, cb.height as i64),
                        None,
                        green,
                        view,
                    )
                    .absolute()
                    .left(px(c_left as f32 + 4.))
                    .top(px(c_top as f32 + 4.)),
                )
                .into_any_element(),
        )
    }

    // -----------------------------------------------------------------------
    // Quick info
    // -----------------------------------------------------------------------

    fn quick_info(&self, window: &NativeWindow, cx: &mut Context<Self>) -> impl IntoElement {
        let id = window.id();
        let bounds = window.bounds();
        let content = window.content_bounds();
        let title: SharedString = window
            .title()
            .filter(|t| !t.is_empty())
            .unwrap_or_else(|| "Untitled".into())
            .into();

        let info_row = |label: &'static str, value: String| {
            div()
                .flex()
                .items_center()
                .py_1()
                .child(
                    div()
                        .w(px(72.))
                        .font_weight(FontWeight::SEMIBOLD)
                        .child(label),
                )
                .child(
                    div()
                        .flex_1()
                        .font_family(ui::MONOSPACE)
                        .text_size(px(13.))
                        .child(value),
                )
        };

        div()
            .id("quick-info")
            .size_full()
            .overflow_y_scroll()
            .p_3()
            .flex()
            .flex_col()
            .gap_2()
            // Identity.
            .child(
                ui::card()
                    .p_4()
                    .flex()
                    .flex_col()
                    .items_start()
                    .gap_2()
                    .child(
                        div()
                            .text_size(px(16.))
                            .font_weight(FontWeight::BOLD)
                            .child(title),
                    )
                    .child(ui::chip(format!("ID: {id}"), color(ui::PRIMARY))),
            )
            // Geometry.
            .child(
                ui::card()
                    .p_3()
                    .flex()
                    .flex_col()
                    .child(
                        div()
                            .font_weight(FontWeight::BOLD)
                            .pb_2()
                            .mb_1()
                            .border_b_1()
                            .border_color(color(ui::OUTLINE_VARIANT))
                            .child("Geometry"),
                    )
                    .child(info_row(
                        "Size",
                        format!("{} × {}", bounds.width as i64, bounds.height as i64),
                    ))
                    .child(info_row(
                        "Position",
                        format!("({}, {})", bounds.x as i64, bounds.y as i64),
                    ))
                    .child(info_row(
                        "Content",
                        format!("{} × {}", content.width as i64, content.height as i64),
                    )),
            )
            // State badges.
            .child(
                ui::card()
                    .p_3()
                    .flex()
                    .flex_wrap()
                    .gap(px(6.))
                    .child(ui::state_chip(
                        "Visible",
                        window.is_visible(),
                        color(ui::GREEN),
                    ))
                    .child(ui::state_chip(
                        "Focused",
                        window.is_focused(),
                        color(ui::INDIGO),
                    ))
                    .child(ui::state_chip(
                        "Maximized",
                        window.is_maximized(),
                        color(ui::PURPLE),
                    ))
                    .child(ui::state_chip(
                        "Minimized",
                        window.is_minimized(),
                        color(ui::ORANGE),
                    ))
                    .child(ui::state_chip(
                        "Fullscreen",
                        window.is_full_screen(),
                        color(ui::RED),
                    ))
                    .child(ui::state_chip(
                        "Always on Top",
                        window.is_always_on_top(),
                        color(ui::TEAL),
                    )),
            )
            // Quick actions.
            .child(
                ui::card()
                    .p_3()
                    .flex()
                    .flex_col()
                    .gap(px(6.))
                    .child(div().font_weight(FontWeight::BOLD).child("Quick Actions"))
                    .child(
                        div()
                            .flex()
                            .gap(px(6.))
                            .child(quick_button(
                                id,
                                "quick-maximize",
                                "Maximize",
                                window.is_maximized(),
                                ui::PURPLE,
                                NativeWindow::maximize,
                                "maximize",
                                cx,
                            ))
                            .child(quick_button(
                                id,
                                "quick-minimize",
                                "Minimize",
                                window.is_minimized(),
                                ui::ORANGE,
                                NativeWindow::minimize,
                                "minimize",
                                cx,
                            )),
                    )
                    .child(
                        div()
                            .flex()
                            .gap(px(6.))
                            .child(quick_button(
                                id,
                                "quick-restore",
                                "Restore",
                                false,
                                ui::TEAL,
                                NativeWindow::restore,
                                "restore",
                                cx,
                            ))
                            .child(quick_button(
                                id,
                                "quick-hide",
                                "Hide",
                                !window.is_visible(),
                                ui::ORANGE,
                                NativeWindow::hide,
                                "hide",
                                cx,
                            )),
                    )
                    .child(
                        ui::small_button("more-actions", "More Actions", color(ui::PRIMARY), false)
                            .w_full()
                            .mt_1()
                            .on_click(cx.listener(|this, _, _, cx| {
                                this.tab = Tab::Actions;
                                cx.notify();
                            })),
                    ),
            )
    }
}

/// How the world (screen coordinates) maps onto the canvas.
pub(crate) struct View {
    world: Rectangle,
    /// The scale that fits the world into the canvas.
    fit: f64,
    zoom: f64,
}

impl View {
    fn scale(&self) -> f64 {
        self.fit * self.zoom
    }

    /// A size that follows the fitted scale within bounds, then zooms — as the
    /// Flutter example's clamped sizes inside its `InteractiveViewer`.
    fn sized(&self, base: f64, min: f64, max: f64) -> f32 {
        ((base * self.fit).clamp(min, max) * self.zoom) as f32
    }
}

/// Everything to draw — displays and windows — plus padding.
fn world_bounds(displays: &[Display], windows: &[NativeWindow]) -> Option<Rectangle> {
    let rects = displays
        .iter()
        .map(|d| {
            let (p, s) = (d.position(), d.size());
            Rectangle {
                x: p.x,
                y: p.y,
                width: s.width,
                height: s.height,
            }
        })
        .chain(windows.iter().map(|w| w.bounds()));
    let mut extent: Option<(f64, f64, f64, f64)> = None;
    for r in rects {
        let (x0, y0, x1, y1) = extent.unwrap_or((r.x, r.y, r.x + r.width, r.y + r.height));
        extent = Some((
            x0.min(r.x),
            y0.min(r.y),
            x1.max(r.x + r.width),
            y1.max(r.y + r.height),
        ));
    }
    let (x0, y0, x1, y1) = extent?;
    Some(Rectangle {
        x: x0 - WORLD_PADDING,
        y: y0 - WORLD_PADDING,
        width: x1 - x0 + WORLD_PADDING * 2.,
        height: y1 - y0 + WORLD_PADDING * 2.,
    })
}

fn display_shape(display: &Display, view: &View) -> AnyElement {
    let scale = view.scale();
    let (pos, sz, work) = (display.position(), display.size(), display.work_area());
    div()
        .absolute()
        .left(px(((pos.x - view.world.x) * scale) as f32))
        .top(px(((pos.y - view.world.y) * scale) as f32))
        .w(px((sz.width * scale) as f32))
        .h(px((sz.height * scale) as f32))
        // Bezel.
        .bg(linear_gradient(
            180.,
            linear_color_stop(color(0x555555), 0.),
            linear_color_stop(color(0x333333), 1.),
        ))
        .border_1()
        .border_color(color(ui::GREY_600))
        // Work area.
        .child(
            div()
                .absolute()
                .left(px(((work.x - pos.x) * scale) as f32))
                .top(px(((work.y - pos.y) * scale) as f32))
                .w(px((work.width * scale) as f32))
                .h(px((work.height * scale) as f32))
                .bg(linear_gradient(
                    135.,
                    linear_color_stop(color(ui::GREY_200), 0.),
                    linear_color_stop(color(ui::GREY_300), 1.),
                ))
                .border_1()
                .border_color(color(ui::GREY_400)),
        )
        // Name.
        .child(
            div()
                .absolute()
                .top_1()
                .left_1()
                .px(px(6.))
                .py(px(2.))
                .rounded(px(4.))
                .bg(gpui::black().opacity(0.6))
                .text_size(px(view.sized(8., 6., 10.)))
                .font_weight(FontWeight::BOLD)
                .text_color(gpui::white())
                .child(display.name().unwrap_or_default()),
        )
        .into_any_element()
}

fn label(line1: String, line2: Option<String>, tint: Hsla, view: &View) -> Div {
    let font = view.sized(7., 5., 10.);
    div()
        .p(px(view.sized(3., 1.5, 4.)))
        .rounded(px(3.))
        .bg(gpui::white().opacity(0.85))
        .border_1()
        .border_color(tint.opacity(0.6))
        .flex()
        .flex_col()
        .child(
            div()
                .text_size(px(font))
                .font_weight(FontWeight::BOLD)
                .text_color(tint)
                .whitespace_nowrap()
                .child(line1),
        )
        .when_some(line2, |this, line2| {
            this.child(
                div()
                    .text_size(px(font * 0.85))
                    .text_color(tint.opacity(0.7))
                    .whitespace_nowrap()
                    .child(line2),
            )
        })
}

#[allow(clippy::too_many_arguments)]
fn quick_button(
    id: WindowId,
    key: &'static str,
    label: &'static str,
    active: bool,
    tint: u32,
    f: fn(&NativeWindow),
    action: &'static str,
    cx: &mut Context<WindowExample>,
) -> impl IntoElement {
    ui::small_button(key, label, color(tint), active)
        .flex_1()
        .on_click(cx.listener(move |this, _, _, cx| {
            this.act(id, cx, move |w| {
                f(w);
                Outcome::log(format!("Action: {action} #{id}"), tint)
            })
        }))
}
