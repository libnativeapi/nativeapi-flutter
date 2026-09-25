//! A stand-in for a web page, with state that would be lost if it were
//! recreated: the address it navigated to, a counter, a scroll position, and a
//! timer that keeps running.

use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::{Duration, Instant};

use gpui::prelude::*;
use gpui::{div, px, rgb, rgba, Context, ScrollHandle, SharedString, Task, Window, WindowId};

use crate::views::{BORDER, MUTED, SURFACE, SURFACE_DIM};

pub struct TabPage {
    tab: usize,
    title: SharedString,
    color: u32,
    instance: usize,
    opened_at: Instant,
    likes: usize,
    window_moves: usize,
    window: Option<WindowId>,
    /// The addresses visited, the current one last. GPUI has no text input,
    /// so the address is changed by following the paragraph links.
    history: Vec<String>,
    scroll: ScrollHandle,
    _timer: Task<()>,
}

impl TabPage {
    pub fn new(tab: usize, title: SharedString, color: u32, cx: &mut Context<Self>) -> Self {
        static INSTANCES: AtomicUsize = AtomicUsize::new(0);
        // Ticks every second for as long as the page lives, in whichever
        // window it is, even while its tab is in the background.
        let timer = cx.spawn(async move |this, cx| loop {
            cx.background_executor().timer(Duration::from_secs(1)).await;
            if this.update(cx, |_, cx| cx.notify()).is_err() {
                break;
            }
        });
        Self {
            tab,
            title,
            color,
            instance: INSTANCES.fetch_add(1, Ordering::Relaxed) + 1,
            opened_at: Instant::now(),
            likes: 0,
            window_moves: 0,
            window: None,
            history: vec![format!("https://example.com/tab-{tab}")],
            scroll: ScrollHandle::new(),
            _timer: timer,
        }
    }

    fn address(&self) -> &str {
        self.history.last().map_or("", String::as_str)
    }
}

impl Render for TabPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        // The same entity is rendered by whichever window shows the tab.
        let window_id = window.window_handle().window_id();
        if self.window.is_some_and(|previous| previous != window_id) {
            self.window_moves += 1;
        }
        self.window = Some(window_id);

        let tab = self.tab;
        let seconds = self.opened_at.elapsed().as_secs();
        let can_go_back = self.history.len() > 1;

        let toolbar = div()
            .flex()
            .items_center()
            .gap_2()
            .px_3()
            .py_2()
            .child(
                icon_button(("back", tab), "←", can_go_back).on_click(cx.listener(
                    |this, _, _, cx| {
                        if this.history.len() > 1 {
                            this.history.pop();
                            cx.notify();
                        }
                    },
                )),
            )
            .child(icon_button(("reload", tab), "↻", false))
            .child(
                div()
                    .id(("address", tab))
                    .flex_1()
                    .min_w_0()
                    .px_3()
                    .py_1()
                    .rounded_full()
                    .bg(rgb(SURFACE_DIM))
                    .text_sm()
                    .overflow_hidden()
                    .whitespace_nowrap()
                    .child(self.address().to_string()),
            );

        let header = div()
            .flex()
            .flex_col()
            .gap_2()
            .pb_6()
            .child(div().text_2xl().child(self.title.clone()))
            .child(div().text_xs().text_color(rgb(MUTED)).child(format!(
                "Page state #{} · open for {seconds}s · moved between windows {}×",
                self.instance, self.window_moves
            )))
            .child(
                div()
                    .flex()
                    .items_center()
                    .gap_3()
                    .pt_2()
                    .child(
                        div()
                            .id(("like", tab))
                            .flex_none()
                            .px_4()
                            .py_2()
                            .rounded_full()
                            .bg(rgb(0xdfe6ee))
                            .hover(|this| this.bg(rgb(0xd0d9e3)))
                            .cursor_pointer()
                            .text_sm()
                            .child(format!("Like ({})", self.likes))
                            .on_click(cx.listener(|this, _, _, cx| {
                                this.likes += 1;
                                cx.notify();
                            })),
                    )
                    .child(div().flex_1().min_w_0().text_xs().child(
                        "Drag the tab to reorder, pull it down to tear it off, \
                         drop it on another strip to merge. Click a paragraph to \
                         navigate to it.",
                    )),
            );

        let color = self.color;
        let title = self.title.clone();
        let paragraphs = (1..30usize).map(|i| {
            let alpha = ((0.08 + (i % 3) as f32 * 0.05) * 255.0).round() as u32;
            div()
                .id(("paragraph", i))
                .h(px(64.))
                .mb_3()
                .px_4()
                .flex()
                .items_center()
                .rounded(px(10.))
                .bg(rgba((color << 8) | alpha))
                .cursor_pointer()
                .hover(|this| this.bg(rgba((color << 8) | (alpha + 0x18))))
                .child(format!("{title} · paragraph {i}"))
                .on_click(cx.listener(move |this, _, _, cx| {
                    let address = format!("https://example.com/tab-{}/paragraph-{i}", this.tab);
                    if this.address() != address {
                        this.history.push(address);
                        cx.notify();
                    }
                }))
        });

        div()
            .size_full()
            .flex()
            .flex_col()
            .bg(rgb(SURFACE))
            .child(toolbar)
            .child(div().h(px(1.)).flex_none().bg(rgb(BORDER)))
            .child(
                div()
                    .id(("page-scroll", tab))
                    .flex_1()
                    .min_h_0()
                    .overflow_y_scroll()
                    // The offset lives in the handle, not in the window's
                    // element state, so it survives a move to another window.
                    .track_scroll(&self.scroll)
                    .p_6()
                    .child(header)
                    .children(paragraphs),
            )
    }
}

fn icon_button(
    id: impl Into<gpui::ElementId>,
    label: &'static str,
    enabled: bool,
) -> gpui::Stateful<gpui::Div> {
    div()
        .id(id)
        .flex_none()
        .size(px(28.))
        .flex()
        .items_center()
        .justify_center()
        .rounded_full()
        .text_color(rgb(if enabled { 0x1f2328 } else { MUTED }))
        .when(enabled, |this| {
            this.cursor_pointer()
                .hover(|this| this.bg(rgb(SURFACE_DIM)))
        })
        .child(label)
}
