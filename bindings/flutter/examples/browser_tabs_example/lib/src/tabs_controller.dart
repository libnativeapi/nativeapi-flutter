// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:nativeapi/nativeapi.dart' as na;

import 'package:nativeapi/windowing.dart';

import 'tab_layout.dart';

/// One tab. Its page is always built under [pageKey], so the page keeps its
/// state in whichever window the tab ends up.
class BrowserTab {
  BrowserTab({required this.id, required this.title, required this.color})
    : pageKey = GlobalKey(debugLabel: 'BrowserTab($id)');

  final int id;
  final String title;
  final Color color;
  final GlobalKey pageKey;
}

/// A browser window: a tab strip and the pages of its tabs.
class BrowserWindow {
  BrowserWindow._(this.controller, this.tabs, this.activeTab);

  final fw.RegularWindowController controller;
  final List<BrowserTab> tabs;
  BrowserTab activeTab;
  na.Window? nativeWindow;

  /// Attached to the tab strip so its screen rect can be computed.
  final GlobalKey stripKey = GlobalKey(debugLabel: 'TabStrip');

  int get viewId => controller.rootView.viewId;
}

enum _DragMode {
  /// Pressed on a tab, not moved far enough yet.
  pending,

  /// The tab moves along the strip of [_TabDrag.window].
  inStrip,

  /// [_TabDrag.window] holds only the dragged tab and follows the cursor.
  window,

  /// The window itself is being moved by its strip background.
  moveWindow,
}

class _TabDrag {
  _TabDrag({
    required this.tab,
    required this.window,
    required this.grab,
    required this.press,
    required this.mode,
  });

  final BrowserTab? tab;
  BrowserWindow window;

  /// Where the tab was grabbed, relative to its top-left corner.
  final Offset grab;

  /// Screen position of the press.
  final Offset press;
  _DragMode mode;

  /// Left edge of the dragged tab relative to the strip, while [inStrip].
  double left = 0;
}

/// Chrome-style tab dragging on top of nativeapi's `WindowDragSession`.
///
/// Everything after the press is driven by the native session's cursor
/// position, including reordering within a strip: once a tab has been merged
/// into another window, that window never saw the press, so Flutter has no
/// pointer to report there.
///
/// - In a strip, the tab follows the cursor horizontally and the others make
///   room for it.
/// - Moving [TabLayout.detachMargin] above or below the strip tears the tab
///   off into a new window of the same size, with the tab still under the
///   cursor. A window's only tab takes the whole window along instead.
/// - A torn-off window dragged over another window's strip merges into it at
///   the cursor, and the drag carries on inside that strip.
class TabsController extends ChangeNotifier {
  TabsController({required this.onLastWindowClosed}) {
    _session?.addListener(_handleDragEvent);
  }

  /// Called once the last window has been destroyed.
  final VoidCallback onLastWindowClosed;

  final TabLayout layout = TabLayout.platform();
  final List<BrowserWindow> windows = [];
  final na.WindowDragSession? _session = na.WindowDragSession.create();
  _TabDrag? _drag;
  int _nextTabId = 1;

  static const Size defaultWindowSize = Size(760, 520);
  static const double popOutDistance = 8;

  static const List<Color> _palette = [
    Colors.indigo,
    Colors.teal,
    Colors.deepOrange,
    Colors.pink,
    Colors.green,
    Colors.purple,
    Colors.blueGrey,
    Colors.amber,
  ];

  // ---------------------------------------------------------------------------
  // Tabs and windows

  BrowserTab createTab() {
    final id = _nextTabId++;
    return BrowserTab(
      id: id,
      title: 'Tab $id',
      color: _palette[(id - 1) % _palette.length],
    );
  }

  BrowserWindow openWindow(List<BrowserTab> tabs, {Size? size}) {
    late final BrowserWindow window;
    final controller = fw.RegularWindowController(
      size: size ?? defaultWindowSize,
      constraints: const BoxConstraints(minWidth: 420, minHeight: 280),
      title: 'Browser',
      delegate: _WindowDelegate(() => closeWindow(window)),
    );
    window = BrowserWindow._(controller, tabs, tabs.first);
    final native = nativeWindowOf(controller);
    // Put the tab strip where the title bar would be; either way the content owns
    // that area, so the strip moves the window itself (`beginWindowDrag`).
    // On macOS the traffic lights stay and the strip leaves room for them, which
    // is a title bar the content has taken in; elsewhere the strip carries its own
    // close button and the title bar goes away with its buttons.
    if (native != null) {
      if (!native.setContentUnderTitleBar(true)) {
        native.titleBarStyle = na.TitleBarStyle.hidden;
      }
      // Either way the frame is kept, so the content just grew into the title
      // bar area; give it back the requested size.
      native.contentSize = size ?? defaultWindowSize;
    }
    window.nativeWindow = native;
    windows.add(window);
    notifyListeners();
    return window;
  }

  void addTab(BrowserWindow window) {
    final tab = createTab();
    window.tabs.add(tab);
    window.activeTab = tab;
    notifyListeners();
  }

  void activate(BrowserWindow window, BrowserTab tab) {
    if (window.activeTab == tab) return;
    window.activeTab = tab;
    notifyListeners();
  }

  void closeTab(BrowserWindow window, BrowserTab tab) {
    if (_drag?.tab == tab) return;
    _removeTab(window, tab);
    if (window.tabs.isEmpty) {
      closeWindow(window);
    } else {
      notifyListeners();
    }
  }

  void closeWindow(BrowserWindow window) {
    if (!windows.remove(window)) return;
    if (_drag?.window == window) {
      _drag = null;
      _session?.cancel();
    }
    window.nativeWindow?.hide();
    notifyListeners();
    // The window can only go once the frame without its view has been built.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      window.controller.destroy();
      if (windows.isEmpty) onLastWindowClosed();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void _removeTab(BrowserWindow window, BrowserTab tab) {
    final index = window.tabs.indexOf(tab);
    if (index < 0) return;
    window.tabs.removeAt(index);
    if (window.activeTab == tab && window.tabs.isNotEmpty) {
      window.activeTab = window.tabs[index.clamp(0, window.tabs.length - 1)];
    }
  }

  // ---------------------------------------------------------------------------
  // Queries for the strip

  /// Left edge of [tab] while it is being dragged along [window]'s strip, or
  /// null if it sits in its slot.
  double? draggedLeft(BrowserWindow window, BrowserTab tab) {
    final drag = _drag;
    if (drag == null || drag.tab != tab || drag.window != window) return null;
    return drag.mode == _DragMode.inStrip ? drag.left : null;
  }

  bool isDragging(BrowserTab tab) => _drag?.tab == tab;

  // ---------------------------------------------------------------------------
  // Starting drags

  /// Pointer went down on [tab] and started to move. [grab] is relative to the
  /// tab, [pointerInView] to the window's view.
  bool beginTabDrag(
    BrowserWindow window,
    BrowserTab tab,
    Offset grab,
    Offset pointerInView,
  ) {
    final session = _session;
    final native = window.nativeWindow;
    if (session == null || native == null || _drag != null) return false;
    if (!session.start(null, Offset.zero)) return false;
    activate(window, tab);
    _drag = _TabDrag(
      tab: tab,
      window: window,
      grab: grab,
      press: native.contentBounds.topLeft + pointerInView,
      mode: _DragMode.pending,
    );
    return true;
  }

  /// Pointer went down on the strip background: move the window.
  bool beginWindowDrag(BrowserWindow window, Offset pointerInView) {
    final session = _session;
    final native = window.nativeWindow;
    if (session == null || native == null || _drag != null) return false;
    if (!session.start(native, native.contentInset + pointerInView)) {
      return false;
    }
    _drag = _TabDrag(
      tab: null,
      window: window,
      grab: Offset.zero,
      press: Offset.zero,
      mode: _DragMode.moveWindow,
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Drag state machine

  void _handleDragEvent(na.WindowDragEvent event) {
    final drag = _drag;
    if (drag == null) return;
    switch (event) {
      case na.WindowDragMovedEvent(:final cursorPosition):
        _handleMove(drag, cursorPosition);
      case na.WindowDragEndedEvent():
        _drag = null;
        if (drag.mode == _DragMode.window) {
          drag.window.nativeWindow?.focus();
        }
        notifyListeners();
      case na.WindowDragCancelledEvent():
        _drag = null;
        notifyListeners();
    }
  }

  void _handleMove(_TabDrag drag, Offset cursor) {
    switch (drag.mode) {
      case _DragMode.moveWindow:
        return;
      case _DragMode.pending:
        if ((cursor - drag.press).distance < popOutDistance) return;
        drag.mode = _DragMode.inStrip;
        _moveInStrip(drag, cursor);
      case _DragMode.inStrip:
        _moveInStrip(drag, cursor);
      case _DragMode.window:
        final target = _windowWithStripAt(cursor, excluding: drag.window);
        if (target != null) _mergeInto(drag, target, cursor);
    }
  }

  void _moveInStrip(_TabDrag drag, Offset cursor) {
    final window = drag.window;
    final strip = _stripRect(window);
    if (strip == null) return;
    if (cursor.dy < strip.top - TabLayout.detachMargin ||
        cursor.dy > strip.bottom + TabLayout.detachMargin) {
      _tearOff(drag);
      return;
    }
    _placeInStrip(drag, window, strip, cursor);
    notifyListeners();
  }

  /// Positions the dragged tab under the cursor in [window]'s strip and moves
  /// it to the index it now covers.
  void _placeInStrip(
    _TabDrag drag,
    BrowserWindow window,
    Rect strip,
    Offset cursor,
  ) {
    final tab = drag.tab!;
    final count = window.tabs.length;
    final extent = layout.tabExtent(strip.width, count);
    drag.left = layout.clampLeft(
      cursor.dx - strip.left - drag.grab.dx,
      extent,
      count,
    );
    final index = layout.indexForLeft(drag.left, extent, count);
    final current = window.tabs.indexOf(tab);
    if (index != current) {
      window.tabs
        ..removeAt(current)
        ..insert(index, tab);
    }
  }

  void _tearOff(_TabDrag drag) {
    final source = drag.window;
    final tab = drag.tab!;
    final session = _session!;

    if (source.tabs.length == 1) {
      // Nothing would be left behind: carry the whole window instead.
      final native = source.nativeWindow!;
      session.start(native, _anchorFor(native, drag));
      drag.mode = _DragMode.window;
      notifyListeners();
      return;
    }

    final size = source.nativeWindow?.contentSize ?? defaultWindowSize;
    _removeTab(source, tab);
    final torn = openWindow([tab], size: size);
    final native = torn.nativeWindow;
    if (native == null || !session.start(native, _anchorFor(native, drag))) {
      // Could not follow the cursor: leave the new window where it is.
      _drag = null;
      session.cancel();
      notifyListeners();
      return;
    }
    native.focus();
    drag
      ..window = torn
      ..mode = _DragMode.window;
    notifyListeners();
  }

  /// The frame point that keeps the grabbed point of a window's first tab
  /// under the cursor.
  Offset _anchorFor(na.Window native, _TabDrag drag) =>
      native.contentInset +
      Offset(
        layout.leadingInset + drag.grab.dx,
        TabLayout.tabTop + drag.grab.dy,
      );

  void _mergeInto(_TabDrag drag, BrowserWindow target, Offset cursor) {
    final strip = _stripRect(target);
    if (strip == null) return;
    final dragged = drag.window;
    final tab = drag.tab!;

    // Stop moving the dragged window before it goes away; the gesture goes on
    // as a drag along the target's strip.
    _session!.start(null, Offset.zero);
    drag
      ..window = target
      ..mode = _DragMode.inStrip;
    _removeTab(dragged, tab);
    closeWindow(dragged);

    target.tabs.add(tab);
    target.activeTab = tab;
    _placeInStrip(drag, target, strip, cursor);
    target.nativeWindow?.focus();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Hit testing

  /// The window whose tab strip is under [cursor] and not covered by another
  /// window, looking through [excluding].
  BrowserWindow? _windowWithStripAt(
    Offset cursor, {
    required BrowserWindow excluding,
  }) {
    final excludedId = excluding.nativeWindow?.id ?? 0;
    final hit = na.WindowManager.instance.getWindowAtPoint(cursor, excludedId);
    if (hit == null) return null;
    final hitId = hit.id;
    for (final window in windows) {
      if (window == excluding || window.nativeWindow?.id != hitId) continue;
      final strip = _stripRect(window);
      return strip != null && strip.contains(cursor) ? window : null;
    }
    return null;
  }

  /// A window's tab strip in screen coordinates.
  Rect? _stripRect(BrowserWindow window) {
    final native = window.nativeWindow;
    final box = window.stripKey.currentContext?.findRenderObject();
    if (native == null || box is! RenderBox || !box.hasSize) return null;
    return (native.contentBounds.topLeft + box.localToGlobal(Offset.zero)) &
        box.size;
  }

  @override
  void dispose() {
    _session?.cancel();
    _session?.dispose();
    for (final window in windows) {
      window.controller.destroy();
    }
    super.dispose();
  }
}

class _WindowDelegate with fw.RegularWindowControllerDelegate {
  _WindowDelegate(this._onCloseRequested);

  final VoidCallback _onCloseRequested;

  @override
  void onWindowCloseRequested(fw.RegularWindowController controller) {
    _onCloseRequested();
  }
}
