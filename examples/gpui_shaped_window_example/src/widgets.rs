//! Small mouse-first controls, as in the Flutter example: option chips in
//! labelled rows, a muted hint, and a slider. Labels are plain text.

use gpui::prelude::*;
use gpui::{
    div, fill, point, px, quad, rgba, size, AnyElement, BorderStyle, Bounds, Div, ElementId,
    FontWeight, Pixels, SharedString, Stateful,
};

use crate::palette::{Palette, MONO};

/// A small choice. `enabled: false` greys it out; the caller adds `on_click`
/// only to enabled chips.
pub fn chip(
    id: impl Into<ElementId>,
    label: impl Into<SharedString>,
    selected: bool,
    enabled: bool,
    p: &Palette,
) -> Stateful<Div> {
    let foreground = if !enabled {
        gpui::Rgba {
            a: 0.45,
            ..rgba(p.muted)
        }
    } else if selected {
        rgba(p.accent)
    } else {
        rgba(p.text)
    };
    let hover = p.hover;
    div()
        .id(id.into())
        .px(px(8.))
        .py(px(4.))
        .rounded(px(6.))
        .border_1()
        .border_color(rgba(if selected { p.accent } else { p.border }))
        .when(selected, |this| this.bg(rgba(p.accent_surface)))
        .when(enabled && !selected, |this| {
            this.hover(move |style| style.bg(rgba(hover)))
        })
        .when(enabled, |this| this.cursor_pointer())
        .text_size(px(11.5))
        .line_height(px(13.8))
        .text_color(foreground)
        .child(label.into())
}

/// One labelled row of chips.
pub fn option_row(label: &'static str, p: &Palette, children: Vec<AnyElement>) -> Div {
    div()
        .flex()
        .items_center()
        .px(px(10.))
        .py(px(6.))
        .border_b_1()
        .border_color(rgba(p.border))
        .child(
            div()
                .w(px(66.))
                .flex_none()
                .text_size(px(11.))
                .text_color(rgba(p.muted))
                .child(label),
        )
        .child(
            div()
                .flex_1()
                .flex()
                .flex_wrap()
                .items_center()
                .gap(px(5.))
                .children(children),
        )
}

/// Muted remark placed after the chips of a row.
pub fn hint(text: impl Into<SharedString>, p: &Palette) -> Div {
    div()
        .text_size(px(11.))
        .text_color(rgba(p.muted))
        .child(text.into())
}

/// Small monospaced text: the status line and value readouts.
pub fn mono(text: impl Into<SharedString>, color: u32) -> Div {
    div()
        .font_family(MONO)
        .text_size(px(11.))
        .line_height(px(14.85))
        .text_color(rgba(color))
        .child(text.into())
}

/// A section caption such as "SHAPE COLLECTION".
pub fn caption(text: &'static str) -> Div {
    div()
        .text_size(px(10.))
        .font_weight(FontWeight::SEMIBOLD)
        .child(text)
}

/// Paints a slider track, its filled part and the thumb into `bounds`.
pub fn paint_slider(
    bounds: Bounds<Pixels>,
    fraction: f64,
    focused: bool,
    p: &Palette,
    window: &mut gpui::Window,
) {
    let width = (f32::from(bounds.size.width) - 14.).max(0.);
    let left = bounds.origin.x + px(7.);
    let middle = bounds.origin.y + bounds.size.height / 2.;
    let filled = width * fraction as f32;
    window.paint_quad(fill(
        Bounds::new(point(left, middle - px(1.5)), size(px(width), px(3.))),
        rgba(p.border),
    ));
    window.paint_quad(fill(
        Bounds::new(point(left, middle - px(1.5)), size(px(filled), px(3.))),
        rgba(p.accent),
    ));
    window.paint_quad(quad(
        Bounds::new(
            point(bounds.origin.x + px(filled), middle - px(7.)),
            size(px(14.), px(14.)),
        ),
        px(7.),
        rgba(p.background),
        px(if focused { 3. } else { 2. }),
        rgba(p.accent),
        BorderStyle::Solid,
    ));
}
