import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nativeapi/src/menu.dart';

class ContextMenuRegion extends StatefulWidget {
  const ContextMenuRegion({super.key, required this.menu, required this.child});

  final Menu menu;
  final Widget child;

  @override
  State<ContextMenuRegion> createState() => _ContextMenuRegionState();
}

class _ContextMenuRegionState extends State<ContextMenuRegion> {
  void _handleSecondaryTapDown(TapDownDetails details) {
    print(details.globalPosition);
    widget.menu.open(at: details.globalPosition);
  }

  void _handleTapDown(TapDownDetails details) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        // Don't open the menu on these platforms with a Ctrl-tap (or a
        // tap).
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // Only open the menu on these platforms if the control button is down
        // when the tap occurs.
        if (HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.controlLeft,
            ) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.controlRight,
            )) {
          widget.menu.open(at: details.localPosition);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onSecondaryTapDown: _handleSecondaryTapDown,
      child: widget.child,
    );
  }
}
