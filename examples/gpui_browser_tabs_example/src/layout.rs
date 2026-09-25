//! Geometry of a tab strip. Pure functions, shared by the view that draws the
//! strip and the controller that hit-tests it, so both always agree.

/// Height of the strip, which takes the place of the title bar.
pub const HEIGHT: f64 = 40.0;
/// Top edge of the tabs inside the strip.
pub const TAB_TOP: f64 = 6.0;
pub const NEW_TAB_BUTTON_WIDTH: f64 = 40.0;
pub const MIN_TAB_WIDTH: f64 = 72.0;
pub const MAX_TAB_WIDTH: f64 = 220.0;
/// Width of the close-window button at the strip's right end (not on macOS).
pub const CLOSE_WINDOW_BUTTON_WIDTH: f64 = 40.0;

/// How far above or below the strip a dragged tab may go before it is torn
/// off into a window of its own.
pub const DETACH_MARGIN: f64 = 28.0;

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct TabLayout {
    pub leading_inset: f64,
    pub trailing_inset: f64,
}

impl TabLayout {
    /// The strip of the current platform. On macOS it sits under a transparent
    /// title bar and leaves room for the traffic lights; elsewhere the title
    /// bar is hidden and the strip carries its own close button.
    pub const fn platform() -> Self {
        if cfg!(target_os = "macos") {
            Self {
                leading_inset: 78.0,
                trailing_inset: 8.0,
            }
        } else {
            Self {
                leading_inset: 8.0,
                trailing_inset: 48.0,
            }
        }
    }

    /// Width of every tab when `count` tabs share a strip `strip_width` wide.
    pub fn tab_extent(&self, strip_width: f64, count: usize) -> f64 {
        if count == 0 {
            return MAX_TAB_WIDTH;
        }
        let available =
            strip_width - self.leading_inset - self.trailing_inset - NEW_TAB_BUTTON_WIDTH;
        (available / count as f64).clamp(MIN_TAB_WIDTH, MAX_TAB_WIDTH)
    }

    /// Left edge of the tab at `index`, relative to the strip.
    pub fn tab_left(&self, index: usize, extent: f64) -> f64 {
        self.leading_inset + index as f64 * extent
    }

    /// Where a dragged tab whose left edge is at `left` (relative to the
    /// strip) belongs among `count` tabs, itself included.
    pub fn index_for_left(&self, left: f64, extent: f64, count: usize) -> usize {
        if count <= 1 {
            return 0;
        }
        let index = ((left - self.leading_inset) / extent).round();
        index.clamp(0.0, (count - 1) as f64) as usize
    }

    /// Clamps a dragged tab's left edge so it stays within the tabs.
    pub fn clamp_left(&self, left: f64, extent: f64, count: usize) -> f64 {
        let last = count.saturating_sub(1) as f64;
        left.clamp(self.leading_inset, self.leading_inset + last * extent)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const LAYOUT: TabLayout = TabLayout {
        leading_inset: 78.0,
        trailing_inset: 8.0,
    };

    #[test]
    fn extent_shares_the_strip_within_limits() {
        // 760 - 78 - 8 - 40 = 634 available.
        assert_eq!(LAYOUT.tab_extent(760.0, 4), 158.5);
        assert_eq!(LAYOUT.tab_extent(760.0, 1), MAX_TAB_WIDTH);
        assert_eq!(LAYOUT.tab_extent(760.0, 20), MIN_TAB_WIDTH);
        assert_eq!(LAYOUT.tab_extent(760.0, 0), MAX_TAB_WIDTH);
    }

    #[test]
    fn index_follows_the_nearest_slot() {
        let extent = 100.0;
        assert_eq!(LAYOUT.index_for_left(78.0, extent, 4), 0);
        assert_eq!(LAYOUT.index_for_left(78.0 + 49.0, extent, 4), 0);
        assert_eq!(LAYOUT.index_for_left(78.0 + 51.0, extent, 4), 1);
        assert_eq!(LAYOUT.index_for_left(10_000.0, extent, 4), 3);
        assert_eq!(LAYOUT.index_for_left(-10.0, extent, 4), 0);
        assert_eq!(LAYOUT.index_for_left(500.0, extent, 1), 0);
    }

    #[test]
    fn clamp_keeps_the_tab_within_the_tabs() {
        let extent = 100.0;
        assert_eq!(LAYOUT.clamp_left(0.0, extent, 3), 78.0);
        assert_eq!(LAYOUT.clamp_left(1_000.0, extent, 3), 278.0);
        assert_eq!(LAYOUT.clamp_left(150.0, extent, 3), 150.0);
        assert_eq!(LAYOUT.clamp_left(150.0, extent, 1), 78.0);
    }
}
