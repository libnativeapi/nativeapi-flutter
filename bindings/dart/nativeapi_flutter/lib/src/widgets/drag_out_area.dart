import 'package:flutter/widgets.dart' hide Image;
import 'package:nativeapi/nativeapi.dart'
    hide Brightness, Color, Display, ModifierKey, ShortcutManager, Size;

/// Lets the user drag files or text out of [child], into other applications
/// (a file manager, an editor) or onto a [DropRegion].
///
/// Pressing on the child and moving past the drag threshold starts a native
/// drag with the data given here; the platform takes over the mouse until the
/// drop. [onDragEnded] reports what the target did with the data.
///
/// ```dart
/// DragOutArea(
///   filePaths: ['/path/to/report.pdf'],
///   onDragEnded: (operation) => print(operation),
///   child: const Icon(Icons.description),
/// )
/// ```
class DragOutArea extends StatefulWidget {
  const DragOutArea({
    super.key,
    required this.child,
    this.window,
    this.filePaths = const [],
    this.text,
    this.image,
    this.operation = DragOperation.copy,
    this.onDragStarted,
    this.onDragEnded,
  });

  final Widget child;

  /// The window the area is in. When omitted, resolves the current window when
  /// the drag starts.
  final Window? window;

  /// Absolute paths of the files to drag.
  final List<String> filePaths;

  /// Plain text to drag, alongside or instead of files.
  final String? text;

  /// The image shown under the cursor, or null for the platform default.
  final Image? image;

  /// The operation offered to drop targets. [DragOperation.move] tells file
  /// managers they may move the files away.
  final DragOperation operation;

  /// The native drag started.
  final VoidCallback? onDragStarted;

  /// The drag ended; [DragOperation.none] when nothing was dropped.
  final ValueChanged<DragOperation>? onDragEnded;

  /// Whether this platform supports dragging data out of windows.
  static bool get isSupported => DragSource.isSupported();

  @override
  State<DragOutArea> createState() => _DragOutAreaState();
}

class _DragOutAreaState extends State<DragOutArea> {
  DragSource? _source;
  ListenerId? _listenerId;

  bool get _hasData => widget.filePaths.isNotEmpty || widget.text != null;

  void _start() {
    final window = widget.window ?? WindowManager.instance.getCurrent();
    if (window == null || !_hasData) return;
    final source = _source ??= DragSource.create()!;
    _listenerId ??= source.addListener((event) {
      if (event is DragSourceEndedEvent && mounted) {
        widget.onDragEnded?.call(event.operation);
      }
    });
    source
      ..filePaths = widget.filePaths
      ..text = widget.text
      ..image = widget.image
      ..dragOperation = widget.operation;
    if (source.startDragging(window)) {
      widget.onDragStarted?.call();
    }
  }

  @override
  void dispose() {
    final source = _source;
    if (source != null) {
      if (_listenerId != null) source.removeListener(_listenerId!);
      source.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _hasData ? (_) => _start() : null,
      child: widget.child,
    );
  }
}
