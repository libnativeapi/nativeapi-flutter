//! Window title bar example — every state a window's title bar can be in, on
//! one screen: the GPUI counterpart of `flutter_window_title_bar_example`.
//!
//! The window is opened with GPUI's default (standard) title bar; every change
//! after that goes through nativeapi (`Window::set_title_bar_style`,
//! `set_content_under_title_bar`, `set_window_control_buttons_visible`), and
//! GPUI follows the resized content view.
//!
//! Usage:
//!   cargo run                          # in examples/gpui_window_title_bar_example
//!   TITLE_BAR_AUTOPLAY=1 cargo run     # walk through the states by itself

use std::rc::Rc;
use std::time::Duration;

use gpui::prelude::*;
use gpui::{
    div, px, rgb, rgba, size, App, AppContext, Application, AsyncApp, Bounds, Context, FontWeight,
    MouseButton, SharedString, TitlebarOptions, WeakEntity, Window, WindowBounds, WindowOptions,
};
use nativeapi::window::{TitleBarStyle, Window as NativeWindow};

use nativeapi_gpui::WindowExt;

const INK: u32 = 0x1b1b1f;
const MUTED: u32 = 0x6b6b76;
const ACCENT: u32 = 0x3f51b5;
const SURFACE: u32 = 0xf2f2f6;
const PANEL: u32 = 0xffffff;
const STRIP: u32 = 0xe4e4ee;
/// 0x1A1B1B1F in Flutter's ARGB.
const LINE: u32 = 0x1b1b1f1a;

/// The strip this example draws where a title bar would be. It is always
/// there, whatever the title bar is doing, so that a window with no title bar
/// and no close button can still be moved and quit.
const STRIP_HEIGHT: f32 = 44.;

/// How far the strip's own controls start from the left, so that they do not
/// end up under the macOS window buttons when those are on top of the content.
const BUTTONS_INSET: f32 = 78.;

fn main() {
    Application::new().run(|cx: &mut App| {
        let options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds::centered(
                None,
                size(px(620.), px(520.)),
                cx,
            ))),
            // GPUI's default title bar: a standard one. nativeapi changes it
            // from there, as the Flutter example does with its window.
            titlebar: Some(TitlebarOptions {
                title: Some("nativeapi · Title bar".into()),
                ..Default::default()
            }),
            window_min_size: Some(size(px(520.), px(420.))),
            ..Default::default()
        };
        cx.open_window(options, |window, cx| {
            let native = window.native_window();
            window.on_window_should_close(cx, |_, cx| {
                cx.quit();
                true
            });
            cx.new(|cx| TitleBarView::new(native, cx))
        })
        .expect("failed to open the window");
        cx.activate(true);
    });
}

type Change = fn(&NativeWindow);

fn normal(w: &NativeWindow) {
    w.set_content_under_title_bar(false);
    w.set_title_bar_style(TitleBarStyle::Normal);
}

fn content_under(w: &NativeWindow) {
    w.set_title_bar_style(TitleBarStyle::Normal);
    w.set_content_under_title_bar(true);
}

fn hidden(w: &NativeWindow) {
    w.set_title_bar_style(TitleBarStyle::Hidden);
}

fn show_buttons(w: &NativeWindow) {
    w.set_window_control_buttons_visible(true);
}

fn hide_buttons(w: &NativeWindow) {
    w.set_window_control_buttons_visible(false);
}

const NOTE_NORMAL: &str = "Standard title bar";
const NOTE_UNDER: &str = "The bar is a transparent overlay; its buttons stay";
const NOTE_HIDDEN: &str = "No title bar and no window buttons — move me by the strip";

struct TitleBarView {
    /// Shared with the strip's mouse handler, which starts window drags.
    window: Option<Rc<NativeWindow>>,
    note: SharedString,
}

impl TitleBarView {
    fn new(window: Option<NativeWindow>, cx: &mut Context<Self>) -> Self {
        let window = window.map(Rc::new);
        if let Some(window) = window.clone() {
            if std::env::var("TITLE_BAR_AUTOPLAY").as_deref() == Ok("1") {
                cx.spawn(async move |this: WeakEntity<Self>, cx: &mut AsyncApp| {
                    autoplay(this, window, cx).await;
                })
                .detach();
            }
        }
        Self {
            window,
            note: "Try the three states and watch the strip below".into(),
        }
    }

    /// Changes the title bar from a task rather than from the click handler.
    fn act(&mut self, what: &'static str, change: Change, cx: &mut Context<Self>) {
        let Some(window) = self.window.clone() else {
            return;
        };
        cx.spawn(async move |this: WeakEntity<Self>, cx: &mut AsyncApp| {
            change_title_bar(&this, &window, what, change, cx);
        })
        .detach();
    }
}

/// Makes a title bar change, then says what happened.
///
/// The change has to happen outside every GPUI update, which is why it runs in
/// a task and not in a click handler or an `update` closure: it resizes GPUI's
/// view synchronously, and GPUI's resize callback cannot reach the app while
/// the app is borrowed — the resize is dropped, and GPUI keeps laying the
/// window out at its old size (see README).
fn change_title_bar(
    this: &WeakEntity<TitleBarView>,
    window: &NativeWindow,
    what: &'static str,
    change: Change,
    cx: &mut AsyncApp,
) -> bool {
    change(window);
    this.update(cx, |this, cx| {
        this.note = what.into();
        cx.notify();
    })
    .is_ok()
}

/// Walks through the states without being asked and prints `STEP <name>` once
/// each is on screen, so the example can be looked at without touching the
/// mouse. The Flutter example has no such mode; this one is for GPUI's sake,
/// to see how its content area follows each change.
async fn autoplay(this: WeakEntity<TitleBarView>, window: Rc<NativeWindow>, cx: &mut AsyncApp) {
    let steps: [(&str, &'static str, Change); 6] = [
        ("under", NOTE_UNDER, content_under),
        ("hidden", NOTE_HIDDEN, hidden),
        ("hidden+buttons", "Buttons shown", show_buttons),
        ("under-again", NOTE_UNDER, content_under),
        ("under-buttons", "Buttons hidden", hide_buttons),
        ("normal", NOTE_NORMAL, normal),
    ];
    cx.background_executor().timer(Duration::from_secs(3)).await;
    println!("STEP start");
    for (name, note, change) in steps {
        cx.background_executor()
            .timer(Duration::from_millis(2500))
            .await;
        if !change_title_bar(&this, &window, note, change, cx) {
            return;
        }
        println!("STEP {name}");
    }
}

impl Render for TitleBarView {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let window = self.window.as_ref();
        let style = window.map_or(TitleBarStyle::Normal, |w| w.title_bar_style());
        let under = window.is_some_and(|w| w.is_content_under_title_bar());
        let buttons = window.is_some_and(|w| w.is_window_control_buttons_visible());
        let supported = NativeWindow::is_content_under_title_bar_supported();
        let content = window.map(|w| w.content_size());
        let size_text = content.map_or("0 × 0".to_string(), |s| {
            format!("{} × {}", s.width.round(), s.height.round())
        });
        let style_name = match style {
            TitleBarStyle::Normal => "normal",
            TitleBarStyle::Hidden => "hidden",
        };

        let states = div()
            .flex()
            .flex_wrap()
            .gap(px(8.))
            .child(
                chip(
                    "normal",
                    "Normal",
                    style == TitleBarStyle::Normal && !under,
                    true,
                )
                .on_click(cx.listener(|this, _, _, cx| this.act(NOTE_NORMAL, normal, cx))),
            )
            .child(
                chip(
                    "under",
                    "Content under title bar",
                    style == TitleBarStyle::Normal && under,
                    supported,
                )
                .when(supported, |this| {
                    this.on_click(
                        cx.listener(|this, _, _, cx| this.act(NOTE_UNDER, content_under, cx)),
                    )
                }),
            )
            .child(
                chip("hidden", "Hidden", style == TitleBarStyle::Hidden, true)
                    .on_click(cx.listener(|this, _, _, cx| this.act(NOTE_HIDDEN, hidden, cx))),
            );

        let button_chips = div()
            .mt(px(10.))
            .flex()
            .flex_wrap()
            .gap(px(8.))
            .child(
                chip("show-buttons", "Show buttons", buttons, true).on_click(
                    cx.listener(|this, _, _, cx| this.act("Buttons shown", show_buttons, cx)),
                ),
            )
            .child(
                chip("hide-buttons", "Hide buttons", !buttons, true).on_click(
                    cx.listener(|this, _, _, cx| this.act("Buttons hidden", hide_buttons, cx)),
                ),
            );

        div()
            .size_full()
            .flex()
            .flex_col()
            .bg(rgb(SURFACE))
            .text_color(rgb(INK))
            .text_size(px(13.))
            .child(self.strip(style == TitleBarStyle::Normal && under))
            .child(
                div()
                    .id("body")
                    .flex_1()
                    .min_h_0()
                    .overflow_y_scroll()
                    .child(
                        div()
                            .flex()
                            .flex_col()
                            .gap(px(16.))
                            .pt(px(20.))
                            .pb(px(24.))
                            .px(px(24.))
                            .child(card(
                                "Now",
                                div()
                                    .flex()
                                    .flex_col()
                                    .child(row("titleBarStyle", style_name.into()))
                                    .child(row("isContentUnderTitleBar", under.to_string()))
                                    .child(row(
                                        "isWindowControlButtonsVisible",
                                        buttons.to_string(),
                                    ))
                                    .child(row(
                                        "isContentUnderTitleBarSupported()",
                                        supported.to_string(),
                                    ))
                                    .child(row("contentSize", size_text))
                                    .child(
                                        div()
                                            .mt(px(8.))
                                            .text_color(rgb(MUTED))
                                            .child(self.note.clone()),
                                    ),
                            ))
                            .child(card("The three states", states))
                            .child(card(
                                "Window control buttons",
                                div()
                                    .flex()
                                    .flex_col()
                                    .child(div().text_color(rgb(MUTED)).child(
                                        "Setting a style resets these to what it implies, so \
                                         these override it and go after it.",
                                    ))
                                    .child(button_chips),
                            ))
                            .child(card(
                                "What to look for",
                                div()
                                    .flex()
                                    .flex_col()
                                    .child(bullet(
                                        "Hidden leaves no title bar and no window buttons on \
                                         every platform. Move the window by the strip above; \
                                         Quit ends the application (core has no \
                                         Window.close() yet).",
                                    ))
                                    .child(bullet(
                                        "Content under title bar keeps the bar and its buttons \
                                         but stops it drawing: the strip runs to the top edge \
                                         behind them. macOS only — elsewhere the chip is \
                                         greyed out and the call returns false.",
                                    ))
                                    .child(bullet(
                                        "Switching states keeps the window where it is and the \
                                         same size; only contentSize above changes, by the \
                                         height of the title bar.",
                                    ))
                                    .child(bullet(
                                        "Hidden also stops the system moving the window when \
                                         you drag the top of the content — that is what the \
                                         strip is for.",
                                    ))
                                    .child(bullet(
                                        "isContentUnderTitleBar stays as it was set while \
                                         Hidden is on: with no title bar there is nothing for \
                                         it to do, and it takes effect again on Normal.",
                                    )),
                            )),
                    ),
            )
    }
}

impl TitleBarView {
    /// The example's own title bar. Under a real title bar it is just a strip;
    /// with the content under the title bar it runs up behind the window
    /// buttons, which is why its controls start clear of them.
    fn strip(&self, under_title_bar: bool) -> impl IntoElement {
        let drag = self.window.clone();
        div()
            .id("strip")
            .flex_none()
            .h(px(STRIP_HEIGHT))
            .flex()
            .items_center()
            .pl(px(if under_title_bar { BUTTONS_INSET } else { 16. }))
            .pr(px(10.))
            .bg(rgb(STRIP))
            .border_b_1()
            .border_color(rgba(LINE))
            // The DragToMoveArea of the Flutter example: the platform moves the
            // window from here on (Window::start_dragging).
            .on_mouse_down(MouseButton::Left, move |_, _, _| {
                if let Some(window) = &drag {
                    window.start_dragging();
                }
            })
            .child(
                div()
                    .flex_1()
                    .font_weight(FontWeight::SEMIBOLD)
                    .child("Drag this strip to move the window"),
            )
            .child(
                chip("quit", "Quit", false, true)
                    // Keep the press from starting a window drag.
                    .on_mouse_down(MouseButton::Left, |_, _, cx| cx.stop_propagation())
                    .on_click(|_, _, cx| cx.quit()),
            )
    }
}

fn card(title: &'static str, child: impl IntoElement) -> impl IntoElement {
    div()
        .flex()
        .flex_col()
        .p(px(16.))
        .rounded(px(14.))
        .border_1()
        .border_color(rgba(LINE))
        .bg(rgb(PANEL))
        .child(
            div()
                .text_size(px(15.))
                .font_weight(FontWeight::BOLD)
                .child(title),
        )
        .child(div().mt(px(10.)).child(child))
}

fn row(name: &'static str, value: String) -> impl IntoElement {
    div()
        .flex()
        .pb(px(4.))
        .child(div().w(px(240.)).text_color(rgb(MUTED)).child(name))
        .child(
            div()
                .flex_1()
                .font_weight(FontWeight::SEMIBOLD)
                .child(value),
        )
}

fn bullet(text: &'static str) -> impl IntoElement {
    div()
        .flex()
        .pb(px(8.))
        .text_color(rgb(MUTED))
        .child(div().flex_none().child("·  "))
        .child(div().flex_1().min_w_0().child(text))
}

fn chip(
    id: &'static str,
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
        .border_color(if selected {
            rgba(ACCENT << 8 | 0xff)
        } else {
            rgba(LINE)
        })
        .bg(rgb(if selected { ACCENT } else { PANEL }))
        .text_color(rgb(if selected { 0xffffff } else { INK }))
        .font_weight(FontWeight::SEMIBOLD)
        .when(enabled, |this| this.cursor_pointer())
        .when(!enabled, |this| this.opacity(0.35))
        .child(label)
}
