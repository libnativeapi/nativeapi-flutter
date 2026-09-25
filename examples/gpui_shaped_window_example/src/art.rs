//! Each shape's fixed look — a three-colour diagonal gradient with light spots
//! and a dotted texture — painted two ways: live with GPUI primitives for the
//! preview window (whose outline nativeapi clips), and rasterized once into a
//! clipped image for each gallery thumbnail, since GPUI has no path clipping.

use std::sync::Arc;

use gpui::{
    fill, linear_color_stop, linear_gradient, point, px, quad, rgb, rgba, size, BorderStyle,
    Bounds, ContentMask, PathBuilder, Pixels, RenderImage, Window,
};
use image::{Frame, ImageBuffer};

use crate::geometry::{shape_points, DemoShape, Pt};

pub struct ShapeLook {
    pub name: &'static str,
    /// `0xRRGGBB`, from the top-left to the bottom-right corner.
    pub colors: [u32; 3],
}

impl ShapeLook {
    pub fn of(shape: DemoShape) -> ShapeLook {
        let (name, colors) = match shape {
            DemoShape::Circle => ("Aurora", [0x6546F5, 0xBF46E9, 0xFF8799]),
            DemoShape::Star => ("Sunset", [0xEA4564, 0xFF843E, 0xFFCD70]),
            DemoShape::Bubble => ("Ocean", [0x154BBC, 0x188BC6, 0x64E4CB]),
            DemoShape::Heart => ("Berry", [0x7525A3, 0xD53788, 0xFFA8CB]),
            DemoShape::Flower => ("Lime", [0x176655, 0x45993B, 0xCCE868]),
            DemoShape::Hexagon => ("Glacier", [0x3542AD, 0x657DED, 0x9FD9FF]),
            DemoShape::Squircle => ("Honey", [0xB96616, 0xEBA92E, 0xFFDD86]),
            DemoShape::Blob => ("Lagoon", [0x116C70, 0x25A99E, 0x84EBC7]),
            DemoShape::Burst => ("Coral", [0xC32E56, 0xF36776, 0xFFAE9D]),
            DemoShape::Droplet => ("Rain", [0x2340A2, 0x467DED, 0x90CEFF]),
            DemoShape::Diamond => ("Peach", [0xC24D70, 0xEF9175, 0xFFD5AE]),
            DemoShape::Shield => ("Forest", [0x245140, 0x438568, 0xB2D69A]),
        };
        ShapeLook { name, colors }
    }
}

/// The white decorations, as (centre x, centre y, radius) fractions of the side.
const SPOTS: [(f64, f64, f64); 2] = [(0.83, 0.18, 0.31), (0.10, 0.86, 0.37)];
const SPOT_ALPHA: u8 = 0x18;
const RING: (f64, f64, f64) = (0.78, 0.22, 0.39);
const RING_ALPHA: u8 = 0x24;
const DOT_RADIUS: f64 = 0.8;
const DOT_ALPHA: u8 = 0x38;

/// Dot centres: every 20 px from 16 px, in both directions.
fn dots(side: f64) -> impl Iterator<Item = (f64, f64)> {
    let steps = move || {
        (0..)
            .map(|i| 16.0 + 20.0 * i as f64)
            .take_while(move |v| *v < side)
    };
    steps().flat_map(move |x| steps().map(move |y| (x, y)))
}

/// Paints the look over the square `bounds`, clipped to it.
pub fn paint_art(bounds: Bounds<Pixels>, look: &ShapeLook, window: &mut Window) {
    let side = f32::from(bounds.size.width);
    let o = bounds.origin;
    let at = |x: f32, y: f32| point(o.x + px(x), o.y + px(y));

    window.with_content_mask(Some(ContentMask { bounds }), |window| {
        // A linear gradient from the top-left to the bottom-right corner with
        // three stops. GPUI gradients take two, so the lower-right half comes
        // from a quad (colour 1 → 2) and the upper-left triangle is painted over
        // it (colour 0 → 1); both are colour 1 along the diagonal, so the
        // triangle's anti-aliased edge leaves no seam. GPUI's gradient line at
        // 135° on a square runs ±√2/2 from the centre where Flutter's
        // corner-to-corner one runs ±1/2, hence the stretched stop positions.
        let [c0, c1, c2] = look.colors;
        let reach = std::f32::consts::FRAC_1_SQRT_2;
        window.paint_quad(fill(
            bounds,
            linear_gradient(
                135.,
                linear_color_stop(rgb(c1), 0.5),
                linear_color_stop(rgb(c2), 0.5 + reach),
            ),
        ));
        let mut triangle = PathBuilder::fill();
        triangle.move_to(at(0., 0.));
        triangle.line_to(at(side, 0.));
        triangle.line_to(at(0., side));
        triangle.close();
        if let Ok(path) = triangle.build() {
            window.paint_path(
                path,
                linear_gradient(
                    135.,
                    linear_color_stop(rgb(c0), 0.5 - reach),
                    linear_color_stop(rgb(c1), 0.5),
                ),
            );
        }

        let circle = |cx: f64, cy: f64, r: f64| {
            Bounds::new(
                at((cx - r) as f32, (cy - r) as f32),
                size(px((2.0 * r) as f32), px((2.0 * r) as f32)),
            )
        };
        let s = side as f64;
        for (x, y, r) in SPOTS {
            let r = r * s;
            window.paint_quad(
                fill(circle(x * s, y * s, r), white(SPOT_ALPHA)).corner_radii(px(r as f32)),
            );
        }
        // A 1 px stroke centred on the circle, as Flutter strokes it.
        let (x, y, r) = RING;
        let r = r * s + 0.5;
        window.paint_quad(quad(
            circle(x * s, y * s, r),
            px(r as f32),
            gpui::transparent_black(),
            px(1.),
            white(RING_ALPHA),
            BorderStyle::Solid,
        ));
        for (x, y) in dots(s) {
            window.paint_quad(
                fill(circle(x, y, DOT_RADIUS), white(DOT_ALPHA))
                    .corner_radii(px(DOT_RADIUS as f32)),
            );
        }
    });
}

fn white(alpha: u8) -> gpui::Rgba {
    rgba(0xFFFFFF00 | alpha as u32)
}

/// The look clipped to `shape`'s polygon (even-odd), `side` logical pixels
/// square, rasterized at `scale` device pixels per logical pixel.
pub fn thumbnail(shape: DemoShape, side: f64, scale: f64) -> Arc<RenderImage> {
    const SUB: usize = 4; // 4 × 4 samples per pixel
    let n = (side * scale).round() as usize;
    let polygon: Vec<Pt> = shape_points(shape, side);
    let look = ShapeLook::of(shape);
    let colors = look.colors.map(|c| {
        [
            ((c >> 16) & 0xFF) as f64,
            ((c >> 8) & 0xFF) as f64,
            (c & 0xFF) as f64,
        ]
    });

    // Polygon coverage per device pixel, by even-odd scanlines.
    let mut coverage = vec![0u16; n * n];
    let mut crossings = Vec::new();
    for row in 0..n * SUB {
        let y = (row as f64 + 0.5) / (SUB as f64 * scale);
        crossings.clear();
        for (i, a) in polygon.iter().enumerate() {
            let b = polygon[(i + 1) % polygon.len()];
            if (a.y <= y) != (b.y <= y) {
                crossings.push(a.x + (y - a.y) / (b.y - a.y) * (b.x - a.x));
            }
        }
        crossings.sort_by(f64::total_cmp);
        for column in 0..n * SUB {
            let x = (column as f64 + 0.5) / (SUB as f64 * scale);
            let inside = crossings.iter().filter(|&&c| c < x).count() % 2 == 1;
            if inside {
                coverage[(row / SUB) * n + column / SUB] += 1;
            }
        }
    }

    let mut pixels = vec![0u8; n * n * 4];
    for py in 0..n {
        for px_ in 0..n {
            let alpha = coverage[py * n + px_] as f64 / (SUB * SUB) as f64;
            if alpha == 0.0 {
                continue;
            }
            // Logical position of the pixel centre.
            let (x, y) = ((px_ as f64 + 0.5) / scale, (py as f64 + 0.5) / scale);
            let t = (x / side + y / side) / 2.0;
            let (from, to, k) = if t < 0.5 {
                (colors[0], colors[1], t * 2.0)
            } else {
                (colors[1], colors[2], (t - 0.5) * 2.0)
            };
            let mut rgb_ = [0.0; 3];
            for i in 0..3 {
                rgb_[i] = from[i] + (to[i] - from[i]) * k;
            }
            // White decorations, anti-aliased over one device pixel.
            let cover = |d: f64| (d * scale + 0.5).clamp(0.0, 1.0);
            let mut overlay = |a: u8, amount: f64| {
                let a = a as f64 / 255.0 * amount;
                for c in &mut rgb_ {
                    *c += (255.0 - *c) * a;
                }
            };
            for (cx, cy, r) in SPOTS {
                let d = (x - cx * side).hypot(y - cy * side);
                overlay(SPOT_ALPHA, cover(r * side - d));
            }
            let (cx, cy, r) = RING;
            let d = (x - cx * side).hypot(y - cy * side);
            overlay(RING_ALPHA, cover(0.5 - (d - r * side).abs()));
            for (cx, cy) in dots(side) {
                let d = (x - cx).hypot(y - cy);
                overlay(DOT_ALPHA, cover(DOT_RADIUS - d));
            }
            // RenderImage frames are BGRA, not premultiplied.
            let i = (py * n + px_) * 4;
            pixels[i] = rgb_[2].round() as u8;
            pixels[i + 1] = rgb_[1].round() as u8;
            pixels[i + 2] = rgb_[0].round() as u8;
            pixels[i + 3] = (alpha * 255.0).round() as u8;
        }
    }
    let buffer = ImageBuffer::from_raw(n as u32, n as u32, pixels).expect("buffer size");
    Arc::new(RenderImage::new(vec![Frame::new(buffer)]))
}
