//! The Actions tab: every `Window` call, grouped as in the Flutter example.

use gpui::prelude::*;
use gpui::{
    canvas, div, px, relative, AnyElement, Context, ElementId, FontWeight, MouseButton, Pixels,
    SharedString,
};
use nativeapi::color::Color;
use nativeapi::geometry::{Point, Size};
use nativeapi::window::{
    ResizeEdge, TitleBarStyle, VisualEffect, Window as NativeWindow, WindowId,
};

use crate::example::{Outcome, WindowExample};
use crate::ui::{self, color};

const OPACITY_MIN: f32 = 0.1;
const OPACITY_MAX: f32 = 1.0;
const OPACITY_DIVISIONS: f32 = 18.0;

const VISUAL_EFFECTS: [(VisualEffect, &str); 8] = [
    (VisualEffect::None, "None"),
    (VisualEffect::Blur, "Blur"),
    (VisualEffect::Acrylic, "Acrylic"),
    (VisualEffect::Mica, "Mica"),
    (VisualEffect::MicaAlt, "MicaAlt"),
    (VisualEffect::Hud, "Hud"),
    (VisualEffect::Popover, "Popover"),
    (VisualEffect::Menu, "Menu"),
];

/// Background presets: label, `0xRRGGBBAA`.
const BACKGROUNDS: [(&str, u32); 5] = [
    ("White", 0xffffffff),
    ("Light Grey", 0xeeeeeeff),
    ("Dark", 0x212121ff),
    ("Blue", 0x90caf9ff),
    ("Transparent", 0x00000000),
];

fn native_color(rgba: u32) -> Color {
    let [r, g, b, a] = rgba.to_be_bytes();
    Color { r, g, b, a }
}

fn size(width: f64, height: f64) -> Size {
    Size { width, height }
}

fn on_off(value: bool) -> &'static str {
    if value {
        "ON"
    } else {
        "OFF"
    }
}

impl WindowExample {
    pub(crate) fn actions_tab(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let Some(window) = self.selected_window() else {
            return div()
                .size_full()
                .flex()
                .items_center()
                .justify_center()
                .text_color(color(ui::GREY_600))
                .child("Select a window on the Canvas tab")
                .into_any_element();
        };
        let id = window.id();
        let w = window;

        let is_full_screen = w.is_full_screen();
        let title_bar_hidden = w.title_bar_style() == TitleBarStyle::Hidden;
        let content_under_title_bar = w.is_content_under_title_bar();
        let has_shadow = w.has_shadow();
        let visual_effect = w.visual_effect();
        let background = w.background_color();
        let opacity = w.opacity();

        let body = div()
            .flex()
            .flex_col()
            // Header.
            .child(
                div()
                    .text_size(px(16.))
                    .font_weight(FontWeight::BOLD)
                    .child(format!("Selected: {}", w.title().unwrap_or_default())),
            )
            .child(
                div()
                    .flex()
                    .mt_1()
                    .mb_4()
                    .child(ui::chip(format!("ID: {id}"), color(ui::PRIMARY))),
            )
            .child(ui::group(
                "Visibility",
                vec![
                    action(id, "show", "Show", None, false, cx, |w| {
                        w.show();
                        Outcome::feedback("Window shown")
                            .and_log(format!("Action: show #{}", w.id()), ui::GREEN)
                    }),
                    action(id, "show-inactive", "Show Inactive", None, false, cx, |w| {
                        w.show_inactive();
                        Outcome::feedback("Window shown (inactive)")
                    }),
                    action(id, "hide", "Hide", None, false, cx, |w| {
                        w.hide();
                        Outcome::feedback("Window hidden")
                            .and_log(format!("Action: hide #{}", w.id()), ui::ORANGE)
                    }),
                ],
            ))
            .child(ui::group(
                "Window State",
                vec![
                    action(id, "maximize", "Maximize", None, false, cx, |w| {
                        w.maximize();
                        Outcome::feedback("Window maximized")
                    }),
                    action(id, "unmaximize", "Unmaximize", None, false, cx, |w| {
                        w.unmaximize();
                        Outcome::feedback("Window unmaximized")
                    }),
                    action(id, "minimize", "Minimize", None, false, cx, |w| {
                        w.minimize();
                        Outcome::feedback("Window minimized")
                    }),
                    action(id, "restore", "Restore", None, false, cx, |w| {
                        w.restore();
                        Outcome::feedback("Window restored")
                    }),
                    action(
                        id,
                        "fullscreen",
                        if is_full_screen {
                            "Exit Fullscreen"
                        } else {
                            "Fullscreen"
                        },
                        is_full_screen.then_some(ui::RED),
                        false,
                        cx,
                        move |w| {
                            w.set_full_screen(!is_full_screen);
                            Outcome::feedback(if is_full_screen {
                                "Fullscreen off"
                            } else {
                                "Fullscreen on"
                            })
                        },
                    ),
                ],
            ))
            .child(ui::group(
                "Focus",
                vec![
                    action(id, "focus", "Focus", None, false, cx, |w| {
                        w.focus();
                        Outcome::feedback("Window focused")
                    }),
                    action(id, "blur", "Blur", None, false, cx, |w| {
                        w.blur();
                        Outcome::feedback("Window blurred")
                    }),
                ],
            ))
            .child(ui::group(
                "Position & Size",
                vec![
                    action(id, "center", "Center", None, false, cx, |w| {
                        w.center();
                        Outcome::feedback("Window centered")
                    }),
                    action(id, "size-800", "800 × 600", None, false, cx, |w| {
                        w.set_size(&size(800., 600.), false);
                        Outcome::feedback("Size set to 800 × 600")
                    }),
                    action(id, "size-1024", "1024 × 768", None, false, cx, |w| {
                        w.set_size(&size(1024., 768.), false);
                        Outcome::feedback("Size set to 1024 × 768")
                    }),
                    action(
                        id,
                        "content-size",
                        "Set Content 760×540",
                        None,
                        false,
                        cx,
                        |w| {
                            w.set_content_size(&size(760., 540.));
                            Outcome::feedback("Content size set to 760 × 540")
                        },
                    ),
                    action(
                        id,
                        "position-100",
                        "Position (100, 100)",
                        None,
                        false,
                        cx,
                        |w| {
                            w.set_position(&Point { x: 100., y: 100. });
                            Outcome::feedback("Position set to (100, 100)")
                        },
                    ),
                    action(
                        id,
                        "position-400",
                        "Position (400, 300)",
                        None,
                        false,
                        cx,
                        |w| {
                            w.set_position(&Point { x: 400., y: 300. });
                            Outcome::feedback("Position set to (400, 300)")
                        },
                    ),
                ],
            ))
            .child(ui::group(
                "Size Constraints",
                vec![
                    action(id, "min-size", "Set Min 400×300", None, false, cx, |w| {
                        w.set_minimum_size(&size(400., 300.));
                        Outcome::feedback("Minimum size set to 400 × 300")
                    }),
                    action(id, "max-size", "Set Max 1200×900", None, false, cx, |w| {
                        w.set_maximum_size(&size(1200., 900.));
                        Outcome::feedback("Maximum size set to 1200 × 900")
                    }),
                    action(
                        id,
                        "reset-constraints",
                        "Reset Constraints",
                        None,
                        false,
                        cx,
                        |w| {
                            w.set_minimum_size(&size(0., 0.));
                            w.set_maximum_size(&size(0., 0.));
                            Outcome::feedback("Size constraints reset")
                        },
                    ),
                ],
            ))
            .child(ui::group(
                "Appearance",
                vec![
                    action(
                        id,
                        "title-bar-colors",
                        "Blue Title Bar (WinUI 3)",
                        None,
                        false,
                        cx,
                        |w| {
                            let ok = w.set_title_bar_colors(
                                &native_color(0x3f51b5ff),
                                &native_color(0xffffffff),
                            );
                            Outcome::feedback(if ok {
                                "Title bar colors applied"
                            } else {
                                "Unsupported: requires Windows WinUI 3 and a live window"
                            })
                        },
                    ),
                    action(
                        id,
                        "reset-title-bar-colors",
                        "Reset Title Bar Colors",
                        None,
                        false,
                        cx,
                        |w| {
                            Outcome::feedback(if w.reset_title_bar_colors() {
                                "Title bar colors reset"
                            } else {
                                "Title bar reset unsupported or failed"
                            })
                        },
                    ),
                    action(
                        id,
                        "title-bar-style",
                        if title_bar_hidden {
                            "Show Title Bar"
                        } else {
                            "Hide Title Bar"
                        },
                        None,
                        false,
                        cx,
                        move |w| {
                            w.set_title_bar_style(if title_bar_hidden {
                                TitleBarStyle::Normal
                            } else {
                                TitleBarStyle::Hidden
                            });
                            let hidden = w.title_bar_style() == TitleBarStyle::Hidden;
                            Outcome::feedback(format!(
                                "Title bar {}",
                                if hidden { "hidden" } else { "shown" }
                            ))
                        },
                    ),
                    action(
                        id,
                        "content-under-title-bar",
                        if content_under_title_bar {
                            "Give Back Title Bar"
                        } else {
                            "Extend Into Title Bar"
                        },
                        None,
                        false,
                        cx,
                        move |w| {
                            let applied = w.set_content_under_title_bar(!content_under_title_bar);
                            Outcome::feedback(if !applied {
                                "Extending into the title bar is not available here".to_string()
                            } else {
                                format!(
                                    "Content {} the title bar",
                                    if w.is_content_under_title_bar() {
                                        "extends into"
                                    } else {
                                        "stops at"
                                    }
                                )
                            })
                        },
                    ),
                    action(
                        id,
                        "shadow",
                        if has_shadow {
                            "Remove Shadow"
                        } else {
                            "Add Shadow"
                        },
                        None,
                        false,
                        cx,
                        move |w| {
                            w.set_has_shadow(!has_shadow);
                            Outcome::feedback(format!(
                                "Shadow {}",
                                if w.has_shadow() {
                                    "enabled"
                                } else {
                                    "disabled"
                                }
                            ))
                        },
                    ),
                    toggle(
                        id,
                        "always-on-top",
                        "Always on Top",
                        w.is_always_on_top(),
                        NativeWindow::set_always_on_top,
                        cx,
                    ),
                    toggle(
                        id,
                        "always-on-bottom",
                        "Always on Bottom",
                        w.is_always_on_bottom(),
                        NativeWindow::set_always_on_bottom,
                        cx,
                    ),
                    self.opacity_slider(id, opacity, cx),
                ],
            ))
            .child(ui::group(
                "Visual Effects",
                VISUAL_EFFECTS
                    .iter()
                    .map(|&(effect, label)| {
                        let active = visual_effect == effect;
                        action(
                            id,
                            SharedString::from(format!("effect-{label}")),
                            label,
                            None,
                            active,
                            cx,
                            move |w| {
                                Outcome::feedback(if w.set_visual_effect(effect) {
                                    format!("Visual effect: {label}")
                                } else {
                                    format!("Visual effect {label} is not available here")
                                })
                            },
                        )
                    })
                    .collect(),
            ))
            .child(ui::group(
                "Background Color",
                BACKGROUNDS
                    .iter()
                    .map(|&(label, rgba)| {
                        color_button(id, label, rgba, background == native_color(rgba), cx)
                    })
                    .collect(),
            ))
            .child(ui::group(
                "Advanced",
                vec![
                    toggle(
                        id,
                        "resizable",
                        "Resizable",
                        w.is_resizable(),
                        NativeWindow::set_resizable,
                        cx,
                    ),
                    toggle(
                        id,
                        "movable",
                        "Movable",
                        w.is_movable(),
                        NativeWindow::set_movable,
                        cx,
                    ),
                    toggle(
                        id,
                        "minimizable",
                        "Minimizable",
                        w.is_minimizable(),
                        NativeWindow::set_minimizable,
                        cx,
                    ),
                    toggle(
                        id,
                        "maximizable",
                        "Maximizable",
                        w.is_maximizable(),
                        NativeWindow::set_maximizable,
                        cx,
                    ),
                    toggle(
                        id,
                        "fullscreenable",
                        "Fullscreenable",
                        w.is_full_screenable(),
                        NativeWindow::set_full_screenable,
                        cx,
                    ),
                    toggle(
                        id,
                        "closable",
                        "Closable",
                        w.is_closable(),
                        NativeWindow::set_closable,
                        cx,
                    ),
                ],
            ))
            .child(ui::group(
                "Platform Specific",
                vec![
                    toggle(
                        id,
                        "control-buttons",
                        "Control Buttons Visible",
                        w.is_window_control_buttons_visible(),
                        NativeWindow::set_window_control_buttons_visible,
                        cx,
                    ),
                    toggle(
                        id,
                        "all-workspaces",
                        "Visible on All Workspaces",
                        w.is_visible_on_all_workspaces(),
                        NativeWindow::set_visible_on_all_workspaces,
                        cx,
                    ),
                    toggle(
                        id,
                        "taskbar",
                        "Visible in Taskbar",
                        w.is_visible_in_taskbar(),
                        NativeWindow::set_visible_in_taskbar,
                        cx,
                    ),
                    toggle(
                        id,
                        "ignore-mouse",
                        "Ignore Mouse Events",
                        w.is_ignore_mouse_events(),
                        NativeWindow::set_ignore_mouse_events,
                        cx,
                    ),
                    toggle(
                        id,
                        "focusable",
                        "Focusable",
                        w.is_focusable(),
                        NativeWindow::set_focusable,
                        cx,
                    ),
                ],
            ))
            .child(ui::group(
                "Interactions",
                vec![
                    press_action(id, "start-dragging", "Start Dragging", cx, |w| {
                        w.start_dragging();
                        Outcome::feedback("Drag started (move the mouse)")
                    }),
                    press_action(id, "start-resizing", "Start Resizing", cx, |w| {
                        w.start_resizing(ResizeEdge::BottomRight);
                        Outcome::feedback("Resize started from bottom-right (move the mouse)")
                    }),
                ],
            ))
            .child(ui::group(
                "Title",
                ["Hello Window", "My App", "nativeapi"]
                    .into_iter()
                    .map(|title| {
                        action(
                            id,
                            SharedString::from(format!("title-{title}")),
                            format!("Set \"{title}\""),
                            None,
                            false,
                            cx,
                            move |w| {
                                w.set_title(title);
                                Outcome::feedback(format!("Title set to \"{title}\""))
                            },
                        )
                    })
                    .collect(),
            ))
            .child(div().h(px(24.)));

        div()
            .id("actions")
            .size_full()
            .overflow_y_scroll()
            .p_3()
            .child(body)
            .into_any_element()
    }

    /// Opacity from 0.1 to 1.0 in 18 steps; click or drag on the track.
    fn opacity_slider(&self, id: WindowId, value: f32, cx: &mut Context<Self>) -> AnyElement {
        let track = self.opacity_track.clone();
        let fraction = ((value - OPACITY_MIN) / (OPACITY_MAX - OPACITY_MIN)).clamp(0., 1.);
        let primary = color(ui::PRIMARY);
        div()
            .flex()
            .items_center()
            .mt_1()
            .child(div().w(px(100.)).text_size(px(13.)).child("Opacity"))
            .child(
                div()
                    .id("opacity-slider")
                    .flex_1()
                    .h(px(28.))
                    .mx_2()
                    .relative()
                    .flex()
                    .items_center()
                    .cursor_pointer()
                    .child(
                        canvas(move |bounds, _, _| track.set(bounds), |_, _, _, _| {})
                            .absolute()
                            .size_full(),
                    )
                    .child(
                        div()
                            .w_full()
                            .h(px(4.))
                            .rounded_full()
                            .bg(primary.opacity(0.24))
                            .child(
                                div()
                                    .h_full()
                                    .w(relative(fraction))
                                    .rounded_full()
                                    .bg(primary),
                            ),
                    )
                    .child(
                        div()
                            .absolute()
                            .top(px(6.))
                            .left(relative(fraction))
                            .ml(px(-8.))
                            .size(px(16.))
                            .rounded_full()
                            .bg(primary),
                    )
                    .on_mouse_down(
                        MouseButton::Left,
                        cx.listener(move |this, event: &gpui::MouseDownEvent, _, cx| {
                            this.dragging_opacity = true;
                            this.set_opacity_at(id, event.position.x, cx);
                        }),
                    )
                    .on_mouse_move(
                        cx.listener(move |this, event: &gpui::MouseMoveEvent, _, cx| {
                            if this.dragging_opacity
                                && event.pressed_button == Some(MouseButton::Left)
                            {
                                this.set_opacity_at(id, event.position.x, cx);
                            }
                        }),
                    )
                    .on_mouse_up(
                        MouseButton::Left,
                        cx.listener(|this, _, _, _| this.dragging_opacity = false),
                    )
                    .on_mouse_up_out(
                        MouseButton::Left,
                        cx.listener(|this, _, _, _| this.dragging_opacity = false),
                    ),
            )
            .child(
                div()
                    .w(px(36.))
                    .font_family(ui::MONOSPACE)
                    .text_size(px(12.))
                    .child(format!("{value:.2}")),
            )
            .into_any_element()
    }

    fn set_opacity_at(&mut self, id: WindowId, x: Pixels, cx: &mut Context<Self>) {
        let track = self.opacity_track.get();
        if track.size.width <= px(0.) {
            return;
        }
        let fraction = ((x - track.origin.x) / track.size.width).clamp(0., 1.);
        let step = (fraction * OPACITY_DIVISIONS).round() / OPACITY_DIVISIONS;
        let value = OPACITY_MIN + step * (OPACITY_MAX - OPACITY_MIN);
        self.act(id, cx, move |w| {
            if (w.opacity() - value).abs() < 0.001 {
                return Outcome::default();
            }
            w.set_opacity(value);
            Outcome::feedback(format!("Opacity: {value:.2}"))
        });
    }
}

/// A full-width button running `f` on the window.
fn action(
    id: WindowId,
    key: impl Into<ElementId>,
    label: impl Into<SharedString>,
    tint: Option<u32>,
    active: bool,
    cx: &mut Context<WindowExample>,
    f: impl Fn(&NativeWindow) -> Outcome + Clone + 'static,
) -> AnyElement {
    ui::action_button(key, label, color(tint.unwrap_or(ui::PRIMARY)), active)
        .on_click(cx.listener(move |this, _, _, cx| this.act(id, cx, f.clone())))
        .into_any_element()
}

/// A button acting on the press rather than the click: dragging and resizing
/// follow the button held down from there.
fn press_action(
    id: WindowId,
    key: &'static str,
    label: &'static str,
    cx: &mut Context<WindowExample>,
    f: fn(&NativeWindow) -> Outcome,
) -> AnyElement {
    ui::action_button(key, label, color(ui::PRIMARY), false)
        .on_mouse_down(
            MouseButton::Left,
            cx.listener(move |this, _, _, cx| this.act(id, cx, f)),
        )
        .into_any_element()
}

/// A labelled switch bound to a boolean window property.
fn toggle(
    id: WindowId,
    key: &'static str,
    label: &'static str,
    value: bool,
    set: fn(&NativeWindow, bool),
    cx: &mut Context<WindowExample>,
) -> AnyElement {
    div()
        .flex()
        .items_center()
        .mb_1()
        .min_h(px(32.))
        .child(div().flex_1().text_size(px(13.)).child(label))
        .child(
            ui::switch(key, value).on_click(cx.listener(move |this, _, _, cx| {
                this.act(id, cx, move |w| {
                    set(w, !value);
                    Outcome::feedback(format!("{label}: {}", on_off(!value)))
                })
            })),
        )
        .into_any_element()
}

/// A button with a color swatch setting the window's background color.
fn color_button(
    id: WindowId,
    label: &'static str,
    rgba: u32,
    selected: bool,
    cx: &mut Context<WindowExample>,
) -> AnyElement {
    let primary = color(ui::PRIMARY);
    let grey = color(ui::GREY);
    div()
        .id(SharedString::from(format!("background-{label}")))
        .flex()
        .items_center()
        .justify_center()
        .gap_2()
        .w_full()
        .h(px(36.))
        .mb(px(6.))
        .rounded_full()
        .cursor_pointer()
        .text_size(px(13.))
        .font_weight(FontWeight::MEDIUM)
        .text_color(if selected {
            color(ui::ON_SURFACE)
        } else {
            primary
        })
        .when(selected, |this| {
            this.bg(grey.opacity(0.15))
                .hover(move |style| style.bg(grey.opacity(0.22)))
        })
        .when(!selected, |this| {
            this.border_1()
                .border_color(color(ui::OUTLINE_VARIANT))
                .hover(move |style| style.bg(primary.opacity(0.08)))
        })
        .child(
            div()
                .size(px(16.))
                .rounded(px(4.))
                .border_1()
                .border_color(color(ui::GREY_400))
                .bg(gpui::rgba(rgba)),
        )
        .child(label)
        .on_click(cx.listener(move |this, _, _, cx| {
            this.act(id, cx, move |w| {
                w.set_background_color(&native_color(rgba));
                Outcome::feedback(format!("Background: {label}"))
            })
        }))
        .into_any_element()
}
