import 'dart:io' show Platform;

/// Geometry of a tab strip. Pure functions, shared by the widgets that draw
/// the strip and the controller that hit-tests it, so both always agree.
class TabLayout {
  const TabLayout({required this.leadingInset, required this.trailingInset});

  /// The strip of the current platform. On macOS it sits under a transparent
  /// title bar and leaves room for the traffic lights; elsewhere the title bar
  /// is hidden and the strip carries its own close button.
  factory TabLayout.platform() => Platform.isMacOS
      ? const TabLayout(leadingInset: 78, trailingInset: 8)
      : const TabLayout(leadingInset: 8, trailingInset: 48);

  static const double height = 40;
  static const double tabTop = 6;
  static const double newTabButtonWidth = 40;
  static const double minTabWidth = 72;
  static const double maxTabWidth = 220;

  /// How far above or below the strip a dragged tab may go before it is torn
  /// off into a window of its own.
  static const double detachMargin = 28;

  final double leadingInset;
  final double trailingInset;

  /// Width of every tab when [count] tabs share a strip [stripWidth] wide.
  double tabExtent(double stripWidth, int count) {
    final available =
        stripWidth - leadingInset - trailingInset - newTabButtonWidth;
    if (count <= 0) return maxTabWidth;
    return (available / count).clamp(minTabWidth, maxTabWidth);
  }

  /// Left edge of the tab at [index], relative to the strip.
  double tabLeft(int index, double extent) => leadingInset + index * extent;

  /// Where a dragged tab whose left edge is at [left] (relative to the strip)
  /// belongs among [count] tabs, itself included.
  int indexForLeft(double left, double extent, int count) {
    if (count <= 1) return 0;
    return ((left - leadingInset) / extent).round().clamp(0, count - 1);
  }

  /// Clamps a dragged tab's left edge so it stays within the tabs.
  double clampLeft(double left, double extent, int count) =>
      left.clamp(leadingInset, leadingInset + (count - 1) * extent);
}
