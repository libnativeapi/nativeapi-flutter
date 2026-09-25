use gpui::{point, px, size, Bounds, Hsla, Pixels, Rgba};
use nativeapi::color::Color;
use nativeapi::geometry::{Point, Rectangle, Size};

/// Converts a GPUI value to its nativeapi counterpart.
///
/// GPUI's logical pixels and nativeapi's coordinates are both points on macOS;
/// on Windows nativeapi uses physical pixels divided by the scale factor of
/// the monitor they fall on, which matches GPUI's logical pixels.
pub trait ToNative {
    type Native;
    fn to_native(&self) -> Self::Native;
}

/// Converts a nativeapi value to its GPUI counterpart.
pub trait ToGpui {
    type Gpui;
    fn to_gpui(&self) -> Self::Gpui;
}

impl ToNative for gpui::Point<Pixels> {
    type Native = Point;
    fn to_native(&self) -> Point {
        Point {
            x: f64::from(self.x),
            y: f64::from(self.y),
        }
    }
}

impl ToGpui for Point {
    type Gpui = gpui::Point<Pixels>;
    fn to_gpui(&self) -> gpui::Point<Pixels> {
        point(px(self.x as f32), px(self.y as f32))
    }
}

impl ToNative for gpui::Size<Pixels> {
    type Native = Size;
    fn to_native(&self) -> Size {
        Size {
            width: f64::from(self.width),
            height: f64::from(self.height),
        }
    }
}

impl ToGpui for Size {
    type Gpui = gpui::Size<Pixels>;
    fn to_gpui(&self) -> gpui::Size<Pixels> {
        size(px(self.width as f32), px(self.height as f32))
    }
}

impl ToNative for Bounds<Pixels> {
    type Native = Rectangle;
    fn to_native(&self) -> Rectangle {
        Rectangle {
            x: f64::from(self.origin.x),
            y: f64::from(self.origin.y),
            width: f64::from(self.size.width),
            height: f64::from(self.size.height),
        }
    }
}

impl ToGpui for Rectangle {
    type Gpui = Bounds<Pixels>;
    fn to_gpui(&self) -> Bounds<Pixels> {
        Bounds::new(
            point(px(self.x as f32), px(self.y as f32)),
            size(px(self.width as f32), px(self.height as f32)),
        )
    }
}

impl ToNative for Rgba {
    type Native = Color;
    fn to_native(&self) -> Color {
        let channel = |value: f32| (value.clamp(0.0, 1.0) * 255.0).round() as u8;
        Color {
            r: channel(self.r),
            g: channel(self.g),
            b: channel(self.b),
            a: channel(self.a),
        }
    }
}

impl ToNative for Hsla {
    type Native = Color;
    fn to_native(&self) -> Color {
        Rgba::from(*self).to_native()
    }
}

impl ToGpui for Color {
    type Gpui = Rgba;
    fn to_gpui(&self) -> Rgba {
        Rgba {
            r: f32::from(self.r) / 255.0,
            g: f32::from(self.g) / 255.0,
            b: f32::from(self.b) / 255.0,
            a: f32::from(self.a) / 255.0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bounds_round_trip() {
        let rect = Rectangle {
            x: 10.0,
            y: -20.5,
            width: 300.0,
            height: 200.25,
        };
        assert_eq!(rect.to_gpui().to_native(), rect);
    }

    #[test]
    fn color_round_trip() {
        let color = Color {
            r: 0x4c,
            g: 0x8d,
            b: 0xff,
            a: 0x80,
        };
        assert_eq!(color.to_gpui().to_native(), color);
        assert_eq!(gpui::rgb(0xff0000).to_native().r, 255);
    }
}
