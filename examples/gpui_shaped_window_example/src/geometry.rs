//! The twelve silhouettes and the morph between them — a port of the Flutter
//! example's `shape_geometry.dart`. Both the native clip and the painted
//! preview use these content-local logical points.

use std::collections::HashMap;
use std::f64::consts::PI;

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum DemoShape {
    Circle,
    Star,
    Bubble,
    Heart,
    Flower,
    Hexagon,
    Squircle,
    Blob,
    Burst,
    Droplet,
    Diamond,
    Shield,
}

impl DemoShape {
    pub const ALL: [DemoShape; 12] = [
        DemoShape::Circle,
        DemoShape::Star,
        DemoShape::Bubble,
        DemoShape::Heart,
        DemoShape::Flower,
        DemoShape::Hexagon,
        DemoShape::Squircle,
        DemoShape::Blob,
        DemoShape::Burst,
        DemoShape::Droplet,
        DemoShape::Diamond,
        DemoShape::Shield,
    ];

    pub fn name(self) -> &'static str {
        match self {
            DemoShape::Circle => "circle",
            DemoShape::Star => "star",
            DemoShape::Bubble => "bubble",
            DemoShape::Heart => "heart",
            DemoShape::Flower => "flower",
            DemoShape::Hexagon => "hexagon",
            DemoShape::Squircle => "squircle",
            DemoShape::Blob => "blob",
            DemoShape::Burst => "burst",
            DemoShape::Droplet => "droplet",
            DemoShape::Diamond => "diamond",
            DemoShape::Shield => "shield",
        }
    }
}

/// A content-local logical point.
#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub struct Pt {
    pub x: f64,
    pub y: f64,
}

pub const fn pt(x: f64, y: f64) -> Pt {
    Pt { x, y }
}

impl Pt {
    pub fn lerp(self, other: Pt, t: f64) -> Pt {
        pt(
            self.x + (other.x - self.x) * t,
            self.y + (other.y - self.y) * t,
        )
    }

    pub fn distance(self, other: Pt) -> f64 {
        (other.x - self.x).hypot(other.y - self.y)
    }

    fn scale(self, factor: f64) -> Pt {
        pt(self.x * factor, self.y * factor)
    }
}

/// The polygon of `shape` in a `size` × `size` square.
pub fn shape_points(shape: DemoShape, size: f64) -> Vec<Pt> {
    let c = size / 2.0;
    let points: Vec<Pt> = match shape {
        DemoShape::Circle => (0..128)
            .map(|i| {
                let a = i as f64 * PI * 2.0 / 128.0;
                pt(c + (c - 4.0) * a.cos(), c + (c - 4.0) * a.sin())
            })
            .collect(),
        DemoShape::Star => (0..10)
            .map(|i| {
                let a = -PI / 2.0 + i as f64 * PI / 5.0;
                let r = (c - 4.0) * if i % 2 == 0 { 1.0 } else { 0.60 };
                pt(c + r * a.cos(), c + r * a.sin())
            })
            .collect(),
        DemoShape::Heart => (0..96)
            .map(|i| {
                let t = i as f64 * PI * 2.0 / 96.0;
                let x = 16.0 * t.sin().powi(3);
                let y = 13.0 * t.cos()
                    - 5.0 * (2.0 * t).cos()
                    - 2.0 * (3.0 * t).cos()
                    - (4.0 * t).cos();
                pt(size * (0.5 + x / 36.0), size * (0.48 - y / 36.0))
            })
            .collect(),
        DemoShape::Flower => radial(size, 96, |a| 0.39 + 0.075 * (6.0 * (a + PI / 2.0)).cos()),
        DemoShape::Hexagon => radial(size, 6, |_| 0.47),
        DemoShape::Squircle => (0..96)
            .map(|i| {
                let a = -PI / 2.0 + i as f64 * PI * 2.0 / 96.0;
                let axis = |v: f64| {
                    if v == 0.0 {
                        0.0
                    } else {
                        v.signum() * v.abs().powf(0.5)
                    }
                };
                pt(
                    c + size * 0.43 * axis(a.cos()),
                    c + size * 0.43 * axis(a.sin()),
                )
            })
            .collect(),
        DemoShape::Blob => radial(size, 96, |a| {
            0.39 + 0.045 * (3.0 * a + 1.0).sin() + 0.025 * (5.0 * a).cos()
        }),
        DemoShape::Burst => radial(size, 24, |a| 0.40 + 0.065 * (12.0 * (a + PI / 2.0)).cos()),
        DemoShape::Droplet => (0..96)
            .map(|i| {
                let t = i as f64 * PI * 2.0 / 96.0;
                pt(
                    size * (0.5 + 0.46 * t.sin() * (0.72 - 0.28 * t.cos())),
                    size * (0.5 - 0.46 * t.cos()),
                )
            })
            .collect(),
        DemoShape::Diamond => radial(size, 4, |_| 0.47),
        DemoShape::Shield => [
            (0.5, 0.07),
            (0.9, 0.16),
            (0.85, 0.60),
            (0.7, 0.8),
            (0.5, 0.95),
            (0.3, 0.8),
            (0.15, 0.60),
            (0.1, 0.16),
        ]
        .iter()
        .map(|&(x, y)| pt(size * x, size * y))
        .collect(),
        DemoShape::Bubble => [
            (0.12, 0.08),
            (0.88, 0.08),
            (0.96, 0.16),
            (0.96, 0.72),
            (0.88, 0.80),
            (0.40, 0.80),
            (0.16, 0.96),
            (0.21, 0.80),
            (0.12, 0.80),
            (0.04, 0.72),
            (0.04, 0.16),
        ]
        .iter()
        .map(|&(x, y)| pt(size * x, size * y))
        .collect(),
    };
    match shape {
        DemoShape::Star
        | DemoShape::Bubble
        | DemoShape::Hexagon
        | DemoShape::Burst
        | DemoShape::Diamond
        | DemoShape::Shield => round_corners(&points),
        _ => points,
    }
}

/// Quadratic corner arcs are sampled into the same polygon the native window
/// gets, so visual clipping, hit testing and shadows stay aligned.
fn round_corners(points: &[Pt]) -> Vec<Pt> {
    let n = points.len();
    let mut rounded = Vec::with_capacity(n * 7);
    for i in 0..n {
        let corner = points[i];
        let before = points[(i + n - 1) % n];
        let after = points[(i + 1) % n];
        let entry = corner.lerp(before, 0.20);
        let exit = corner.lerp(after, 0.20);
        for j in 0..=6 {
            let t = j as f64 / 6.0;
            let (a, b, c) = ((1.0 - t) * (1.0 - t), 2.0 * (1.0 - t) * t, t * t);
            rounded.push(pt(
                entry.x * a + corner.x * b + exit.x * c,
                entry.y * a + corner.y * b + exit.y * c,
            ));
        }
    }
    rounded
}

fn radial(size: f64, count: usize, radius: impl Fn(f64) -> f64) -> Vec<Pt> {
    (0..count)
        .map(|i| {
            let a = -PI / 2.0 + i as f64 * PI * 2.0 / count as f64;
            let r = size * radius(a);
            pt(size / 2.0 + r * a.cos(), size / 2.0 + r * a.sin())
        })
        .collect()
}

/// Every contour resampled onto the same perimeter landmarks, including every
/// original vertex. This keeps the rounded contours exact at the endpoints
/// without twisting differently sized polygons around each other. `None` is
/// the restored rectangle.
pub fn morph_contours(extent: f64) -> HashMap<Option<DemoShape>, Vec<Pt>> {
    // Landmarks come from a fixed reference size, so point counts and
    // correspondence are identical at every window size, including mid-resize
    // retargeting.
    const REFERENCE: f64 = 320.0;
    let mut polygons: Vec<(Option<DemoShape>, Vec<Pt>)> = DemoShape::ALL
        .iter()
        .map(|&shape| (Some(shape), shape_points(shape, REFERENCE)))
        .collect();
    polygons.push((
        None,
        vec![
            pt(REFERENCE / 2.0, 0.0),
            pt(REFERENCE, 0.0),
            pt(REFERENCE, REFERENCE),
            pt(0.0, REFERENCE),
            pt(0.0, 0.0),
        ],
    ));
    // Give every clockwise contour the same top-centre starting landmark.
    for (shape, points) in &mut polygons {
        match shape {
            Some(DemoShape::Circle) => points.rotate_left(96),
            Some(DemoShape::Bubble) => {
                points.rotate_left(7);
                points.insert(0, pt(REFERENCE / 2.0, REFERENCE * 0.08));
            }
            _ => {}
        }
    }

    let mut landmarks: Vec<f64> = (0..128).map(|i| i as f64 / 128.0).collect();
    let fractions: Vec<Vec<f64>> = polygons
        .iter()
        .map(|(_, points)| {
            let n = points.len();
            let mut distances = vec![0.0];
            for i in 0..n {
                let last = *distances.last().unwrap();
                distances.push(last + points[i].distance(points[(i + 1) % n]));
            }
            let total = *distances.last().unwrap();
            let fractions: Vec<f64> = distances.iter().map(|d| d / total).collect();
            landmarks.extend_from_slice(&fractions[..n]);
            fractions
        })
        .collect();
    landmarks.sort_by(f64::total_cmp);
    landmarks.dedup();

    polygons
        .into_iter()
        .zip(fractions)
        .map(|((shape, points), fractions)| {
            let n = points.len();
            let mut edge = 0;
            let samples = landmarks.iter().map(|&t| {
                while edge + 1 < n && fractions[edge + 1] <= t {
                    edge += 1;
                }
                points[edge].lerp(
                    points[(edge + 1) % n],
                    (t - fractions[edge]) / (fractions[edge + 1] - fractions[edge]),
                )
            });
            let centre = pt(REFERENCE / 2.0, REFERENCE / 2.0);
            let scaled = samples
                .map(|p| {
                    // Circle and star keep their absolute 4 px inset; the
                    // others scale fully.
                    if matches!(shape, Some(DemoShape::Circle | DemoShape::Star)) {
                        let k = (extent - 8.0) / (REFERENCE - 8.0);
                        pt(
                            extent / 2.0 + (p.x - centre.x) * k,
                            extent / 2.0 + (p.y - centre.y) * k,
                        )
                    } else {
                        p.scale(extent / REFERENCE)
                    }
                })
                .collect();
            (shape, scaled)
        })
        .collect()
}

pub fn interpolate_contour(from: &[Pt], to: &[Pt], t: f64) -> Vec<Pt> {
    debug_assert_eq!(from.len(), to.len());
    from.iter().zip(to).map(|(a, b)| a.lerp(*b, t)).collect()
}

/// Flutter's `Cubic` curve: a CSS-style cubic Bézier easing.
#[derive(Clone, Copy)]
pub struct Cubic(f64, f64, f64, f64);

/// `Curves.easeInOut`.
pub const EASE_IN_OUT: Cubic = Cubic(0.42, 0.0, 0.58, 1.0);
/// `Curves.easeInOutCubic`.
pub const EASE_IN_OUT_CUBIC: Cubic = Cubic(0.645, 0.045, 0.355, 1.0);

impl Cubic {
    fn evaluate(a: f64, b: f64, m: f64) -> f64 {
        3.0 * a * (1.0 - m) * (1.0 - m) * m + 3.0 * b * (1.0 - m) * m * m + m * m * m
    }

    pub fn transform(self, t: f64) -> f64 {
        if t <= 0.0 {
            return 0.0;
        }
        if t >= 1.0 {
            return 1.0;
        }
        let (mut start, mut end) = (0.0, 1.0);
        loop {
            let midpoint = (start + end) / 2.0;
            let estimate = Self::evaluate(self.0, self.2, midpoint);
            if (t - estimate).abs() < 0.001 {
                return Self::evaluate(self.1, self.3, midpoint);
            }
            if estimate < t {
                start = midpoint;
            } else {
                end = midpoint;
            }
        }
    }
}
