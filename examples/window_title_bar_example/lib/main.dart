import 'package:flutter/widgets.dart';
import 'package:nativeapi/nativeapi.dart';

void main() {
  runApp(const TitleBarApp());
}

const Color _ink = Color(0xFF1B1B1F);
const Color _muted = Color(0xFF6B6B76);
const Color _accent = Color(0xFF3F51B5);
const Color _surface = Color(0xFFF2F2F6);
const Color _panel = Color(0xFFFFFFFF);
const Color _line = Color(0x1A1B1B1F);

/// The strip this example draws where a title bar would be. It is always there,
/// whatever the title bar is doing, so that a window with no title bar and no
/// close button can still be moved and quit.
const double _stripHeight = 44;

/// How far the strip's own controls start from the left, so that they do not end
/// up under the macOS window buttons when those are on top of the content.
const double _buttonsInset = 78;

class TitleBarApp extends StatelessWidget {
  const TitleBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      debugShowCheckedModeBanner: false,
      color: _accent,
      textStyle: const TextStyle(color: _ink, fontSize: 13),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
      home: const TitleBarPage(),
    );
  }
}

class TitleBarPage extends StatefulWidget {
  const TitleBarPage({super.key});

  @override
  State<TitleBarPage> createState() => _TitleBarPageState();
}

class _TitleBarPageState extends State<TitleBarPage> {
  Window? _window;
  String _note = 'Try the three states and watch the strip below';

  @override
  void initState() {
    super.initState();
    final window = WindowManager.instance.getCurrent();
    if (window == null) return;
    _window = window;
    window.title = 'nativeapi · Title bar';
    window.minimumSize = const Size(520, 420);
    window.contentSize = const Size(620, 520);
    window.center();
  }

  void _act(String what, void Function(Window window) change) {
    final window = _window;
    if (window == null) return;
    change(window);
    setState(() => _note = what);
  }

  @override
  Widget build(BuildContext context) {
    final window = _window;
    final style = window?.titleBarStyle ?? TitleBarStyle.normal;
    final under = window?.isContentUnderTitleBar ?? false;
    final buttons = window?.isWindowControlButtonsVisible ?? false;
    final supported = Window.isContentUnderTitleBarSupported();
    final size = window?.contentSize ?? Size.zero;

    return ColoredBox(
      color: _surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Strip(
            underTitleBar: style == TitleBarStyle.normal && under,
            onQuit: () => Application.instance.quit(0),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Card(
                    title: 'Now',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Row('titleBarStyle', style.name),
                        _Row('isContentUnderTitleBar', '$under'),
                        _Row('isWindowControlButtonsVisible', '$buttons'),
                        _Row(
                          'isContentUnderTitleBarSupported()',
                          '$supported',
                        ),
                        _Row(
                          'contentSize',
                          '${size.width.round()} × ${size.height.round()}',
                        ),
                        const SizedBox(height: 8),
                        Text(_note, style: const TextStyle(color: _muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: 'The three states',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: 'Normal',
                          selected:
                              style == TitleBarStyle.normal && !under,
                          onTap: () => _act('Standard title bar', (w) {
                            w.setContentUnderTitleBar(false);
                            w.titleBarStyle = TitleBarStyle.normal;
                          }),
                        ),
                        _Chip(
                          label: 'Content under title bar',
                          enabled: supported,
                          selected:
                              style == TitleBarStyle.normal && under,
                          onTap: () => _act(
                            'The bar is a transparent overlay; its buttons stay',
                            (w) {
                              w.titleBarStyle = TitleBarStyle.normal;
                              w.setContentUnderTitleBar(true);
                            },
                          ),
                        ),
                        _Chip(
                          label: 'Hidden',
                          selected: style == TitleBarStyle.hidden,
                          onTap: () => _act(
                            'No title bar and no window buttons — move me by the strip',
                            (w) => w.titleBarStyle = TitleBarStyle.hidden,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: 'Window control buttons',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Setting a style resets these to what it implies, so '
                          'these override it and go after it.',
                          style: TextStyle(color: _muted),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(
                              label: 'Show buttons',
                              selected: buttons,
                              onTap: () => _act(
                                'Buttons shown',
                                (w) => w.isWindowControlButtonsVisible = true,
                              ),
                            ),
                            _Chip(
                              label: 'Hide buttons',
                              selected: !buttons,
                              onTap: () => _act(
                                'Buttons hidden',
                                (w) => w.isWindowControlButtonsVisible = false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _Card(
                    title: 'What to look for',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bullet(
                          'Hidden leaves no title bar and no window buttons on '
                          'every platform. Move the window by the strip above; '
                          'Quit ends the application (core has no '
                          'Window.close() yet).',
                        ),
                        _Bullet(
                          'Content under title bar keeps the bar and its '
                          'buttons but stops it drawing: the strip runs to the '
                          'top edge behind them. macOS only — elsewhere the '
                          'chip is greyed out and the call returns false.',
                        ),
                        _Bullet(
                          'Switching states keeps the window where it is and '
                          'the same size; only contentSize above changes, by '
                          'the height of the title bar.',
                        ),
                        _Bullet(
                          'Hidden also stops the system moving the window when '
                          'you drag the top of the content — that is what the '
                          'strip is for.',
                        ),
                        _Bullet(
                          'isContentUnderTitleBar stays as it was set while '
                          'Hidden is on: with no title bar there is nothing for '
                          'it to do, and it takes effect again on Normal.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The example's own title bar. Under a real title bar it is just a strip; with
/// the content under the title bar it runs up behind the window buttons, which
/// is why its controls start clear of them.
class _Strip extends StatelessWidget {
  const _Strip({required this.underTitleBar, required this.onQuit});

  final bool underTitleBar;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFE4E4EE),
          border: Border(bottom: BorderSide(color: _line)),
        ),
        child: SizedBox(
          height: _stripHeight,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              underTitleBar ? _buttonsInset : 16,
              0,
              10,
              0,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Drag this strip to move the window',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                _Chip(label: 'Quit', onTap: onQuit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.name, this.value);

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 240,
            child: Text(name, style: const TextStyle(color: _muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('·  ', style: TextStyle(color: _muted)),
          Expanded(child: Text(text, style: const TextStyle(color: _muted))),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? _accent : _panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? _accent : _line),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFFFFFFFF) : _ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
