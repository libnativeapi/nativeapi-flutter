import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:nativeapi/src/foundation/geometry.dart' show Placement;
import 'package:nativeapi/src/foundation/positioning_strategy.dart';
import 'package:nativeapi/src/menu.dart';

/// A widget that wraps a child and adds context menu functionality.
///
/// This widget listens for right-click (secondary mouse button) events on
/// its child and opens a context menu at the click position.
///
/// Example:
/// ```dart
/// ContextMenuRegion(
///   menu: myMenu,
///   placement: Placement.bottomStart,
///   child: Container(
///     width: 200,
///     height: 200,
///     color: Colors.blue,
///   ),
/// )
/// ```
class ContextMenuRegion extends StatefulWidget {
  /// Creates a [ContextMenuRegion] widget.
  ///
  /// The [menu] and [child] arguments must not be null.
  ///
  /// The [placement] argument defaults to [Placement.bottomStart] if not provided.
  const ContextMenuRegion({
    super.key,
    required this.menu,
    required this.child,
    this.placement = Placement.bottomStart,
  });

  /// The menu to display when the region is right-clicked.
  final Menu menu;

  /// The widget to wrap with context menu functionality.
  final Widget child;

  /// The placement strategy for positioning the menu relative to the click position.
  ///
  /// Defaults to [Placement.bottomStart].
  final Placement placement;

  @override
  State<ContextMenuRegion> createState() => _ContextMenuRegionState();
}

class _ContextMenuRegionState extends State<ContextMenuRegion> {
  /// Whether the pointer down event should trigger a context menu.
  ///
  /// This is set to true only when the event is from a mouse and
  /// the secondary button (right-click) is pressed.
  bool _shouldReact = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        // Track whether this is a right-click event
        _shouldReact =
            event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton;
      },
      onPointerUp: (event) {
        // Only open menu if it was triggered by a right-click
        if (!_shouldReact) return;
        
        // Open the menu at the click position using absolute positioning
        widget.menu.open(
          PositioningStrategy.absolute(
            Offset(event.position.dx, event.position.dy),
          ),
          widget.placement,
        );
      },
      child: widget.child,
    );
  }
}
