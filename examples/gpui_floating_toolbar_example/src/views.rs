//! The main window's page and the toolbar pill.

use gpui::prelude::*;
use gpui::{div, px, rgb, rgba, Context, Entity, SharedString, Window};

use crate::toolbar::{Toolbar, SWATCHES};

// Material 3 colours of the Flutter example's indigo-seeded light theme.
const SURFACE: u32 = 0xfbf8ff;
const ON_SURFACE: u32 = 0x1b1b21;
const SECONDARY_CONTAINER: u32 = 0xe1e0f9;
const ON_SECONDARY_CONTAINER: u32 = 0x191a2c;
/// The dark theme's primary, which the toolbar's text button uses.
const DARK_PRIMARY: u32 = 0xbac3ff;
/// The pill: 0xF0202124.
const PILL: u32 = 0x202124f0;

pub struct MainView {
    model: Entity<Toolbar>,
}

impl MainView {
    pub fn new(model: Entity<Toolbar>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        Self { model }
    }
}

impl Render for MainView {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let model = self.model.read(cx);
        let attached = model.attached;
        let visible = model.toolbar_visible;
        let log: Vec<SharedString> = model.log.iter().cloned().map(Into::into).collect();

        let attach_button = tonal_button(
            "attach",
            if attached {
                "Detach toolbar"
            } else {
                "Attach toolbar"
            },
        )
        .on_click({
            let model = self.model.clone();
            move |_, _, cx| model.update(cx, |model, cx| model.set_attached(!attached, cx))
        });
        let visible_button = tonal_button(
            "visible",
            if visible {
                "Hide toolbar"
            } else {
                "Show toolbar"
            },
        )
        .on_click({
            let model = self.model.clone();
            move |_, _, cx| model.update(cx, |model, cx| model.set_toolbar_visible(!visible, cx))
        });

        div()
            .size_full()
            .flex()
            .flex_col()
            .bg(rgb(SURFACE))
            .text_color(rgb(ON_SURFACE))
            .child(
                div()
                    .h(px(64.))
                    .flex_none()
                    .flex()
                    .items_center()
                    .px_4()
                    .text_xl()
                    .child("Floating toolbar"),
            )
            .child(
                div()
                    .flex_1()
                    .min_h_0()
                    .flex()
                    .flex_col()
                    .p(px(20.))
                    .text_sm()
                    .child(if model.available() {
                        "The pill above this window is a second GPUI window: transparent, \
                         frameless, and a child of this one. Move, resize or minimize this \
                         window and it comes along."
                    } else {
                        "Needs macOS or Windows: nativeapi cannot reach GPUI's windows here, \
                         so the pill is an ordinary window that does not follow."
                    })
                    .child(
                        div()
                            .mt(px(16.))
                            .flex()
                            .items_center()
                            .gap(px(16.))
                            .child(
                                div()
                                    .id("swatch")
                                    .size(px(56.))
                                    .rounded(px(12.))
                                    .bg(rgb(model.color)),
                            )
                            .child(div().text_2xl().child(format!("Stamps: {}", model.stamps))),
                    )
                    .child(
                        div()
                            .mt(px(16.))
                            .flex()
                            .flex_wrap()
                            .gap(px(12.))
                            .child(attach_button)
                            .child(visible_button),
                    )
                    .child(
                        div()
                            .mt(px(16.))
                            .mb(px(4.))
                            .font_weight(gpui::FontWeight::MEDIUM)
                            .child("Log"),
                    )
                    .child(
                        div()
                            .id("log")
                            .flex_1()
                            .min_h_0()
                            .overflow_y_scroll()
                            .text_xs()
                            .children(log.into_iter().map(|line| div().child(line))),
                    ),
            )
    }
}

fn tonal_button(id: &'static str, label: &'static str) -> gpui::Stateful<gpui::Div> {
    div()
        .id(id)
        .px_6()
        .py_2p5()
        .rounded_full()
        .bg(rgb(SECONDARY_CONTAINER))
        .text_color(rgb(ON_SECONDARY_CONTAINER))
        .cursor_pointer()
        .hover(|this| this.opacity(0.85))
        .child(label)
}

pub struct ToolbarView {
    model: Entity<Toolbar>,
}

impl ToolbarView {
    pub fn new(model: Entity<Toolbar>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        Self { model }
    }
}

impl Render for ToolbarView {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let selected = self.model.read(cx).color;
        let swatches = SWATCHES.iter().map(|&swatch| {
            let model = self.model.clone();
            div()
                .id(SharedString::from(format!("swatch-{swatch:06x}")))
                .mx(px(5.))
                .size(px(28.))
                .rounded_full()
                .bg(rgb(swatch))
                .border_2()
                .border_color(if swatch == selected {
                    rgba(0xffffffff)
                } else {
                    rgba(0x00000000)
                })
                .cursor_pointer()
                .on_click(move |_, _, cx| model.update(cx, |model, cx| model.pick(swatch, cx)))
        });
        let stamp = {
            let model = self.model.clone();
            div()
                .id("stamp")
                .ml(px(10.))
                .px_3()
                .py_1p5()
                .rounded_full()
                .text_sm()
                .text_color(rgb(DARK_PRIMARY))
                .cursor_pointer()
                .hover(|this| this.bg(rgba(0xbac3ff1f)))
                .child("Stamp")
                .on_click(move |_, _, cx| model.update(cx, |model, cx| model.stamp(cx)))
        };

        // Nothing opaque between the pill and the desktop.
        div()
            .size_full()
            .flex()
            .items_center()
            .justify_center()
            .child(
                div()
                    .h(px(52.))
                    .px(px(14.))
                    .flex()
                    .items_center()
                    .rounded(px(26.))
                    .bg(rgba(PILL))
                    .children(swatches)
                    .child(stamp),
            )
    }
}
