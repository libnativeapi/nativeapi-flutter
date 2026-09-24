//! The windows and the two demo panels.

use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::{Duration, Instant};

use gpui::prelude::*;
use gpui::{canvas, div, px, rgb, Context, Entity, MouseButton, SharedString, Window};

use crate::detach::{open_floating, Detach, PanelId, SlotId};

const BACKGROUND: u32 = 0x1e1f22;
const SURFACE: u32 = 0x2b2d31;
const HEADER: u32 = 0x383a40;
const BORDER: u32 = 0x45474d;
const TEXT: u32 = 0xe6e6e6;
const MUTED: u32 = 0x9a9ca3;
const ACCENT: u32 = 0x4c8dff;

// ---------------------------------------------------------------------------
// Windows
// ---------------------------------------------------------------------------

pub struct MainView {
    detach: Entity<Detach>,
}

impl MainView {
    pub fn new(detach: Entity<Detach>, cx: &mut Context<Self>) -> Self {
        cx.observe(&detach, |_, _, cx| cx.notify()).detach();
        Self { detach }
    }

    fn slot(&self, slot: SlotId, cx: &Context<Self>) -> impl IntoElement {
        let detach = self.detach.read(cx);
        let rects = detach.slot_rects();
        let highlighted = detach.highlight() == Some(slot);
        let content = match detach.docked(slot) {
            Some(panel) => panel_frame(&self.detach, panel, true, cx).into_any_element(),
            None => div()
                .size_full()
                .flex()
                .items_center()
                .justify_center()
                .text_sm()
                .text_color(rgb(if highlighted { ACCENT } else { MUTED }))
                .child(if highlighted {
                    "Release to dock"
                } else {
                    "Drop a panel here"
                })
                .into_any_element(),
        };
        div()
            .relative()
            .size_full()
            // Records where the slot is, for hit testing during a drag and as
            // the size of the panel's window when it pops out.
            .child(
                canvas(
                    move |bounds, _, _| {
                        rects.borrow_mut().insert(slot, bounds);
                    },
                    |_, _, _, _| {},
                )
                .absolute()
                .size_full(),
            )
            .child(
                div()
                    .size_full()
                    .rounded_md()
                    .border_1()
                    .when(highlighted, |this| this.border_2().bg(rgb(0x263352)))
                    .border_color(rgb(if highlighted { ACCENT } else { BORDER }))
                    .when(detach.docked(slot).is_none(), |this| this.border_dashed())
                    .overflow_hidden()
                    .child(content),
            )
    }
}

impl Render for MainView {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let can_drag = self.detach.read(cx).can_drag();
        div()
            .size_full()
            .flex()
            .gap_2()
            .p_2()
            .bg(rgb(BACKGROUND))
            .text_color(rgb(TEXT))
            .child(
                div()
                    .w(px(260.))
                    .h_full()
                    .child(self.slot(SlotId::Sidebar, cx)),
            )
            .child(
                div()
                    .flex_1()
                    .min_w_0()
                    .h_full()
                    .flex()
                    .flex_col()
                    .gap_2()
                    .child(
                        div()
                            .flex_1()
                            .flex()
                            .flex_col()
                            .gap_2()
                            .p_4()
                            .rounded_md()
                            .bg(rgb(SURFACE))
                            .child(div().text_xl().child("Detachable Window"))
                            .child(div().text_sm().text_color(rgb(MUTED)).child(if can_drag {
                                "Drag a panel header out of this window to tear it off. \
                                 Drag a floating panel back over an empty slot to dock it."
                            } else {
                                "Needs macOS or Windows: nativeapi cannot reach GPUI's windows here."
                            })),
                    )
                    .child(div().h(px(220.)).child(self.slot(SlotId::Bottom, cx))),
            )
    }
}

pub struct FloatingView {
    detach: Entity<Detach>,
    panel: PanelId,
}

impl FloatingView {
    pub fn new(detach: Entity<Detach>, panel: PanelId, cx: &mut Context<Self>) -> Self {
        cx.observe(&detach, |_, _, cx| cx.notify()).detach();
        Self { detach, panel }
    }
}

impl Render for FloatingView {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .size_full()
            .bg(rgb(BACKGROUND))
            .text_color(rgb(TEXT))
            .child(panel_frame(&self.detach, self.panel, false, cx))
    }
}

/// A panel with its header: the drag handle, the move counter and the
/// Pop out / Dock button.
fn panel_frame<V>(
    detach: &Entity<Detach>,
    panel: PanelId,
    docked: bool,
    cx: &Context<V>,
) -> impl IntoElement {
    let state = detach.read(cx).panel(panel);
    let body = state.body.clone();

    let on_press = {
        let detach = detach.clone();
        move |event: &gpui::MouseDownEvent, _: &mut Window, cx: &mut gpui::App| {
            detach.update(cx, |detach, _| detach.press_header(panel, event.position));
        }
    };
    let on_toggle = {
        let detach = detach.clone();
        move |_: &gpui::ClickEvent, _: &mut Window, cx: &mut gpui::App| {
            if docked {
                let rect = detach.update(cx, |detach, cx| detach.undock_beside(panel, cx));
                if let Some(rect) = rect {
                    open_floating(&detach, panel, &rect, cx);
                }
            } else {
                detach.update(cx, |detach, cx| detach.dock_panel(panel, None, cx));
            }
        }
    };

    div()
        .size_full()
        .flex()
        .flex_col()
        .bg(rgb(SURFACE))
        .child(
            div()
                .flex()
                .items_center()
                .gap_2()
                .px_3()
                .py_2()
                .bg(rgb(HEADER))
                .cursor_grab()
                .on_mouse_down(MouseButton::Left, on_press)
                .child(div().text_sm().child(state.title))
                .child(
                    div()
                        .flex_1()
                        .text_xs()
                        .text_color(rgb(MUTED))
                        .child(format!("moved {}×", state.moves)),
                )
                .child(
                    button(
                        SharedString::from(format!("toggle-{panel:?}")),
                        if docked { "Pop out" } else { "Dock" },
                    )
                    // Keep the press from starting a drag on the header.
                    .on_mouse_down(MouseButton::Left, |_, _, cx| cx.stop_propagation())
                    .on_click(on_toggle),
                ),
        )
        .child(div().flex_1().min_h_0().child(body))
}

fn button(id: SharedString, label: &'static str) -> gpui::Stateful<gpui::Div> {
    div()
        .id(id)
        .px_2()
        .py_0p5()
        .rounded_sm()
        .text_xs()
        .bg(rgb(BORDER))
        .hover(|this| this.bg(rgb(0x5a5c63)))
        .cursor_pointer()
        .child(label)
}

// ---------------------------------------------------------------------------
// Panels
// ---------------------------------------------------------------------------

/// Shows that the panel keeps its state: the counter and the instance number
/// never reset, whichever window renders it.
pub struct Inspector {
    instance: usize,
    clicks: usize,
}

impl Inspector {
    pub fn new() -> Self {
        static INSTANCES: AtomicUsize = AtomicUsize::new(0);
        Self {
            instance: INSTANCES.fetch_add(1, Ordering::Relaxed) + 1,
            clicks: 0,
        }
    }
}

impl Render for Inspector {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let row = |label: &'static str, value: String| {
            div()
                .flex()
                .justify_between()
                .text_sm()
                .child(div().text_color(rgb(MUTED)).child(label))
                .child(value)
        };
        div()
            .size_full()
            .flex()
            .flex_col()
            .gap_2()
            .p_3()
            .child(row("Instance", format!("#{}", self.instance)))
            .child(row("Clicks", self.clicks.to_string()))
            .child(
                button("inspector-click".into(), "Click me").on_click(cx.listener(
                    |this, _, _, cx| {
                        this.clicks += 1;
                        cx.notify();
                    },
                )),
            )
    }
}

/// Keeps running while its panel moves between windows.
#[derive(Default)]
pub struct Stopwatch {
    started: Option<Instant>,
    accumulated: Duration,
}

impl Stopwatch {
    fn elapsed(&self) -> Duration {
        self.accumulated
            + self
                .started
                .map_or(Duration::ZERO, |started| started.elapsed())
    }
}

impl Render for Stopwatch {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        if self.started.is_some() {
            window.request_animation_frame();
        }
        let elapsed = self.elapsed();
        let text = format!(
            "{:02}:{:02}.{:02}",
            elapsed.as_secs() / 60,
            elapsed.as_secs() % 60,
            elapsed.subsec_millis() / 10
        );
        div()
            .size_full()
            .flex()
            .flex_col()
            .items_center()
            .justify_center()
            .gap_3()
            .child(div().text_3xl().child(text))
            .child(
                div()
                    .flex()
                    .gap_2()
                    .child(
                        button(
                            "stopwatch-toggle".into(),
                            if self.started.is_some() {
                                "Stop"
                            } else {
                                "Start"
                            },
                        )
                        .on_click(cx.listener(|this, _, _, cx| {
                            match this.started.take() {
                                Some(started) => this.accumulated += started.elapsed(),
                                None => this.started = Some(Instant::now()),
                            }
                            cx.notify();
                        })),
                    )
                    .child(
                        button("stopwatch-reset".into(), "Reset").on_click(cx.listener(
                            |this, _, _, cx| {
                                *this = Stopwatch::default();
                                cx.notify();
                            },
                        )),
                    ),
            )
    }
}
