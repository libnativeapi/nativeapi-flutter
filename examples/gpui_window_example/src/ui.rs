//! Colors and the small widgets GPUI does not ship: buttons, switches, chips,
//! cards. Styled after the Material 3 look of the Flutter example.

use gpui::prelude::*;
use gpui::{div, px, rgb, Div, ElementId, FontWeight, Hsla, SharedString, Stateful};

pub fn color(hex: u32) -> Hsla {
    rgb(hex).into()
}

// Theme (Material 3, seeded from indigo).
pub const PRIMARY: u32 = 0x4355b9;
pub const PRIMARY_CONTAINER: u32 = 0xdee0ff;
pub const ON_PRIMARY_CONTAINER: u32 = 0x00105c;
pub const BACKGROUND: u32 = 0xfbf8ff;
pub const CARD: u32 = 0xf5f2fa;
pub const ON_SURFACE: u32 = 0x1b1b21;
pub const ON_SURFACE_VARIANT: u32 = 0x46464f;
pub const OUTLINE_VARIANT: u32 = 0xc6c5d0;

// Material palette.
pub const INDIGO: u32 = 0x3f51b5;
pub const GREEN: u32 = 0x4caf50;
pub const GREEN_700: u32 = 0x388e3c;
pub const ORANGE: u32 = 0xff9800;
pub const DEEP_ORANGE: u32 = 0xff5722;
pub const PURPLE: u32 = 0x9c27b0;
pub const RED: u32 = 0xf44336;
pub const TEAL: u32 = 0x009688;
pub const GREY: u32 = 0x9e9e9e;
pub const GREY_100: u32 = 0xf5f5f5;
pub const GREY_200: u32 = 0xeeeeee;
pub const GREY_300: u32 = 0xe0e0e0;
pub const GREY_400: u32 = 0xbdbdbd;
pub const GREY_500: u32 = 0x9e9e9e;
pub const GREY_600: u32 = 0x757575;

/// Flutter's `Colors.black87`.
pub fn black87() -> Hsla {
    gpui::black().opacity(0.87)
}

pub const MONOSPACE: &str = "Menlo";

/// A Material card.
pub fn card() -> Div {
    div()
        .rounded(px(12.))
        .bg(color(CARD))
        .shadow_sm()
        .border_1()
        .border_color(color(OUTLINE_VARIANT).opacity(0.4))
}

/// A card with a bold title, the Flutter example's `_group`.
pub fn group(title: &'static str, children: Vec<gpui::AnyElement>) -> Div {
    card()
        .p_3()
        .mb_4()
        .flex()
        .flex_col()
        .child(
            div()
                .mb_2()
                .text_size(px(14.))
                .font_weight(FontWeight::BOLD)
                .child(title),
        )
        .children(children)
}

/// A full-width button: outlined, or tonal (filled with a tint) when active.
pub fn action_button(
    id: impl Into<ElementId>,
    label: impl Into<SharedString>,
    tint: Hsla,
    active: bool,
) -> Stateful<Div> {
    base_button(id, label, tint, active)
        .w_full()
        .h(px(36.))
        .mb(px(6.))
        .text_size(px(13.))
}

/// A compact button for the quick actions and toolbars.
pub fn small_button(
    id: impl Into<ElementId>,
    label: impl Into<SharedString>,
    tint: Hsla,
    active: bool,
) -> Stateful<Div> {
    base_button(id, label, tint, active)
        .h(px(36.))
        .px_2()
        .text_size(px(12.))
}

fn base_button(
    id: impl Into<ElementId>,
    label: impl Into<SharedString>,
    tint: Hsla,
    active: bool,
) -> Stateful<Div> {
    let label: SharedString = label.into();
    div()
        .id(id)
        .flex()
        .flex_none()
        .items_center()
        .justify_center()
        .gap_2()
        .rounded_full()
        .cursor_pointer()
        .text_color(tint)
        .font_weight(FontWeight::MEDIUM)
        .when(active, |this| {
            this.bg(tint.opacity(0.2))
                .hover(move |style| style.bg(tint.opacity(0.28)))
        })
        .when(!active, |this| {
            this.border_1()
                .border_color(tint.opacity(0.4))
                .hover(move |style| style.bg(tint.opacity(0.08)))
        })
        .child(label)
}

/// A flat text button (Material `TextButton`).
pub fn text_button(id: impl Into<ElementId>, label: impl Into<SharedString>) -> Stateful<Div> {
    let label: SharedString = label.into();
    div()
        .id(id)
        .flex()
        .items_center()
        .px_3()
        .h(px(32.))
        .rounded_full()
        .cursor_pointer()
        .text_size(px(13.))
        .font_weight(FontWeight::MEDIUM)
        .text_color(color(PRIMARY))
        .hover(|style| style.bg(color(PRIMARY).opacity(0.08)))
        .child(label)
}

/// A Material switch; the caller attaches the click handler.
pub fn switch(id: impl Into<ElementId>, on: bool) -> Stateful<Div> {
    let track = if on { color(PRIMARY) } else { color(GREY_300) };
    div()
        .id(id)
        .flex()
        .flex_none()
        .items_center()
        .w(px(40.))
        .h(px(22.))
        .px(px(3.))
        .rounded_full()
        .cursor_pointer()
        .bg(track)
        .border_1()
        .border_color(if on { track } else { color(GREY_500) })
        .when(on, |this| this.justify_end())
        .child(
            div()
                .size(px(if on { 16. } else { 12. }))
                .rounded_full()
                .bg(if on { gpui::white() } else { color(GREY_600) }),
        )
}

/// A label with a tinted background.
pub fn chip(label: impl Into<SharedString>, tint: Hsla) -> Div {
    let label: SharedString = label.into();
    div()
        .px_2()
        .py_1()
        .rounded(px(12.))
        .bg(tint.opacity(0.12))
        .text_size(px(12.))
        .font_weight(FontWeight::SEMIBOLD)
        .text_color(tint)
        .child(label)
}

/// A state badge, lit when `active`.
pub fn state_chip(label: &'static str, active: bool, tint: Hsla) -> Div {
    let grey = color(GREY);
    div()
        .px_2()
        .py_1()
        .rounded(px(12.))
        .border_1()
        .bg(if active {
            tint.opacity(0.15)
        } else {
            grey.opacity(0.1)
        })
        .border_color(if active {
            tint.opacity(0.5)
        } else {
            grey.opacity(0.3)
        })
        .text_size(px(11.))
        .font_weight(FontWeight::SEMIBOLD)
        .text_color(if active { tint } else { grey })
        .child(label)
}
