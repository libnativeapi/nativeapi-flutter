import 'package:flutter/widgets.dart';
import 'package:nativeapi/src/window.dart';
import 'package:nativeapi/src/window_manager.dart';

/// A custom title-bar region that drags the window and toggles maximization
/// on double tap.
class DragToMoveArea extends StatelessWidget {
  const DragToMoveArea({super.key, required this.child, this.window});

  final Widget child;

  /// The target window. When omitted, resolves the current window on interaction.
  final Window? window;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) {
        (window ?? WindowManager.instance.getCurrent())?.startDragging();
      },
      onDoubleTap: () {
        final target = window ?? WindowManager.instance.getCurrent();
        if (target == null) return;
        if (target.isMaximized) {
          target.unmaximize();
        } else {
          target.maximize();
        }
      },
      child: child,
    );
  }
}
