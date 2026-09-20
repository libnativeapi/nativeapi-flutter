import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:nativeapi/nativeapi.dart';

void main() {
  runApp(const VisualEffectApp());
}

const Color _ink = Color(0xFF1B1B1F);
const Color _accent = Color(0xFF3F51B5);
/// What the window paints while no effect stands in for its background.
const Color _surface = Color(0xFFF2F2F6);

/// macOS draws its title bar over the content, so a material would stop at the
/// bar; letting the content take the bar in makes it transparent and keeps the
/// window buttons on it, which is why the panel below starts clear of them.
/// Elsewhere the call does nothing and none is needed: Windows 11 draws the
/// material across its caption by itself.
final bool _contentUnderTitleBar =
    Window.isContentUnderTitleBarSupported();

/// The window's background is the visual effect, so nothing here paints one:
/// no MaterialApp, no Scaffold. Whatever the app leaves unpainted is the
/// material, and what it paints sits on top of it.
class VisualEffectApp extends StatelessWidget {
  const VisualEffectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      debugShowCheckedModeBanner: false,
      color: _accent,
      textStyle: const TextStyle(color: _ink, fontSize: 14),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
      home: const VisualEffectPage(),
    );
  }
}

class VisualEffectPage extends StatefulWidget {
  const VisualEffectPage({super.key});

  @override
  State<VisualEffectPage> createState() => _VisualEffectPageState();
}

class _VisualEffectPageState extends State<VisualEffectPage> {
  Window? _window;

  /// A plain red window behind this one, so that there is something to see
  /// through the material wherever the example happens to be on the desktop.
  Window? _backdrop;

  String _note = 'Pick an effect';

  @override
  void initState() {
    super.initState();
    final window = WindowManager.instance.getCurrent();
    if (window == null) return;
    _window = window;
    window.title = 'Visual effect';
    window.contentSize = const Size(560, 480);
    window.center();
    window.setContentUnderTitleBar(true);
    if (Platform.environment['VISUAL_EFFECT_AUTOPLAY'] == '1') {
      unawaited(_autoplay());
    }
  }

  /// Walks through the effects without being asked, over the backdrop, and
  /// says on the console when each one is on screen. This is how
  /// tools/gui/flutter_visual_effect_test.py in the workspace repository
  /// watches the example without touching the mouse.
  Future<void> _autoplay() async {
    const step = Duration(milliseconds: 2500);
    await Future<void>.delayed(const Duration(seconds: 4));
    _toggleBackdrop();
    debugPrint('STEP backdrop shown');
    for (final effect in [
      ...VisualEffect.values.where((e) => e != VisualEffect.none),
      VisualEffect.none,
    ]) {
      await Future<void>.delayed(step);
      if (!mounted) return;
      _apply(effect);
      debugPrint('STEP ${effect.name} ${_note.split(' ').first.toLowerCase()}');
    }
  }

  @override
  void dispose() {
    _backdrop?.dispose();
    super.dispose();
  }

  void _apply(VisualEffect effect) {
    final window = _window;
    if (window == null) return;
    final applied = window.setVisualEffect(effect);
    setState(() {
      _note = applied ? 'Applied ${effect.name}' : 'Refused ${effect.name}';
    });
  }

  void _toggleBackdrop() {
    final window = _window;
    if (window == null) return;
    final existing = _backdrop;
    if (existing != null) {
      window.setParentWindow(null);
      existing.hide();
      existing.dispose();
      setState(() => _backdrop = null);
      return;
    }
    final backdrop = Window.create();
    if (backdrop == null) return;
    final frame = window.bounds;
    backdrop.title = 'Backdrop';
    backdrop.backgroundColor = const Color(0xFFFF0000);
    backdrop.bounds = frame.inflate(80);
    backdrop.show();
    // A child stays above its parent, whichever of the two is brought forward.
    window.setParentWindow(backdrop);
    window.focus();
    setState(() => _backdrop = backdrop);
  }

  @override
  Widget build(BuildContext context) {
    final current = _window?.visualEffect ?? VisualEffect.none;
    final hasEffect = current != VisualEffect.none;
    // A material stands in for the window's background, so it shows only where this
    // app paints nothing: with no effect the window paints its own surface, with one
    // it paints only the panel and leaves the rest of the window bare. The controls
    // keep a panel of their own because a material takes its colour from whatever is
    // behind the window, which can be anything.
    return ColoredBox(
      color: hasEffect ? const Color(0x00000000) : _surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, _contentUnderTitleBar ? 46 : 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xE6FFFFFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Effect: ${current.name}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_note),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final effect in VisualEffect.values)
                          _Chip(
                            label: effect.name,
                            selected: effect == current,
                            enabled: Window.isVisualEffectSupported(effect),
                            onTap: () => _apply(effect),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _Chip(
                      label: _backdrop == null ? 'Show backdrop' : 'Hide backdrop',
                      selected: _backdrop != null,
                      enabled: true,
                      onTap: _toggleBackdrop,
                    ),
                    const SizedBox(height: 16),
                    const Text('Greyed out effects are not available here.'),
                  ],
                ),
              ),
            ),
            // Bare window below the panel: this is where the material shows.
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill = selected ? _accent : const Color(0xCCFFFFFF);
    final Color text = selected ? const Color(0xFFFFFFFF) : _ink;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x331B1B1F)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(label, style: TextStyle(color: text)),
          ),
        ),
      ),
    );
  }
}
