import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:nativeapi/src/foundation/positioning_strategy.dart';
import 'package:nativeapi/src/menu.dart';

class ContextMenuRegion extends StatefulWidget {
  const ContextMenuRegion({super.key, required this.menu, required this.child});

  final Menu menu;
  final Widget child;

  @override
  State<ContextMenuRegion> createState() => _ContextMenuRegionState();
}

class _ContextMenuRegionState extends State<ContextMenuRegion> {
  bool _shouldReact = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _shouldReact =
            event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton;
      },
      onPointerUp: (event) {
        if (!_shouldReact) return;
        widget.menu.open(
          PositioningStrategy.absolute(
            Offset(event.position.dx, event.position.dy),
          ),
        );
      },
      child: widget.child,
    );
  }
}
