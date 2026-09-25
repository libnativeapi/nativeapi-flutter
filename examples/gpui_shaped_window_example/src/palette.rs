//! The example's colours: the Flutter example's small light/dark table,
//! picked by the window's appearance. Values are `0xRRGGBBAA`.

use gpui::{Window, WindowAppearance};

pub struct Palette {
    pub background: u32,
    pub surface: u32,
    pub text: u32,
    pub muted: u32,
    pub border: u32,
    pub hover: u32,
    pub accent: u32,
    pub accent_surface: u32,
    pub danger: u32,
}

pub const LIGHT: Palette = Palette {
    background: 0xFFFFFFFF,
    surface: 0xF5F5F7FF,
    text: 0x1D1D1FFF,
    muted: 0x6E6E73FF,
    border: 0xDCDCE0FF,
    hover: 0x0000000F,
    accent: 0x1668DCFF,
    accent_surface: 0xE3EEFDFF,
    danger: 0xD93025FF,
};

pub const DARK: Palette = Palette {
    background: 0x1E1E20FF,
    surface: 0x28282BFF,
    text: 0xF2F2F4FF,
    muted: 0x9A9AA0FF,
    border: 0x3A3A3EFF,
    hover: 0xFFFFFF14,
    accent: 0x6AA8FFFF,
    accent_surface: 0x1D3557FF,
    danger: 0xFF6B61FF,
};

impl Palette {
    pub fn of(window: &Window) -> &'static Palette {
        match window.appearance() {
            WindowAppearance::Dark | WindowAppearance::VibrantDark => &DARK,
            WindowAppearance::Light | WindowAppearance::VibrantLight => &LIGHT,
        }
    }
}

/// The monospaced font of the status line and the value readouts.
#[cfg(target_os = "windows")]
pub const MONO: &str = "Consolas";
#[cfg(not(target_os = "windows"))]
pub const MONO: &str = "Menlo";
