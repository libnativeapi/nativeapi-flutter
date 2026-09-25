//! The content of one browser window: its tab strip and the active tab's page.

use std::collections::HashMap;
use std::time::{Duration, Instant};

use gpui::prelude::*;
use gpui::{canvas, div, px, rgb, Context, Entity, MouseButton, Window};

use crate::layout::{CLOSE_WINDOW_BUTTON_WIDTH, HEIGHT, NEW_TAB_BUTTON_WIDTH, TAB_TOP};
use crate::tabs::{TabId, Tabs, WindowKey};

pub const STRIP: u32 = 0xdde3ea;
pub const TAB: u32 = 0xe9edf2;
pub const SURFACE: u32 = 0xffffff;
pub const SURFACE_DIM: u32 = 0xeef1f5;
pub const BORDER: u32 = 0xd5dbe2;
pub const TEXT: u32 = 0x1f2328;
pub const MUTED: u32 = 0x7a828c;
const HOVER: u32 = 0xcfd6de;

/// How quickly the other tabs slide out of the way of a dragged tab.
const SLIDE_TIME_CONSTANT: f64 = 0.045;

pub struct BrowserWindowView {
    tabs: Entity<Tabs>,
    key: WindowKey,
    /// Where each tab is drawn, easing towards its slot.
    lefts: HashMap<TabId, f64>,
    last_frame: Option<Instant>,
}

impl BrowserWindowView {
    pub fn new(tabs: Entity<Tabs>, key: WindowKey, cx: &mut Context<Self>) -> Self {
        cx.observe(&tabs, |_, _, cx| cx.notify()).detach();
        Self {
            tabs,
            key,
            lefts: HashMap::new(),
            last_frame: None,
        }
    }

    /// Moves every tab towards its slot (the dragged one straight to the
    /// cursor) and returns where to draw them. Requests another frame while
    /// any tab is still sliding.
    fn slide(&mut self, targets: &[(TabId, f64, bool)], window: &mut Window) -> Vec<f64> {
        let now = Instant::now();
        let elapsed = self
            .last_frame
            .map(|last| now - last)
            .filter(|elapsed| *elapsed < Duration::from_millis(100))
            .unwrap_or(Duration::from_millis(16));
        let step = 1.0 - (-elapsed.as_secs_f64() / SLIDE_TIME_CONSTANT).exp();

        let mut sliding = false;
        let lefts: Vec<f64> = targets
            .iter()
            .map(|&(tab, target, dragged)| {
                let left = match self.lefts.get(&tab) {
                    Some(&current) if !dragged => current + (target - current) * step,
                    _ => target,
                };
                if (left - target).abs() < 0.5 {
                    target
                } else {
                    sliding = true;
                    left
                }
            })
            .collect();
        self.lefts = targets
            .iter()
            .zip(&lefts)
            .map(|(&(tab, ..), &left)| (tab, left))
            .collect();
        if sliding {
            window.request_animation_frame();
            self.last_frame = Some(now);
        } else {
            self.last_frame = None;
        }
        lefts
    }
}

impl Render for BrowserWindowView {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let key = self.key;
        let entity = self.tabs.clone();
        let tabs = self.tabs.read(cx);
        let root = div()
            .size_full()
            .flex()
            .flex_col()
            .bg(rgb(SURFACE))
            .text_color(rgb(TEXT));
        let Some(browser) = tabs.window(key) else {
            // Closing: the window is removed after this update.
            return root;
        };

        let layout = tabs.layout;
        let strip_width = f64::from(window.viewport_size().width);
        let ids = browser.tabs.clone();
        let active = browser.active;
        let strip_cell = browser.strip.clone();
        let record_strip = browser.strip.clone();
        let extent = layout.tab_extent(strip_width, ids.len());
        let targets: Vec<(TabId, f64, bool)> = ids
            .iter()
            .enumerate()
            .map(|(index, &tab)| match tabs.dragged_left(key, tab) {
                Some(left) => (tab, left, true),
                None => (tab, layout.tab_left(index, extent), false),
            })
            .collect();
        let chips: Vec<_> = ids
            .iter()
            .map(|&tab| {
                let info = tabs.tab(tab);
                (
                    tab,
                    info.map(|info| info.title.clone()).unwrap_or_default(),
                    info.map_or(0, |info| info.color),
                    tabs.is_dragging(tab),
                )
            })
            .collect();
        let page = active
            .and_then(|tab| tabs.tab(tab))
            .map(|tab| tab.page.clone());
        let can_drag = tabs.can_drag();

        let lefts = self.slide(&targets, window);

        // Paint the dragged tab on top.
        let mut order: Vec<usize> = (0..chips.len()).collect();
        order.sort_by_key(|&i| chips[i].3);

        let tab_chips = order.into_iter().map(|i| {
            let (tab, ref title, color, lifted) = chips[i];
            let left = lefts[i];
            let is_active = active == Some(tab);
            let on_press = {
                let entity = entity.clone();
                let strip_cell = strip_cell.clone();
                move |event: &gpui::MouseDownEvent, _: &mut Window, cx: &mut gpui::App| {
                    cx.stop_propagation();
                    let origin = strip_cell
                        .get()
                        .map(|strip| strip.origin)
                        .unwrap_or_default();
                    let grab = gpui::point(
                        f64::from(event.position.x - origin.x) - left,
                        f64::from(event.position.y - origin.y) - TAB_TOP,
                    );
                    entity.update(cx, |tabs, cx| {
                        tabs.press_tab(key, tab, grab, event.position, cx)
                    });
                }
            };
            let on_close = {
                let entity = entity.clone();
                move |_: &gpui::ClickEvent, _: &mut Window, cx: &mut gpui::App| {
                    entity.update(cx, |tabs, cx| tabs.close_tab(key, tab, cx));
                }
            };
            div()
                .id(("tab", tab))
                .absolute()
                .left(px(left as f32))
                .top(px(TAB_TOP as f32))
                .w(px(extent as f32))
                .h(px((HEIGHT - TAB_TOP) as f32))
                .px(px(1.))
                .on_mouse_down(MouseButton::Left, on_press)
                .child(
                    div()
                        .size_full()
                        .flex()
                        .items_center()
                        .gap_2()
                        .pl(px(10.))
                        .pr(px(2.))
                        .rounded_t(px(8.))
                        .bg(rgb(if is_active { SURFACE } else { TAB }))
                        .when(lifted, |this| this.shadow_md())
                        .child(
                            div()
                                .flex_none()
                                .size(px(10.))
                                .rounded_full()
                                .bg(rgb(color)),
                        )
                        .child(
                            div()
                                .flex_1()
                                .min_w_0()
                                .overflow_hidden()
                                .whitespace_nowrap()
                                .text_xs()
                                .when(is_active, |this| {
                                    this.font_weight(gpui::FontWeight::SEMIBOLD)
                                })
                                .child(title.clone()),
                        )
                        .child(
                            div()
                                .id(("close-tab", tab))
                                .flex_none()
                                .size(px(20.))
                                .flex()
                                .items_center()
                                .justify_center()
                                .rounded_full()
                                .text_sm()
                                .text_color(rgb(MUTED))
                                .hover(|this| this.bg(rgb(HOVER)).text_color(rgb(TEXT)))
                                .cursor_pointer()
                                .child("×")
                                // Keep the press from starting a tab drag.
                                .on_mouse_down(MouseButton::Left, |_, _, cx| cx.stop_propagation())
                                .on_click(on_close),
                        ),
                )
        });

        let new_tab = {
            let entity = entity.clone();
            div()
                .id("new-tab")
                .absolute()
                .left(px((layout.tab_left(ids.len(), extent) + 4.0) as f32))
                .top(px(TAB_TOP as f32))
                .w(px((NEW_TAB_BUTTON_WIDTH - 8.0) as f32))
                .h(px((HEIGHT - TAB_TOP - 4.0) as f32))
                .flex()
                .items_center()
                .justify_center()
                .rounded_md()
                .text_lg()
                .hover(|this| this.bg(rgb(HOVER)))
                .cursor_pointer()
                .child("+")
                .on_mouse_down(MouseButton::Left, |_, _, cx| cx.stop_propagation())
                .on_click(move |_, _, cx| entity.update(cx, |tabs, cx| tabs.add_tab(key, cx)))
        };

        let close_window = (!cfg!(target_os = "macos")).then(|| {
            let entity = entity.clone();
            div()
                .id("close-window")
                .absolute()
                .right(px(4.))
                .top(px(4.))
                .w(px(CLOSE_WINDOW_BUTTON_WIDTH as f32))
                .h(px((HEIGHT - 8.0) as f32))
                .flex()
                .items_center()
                .justify_center()
                .rounded_md()
                .hover(|this| this.bg(rgb(HOVER)))
                .cursor_pointer()
                .child("×")
                .on_mouse_down(MouseButton::Left, |_, _, cx| cx.stop_propagation())
                .on_click(move |_, _, cx| entity.update(cx, |tabs, cx| tabs.close_window(key, cx)))
        });

        // The empty part of the strip moves the window, like a title bar.
        let on_strip_press = {
            let entity = entity.clone();
            move |event: &gpui::MouseDownEvent, _: &mut Window, cx: &mut gpui::App| {
                entity.update(cx, |tabs, _| tabs.press_strip(key, event.position));
            }
        };

        let strip = div()
            .relative()
            .flex_none()
            .w_full()
            .h(px(HEIGHT as f32))
            .bg(rgb(STRIP))
            .on_mouse_down(MouseButton::Left, on_strip_press)
            // Records where the strip is, for hit testing during a drag.
            .child(
                canvas(
                    move |bounds, _, _| record_strip.set(Some(bounds)),
                    |_, _, _, _| {},
                )
                .absolute()
                .size_full(),
            )
            .children(tab_chips)
            .child(new_tab)
            .children(close_window);

        let body = match page {
            Some(page) => div().flex_1().min_h_0().child(page),
            None => div().flex_1(),
        };
        let root = root.child(strip).child(body);
        if can_drag {
            root
        } else {
            root.child(
                div()
                    .flex_none()
                    .px_3()
                    .py_1()
                    .text_xs()
                    .bg(rgb(0xfff4ce))
                    .child("Needs macOS or Windows: nativeapi cannot reach GPUI's windows here."),
            )
        }
    }
}
