import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:nativeapi/nativeapi.dart'
    hide Brightness, Color, Display, Image, ModifierKey, ShortcutManager, Size;

/// Adds native resize handles over the edges and corners of [child].
///
/// The child determines the size of the area. The center and disabled handles
/// allow pointer events to reach the child. Native platform support determines
/// whether resizing is available; double-tap vertical maximization is unsupported.
class DragToResizeArea extends StatelessWidget {
  const DragToResizeArea({
    super.key,
    required this.child,
    this.window,
    this.resizeEdgeSize = 8,
    this.resizeEdgeColor = const Color(0x00000000),
    this.resizeEdgeMargin = EdgeInsets.zero,
    this.enableResizeEdges,
  }) : assert(resizeEdgeSize >= 0 && resizeEdgeSize < double.infinity);

  final Widget child;

  /// The target window. When omitted, resolves the current window on interaction.
  final Window? window;

  /// Thickness of the handles, in logical pixels.
  final double resizeEdgeSize;

  /// Optional visible color for the handles, useful for debugging.
  final Color resizeEdgeColor;

  /// Insets between the child's bounds and the resize handles.
  final EdgeInsets resizeEdgeMargin;

  /// Enabled edges and corners. Null enables all; an empty list disables all.
  final List<ResizeEdge>? enableResizeEdges;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Padding(
            padding: resizeEdgeMargin,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final x = math.min(resizeEdgeSize, w / 2);
                final y = math.min(resizeEdgeSize, h / 2);
                final regions = <ResizeEdge, Rect>{
                  ResizeEdge.topLeft: Rect.fromLTWH(0, 0, x, y),
                  ResizeEdge.top: Rect.fromLTWH(x, 0, w - 2 * x, y),
                  ResizeEdge.topRight: Rect.fromLTWH(w - x, 0, x, y),
                  ResizeEdge.left: Rect.fromLTWH(0, y, x, h - 2 * y),
                  ResizeEdge.right: Rect.fromLTWH(w - x, y, x, h - 2 * y),
                  ResizeEdge.bottomLeft: Rect.fromLTWH(0, h - y, x, y),
                  ResizeEdge.bottom: Rect.fromLTWH(x, h - y, w - 2 * x, y),
                  ResizeEdge.bottomRight: Rect.fromLTWH(w - x, h - y, x, y),
                };
                return Stack(
                  children: [
                    for (final entry in regions.entries)
                      if (enableResizeEdges?.contains(entry.key) ?? true)
                        Positioned.fromRect(
                          rect: entry.value,
                          child: MouseRegion(
                            cursor: _cursorFor(entry.key),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (_) {
                                (window ?? WindowManager.instance.getCurrent())
                                    ?.startResizing(entry.key);
                              },
                              child: ColoredBox(color: resizeEdgeColor),
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  MouseCursor _cursorFor(ResizeEdge edge) => switch (edge) {
    ResizeEdge.top => SystemMouseCursors.resizeUp,
    ResizeEdge.bottom => SystemMouseCursors.resizeDown,
    ResizeEdge.left => SystemMouseCursors.resizeLeft,
    ResizeEdge.right => SystemMouseCursors.resizeRight,
    ResizeEdge.topLeft => SystemMouseCursors.resizeUpLeft,
    ResizeEdge.topRight => SystemMouseCursors.resizeUpRight,
    ResizeEdge.bottomLeft => SystemMouseCursors.resizeDownLeft,
    ResizeEdge.bottomRight => SystemMouseCursors.resizeDownRight,
  };
}
