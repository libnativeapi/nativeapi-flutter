// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:flutter/gestures.dart';
import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:flutter/widgets.dart';

import 'detach_controller.dart';

/// Provides a [DetachController] to every window of the application.
class DetachScope extends InheritedNotifier<DetachController> {
  const DetachScope({
    super.key,
    required DetachController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller, rebuilding [context] when docking state changes.
  static DetachController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DetachScope>();
    assert(scope != null, 'No DetachScope above ${context.widget}');
    return scope!.notifier!;
  }

  /// The controller, without a dependency; for event handlers.
  static DetachController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DetachScope>();
    assert(scope != null, 'No DetachScope above ${context.widget}');
    return scope!.notifier!;
  }
}

/// Renders the host windows plus one window per floating item, all in one
/// widget tree so content can move between them without losing state.
class DetachableWindows extends StatefulWidget {
  const DetachableWindows({
    super.key,
    required this.controller,
    required this.hosts,
    required this.floatingWindowBuilder,
  });

  final DetachController controller;
  final List<HostWindow> hosts;

  /// Wraps an item's content for its floating window; `content` must be put
  /// in the tree as is.
  final Widget Function(
    BuildContext context,
    DetachableItem item,
    Widget content,
  )
  floatingWindowBuilder;

  @override
  State<DetachableWindows> createState() => _DetachableWindowsState();
}

class _DetachableWindowsState extends State<DetachableWindows> {
  @override
  void initState() {
    super.initState();
    widget.hosts.forEach(_register);
  }

  @override
  void didUpdateWidget(DetachableWindows oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final host in widget.hosts) {
      if (!oldWidget.hosts.any((old) => old.controller == host.controller)) {
        _register(host);
      }
    }
  }

  void _register(HostWindow host) {
    widget.controller.registerHostWindow(host.controller);
  }

  @override
  Widget build(BuildContext context) {
    return DetachScope(
      controller: widget.controller,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => ViewCollection(
          views: [
            for (final host in widget.hosts)
              fw.RegularWindow(
                key: ObjectKey(host.controller),
                controller: host.controller,
                child: Builder(builder: host.builder),
              ),
            for (final floating in widget.controller.floatingWindows)
              fw.RegularWindow(
                key: ObjectKey(floating.controller),
                controller: floating.controller,
                child: Builder(
                  builder: (context) => widget.floatingWindowBuilder(
                    context,
                    floating.item,
                    widget.controller.buildItem(floating.item.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A place in a host window where one [DetachableItem] can be docked.
///
/// Shows the docked item, or [emptyBuilder] when the slot is free. A free slot
/// is a drop target while an item's window is dragged over it.
class DockSlot extends StatefulWidget {
  const DockSlot({super.key, required this.slotId, required this.emptyBuilder});

  final String slotId;

  /// Builds the free slot; `isDropTarget` is true while a dragged window would
  /// dock here on release.
  final Widget Function(BuildContext context, bool isDropTarget) emptyBuilder;

  @override
  State<DockSlot> createState() => _DockSlotState();
}

class _DockSlotState extends State<DockSlot> {
  DetachController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = DetachScope.of(context);
    _controller!.registerSlot(widget.slotId, context, View.of(context).viewId);
  }

  @override
  void didUpdateWidget(DockSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slotId != widget.slotId) {
      _controller?.unregisterSlot(oldWidget.slotId, context);
      _controller?.registerSlot(
        widget.slotId,
        context,
        View.of(context).viewId,
      );
    }
  }

  @override
  void dispose() {
    _controller?.unregisterSlot(widget.slotId, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = DetachScope.of(context);
    final item = controller.itemInSlot(widget.slotId);
    if (item != null) return controller.buildItem(item.id);
    return widget.emptyBuilder(
      context,
      controller.hoveredSlotId == widget.slotId,
    );
  }
}

/// The part of an item's content that the user grabs to tear it off or move
/// its window, such as a panel header or a tab.
class DetachHandle extends StatefulWidget {
  const DetachHandle({super.key, required this.itemId, required this.child});

  final String itemId;
  final Widget child;

  @override
  State<DetachHandle> createState() => _DetachHandleState();
}

class _DetachHandleState extends State<DetachHandle> {
  int? _pointer;

  void _handlePanStart(DragStartDetails details) {
    final pointer = _pointer;
    final started = DetachScope.read(context)
        .beginDrag(widget.itemId, details.globalPosition);
    if (started && pointer != null) {
      // The native session owns the gesture from here on. The content (and
      // with it this recognizer) is about to move to another window, and the
      // window that saw the press may never see the release, which would
      // leave the recognizer stuck mid-drag and deaf to later presses. End
      // the pointer on the Flutter side now.
      GestureBinding.instance.cancelPointer(pointer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Listener(
        onPointerDown: (event) => _pointer = event.pointer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Start from the exact point that was pressed, not where the pan
          // gesture was recognized.
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: _handlePanStart,
          child: widget.child,
        ),
      ),
    );
  }
}
