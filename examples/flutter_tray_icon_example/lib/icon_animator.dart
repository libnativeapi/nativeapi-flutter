import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:nativeapi/nativeapi.dart';

import 'icon_animations.dart';

/// Tray icons are laid out at this many points; [IconAnimator.scale] decides
/// how many pixels are rendered into them.
const double kIconPoints = 18;

/// Renders [IconAnimation] frames and hands each one to a tray icon.
///
/// Every frame goes Flutter canvas (or widget) → `ui.Image` → PNG → nativeapi
/// [Image] → `TrayIcon.icon`. The same `ui.Image` is kept in [lastFrame], so
/// what the in-window preview shows is exactly what the tray received.
class IconAnimator extends ChangeNotifier {
  IconAnimator({required this.onFrame, this.onMilestone});

  /// Receives each finished frame; the caller assigns it to the tray icon.
  final void Function(Image image) onFrame;

  /// Called once per run when [kMilestoneFrames] frames have been pushed.
  final void Function(IconAnimator animator)? onMilestone;

  static const int kMilestoneFrames = 100;

  /// Boundary around the [CounterBadge] that [IconAnimation.widget] captures.
  final GlobalKey captureKey = GlobalKey();

  /// Animation time in seconds. Advances by 1/fps per frame rather than with
  /// the wall clock, so Pause and Step behave and frames are reproducible.
  final ValueNotifier<double> time = ValueNotifier(0);

  IconAnimation? get animation => _animation;
  IconAnimation? _animation;

  int get fps => _fps;
  int _fps = 30;

  /// Pixels per point: 1, 2 or 3.
  int get scale => _scale;
  int _scale = 2;

  Color get color => _color;
  Color _color = const Color(0xFF000000);

  bool get paused => _paused;
  bool _paused = false;

  bool get isPlaying => _animation != null;

  // Stats of the current run.
  int frames = 0;
  int dropped = 0;
  double renderMs = 0;
  double measuredFps = 0;
  int get pixelSize => (kIconPoints * _scale).round();

  /// The frame most recently pushed to the tray (or the current still icon).
  ui.Image? get lastFrame => _lastFrame;
  ui.Image? _lastFrame;

  Timer? _timer;
  bool _busy = false;
  int _run = 0;
  bool _milestoneReported = false;
  Image? _lastNative;
  final Queue<int> _stamps = Queue<int>();
  final Stopwatch _clock = Stopwatch()..start();

  void play(IconAnimation animation) {
    _animation = animation;
    _paused = false;
    _restart(resetTime: true);
  }

  /// Stops animating. The tray keeps the last frame until a still icon is set.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _animation = null;
    _paused = false;
    _run++;
    notifyListeners();
  }

  void setFps(int value) {
    _fps = value;
    if (isPlaying) _restart(resetTime: false);
    notifyListeners();
  }

  void setScale(int value) {
    _scale = value;
    if (isPlaying) _restart(resetTime: false);
    notifyListeners();
  }

  void setColor(Color value) {
    _color = value;
    notifyListeners();
  }

  void togglePaused() {
    if (!isPlaying) return;
    _paused = !_paused;
    _stamps.clear();
    notifyListeners();
  }

  /// Renders exactly one more frame while paused.
  Future<void> step() async {
    if (!isPlaying) return;
    _paused = true;
    await _renderFrame(_run);
  }

  /// Shows a still image in the preview (the caller sets the tray icon).
  void showStill(ui.Image image) {
    _setLastFrame(image);
    notifyListeners();
  }

  void _restart({required bool resetTime}) {
    _timer?.cancel();
    _run++;
    if (resetTime) time.value = 0;
    frames = 0;
    dropped = 0;
    measuredFps = 0;
    _milestoneReported = false;
    _stamps.clear();
    _timer = Timer.periodic(
      Duration(microseconds: (1000000 / _fps).round()),
      (_) => _tick(),
    );
    notifyListeners();
  }

  void _tick() {
    if (_paused) return;
    if (_busy) {
      // The previous frame is still being rendered/encoded: skip this slot.
      dropped++;
      return;
    }
    _renderFrame(_run);
  }

  Future<void> _renderFrame(int run) async {
    final animation = _animation;
    if (animation == null || _busy) return;
    _busy = true;
    final started = _clock.elapsedMicroseconds;
    try {
      time.value += 1.0 / _fps;

      final ui.Image frame;
      if (animation == IconAnimation.widget) {
        // Let the widget rebuild for the new time, then screenshot it.
        await WidgetsBinding.instance.endOfFrame;
        final boundary = captureKey.currentContext?.findRenderObject();
        if (boundary is! RenderRepaintBoundary) {
          return; // Not mounted yet; try again next tick.
        }
        frame = await boundary.toImage(pixelRatio: _scale.toDouble());
      } else {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.scale(_scale.toDouble());
        animation.paint(canvas, kIconPoints, time.value, _color);
        final picture = recorder.endRecording();
        frame = await picture.toImage(pixelSize, pixelSize);
        picture.dispose();
      }

      final png = await frame.toByteData(format: ui.ImageByteFormat.png);
      if (png == null || run != _run) {
        frame.dispose();
        return;
      }
      final native = Image.fromBase64(
        'data:image/png;base64,${base64Encode(png.buffer.asUint8List())}',
      );
      if (native == null) {
        frame.dispose();
        return;
      }

      onFrame(native);
      // The tray now holds the new image; release our handle to the old one.
      _lastNative?.dispose();
      _lastNative = native;
      _setLastFrame(frame);

      final now = _clock.elapsedMicroseconds;
      renderMs = (now - started) / 1000.0;
      frames++;
      _stamps.addLast(now);
      if (_stamps.length > 30) _stamps.removeFirst();
      if (_stamps.length > 1) {
        measuredFps =
            (_stamps.length - 1) * 1000000.0 / (_stamps.last - _stamps.first);
      }
      if (!_milestoneReported && frames >= kMilestoneFrames) {
        _milestoneReported = true;
        onMilestone?.call(this);
      }
      notifyListeners();
    } finally {
      _busy = false;
    }
  }

  void _setLastFrame(ui.Image image) {
    final old = _lastFrame;
    _lastFrame = image;
    if (old != null) {
      // The preview may still be painting the old image this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _run++;
    _lastNative?.dispose();
    super.dispose();
  }
}
