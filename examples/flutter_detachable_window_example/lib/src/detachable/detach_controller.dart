// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:flutter/widgets.dart';
import 'package:nativeapi_flutter/nativeapi_flutter.dart' as na;

import 'package:nativeapi_flutter/windowing.dart';

/// A piece of UI that can live docked in a [DockSlot] or float in a window of
/// its own.
///
/// The content is always built under [contentKey]. Because every window of the
/// application is part of one widget tree, moving the content between windows
/// is a `GlobalKey` reparent: its `State` objects, controllers, scroll
/// positions and animations survive the move.
class DetachableItem {
  DetachableItem({
    required this.id,
    required this.title,
    required this.builder,
    this.minimumFloatingSize = const Size(240, 200),
  }) : contentKey = GlobalKey(debugLabel: 'DetachableItem($id)');

  final String id;
  final String title;
  final WidgetBuilder builder;

  /// How small the user may resize the item's floating window. The window
  /// always opens with the content size the item had while docked; if that is
  /// smaller, it becomes the minimum instead.
  final Size minimumFloatingSize;

  final GlobalKey contentKey;
}

/// A top-level window that hosts [DockSlot]s, such as the main window.
class HostWindow {
  HostWindow({required this.controller, required this.builder});

  final fw.RegularWindowController controller;
  final WidgetBuilder builder;
}

/// An item currently shown in its own window.
class FloatingWindow {
  FloatingWindow._(this.item, this.controller, this.nativeWindow);

  final DetachableItem item;
  final fw.RegularWindowController controller;

  /// Null if the platform window could not be resolved; dragging the window
  /// by its content is unavailable then, but it still works as a window.
  final na.Window? nativeWindow;
}

/// What happened, for the example's activity log.
typedef DetachLogger = void Function(String message);

class _Drag {
  _Drag({
    required this.item,
    required this.pointerInItem,
    required this.itemSize,
    this.restoreSlotId,
    this.pressPosition,
    this.tornOff = false,
  });

  final DetachableItem item;
  final Offset pointerInItem;
  final Size itemSize;

  /// Where the item was docked when the drag began, if it was.
  final String? restoreSlotId;

  /// Screen position of the press on a docked item.
  final Offset? pressPosition;

  /// Whether the item is in its own window, following the cursor.
  bool tornOff;
}

class _SlotRegistration {
  _SlotRegistration(this.id, this.context, this.viewId);

  final String id;
  final BuildContext context;
  final int viewId;
}

/// Owns the docked/floating state of [DetachableItem]s and runs the tear-off
/// gesture on top of nativeapi's `WindowDragSession`.
///
/// The gesture:
/// 1. [beginDrag] on a docked item starts a pointer-only session.
/// 2. Once the cursor is [popOutDistance] away from the press, the item is
///    torn off: a window is created for it exactly where the item was, its
///    content moves there, and the session is retargeted so the window follows
///    the cursor. Shorter drags change nothing, so there is no flicker.
/// 3. While the window moves, `WindowManager.getWindowAtPoint` (excluding the
///    moving window) finds the window under the cursor; an empty [DockSlot]
///    there under the cursor, including the one the item came from, is the
///    drop target.
/// 4. On release the item docks into the target. Anywhere else it stays a
///    window of its own, even over the window it came from; this is how
///    browser tabs and IDE tool windows behave.
///
/// [beginDrag] on a floating item starts at step 3.
class DetachController extends ChangeNotifier {
  DetachController({
    required List<DetachableItem> items,
    required Map<String, String> initialSlots,
    this.logger,
    this.popOutDistance = 8,
  }) : _items = {for (final item in items) item.id: item},
       _dockedIn = Map.of(initialSlots),
       _homeSlots = Map.of(initialSlots) {
    _session?.addListener(_handleDragEvent);
  }

  final Map<String, DetachableItem> _items;
  final Map<String, String> _dockedIn; // item id -> slot id
  final Map<String, String> _homeSlots; // item id -> initial slot id
  final Map<String, FloatingWindow> _floating = {}; // item id -> window
  final Map<String, _SlotRegistration> _slots = {};
  final Map<int, na.Window> _nativeWindowsByView = {};
  final DetachLogger? logger;

  /// How far, in logical pixels, a docked item must be dragged before it
  /// becomes a window.
  final double popOutDistance;

  final na.WindowDragSession? _session = na.WindowDragSession.create();
  _Drag? _drag;
  String? _hoveredSlotId;

  Iterable<DetachableItem> get items => _items.values;

  List<FloatingWindow> get floatingWindows =>
      List.unmodifiable(_floating.values);

  /// The empty slot the dragged window would dock into if released now.
  String? get hoveredSlotId => _hoveredSlotId;

  /// Whether a floating item's window is being dragged.
  bool get isMovingWindow => _drag?.tornOff ?? false;

  DetachableItem? itemInSlot(String slotId) {
    for (final entry in _dockedIn.entries) {
      if (entry.value == slotId) return _items[entry.key];
    }
    return null;
  }

  String? slotOf(String itemId) => _dockedIn[itemId];

  bool isFloating(String itemId) => _floating.containsKey(itemId);

  /// The content of [itemId]. Build it exactly once, wherever the item lives.
  Widget buildItem(String itemId) {
    final item = _items[itemId]!;
    return KeyedSubtree(
      key: item.contentKey,
      child: Builder(builder: item.builder),
    );
  }

  // ---------------------------------------------------------------------------
  // Registration

  /// Makes the native window of a host window known, so slots inside it can be
  /// hit-tested.
  void registerHostWindow(fw.BaseWindowController controller) {
    final window = nativeWindowOf(controller);
    if (window != null) {
      _nativeWindowsByView[controller.rootView.viewId] = window;
    }
  }

  /// Forgets a host window that is about to close. Call [floatItemsInView]
  /// first so nothing docked in it is lost.
  void unregisterHostWindow(fw.BaseWindowController controller) {
    _nativeWindowsByView.remove(controller.rootView.viewId);
  }

  /// Called by [DockSlot] whenever it is (re)inserted into a view.
  void registerSlot(String slotId, BuildContext context, int viewId) {
    _slots[slotId] = _SlotRegistration(slotId, context, viewId);
  }

  void unregisterSlot(String slotId, BuildContext context) {
    if (_slots[slotId]?.context == context) _slots.remove(slotId);
  }

  // ---------------------------------------------------------------------------
  // Commands

  /// Starts dragging [itemId]; call on pointer down, with the pointer position
  /// relative to the view the item is in.
  ///
  /// Returns false if the platform cannot track the pointer globally (for
  /// example Wayland); use [float] and [dock] there instead.
  bool beginDrag(String itemId, Offset pointerInView) {
    final session = _session;
    final item = _items[itemId];
    final context = item?.contentKey.currentContext;
    if (session == null || item == null || context == null) return false;
    // One gesture at a time.
    if (_drag != null && session.isActive) return false;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return false;

    final pointerInItem = box.globalToLocal(pointerInView);

    final floating = _floating[itemId];
    if (floating != null) {
      final window = floating.nativeWindow;
      if (window == null) return false;
      // The item fills its window, so the pointer's position in the view is
      // its position in the content.
      if (!session.start(
        window,
        (window.contentInset + pointerInView).toNative(),
      )) {
        return false;
      }
      _drag = _Drag(
        item: item,
        pointerInItem: pointerInItem,
        itemSize: box.size,
        tornOff: true,
      );
      notifyListeners();
      return true;
    }

    // Docked: follow the pointer until it has moved far enough to pop out.
    final hostWindow = _nativeWindowsByView[View.of(context).viewId];
    if (hostWindow == null || !session.start(null, Offset.zero.toNative())) {
      return false;
    }
    _drag = _Drag(
      item: item,
      pointerInItem: pointerInItem,
      itemSize: box.size,
      restoreSlotId: _dockedIn[itemId],
      pressPosition: hostWindow.contentBounds.toRect().topLeft + pointerInView,
    );
    return true;
  }

  /// Moves a docked item into its own window without a drag.
  void float(String itemId) {
    if (_floating.containsKey(itemId)) {
      _floating[itemId]!.nativeWindow?.focus();
      return;
    }
    final item = _items[itemId]!;
    final slotId = _dockedIn[itemId];
    final slot = slotId == null ? null : _slots[slotId];
    final slotRect = slot == null ? null : _slotScreenRect(slot);
    final size = slotRect?.size ?? const Size(320, 480);
    final floating = _tearOff(item, size);
    logger?.call(
      'Opened "${item.title}" in window #${floating.nativeWindow?.id ?? '?'}',
    );
    final window = floating.nativeWindow;
    if (window != null && slotRect != null) {
      window.position =
          (slotRect.topLeft - window.contentInset + const Offset(32, 32))
              .toNative();
    }
    window?.focus();
  }

  /// Moves every item docked in the view [viewId] into a window of its own,
  /// for example because that host window is closing.
  void floatItemsInView(int viewId) {
    final slots = _slots.values.where((slot) => slot.viewId == viewId).toList();
    for (final slot in slots) {
      final item = itemInSlot(slot.id);
      if (item != null) float(item.id);
    }
  }

  /// Docks [itemId] into [slotId], closing its window if it was floating.
  void dock(String itemId, String slotId) {
    if (_dockSilently(itemId, slotId)) {
      logger?.call('Docked "${_items[itemId]!.title}" into $slotId');
    }
  }

  bool _dockSilently(String itemId, String slotId) {
    // The slot's window may have closed since.
    if (!_slots.containsKey(slotId)) return false;
    final occupant = itemInSlot(slotId);
    if (occupant != null && occupant.id != itemId) return false;

    _dockedIn[itemId] = slotId;
    final floating = _floating.remove(itemId);
    if (floating != null) {
      // Hide right away; the window can only be destroyed once the frame that
      // moves the content out of it (and removes its view) has been built.
      floating.nativeWindow?.hide();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        floating.controller.destroy();
      });
      SchedulerBinding.instance.scheduleFrame();
    }
    notifyListeners();
    return true;
  }

  /// Docks a floating item back where it came from, or into any empty slot.
  /// Returns false if every slot is taken.
  bool dockAnywhere(String itemId) {
    final home = _homeSlots[itemId];
    final candidates = [
      if (home != null && _slots.containsKey(home)) home,
      ..._slots.keys.where((id) => id != home),
    ];
    for (final slotId in candidates) {
      if (itemInSlot(slotId) == null) {
        dock(itemId, slotId);
        return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Drag state machine

  void _handleDragEvent(na.WindowDragEvent event) {
    final drag = _drag;
    if (drag == null) return;
    switch (event) {
      case na.WindowDragMovedEvent(:final cursorPosition):
        final cursor = cursorPosition.toOffset();
        if (!drag.tornOff) {
          final press = drag.pressPosition!;
          if ((cursor - press).distance < popOutDistance) return;
          if (!_popOut(drag)) return;
        }
        final floating = _floating[drag.item.id];
        _setHoveredSlot(_dropTarget(cursor, floating), floating);
      case na.WindowDragEndedEvent():
        _drag = null;
        if (!drag.tornOff) return; // Released before popping out.
        final floating = _floating[drag.item.id];
        // Exactly what the highlight promised: the last move event, emitted
        // in the same tick before this one, already evaluated the release
        // position.
        final target = _hoveredSlotId;
        _setHoveredSlot(null, floating);
        final title = drag.item.title;
        if (target == null) {
          floating?.nativeWindow?.focus();
          if (drag.restoreSlotId != null) {
            logger?.call('Detached "$title" into its own window');
          }
        } else if (target == drag.restoreSlotId) {
          _dockSilently(drag.item.id, target);
          logger?.call('"$title" was dropped back onto $target');
        } else {
          dock(drag.item.id, target);
        }
        notifyListeners();
      case na.WindowDragCancelledEvent():
        _drag = null;
        if (!drag.tornOff) return;
        _setHoveredSlot(null, _floating[drag.item.id]);
        final restore = drag.restoreSlotId;
        if (restore != null) _dockSilently(drag.item.id, restore);
        notifyListeners();
    }
  }

  /// Tears the dragged item off into a window placed exactly where it was,
  /// and hands the session over to that window.
  bool _popOut(_Drag drag) {
    final torn = _tearOff(drag.item, drag.itemSize);
    final window = torn.nativeWindow;
    // Keep the point of the item that was pressed under the cursor. The
    // session moves the window there immediately and keeps it there.
    if (window == null ||
        !_session!.start(
          window,
          (window.contentInset + drag.pointerInItem).toNative(),
        )) {
      _drag = null;
      _session?.cancel();
      final restore = drag.restoreSlotId;
      if (restore != null) _dockSilently(drag.item.id, restore);
      return false;
    }
    window.focus();
    drag.tornOff = true;
    notifyListeners();
    return true;
  }

  /// Where the dragged item would go if released at [cursor]: the empty slot
  /// under the cursor in whichever window is frontmost there, if any.
  String? _dropTarget(Offset cursor, FloatingWindow? moving) {
    final excluded = moving?.nativeWindow?.id ?? 0;
    final target = na.WindowManager.instance.getWindowAtPoint(
      cursor.toNative(),
      excluded,
    );
    if (target == null) return null;
    return _emptySlotAt(cursor, target.id);
  }

  FloatingWindow _tearOff(DetachableItem item, Size size) {
    _dockedIn.remove(item.id);
    final controller = fw.RegularWindowController(
      size: size,
      title: item.title,
      constraints: BoxConstraints(
        minWidth: math.min(item.minimumFloatingSize.width, size.width),
        minHeight: math.min(item.minimumFloatingSize.height, size.height),
      ),
      delegate: _FloatingWindowDelegate(this, item.id),
    );
    final window = nativeWindowOf(controller);
    if (window != null) {
      _nativeWindowsByView[controller.rootView.viewId] = window;
      // The requested size is only a hint to the platform; the content area
      // must match the item exactly so it does not reflow when torn off.
      if (window.contentSize.toSize() != size) {
        window.contentSize = size.toNative();
      }
    }
    final floating = FloatingWindow._(item, controller, window);
    _floating[item.id] = floating;
    // The next frame builds the item inside the new window, reparenting its
    // subtree out of the slot.
    notifyListeners();
    return floating;
  }

  void _handleFloatingWindowCloseRequested(String itemId) {
    // Closing a floating window puts the panel back rather than discarding it.
    if (!dockAnywhere(itemId)) {
      _floating[itemId]?.nativeWindow?.focus();
    }
  }

  // ---------------------------------------------------------------------------
  // Hit testing

  /// The empty slot under [cursor] in the window [windowId].
  String? _emptySlotAt(Offset cursor, int windowId) {
    for (final slot in _slots.values) {
      if (itemInSlot(slot.id) != null) continue;
      if (!slot.context.mounted) continue;
      if (_nativeWindowsByView[slot.viewId]?.id != windowId) continue;
      if (_slotScreenRect(slot)?.contains(cursor) ?? false) return slot.id;
    }
    return null;
  }

  /// A slot's bounds in screen coordinates.
  Rect? _slotScreenRect(_SlotRegistration slot) {
    if (!slot.context.mounted) return null;
    final box = slot.context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final window = _nativeWindowsByView[slot.viewId];
    if (window == null) return null;
    // `localToGlobal` is relative to the slot's own view.
    final origin =
        window.contentBounds.toRect().topLeft + box.localToGlobal(Offset.zero);
    return origin & box.size;
  }

  /// Highlights [slotId] and makes the window being dragged translucent while
  /// it is over a slot, so the slot shows through.
  void _setHoveredSlot(String? slotId, FloatingWindow? moving) {
    if (_hoveredSlotId == slotId) return;
    _hoveredSlotId = slotId;
    moving?.nativeWindow?.opacity = slotId == null ? 1.0 : 0.6;
    notifyListeners();
  }

  @override
  void dispose() {
    _session?.cancel();
    _session?.dispose();
    for (final floating in _floating.values) {
      floating.controller.destroy();
    }
    super.dispose();
  }
}

class _FloatingWindowDelegate with fw.RegularWindowControllerDelegate {
  _FloatingWindowDelegate(this._controller, this._itemId);

  final DetachController _controller;
  final String _itemId;

  @override
  void onWindowCloseRequested(fw.RegularWindowController controller) {
    _controller._handleFloatingWindowCloseRequested(_itemId);
  }
}
