//! The playground's state and everything it asks of nativeapi: the preview
//! window's shape (`Window::set_shape`), its contour shadow
//! (`Window::set_custom_shadow`), its size, and the 450 ms morph between
//! contours. Both windows render from this entity.

use std::rc::Rc;
use std::time::{Duration, Instant};

use gpui::{AsyncApp, Context, Task, WeakEntity};
use nativeapi::color::Color;
use nativeapi::display_manager::DisplayManager;
use nativeapi::geometry::{Point, Rectangle};
use nativeapi::window::{TitleBarStyle, Window as NativeWindow};
use nativeapi::window_shadow::WindowShadow;
use nativeapi::window_shape::WindowShape;

use crate::geometry::{
    interpolate_contour, morph_contours, DemoShape, Pt, EASE_IN_OUT, EASE_IN_OUT_CUBIC,
};

const MORPH: Duration = Duration::from_millis(450);
const SHADOW_FADE: Duration = Duration::from_millis(220);
/// Animation tick: GPUI has no animation controller that runs native work, so
/// the transitions are timer-driven tasks.
const FRAME: Duration = Duration::from_millis(16);

pub const SMALL: f64 = 320.0;
pub const LARGE: f64 = 400.0;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Rgb(pub u8, pub u8, pub u8);

impl Rgb {
    fn lerp(self, other: Rgb, t: f64) -> Rgb {
        let mix = |a: u8, b: u8| (a as f64 + (b as f64 - a as f64) * t).round() as u8;
        Rgb(
            mix(self.0, other.0),
            mix(self.1, other.1),
            mix(self.2, other.2),
        )
    }
}

const BLACK: Rgb = Rgb(0, 0, 0);

pub const SHADOW_COLORS: [(&str, Rgb); 5] = [
    ("Black", BLACK),
    ("Purple", Rgb(0x65, 0x58, 0xF5)),
    ("Blue", Rgb(0x19, 0x76, 0xD2)),
    ("Rose", Rgb(0xE7, 0x47, 0x79)),
    ("Green", Rgb(0x00, 0x89, 0x7B)),
];

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct ShadowParams {
    pub opacity: f64,
    pub blur: f64,
    pub x: f64,
    pub y: f64,
    pub color: Rgb,
}

const DEFAULT_SHADOW: ShadowParams = ShadowParams {
    opacity: 0.3,
    blur: 18.0,
    x: 0.0,
    y: 6.0,
    color: BLACK,
};

/// Name, opacity, blur radius, vertical offset and colour; every preset has
/// no horizontal offset.
pub const SHADOW_PRESETS: [(&str, f64, f64, f64, Rgb); 4] = [
    ("Soft", 0.30, 18.0, 6.0, BLACK),
    ("Float", 0.32, 32.0, 14.0, BLACK),
    ("Sharp", 0.40, 3.0, 5.0, BLACK),
    ("Glow", 0.55, 28.0, 0.0, Rgb(0x98, 0x64, 0xEF)),
];

struct ShadowAnimation {
    from: ShadowParams,
    to: ShadowParams,
    /// "None": fade the opacity out, then hide the shadow.
    fade_out: bool,
    _task: Task<()>,
}

pub struct Playground {
    main: Option<Rc<NativeWindow>>,
    preview: Option<Rc<NativeWindow>>,
    pub shape: DemoShape,
    /// The size the preview content is laid out at this frame.
    pub size: f64,
    /// The preview window's content size, which stays at the larger endpoint
    /// while a resize animates.
    native_size: f64,
    from_size: f64,
    pub to_size: f64,
    points: Vec<Pt>,
    from: Vec<Pt>,
    to: Vec<Pt>,
    target_rectangle: bool,
    pub rectangle_restored: bool,
    transition: Option<Task<()>>,
    pub count: u32,
    pub editing_shadow: bool,
    pub status: String,
    pub shadow_enabled: bool,
    pub shadow: ShadowParams,
    pub shadow_error: Option<String>,
    shadow_animation: Option<ShadowAnimation>,
}

impl Playground {
    pub fn new() -> Self {
        let points = morph_contours(SMALL)[&Some(DemoShape::Circle)].clone();
        Self {
            main: None,
            preview: None,
            shape: DemoShape::Circle,
            size: SMALL,
            native_size: SMALL,
            from_size: SMALL,
            to_size: SMALL,
            points,
            from: Vec::new(),
            to: Vec::new(),
            target_rectangle: false,
            rectangle_restored: false,
            transition: None,
            count: 0,
            editing_shadow: false,
            status: "Preparing preview…".into(),
            shadow_enabled: true,
            shadow: DEFAULT_SHADOW,
            shadow_error: None,
            shadow_animation: None,
        }
    }

    pub fn set_windows(&mut self, main: Option<NativeWindow>, preview: Option<NativeWindow>) {
        self.main = main.map(Rc::new);
        self.preview = preview.map(Rc::new);
    }

    pub fn preview_window(&self) -> Option<&NativeWindow> {
        self.preview.as_deref()
    }

    /// Readies the preview window once both windows are open: no title bar, a
    /// transparent background, the contour shadow, placement, then the first
    /// contour. Runs outside any GPUI update: moving and resizing a window
    /// calls back into GPUI.
    pub async fn configure(this: WeakEntity<Self>, cx: &mut AsyncApp) {
        let Ok((main, preview)) = this.update(cx, |p, _| (p.main.clone(), p.preview.clone()))
        else {
            return;
        };
        let Some(preview) = preview else {
            let _ = this.update(cx, |p, cx| {
                p.status =
                    "Needs macOS or Windows: nativeapi cannot reach GPUI's windows here.".into();
                cx.notify();
            });
            return;
        };
        preview.set_title_bar_style(TitleBarStyle::Hidden);
        preview.set_background_color(&Color {
            r: 0,
            g: 0,
            b: 0,
            a: 0,
        });
        let Ok(configured) = this.update(cx, |p, cx| {
            preview.set_has_shadow(p.shadow_enabled);
            p.apply_shadow_parameters(cx)
        }) else {
            return;
        };
        if !configured {
            return;
        }
        preview.set_resizable(false);
        set_content_size(&preview, SMALL);
        if let Some(area) = DisplayManager::get_primary().map(|display| display.work_area()) {
            if let Some(main) = &main {
                main.set_position(&Point {
                    x: area.x + 60.0,
                    y: area.y + 100.0,
                });
            }
            preview.set_position(&Point {
                x: area.x + 590.0,
                y: area.y + 150.0,
            });
        }
        let _ = this.update(cx, |p, cx| p.apply(cx));
        if !preview.is_visible() {
            preview.show();
        }
    }

    /// Closing the preview only hides it; the next applied contour shows it.
    pub fn hide_preview(&mut self, cx: &mut Context<Self>) {
        self.transition = None;
        if let Some(window) = self.preview.clone() {
            cx.spawn(async move |_, _| window.hide()).detach();
        }
    }

    // -----------------------------------------------------------------------
    // Shape
    // -----------------------------------------------------------------------

    fn apply(&mut self, cx: &mut Context<Self>) {
        self.apply_points(self.points.clone(), true, cx);
    }

    fn apply_points(&mut self, points: Vec<Pt>, report: bool, cx: &mut Context<Self>) -> bool {
        let Some(window) = self.preview.clone() else {
            return false;
        };
        cx.notify();
        let Some(shape) = WindowShape::new() else {
            self.status = "Could not allocate a shape.".into();
            return false;
        };
        for p in &points {
            if !shape.add_point(&Point { x: p.x, y: p.y }) {
                self.status = "Invalid polygon.".into();
                return false;
            }
        }
        // The window copies the points; `shape` is released on return.
        let ok = window.set_shape(Some(&shape));
        if ok {
            self.points = points;
            self.rectangle_restored = false;
            self.status = format!(
                "{}: native shape active ({} vertices)",
                self.shape.name(),
                shape.point_count()
            );
        } else {
            self.status = "Could not apply shape. Keeping the previous contour.".into();
        }
        if report {
            eprintln!("[shape] {}; isShaped={}", self.status, window.is_shaped());
            if !window.is_visible() {
                // Showing activates the window, which calls back into GPUI.
                cx.spawn(async move |_, _| window.show()).detach();
            }
        }
        ok
    }

    fn clear_shape(&mut self, cx: &mut Context<Self>) {
        let ok = self
            .preview
            .as_ref()
            .is_some_and(|window| window.set_shape(None));
        if ok {
            self.rectangle_restored = true;
        }
        self.status = if ok {
            "Rectangle restored"
        } else {
            "Could not restore shape"
        }
        .into();
        eprintln!("[shape] {}", self.status);
        cx.notify();
    }

    pub fn select_shape(&mut self, shape: DemoShape, cx: &mut Context<Self>) {
        self.shape = shape;
        self.transition_to(Some(shape), None, cx);
    }

    /// Toggles the destination size, not a potentially fractional in-flight
    /// one. A restored rectangle stays rectangular; an interrupted morph keeps
    /// its intended silhouette while retargeting from the current frame.
    pub fn toggle_size(&mut self, cx: &mut Context<Self>) {
        let shape = if self.rectangle_restored || self.target_rectangle {
            None
        } else {
            Some(self.shape)
        };
        let size = if self.to_size == SMALL { LARGE } else { SMALL };
        self.transition_to(shape, Some(size), cx);
    }

    pub fn restore_rectangle(&mut self, cx: &mut Context<Self>) {
        self.transition_to(None, None, cx);
    }

    /// Retargets from the displayed frame, also when a click interrupts a morph.
    fn transition_to(
        &mut self,
        shape: Option<DemoShape>,
        size: Option<f64>,
        cx: &mut Context<Self>,
    ) {
        self.transition = None;
        self.from = self.points.clone();
        self.from_size = self.size;
        self.to_size = size.unwrap_or(self.to_size);
        self.to = morph_contours(self.to_size)
            .remove(&shape)
            .unwrap_or_default();
        self.target_rectangle = shape.is_none();
        self.rectangle_restored = false;
        self.transition =
            Some(cx.spawn(async move |this, cx| Self::run_transition(this, cx).await));
        cx.notify();
    }

    async fn run_transition(this: WeakEntity<Self>, cx: &mut AsyncApp) {
        let start = Instant::now();
        loop {
            let progress = (start.elapsed().as_secs_f64() / MORPH.as_secs_f64()).min(1.0);
            // Keep a stable surface during the animation: grow once to the
            // larger endpoint, and shrink only when it has finished.
            let Ok(grow) = this.update(cx, |p, _| {
                let capacity = p.from_size.max(p.to_size);
                (p.native_size < capacity).then(|| (p.preview.clone(), capacity))
            }) else {
                return;
            };
            if let Some((window, size)) = grow {
                if let Some(window) = window {
                    set_content_size(&window, size);
                }
                let _ = this.update(cx, |p, _| p.native_size = size);
            }
            let t = EASE_IN_OUT_CUBIC.transform(progress);
            let Ok(true) = this.update(cx, |p, cx| p.transition_frame(t, cx)) else {
                return;
            };
            if progress >= 1.0 {
                let Ok(shrink) = this.update(cx, |p, _| {
                    (p.native_size != p.to_size).then(|| (p.preview.clone(), p.to_size))
                }) else {
                    return;
                };
                if let Some((window, size)) = shrink {
                    if let Some(window) = window {
                        set_content_size(&window, size);
                    }
                    let _ = this.update(cx, |p, _| p.native_size = size);
                }
                let _ = this.update(cx, |p, cx| {
                    if p.target_rectangle {
                        p.clear_shape(cx);
                    } else {
                        p.apply(cx);
                    }
                });
                return;
            }
            cx.background_executor().timer(FRAME).await;
        }
    }

    fn transition_frame(&mut self, t: f64, cx: &mut Context<Self>) -> bool {
        // Keep window geometry on whole logical pixels.
        self.size = (self.from_size + (self.to_size - self.from_size) * t).round();
        let points = interpolate_contour(&self.from, &self.to, t);
        self.apply_points(points, false, cx)
    }

    // -----------------------------------------------------------------------
    // Shadow
    // -----------------------------------------------------------------------

    fn apply_shadow_parameters(&mut self, cx: &mut Context<Self>) -> bool {
        let error = match (&self.preview, WindowShadow::new()) {
            (Some(window), Some(shadow)) => {
                let ShadowParams {
                    opacity,
                    blur,
                    x,
                    y,
                    color,
                } = self.shadow;
                shadow.set_color(&Color {
                    r: color.0,
                    g: color.1,
                    b: color.2,
                    a: (opacity * 255.0).round() as u8,
                });
                let valid = shadow.set_blur_radius(blur) && shadow.set_offset(&Point { x, y });
                // Core copies the configuration; `shadow` is released on return.
                (!valid || !window.set_custom_shadow(Some(&shadow)))
                    .then(|| "Could not apply the shadow parameters.".to_string())
            }
            _ => Some("Could not configure the preview shadow.".into()),
        };
        let ok = error.is_none();
        self.shadow_error = error;
        cx.notify();
        ok
    }

    pub fn change_shadow(
        &mut self,
        change: impl FnOnce(&mut ShadowParams),
        cx: &mut Context<Self>,
    ) {
        self.shadow_animation = None;
        change(&mut self.shadow);
        self.apply_shadow_parameters(cx);
    }

    pub fn reset_shadow_parameters(&mut self, cx: &mut Context<Self>) {
        self.change_shadow(|shadow| *shadow = DEFAULT_SHADOW, cx);
    }

    pub fn toggle_shadow(&mut self, cx: &mut Context<Self>) {
        self.shadow_animation = None;
        self.shadow_enabled = !self.shadow_enabled;
        if let Some(window) = &self.preview {
            window.set_has_shadow(self.shadow_enabled);
            eprintln!("[shadow] hasShadow={}", window.has_shadow());
        }
        cx.notify();
    }

    pub fn selected_shadow_preset(&self) -> &'static str {
        if !self.shadow_enabled {
            return "None";
        }
        SHADOW_PRESETS
            .iter()
            .find(|(_, opacity, blur, y, color)| {
                self.shadow
                    == ShadowParams {
                        opacity: *opacity,
                        blur: *blur,
                        x: 0.0,
                        y: *y,
                        color: *color,
                    }
            })
            .map_or("Custom", |preset| preset.0)
    }

    /// Animates to a preset over 220 ms; "None" fades the shadow out and then
    /// hides it.
    pub fn select_shadow_preset(&mut self, name: &str, cx: &mut Context<Self>) {
        self.shadow_animation = None;
        if name == "None" && !self.shadow_enabled {
            return;
        }
        let from = ShadowParams {
            opacity: if self.shadow_enabled {
                self.shadow.opacity
            } else {
                0.0
            },
            ..self.shadow
        };
        let fade_out = name == "None";
        let to = if fade_out {
            ShadowParams {
                opacity: 0.0,
                ..self.shadow
            }
        } else {
            let Some(&(_, opacity, blur, y, color)) =
                SHADOW_PRESETS.iter().find(|preset| preset.0 == name)
            else {
                return;
            };
            if !self.shadow_enabled {
                self.shadow.opacity = 0.0;
                self.shadow_enabled = true;
                self.apply_shadow_parameters(cx);
                if let Some(window) = &self.preview {
                    window.set_has_shadow(true);
                }
            }
            ShadowParams {
                opacity,
                blur,
                x: 0.0,
                y,
                color,
            }
        };
        let task = cx.spawn(async move |this, cx| {
            let start = Instant::now();
            loop {
                let progress = (start.elapsed().as_secs_f64() / SHADOW_FADE.as_secs_f64()).min(1.0);
                let Ok(()) = this.update(cx, |p, cx| p.shadow_frame(progress, cx)) else {
                    return;
                };
                if progress >= 1.0 {
                    return;
                }
                cx.background_executor().timer(FRAME).await;
            }
        });
        self.shadow_animation = Some(ShadowAnimation {
            from,
            to,
            fade_out,
            _task: task,
        });
    }

    fn shadow_frame(&mut self, progress: f64, cx: &mut Context<Self>) {
        let Some(animation) = &self.shadow_animation else {
            return;
        };
        let (from, to, fade_out) = (animation.from, animation.to, animation.fade_out);
        self.shadow = if progress >= 1.0 {
            to
        } else {
            let t = EASE_IN_OUT.transform(progress);
            let mix = |a: f64, b: f64| a + (b - a) * t;
            ShadowParams {
                opacity: mix(from.opacity, to.opacity),
                blur: mix(from.blur, to.blur),
                x: mix(from.x, to.x),
                y: mix(from.y, to.y),
                color: from.color.lerp(to.color, t),
            }
        };
        self.apply_shadow_parameters(cx);
        if progress >= 1.0 && fade_out {
            self.shadow_enabled = false;
            if let Some(window) = &self.preview {
                window.set_has_shadow(false);
            }
        }
    }
}

/// Resizes a window's content, keeping its top-left corner in place.
fn set_content_size(window: &NativeWindow, size: f64) {
    let bounds = window.content_bounds();
    window.set_content_bounds(&Rectangle {
        width: size,
        height: size,
        ..bounds
    });
}
