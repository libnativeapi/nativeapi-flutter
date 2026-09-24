// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:async';
import 'dart:ui' show AppExitType;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:nativeapi_flutter/nativeapi_flutter.dart' as na;
import 'package:nativeapi_flutter/windowing.dart';

import 'shape_geometry.dart';
import 'widgets/option_chip.dart';
import 'widgets/palette.dart';
import 'widgets/value_slider.dart';
import 'widgets/shape_art.dart';

void main() {
  isWindowingEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();
  runWidget(const ShapeDemo());
}

class _CloseDelegate with fw.RegularWindowControllerDelegate {
  _CloseDelegate(this.close);
  final VoidCallback close;
  @override
  void onWindowCloseRequested(fw.RegularWindowController controller) => close();
}

class ShapeDemo extends StatefulWidget {
  const ShapeDemo({super.key});
  @override
  State<ShapeDemo> createState() => _ShapeDemoState();
}

class _ShapeDemoState extends State<ShapeDemo>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final _main = fw.RegularWindowController(
    size: const Size(480, 680),
    title: 'Window shapes',
    delegate: _CloseDelegate(_close),
  );
  static const _resizeChannel = MethodChannel('shape_demo/resize');
  bool get _keepsSurfaceDuringTransition =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
  late final fw.RegularWindowController _demo = fw.RegularWindowController(
    size: const Size(320, 320),
    title: 'Shape preview',
    delegate: _CloseDelegate(_hidePreview),
  );

  void _hidePreview() {
    _stopTransition();
    _nativePreview?.hide();
  }

  late final na.Window? _nativePreview = _demo.nativeWindow;
  DemoShape _shape = DemoShape.circle;
  double _size = 320;
  double _nativeSize = 320;
  double _fromSize = 320;
  double _toSize = 320;
  Timer? _transitionTimer;
  double? _pendingProgress;
  bool _applyingTransition = false;
  int _transitionRevision = 0;
  Timer? _shadowFrameTimer;
  late final AnimationController _shadowAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(_scheduleShadowFrame);
  late (double, double, double, double, Color) _shadowFrom;
  late (double, double, double, double, Color) _shadowTo;
  bool _shadowFadeOut = false;

  void _scheduleShadowFrame() {
    _shadowFrameTimer ??= Timer(Duration.zero, () {
      _shadowFrameTimer = null;
      if (!mounted || _closing) return;
      final t = Curves.easeInOut.transform(_shadowAnimation.value);
      double mix(double a, double b) => a + (b - a) * t;
      setState(() {
        _shadowOpacity = mix(_shadowFrom.$1, _shadowTo.$1);
        _shadowBlur = mix(_shadowFrom.$2, _shadowTo.$2);
        _shadowX = mix(_shadowFrom.$3, _shadowTo.$3);
        _shadowY = mix(_shadowFrom.$4, _shadowTo.$4);
        _shadowColor = Color.lerp(_shadowFrom.$5, _shadowTo.$5, t)!;
      });
      _applyShadowParameters();
      if (_shadowAnimation.value == 1 && _shadowFadeOut) {
        setState(() => _shadowEnabled = false);
        _nativePreview?.hasShadow = false;
      }
    });
  }

  void _stopShadowAnimation() {
    _shadowAnimation.stop();
    _shadowFrameTimer?.cancel();
    _shadowFrameTimer = null;
  }

  int _count = 0;
  bool _editingShadow = false;
  ShapeLook get _look => ShapeLook.forShape(_shape);
  bool _closing = false;
  String _status = 'Preparing preview…';
  // Linux clips content in Flutter; core alone renders and positions its shadow.
  // Shape coordinates and content size never include the native shadow gutter.
  late final bool _usesInputShape = na.Window.isInputShapeSupported();
  bool _shadowEnabled = true;
  Color _shadowColor = const Color(0xFF000000);
  double _shadowOpacity = 0.3;
  double _shadowBlur = 18;
  double _shadowX = 0;
  double _shadowY = 6;
  String? _shadowError;
  bool _rectangleRestored = false;
  bool _applyPending = false;
  bool _previewReady = false;
  late List<Offset> _points = morphContours(_size)[_shape]!;
  List<Offset> _from = [];
  List<Offset> _to = [];
  bool _targetRectangle = false;
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..addListener(_animateFrame);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Configure the native handle after Flutter has attached both window views.
    // On Windows it is not ready while this State is being initialized.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_closing) _configurePreview();
    });
  }

  void _configurePreview() {
    final window = _nativePreview;
    if (window != null) {
      window.titleBarStyle = na.TitleBarStyle.hidden;
      window.backgroundColor = const Color(0x00000000).toNative();
      window.hasShadow = _shadowEnabled;
      if (!_applyShadowParameters()) return;
      window.isResizable = false;
      // Wayland ignores absolute positioning. Keep the preview above its own
      // controller window instead of letting the latter cover the silhouette.
      if (_usesInputShape) window.setParentWindow(_main.nativeWindow);
      window.contentSize = Size.square(_size).toNative();
      final area = na.DisplayManager.instance.getPrimary()?.workArea.toRect();
      if (area != null) {
        _main.nativeWindow?.position = Offset(
          area.left + 60,
          area.top + 100,
        ).toNative();
        window.position = Offset(area.left + 590, area.top + 150).toNative();
      }
    }
    _previewReady = true;
    _scheduleApply();
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _shadowFrameTimer?.cancel();
    _shadowAnimation.dispose();
    _morph.dispose();
    _nativePreview?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Active animation frames already replace the contour after resizing.
    // Reapplying it from every metrics callback duplicates native/shadow work.
    if (_previewReady && !_rectangleRestored && !_applyingTransition) {
      _scheduleApply();
    }
  }

  void _scheduleApply() {
    if (_applyPending || _closing) return;
    _applyPending = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _applyPending = false;
      if (!_rectangleRestored) {
        if (_morph.isAnimating) {
          _applyPoints(_points, report: false);
        } else {
          _apply();
        }
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _apply() {
    _applyPoints(_points);
  }

  bool _applyPoints(List<Offset> points, {bool report = true}) {
    if (!mounted || _closing) return false;
    final window = _nativePreview;
    if (window == null) return false;
    final shape = na.WindowShape.create();
    if (shape == null) {
      setState(() => _status = 'Could not allocate a shape.');
      return false;
    }
    try {
      for (final point in points) {
        if (!shape.addPoint(point.toNative())) {
          setState(() => _status = 'Invalid polygon.');
          return false;
        }
      }
      final ok = _usesInputShape
          ? window.setInputShape(shape)
          : window.setShape(shape);
      setState(() {
        if (ok) {
          _points = points;
          _rectangleRestored = false;
        }
        _status = ok
            ? _usesInputShape
                  ? '${_shape.name}: Flutter clip + native input region (${shape.pointCount} vertices)'
                  : '${_shape.name}: native shape active (${shape.pointCount} vertices)'
            : 'Could not apply shape. Keeping the previous contour.';
      });
      if (report) {
        debugPrint(
          '[shape] $_status; isShaped=${window.isShaped}; '
          'isInputShaped=${window.isInputShaped}',
        );
        if (!window.isVisible) window.show();
      }
      return ok;
    } finally {
      // The window copied the points and does not retain the builder.
      shape.dispose();
    }
  }

  void _stopTransition() {
    _morph.stop();
    _transitionTimer?.cancel();
    _transitionTimer = null;
    _pendingProgress = null;
    _transitionRevision++;
  }

  void _animateFrame() {
    _pendingProgress = Curves.easeInOutCubic.transform(_morph.value);
    _scheduleTransitionFrame();
  }

  void _scheduleTransitionFrame() {
    if (_transitionTimer != null || _applyingTransition) return;
    // Native resize can synchronously pump Flutter's event loop. Run at idle,
    // outside handleBeginFrame, and serialize/coalesce any reentrant ticks.
    _transitionTimer = Timer(Duration.zero, () async {
      _transitionTimer = null;
      final progress = _pendingProgress;
      _pendingProgress = null;
      if (!mounted || _closing || progress == null) return;
      _applyingTransition = true;
      try {
        await _applyTransitionFrame(progress);
      } on PlatformException catch (error) {
        _stopTransition();
        if (mounted && !_closing) {
          setState(
            () => _status = 'Could not resize preview: ${error.message}',
          );
        }
      } finally {
        _applyingTransition = false;
        if (_pendingProgress != null) _scheduleTransitionFrame();
      }
    });
  }

  Future<void> _applyTransitionFrame(double t) async {
    final revision = _transitionRevision;
    // Keep window geometry on whole logical pixels.
    final nextSize = (_fromSize + (_toSize - _fromSize) * t).roundToDouble();
    if (_keepsSurfaceDuringTransition) {
      // Keep a stable backing surface during the animation. Reallocating the
      // Flutter surface for every pixel step makes the native host wait for raster.
      final capacity = _fromSize > _toSize ? _fromSize : _toSize;
      if (_nativeSize < capacity) await _resizePreviewSurface(capacity);
    } else if (nextSize != _size) {
      _nativePreview?.contentSize = Size.square(nextSize).toNative();
    }
    if (revision != _transitionRevision || !mounted || _closing) return;
    final points = interpolateContour(_from, _to, t);
    if (_usesInputShape) {
      // Submit the Flutter clip before publishing its matching native contour.
      // Applying the shadow at idle first lets GTK paint the new silhouette over
      // the previous Flutter frame. Serialize this pair before consuming a tick.
      setState(() {
        _size = nextSize;
        _points = points;
      });
      await WidgetsBinding.instance.endOfFrame;
      if (revision != _transitionRevision || !mounted || _closing) return;
    } else if (nextSize != _size) {
      setState(() => _size = nextSize);
    }
    if (!_applyPoints(points, report: false)) {
      _stopTransition();
      return;
    }
    if (t == 1) {
      if (_keepsSurfaceDuringTransition && _nativeSize != _toSize) {
        // Finish the endpoint layout before tightening the native bounds.
        // This waits for framework layout, not for GPU completion.
        await WidgetsBinding.instance.endOfFrame;
        if (revision != _transitionRevision || !mounted || _closing) return;
        await _resizePreviewSurface(_toSize);
        if (revision != _transitionRevision || !mounted || _closing) return;
      }
      if (_targetRectangle) {
        _clearShape();
      } else {
        _apply();
      }
    }
  }

  Future<void> _resizePreviewSurface(double size) async {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _resizeChannel.invokeMethod<void>('setContentSize', {
        'window': _nativePreview!.nativeObject.address,
        'size': size,
      });
    } else {
      _nativePreview?.contentSize = Size.square(size).toNative();
    }
    _nativeSize = size;
  }

  void _transitionTo(DemoShape? shape, {double? targetSize}) {
    // Retarget from the displayed frame, including when clicks interrupt a morph.
    _stopTransition();
    _from = List.of(_points);
    _fromSize = _size;
    _toSize = targetSize ?? _toSize;
    _to = morphContours(_toSize)[shape]!;
    _targetRectangle = shape == null;
    _rectangleRestored = false;
    if (WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations) {
      // Apply directly even when the controller already finished at value 1.
      _pendingProgress = 1;
      _scheduleTransitionFrame();
    } else {
      _morph.forward(from: 0);
    }
  }

  void selectShape(DemoShape shape) {
    setState(() => _shape = shape);
    _transitionTo(shape);
  }

  void resizePreview() {
    // Toggle the destination, not a potentially fractional in-flight size.
    // A restored rectangle stays rectangular; interrupted shape morphs keep
    // their intended silhouette while retargeting from the current frame.
    _transitionTo(
      _rectangleRestored || _targetRectangle ? null : _shape,
      targetSize: _toSize == 320 ? 400 : 320,
    );
  }

  void restoreRectangle() => _transitionTo(null);

  bool _applyShadowParameters() {
    final window = _nativePreview;
    final shadow = na.WindowShadow.create();
    String? error;
    try {
      if (window == null || shadow == null) {
        error = 'Could not configure the preview shadow.';
      } else {
        shadow.color = _shadowColor
            .withValues(alpha: _shadowOpacity)
            .toNative();
        final valid =
            shadow.setBlurRadius(_shadowBlur) &&
            shadow.setOffset(Offset(_shadowX, _shadowY).toNative());
        if (!valid || !window.setCustomShadow(shadow)) {
          error = 'Could not apply the shadow parameters.';
        }
      }
    } finally {
      shadow?.dispose();
    }
    if (mounted) setState(() => _shadowError = error);
    return error == null;
  }

  void _changeShadow(VoidCallback change) {
    _stopShadowAnimation();
    setState(change);
    _applyShadowParameters();
  }

  void _resetShadowParameters() => _changeShadow(() {
    _shadowColor = const Color(0xFF000000);
    _shadowOpacity = 0.3;
    _shadowBlur = 18;
    _shadowX = 0;
    _shadowY = 6;
  });

  Widget _shadowSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool percent = false,
  }) {
    final display = percent
        ? '${(value * 100).round()}%'
        : '${value.round()} px';
    return Builder(
      builder: (context) {
        final p = Palette.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: p.muted),
                ),
              ),
              Expanded(
                child: ValueSlider(
                  label: label,
                  value: value,
                  min: min,
                  max: max,
                  step: percent ? 0.01 : 1,
                  display: display,
                  formatValue: (v) =>
                      percent ? '${(v * 100).round()}%' : '${v.round()} px',
                  onChanged: (next) => _changeShadow(() => onChanged(next)),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(display, textAlign: TextAlign.end, style: p.mono),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shadowControls() {
    const colors = <String, Color>{
      'Black': Color(0xFF000000),
      'Purple': Color(0xFF6558F5),
      'Blue': Color(0xFF1976D2),
      'Rose': Color(0xFFE74779),
      'Green': Color(0xFF00897B),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OptionRow(
          label: 'Shadow',
          children: [
            OptionChip(
              label: 'On',
              selected: _shadowEnabled,
              onTap: _shadowEnabled ? null : toggleShadow,
            ),
            OptionChip(
              label: 'Off',
              selected: !_shadowEnabled,
              onTap: _shadowEnabled ? toggleShadow : null,
            ),
            const Hint('Contour shadow'),
          ],
        ),
        OptionRow(
          label: 'Color',
          children: [
            for (final entry in colors.entries)
              OptionChip(
                label: entry.key,
                selected: _shadowColor == entry.value,
                onTap: () => _changeShadow(() => _shadowColor = entry.value),
              ),
          ],
        ),
        _shadowSlider(
          'Opacity',
          _shadowOpacity,
          0,
          1,
          (v) => _shadowOpacity = v,
          percent: true,
        ),
        _shadowSlider(
          'Blur radius',
          _shadowBlur,
          0,
          64,
          (v) => _shadowBlur = v,
        ),
        _shadowSlider('Horizontal', _shadowX, -64, 64, (v) => _shadowX = v),
        _shadowSlider('Vertical', _shadowY, -64, 64, (v) => _shadowY = v),
        OptionRow(
          label: 'Defaults',
          children: [
            OptionChip(
              label: 'Reset shadow parameters',
              onTap: _resetShadowParameters,
            ),
          ],
        ),
        if (!_shadowEnabled)
          const Padding(
            padding: EdgeInsets.all(10),
            child: Hint('Shadow hidden. Changes appear when enabled.'),
          ),
        if (_shadowError != null)
          Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                _shadowError!,
                style: TextStyle(color: Palette.of(context).danger),
              ),
            ),
          ),
      ],
    );
  }

  void toggleShadow() {
    _stopShadowAnimation();
    setState(() => _shadowEnabled = !_shadowEnabled);
    _nativePreview?.hasShadow = _shadowEnabled;
    debugPrint('[shadow] hasShadow=${_nativePreview?.hasShadow}');
  }

  void _clearShape() {
    final window = _nativePreview;
    final ok =
        (_usesInputShape
            ? window?.setInputShape(null)
            : window?.setShape(null)) ??
        false;
    setState(() {
      if (ok) {
        _rectangleRestored = true;
      }
      _status = ok ? 'Rectangle restored' : 'Could not restore shape';
    });
    debugPrint('[shape] $_status');
  }

  void _close() {
    if (_closing) return;
    _stopTransition();
    _stopShadowAnimation();
    setState(() => _closing = true);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _demo.destroy();
      _main.destroy();
      ServicesBinding.instance.exitApplication(AppExitType.required);
    });
  }

  Object? _controlsConfiguration;
  Widget? _controlsWindow;

  static const _shadowPresets = <String, (double, double, double, Color)>{
    'Soft': (.30, 18, 6, Color(0xFF000000)),
    'Float': (.32, 32, 14, Color(0xFF000000)),
    'Sharp': (.40, 3, 5, Color(0xFF000000)),
    'Glow': (.55, 28, 0, Color(0xFF9864EF)),
  };

  void _selectShadowPreset(String name) {
    _stopShadowAnimation();
    if (name == 'None' && !_shadowEnabled) return;
    _shadowFrom = (
      _shadowEnabled ? _shadowOpacity : 0,
      _shadowBlur,
      _shadowX,
      _shadowY,
      _shadowColor,
    );
    _shadowFadeOut = name == 'None';
    if (_shadowFadeOut) {
      _shadowTo = (0, _shadowBlur, _shadowX, _shadowY, _shadowColor);
    } else {
      final p = _shadowPresets[name]!;
      _shadowTo = (p.$1, p.$2, 0, p.$3, p.$4);
      if (!_shadowEnabled) {
        setState(() {
          _shadowOpacity = 0;
          _shadowEnabled = true;
        });
        _applyShadowParameters();
        _nativePreview?.hasShadow = true;
      }
    }
    if (WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations) {
      _shadowAnimation.value = 1;
      _scheduleShadowFrame();
    } else {
      _shadowAnimation.forward(from: 0);
    }
  }

  String get _selectedShadowPreset {
    if (!_shadowEnabled) return 'None';
    for (final entry in _shadowPresets.entries) {
      final p = entry.value;
      if (_shadowOpacity == p.$1 &&
          _shadowBlur == p.$2 &&
          _shadowY == p.$3 &&
          _shadowX == 0 &&
          _shadowColor == p.$4) {
        return entry.key;
      }
    }
    return 'Custom';
  }

  Widget _buildControlsWindow() {
    // Keep the control view unchanged while the independent preview animates.
    final configuration = (
      _shape,
      _editingShadow,
      _count,
      _toSize,
      _status,
      _rectangleRestored,
      _shadowEnabled,
      _shadowColor,
      _shadowOpacity,
      _shadowBlur,
      _shadowX,
      _shadowY,
      _shadowError,
    );
    if (_controlsConfiguration != configuration) {
      _controlsConfiguration = configuration;
      _controlsWindow = fw.RegularWindow(
        controller: _main,
        child: WidgetsApp(
          color: Palette.light.accent,
          debugShowCheckedModeBanner: false,
          builder: (context, _) {
            final p = Palette.of(context);
            return DefaultTextStyle(
              style: TextStyle(fontSize: 12, height: 1.3, color: p.text),
              child: ColoredBox(
                color: p.background,
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF201C45), _look.colors.first],
                        ),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Outside the box.',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                          Spacer(),
                          Text(
                            'SHAPE PLAYGROUND',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.3,
                              color: Color(0xFFDDD5FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Row(
                        children: [
                          Text(
                            _editingShadow
                                ? 'CUSTOM SHADOW'
                                : 'SHAPE COLLECTION',
                            style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (_editingShadow)
                            OptionChip(
                              label: 'Done',
                              selected: true,
                              onTap: () =>
                                  setState(() => _editingShadow = false),
                            )
                          else
                            Text(
                              '${DemoShape.values.length} silhouettes',
                              style: p.mono,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _editingShadow
                          ? Center(child: _shadowControls())
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  for (var row = 0; row < 3; row++)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            for (
                                              var col = 0;
                                              col < 4;
                                              col++
                                            ) ...[
                                              if (col > 0)
                                                const SizedBox(width: 8),
                                              Expanded(
                                                child: _shapeCard(
                                                  DemoShape.values[row * 4 +
                                                      col],
                                                  p,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                    if (!_editingShadow)
                      OptionRow(
                        label: 'Window',
                        children: [
                          OptionChip(
                            label: 'Apply shape',
                            onTap: () => selectShape(_shape),
                          ),
                          OptionChip(
                            label: 'Restore rectangle',
                            onTap: restoreRectangle,
                          ),
                        ],
                      ),
                    if (!_editingShadow)
                      OptionRow(
                        label: 'Size',
                        children: [
                          OptionChip(
                            label: 'Toggle size',
                            onTap: resizePreview,
                          ),
                          Text(
                            '${_toSize.toInt()} × ${_toSize.toInt()} · 450 ms',
                            style: p.mono,
                          ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                      child: Row(
                        children: [
                          const Text(
                            'SHADOW',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_selectedShadowPreset, style: p.mono),
                          const Spacer(),
                          OptionChip(
                            label: _editingShadow
                                ? 'Back to shapes'
                                : 'Adjust…',
                            selected: _editingShadow,
                            onTap: () => setState(
                              () => _editingShadow = !_editingShadow,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: [
                          for (final name in ['None', ..._shadowPresets.keys])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: OptionChip(
                                  label: name,
                                  selected: _selectedShadowPreset == name,
                                  onTap: () => _selectShadowPreset(name),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: p.surface,
                        border: Border(top: BorderSide(color: p.border)),
                      ),
                      child: Text(
                        _shadowError ?? _status,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _shadowError == null
                            ? p.mono
                            : p.mono.copyWith(color: p.danger),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    return _controlsWindow!;
  }

  Widget _shapeCard(DemoShape shape, Palette p) {
    final selected = !_rectangleRestored && shape == _shape;
    return Semantics(
      button: true,
      selected: selected,
      label: shape.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => selectShape(shape),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? p.accentSurface : p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? p.accent : p.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipPath(
                  clipper: ShapeClipper(shape, 46),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: ShapeArt(look: ShapeLook.forShape(shape)),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  shape.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? p.accent : p.text,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_closing) return const ViewCollection(views: []);
    return ViewCollection(
      views: [
        _buildControlsWindow(),
        fw.RegularWindow(
          controller: _demo,
          child: WidgetsApp(
            debugShowCheckedModeBanner: false,
            color: const Color(0x00000000),
            builder: (context, _) => DefaultTextStyle(
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: const Color(0xFFFFFFFF),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: _size,
                  height: _size,
                  child: ClipPath(
                    clipper: _usesInputShape && !_rectangleRestored
                        ? PolygonClipper(_points)
                        : null,
                    child: ShapeArt(
                      look: _look,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.move,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (_) =>
                                    _nativePreview?.startDragging(),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Text(
                                    '⠿  DRAG ME',
                                    style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 2,
                                      color: Color(0xDDFFFFFF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              _rectangleRestored ? 'rectangle' : _shape.name,
                              style: const TextStyle(
                                fontSize: 29,
                                letterSpacing: -1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() => _count++),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x30FFFFFF),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(0x70FFFFFF),
                                    ),
                                  ),
                                  child: Text(
                                    'Tap · $_count',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _look.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                letterSpacing: 3,
                                color: Color(0xCCFFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
