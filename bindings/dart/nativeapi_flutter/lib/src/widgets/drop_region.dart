import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:nativeapi/nativeapi.dart'
    hide
        Brightness,
        Color,
        Display,
        EdgeInsets,
        Image,
        ModifierKey,
        ShortcutManager,
        Size,
        TextField,
        View;

import '../conversions.dart';

/// What was dropped on a [DropRegion].
class DropRegionDropDetails {
  const DropRegionDropDetails({
    required this.localPosition,
    required this.filePaths,
    required this.text,
  });

  /// Where the data was dropped, relative to the region.
  final Offset localPosition;

  /// Absolute paths of the dropped files and directories; empty when none.
  final List<String> filePaths;

  /// The dropped plain text, or null when none.
  final String? text;
}

/// Accepts files and text dragged onto [child] from other applications or
/// other windows.
///
/// All regions of a window share one native [DropTarget], created while at
/// least one region is mounted. The target accepts drags over the whole
/// window; each event goes to the innermost region under the cursor, and a
/// drop outside every region is ignored.
///
/// ```dart
/// DropRegion(
///   onDropped: (details) => print(details.filePaths),
///   child: const SizedBox.expand(),
/// )
/// ```
///
/// Positions assume the Flutter view fills the window's content area, which is
/// the case for the default runners.
class DropRegion extends StatefulWidget {
  const DropRegion({
    super.key,
    required this.child,
    this.window,
    this.onDragEntered,
    this.onDragUpdated,
    this.onDragExited,
    this.onDropped,
  });

  final Widget child;

  /// The window the region is in. When omitted, the focused window is used,
  /// or the only window when the app has one. Pass it in multi-window apps.
  final Window? window;

  /// A drag entered the region, at this position relative to it.
  final ValueChanged<Offset>? onDragEntered;

  /// A drag moved within the region, to this position relative to it.
  final ValueChanged<Offset>? onDragUpdated;

  /// The drag left the region, or was cancelled, without dropping.
  final VoidCallback? onDragExited;

  /// Data was dropped on the region.
  final ValueChanged<DropRegionDropDetails>? onDropped;

  /// Whether this platform supports dropping onto windows.
  static bool get isSupported => DropTarget.isSupported();

  @override
  State<DropRegion> createState() => _DropRegionState();
}

class _DropRegionState extends State<DropRegion> {
  _DropTargetHub? _hub;

  RenderBox? get _box {
    final object = context.findRenderObject();
    return object is RenderBox && object.attached ? object : null;
  }

  int get _viewId => View.of(context).viewId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attach();
  }

  @override
  void didUpdateWidget(DropRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.window?.id != widget.window?.id) _attach();
  }

  void _attach() {
    final window = widget.window ?? _defaultWindow();
    if (window == null) return;
    if (_hub?.windowId == window.id) return;
    _hub?.remove(this);
    _hub = _DropTargetHub.forWindow(window)..add(this);
  }

  static Window? _defaultWindow() {
    final manager = WindowManager.instance;
    final current = manager.getCurrent();
    if (current != null) return current;
    final all = manager.getAll();
    return all.length == 1 ? all.single : null;
  }

  @override
  void dispose() {
    _hub?.remove(this);
    _hub = null;
    super.dispose();
  }

  Offset _local(Offset global) => _box?.globalToLocal(global) ?? global;

  @override
  Widget build(BuildContext context) {
    // Translucent: the region is found by hit testing even over empty space.
    return _DropRegionMarker(child: widget.child);
  }
}

class _DropRegionMarker extends SingleChildRenderObjectWidget {
  const _DropRegionMarker({super.child});

  @override
  _RenderDropRegionMarker createRenderObject(BuildContext context) =>
      _RenderDropRegionMarker();
}

class _RenderDropRegionMarker extends RenderProxyBoxWithHitTestBehavior {
  _RenderDropRegionMarker() : super(behavior: HitTestBehavior.translucent);
}

/// The native target of one window, shared by that window's regions.
class _DropTargetHub {
  _DropTargetHub._(this.windowId, this.target) {
    _listenerId = target.addListener(_handle);
  }

  static final Map<WindowId, _DropTargetHub> _hubs = {};

  static _DropTargetHub forWindow(Window window) {
    return _hubs[window.id] ??= _DropTargetHub._(
      window.id,
      DropTarget.create(window)!,
    );
  }

  final WindowId windowId;
  final DropTarget target;
  late final ListenerId _listenerId;
  final List<_DropRegionState> _regions = [];
  _DropRegionState? _current;

  void add(_DropRegionState region) => _regions.add(region);

  void remove(_DropRegionState region) {
    _regions.remove(region);
    if (_current == region) _current = null;
    if (_regions.isEmpty) {
      target.removeListener(_listenerId);
      target.dispose();
      _hubs.remove(windowId);
    }
  }

  /// The innermost mounted region under [position], by Flutter's own hit test.
  _DropRegionState? _regionAt(Offset position) {
    if (_regions.isEmpty) return null;
    final result = HitTestResult();
    RendererBinding.instance.hitTestInView(
      result,
      position,
      _regions.first._viewId,
    );
    for (final entry in result.path) {
      for (final region in _regions) {
        if (region.mounted && identical(region._box, entry.target)) {
          return region;
        }
      }
    }
    return null;
  }

  void _moveTo(_DropRegionState? region, Offset position) {
    if (region != _current) {
      _current?.widget.onDragExited?.call();
      _current = region;
      region?.widget.onDragEntered?.call(region._local(position));
    } else {
      region?.widget.onDragUpdated?.call(region._local(position));
    }
  }

  void _handle(DropTargetEvent event) {
    switch (event) {
      case DropTargetEnteredEvent(:final position):
        _current = null;
        _moveTo(_regionAt(position.toOffset()), position.toOffset());
      case DropTargetMovedEvent(:final position):
        _moveTo(_regionAt(position.toOffset()), position.toOffset());
      case DropTargetExitedEvent():
        _current?.widget.onDragExited?.call();
        _current = null;
      case DropTargetDroppedEvent(
        :final position,
        :final filePaths,
        :final text,
      ):
        final region = _regionAt(position.toOffset());
        if (region != _current) _current?.widget.onDragExited?.call();
        _current = null;
        region?.widget.onDropped?.call(
          DropRegionDropDetails(
            localPosition: region._local(position.toOffset()),
            filePaths: filePaths,
            text: text,
          ),
        );
    }
  }
}
