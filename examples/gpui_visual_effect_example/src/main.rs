//! Visual effect example — a GPUI window whose background is a translucent
//! material, set with nativeapi's `Window::set_visual_effect`. The GPUI
//! counterpart of `flutter_visual_effect_example`.
//!
//! The window is opened with `WindowBackgroundAppearance::Transparent`, so
//! wherever the app paints nothing the material shows. The app paints a
//! background of its own only while there is no effect.
//!
//! Usage:
//!   cargo run                            # in examples/gpui_visual_effect_example
//!   VISUAL_EFFECT_AUTOPLAY=1 cargo run   # show the backdrop and walk the effects

mod native;

use std::rc::Rc;
use std::time::Duration;

use gpui::prelude::*;
use gpui::{
    div, px, rgb, rgba, size, App, AppContext, Application, AsyncApp, Bounds, Context, FontWeight,
    SharedString, TitlebarOptions, WeakEntity, Window, WindowBackgroundAppearance, WindowBounds,
    WindowOptions,
};
use nativeapi::color::Color;
use nativeapi::geometry::Rectangle;
use nativeapi::window::{VisualEffect, Window as NativeWindow};

use crate::native::native_window_of;

const INK: u32 = 0x1b1b1f;
const ACCENT: u32 = 0x3f51b5;
/// What the window paints while no effect stands in for its background.
const SURFACE: u32 = 0xf2f2f6;

const ALL_EFFECTS: [VisualEffect; 8] = [
    VisualEffect::None,
    VisualEffect::Blur,
    VisualEffect::Acrylic,
    VisualEffect::Mica,
    VisualEffect::MicaAlt,
    VisualEffect::Hud,
    VisualEffect::Popover,
    VisualEffect::Menu,
];

/// The names the Flutter example shows (Dart's `VisualEffect.name`), so that
/// both examples and the GUI tests speak the same words.
fn effect_name(effect: VisualEffect) -> &'static str {
    match effect {
        VisualEffect::None => "none",
        VisualEffect::Blur => "blur",
        VisualEffect::Acrylic => "acrylic",
        VisualEffect::Mica => "mica",
        VisualEffect::MicaAlt => "micaAlt",
        VisualEffect::Hud => "hud",
        VisualEffect::Popover => "popover",
        VisualEffect::Menu => "menu",
    }
}

fn main() {
    Application::new().run(|cx: &mut App| {
        let options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds::centered(
                None,
                size(px(560.), px(480.)),
                cx,
            ))),
            titlebar: Some(TitlebarOptions {
                title: Some("Visual effect".into()),
                ..Default::default()
            }),
            // The GPUI view clears to transparent instead of black: whatever the
            // app leaves unpainted is the window's background, i.e. the material.
            window_background: WindowBackgroundAppearance::Transparent,
            ..Default::default()
        };
        cx.open_window(options, |window, cx| {
            let native = native_window_of(window);
            window.on_window_should_close(cx, |_, cx| {
                cx.quit();
                true
            });
            cx.new(|cx| VisualEffectView::new(native, cx))
        })
        .expect("failed to open the window");
        cx.activate(true);
    });
}

struct VisualEffectView {
    window: Option<Rc<NativeWindow>>,
    /// A plain red window behind this one, so that there is something to see
    /// through the material wherever the example happens to be on the desktop.
    backdrop: Option<NativeWindow>,
    note: SharedString,
    /// macOS draws its title bar over the content, so a material would stop at
    /// the bar; letting the content take the bar in makes it transparent and
    /// keeps the window buttons on it, which is why the panel starts clear of
    /// them. Elsewhere the call does nothing and none is needed.
    content_under_title_bar: bool,
}

impl VisualEffectView {
    fn new(window: Option<NativeWindow>, cx: &mut Context<Self>) -> Self {
        let window = window.map(Rc::new);
        let content_under_title_bar =
            window.is_some() && NativeWindow::is_content_under_title_bar_supported();
        if let Some(window) = window.clone() {
            let autoplay_on = std::env::var("VISUAL_EFFECT_AUTOPLAY").as_deref() == Ok("1");
            cx.spawn(async move |this: WeakEntity<Self>, cx: &mut AsyncApp| {
                // Taking the title bar in resizes GPUI's view, so it runs here,
                // outside every GPUI update: GPUI drops a resize that arrives
                // while the app is borrowed (see README).
                window.set_content_under_title_bar(true);
                if autoplay_on {
                    autoplay(this, window, cx).await;
                }
            })
            .detach();
        }
        Self {
            window,
            backdrop: None,
            note: "Pick an effect".into(),
            content_under_title_bar,
        }
    }

    fn apply(&mut self, effect: VisualEffect, cx: &mut Context<Self>) {
        let Some(window) = &self.window else {
            return;
        };
        let applied = window.set_visual_effect(effect);
        let verb = if applied { "Applied" } else { "Refused" };
        self.note = format!("{verb} {}", effect_name(effect)).into();
        cx.notify();
    }

    fn toggle_backdrop(&mut self, cx: &mut Context<Self>) {
        let Some(window) = self.window.clone() else {
            return;
        };
        // Showing a window and focusing this one make GPUI call back into the
        // app (activation), so this too runs outside the click handler.
        cx.spawn(async move |this: WeakEntity<Self>, cx: &mut AsyncApp| {
            toggle_backdrop(&this, &window, cx);
        })
        .detach();
    }
}

/// Shows the backdrop, or takes it away when it is there.
fn toggle_backdrop(
    this: &WeakEntity<VisualEffectView>,
    window: &NativeWindow,
    cx: &mut AsyncApp,
) -> bool {
    let Ok(existing) = this.update(cx, |this, _| this.backdrop.take()) else {
        return false;
    };
    let backdrop = match existing {
        Some(existing) => {
            window.set_parent_window(None);
            existing.hide();
            None
        }
        None => show_backdrop(window),
    };
    this.update(cx, |this, cx| {
        this.backdrop = backdrop;
        cx.notify();
    })
    .is_ok()
}

fn show_backdrop(window: &NativeWindow) -> Option<NativeWindow> {
    let backdrop = NativeWindow::new()?;
    let frame = window.bounds();
    backdrop.set_title("Backdrop");
    backdrop.set_background_color(&Color {
        r: 255,
        g: 0,
        b: 0,
        a: 255,
    });
    backdrop.set_bounds(&Rectangle {
        x: frame.x - 80.,
        y: frame.y - 80.,
        width: frame.width + 160.,
        height: frame.height + 160.,
    });
    backdrop.show();
    // A child stays above its parent, whichever of the two is brought forward.
    window.set_parent_window(Some(&backdrop));
    window.focus();
    Some(backdrop)
}

/// Walks through the effects without being asked, over the backdrop, and says
/// on stdout when each one is on screen (`STEP <effect> applied|refused`), like
/// the Flutter example does for tools/gui/flutter_visual_effect_test.py.
async fn autoplay(this: WeakEntity<VisualEffectView>, window: Rc<NativeWindow>, cx: &mut AsyncApp) {
    let step = Duration::from_millis(2500);
    cx.background_executor().timer(Duration::from_secs(4)).await;
    if !toggle_backdrop(&this, &window, cx) {
        return;
    }
    println!("STEP backdrop shown");
    let order = ALL_EFFECTS[1..]
        .iter()
        .chain(std::iter::once(&VisualEffect::None));
    for &effect in order {
        cx.background_executor().timer(step).await;
        let Ok(note) = this.update(cx, |this, cx| {
            this.apply(effect, cx);
            this.note.clone()
        }) else {
            return;
        };
        let outcome = note.split(' ').next().unwrap_or_default().to_lowercase();
        println!("STEP {} {outcome}", effect_name(effect));
    }
}

impl Drop for VisualEffectView {
    fn drop(&mut self) {
        if let Some(backdrop) = self.backdrop.take() {
            backdrop.hide();
        }
    }
}

impl Render for VisualEffectView {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let current = self
            .window
            .as_ref()
            .map_or(VisualEffect::None, |window| window.visual_effect());
        let has_effect = current != VisualEffect::None;

        let chips = ALL_EFFECTS.iter().map(|&effect| {
            let enabled = NativeWindow::is_visual_effect_supported(effect);
            chip(
                SharedString::from(format!("effect-{}", effect_name(effect))),
                effect_name(effect),
                effect == current,
                enabled,
            )
            .when(enabled, |this| {
                this.on_click(cx.listener(move |this, _, _, cx| this.apply(effect, cx)))
            })
        });

        // A material stands in for the window's background, so it shows only where
        // this app paints nothing: with no effect the window paints its own surface,
        // with one it paints only the panel and leaves the rest of the window bare.
        div()
            .size_full()
            .when(!has_effect, |this| this.bg(rgb(SURFACE)))
            .text_color(rgb(INK))
            .text_size(px(14.))
            .pl(px(24.))
            .pr(px(24.))
            .pb(px(24.))
            .pt(px(if self.content_under_title_bar {
                46.
            } else {
                24.
            }))
            .flex()
            .flex_col()
            .child(
                div()
                    .flex()
                    .flex_col()
                    .p(px(18.))
                    .rounded(px(18.))
                    .bg(rgba(0xffffffe6))
                    .child(
                        div()
                            .text_size(px(22.))
                            .font_weight(FontWeight::SEMIBOLD)
                            .child(format!("Effect: {}", effect_name(current))),
                    )
                    .child(div().mt(px(4.)).child(self.note.clone()))
                    .child(
                        div()
                            .mt(px(20.))
                            .flex()
                            .flex_wrap()
                            .gap(px(8.))
                            .children(chips),
                    )
                    .child(
                        div().mt(px(20.)).flex().child(
                            chip(
                                "backdrop".into(),
                                if self.backdrop.is_none() {
                                    "Show backdrop"
                                } else {
                                    "Hide backdrop"
                                },
                                self.backdrop.is_some(),
                                true,
                            )
                            .on_click(cx.listener(|this, _, _, cx| this.toggle_backdrop(cx))),
                        ),
                    )
                    .child(
                        div()
                            .mt(px(16.))
                            .child("Greyed out effects are not available here."),
                    ),
            )
        // Bare window below the panel: this is where the material shows.
    }
}

fn chip(
    id: SharedString,
    label: &'static str,
    selected: bool,
    enabled: bool,
) -> gpui::Stateful<gpui::Div> {
    div()
        .id(id)
        .px(px(14.))
        .py(px(7.))
        .rounded(px(16.))
        .border_1()
        .border_color(rgba(0x1b1b1f33))
        .bg(if selected {
            rgba(ACCENT << 8 | 0xff)
        } else {
            rgba(0xffffffcc)
        })
        .text_color(rgb(if selected { 0xffffff } else { INK }))
        .when(enabled, |this| this.cursor_pointer())
        .when(!enabled, |this| this.opacity(0.35))
        .child(label)
}
