// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:ui' show AppExitType;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:nativeapi/nativeapi.dart' as na;
import 'package:nativeapi/windowing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runWidget(const FloatingToolbarApp());
}

const Size _mainWindowSize = Size(720, 520);
const Size _toolbarSize = Size(380, 64);

/// How far the toolbar floats above the top edge of the main window.
const double _toolbarGap = 10;

const List<Color> _swatches = [
  Color(0xFF3F51B5),
  Color(0xFF009688),
  Color(0xFFFF9800),
  Color(0xFFE91E63),
];

/// What both windows show. They run in one isolate, so a plain [ChangeNotifier]
/// is all the "communication between windows" there is.
class ToolbarModel extends ChangeNotifier {
  Color color = _swatches.first;
  int stamps = 0;
  bool attached = true;
  bool toolbarVisible = true;
  final List<String> log = [];

  void pick(Color value) {
    color = value;
    notifyListeners();
  }

  void stamp() {
    stamps++;
    notifyListeners();
  }

  void note(String message) {
    debugPrint('[floating_toolbar] $message');
    log.insert(0, message);
    if (log.length > 40) log.removeLast();
    notifyListeners();
  }

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}

class _CloseDelegate with fw.WindowControllerDelegate {
  _CloseDelegate(this.onCloseRequested);

  final VoidCallback onCloseRequested;

  @override
  void onWindowCloseRequested(fw.WindowController controller) =>
      onCloseRequested();
}

class FloatingToolbarApp extends StatefulWidget {
  const FloatingToolbarApp({super.key});

  @override
  State<FloatingToolbarApp> createState() => _FloatingToolbarAppState();
}

class _FloatingToolbarAppState extends State<FloatingToolbarApp> {
  final _model = ToolbarModel();

  late final fw.WindowController _mainController = fw.WindowController(
    size: _mainWindowSize,
    constraints: const BoxConstraints(minWidth: 480, minHeight: 360),
    title: 'Floating toolbar',
    delegate: _CloseDelegate(_closeEverything),
  );

  late final fw.WindowController _toolbarController = fw.WindowController(
    size: _toolbarSize,
    title: 'Toolbar',
    // The toolbar has no close button; closing the main window closes it.
    delegate: _CloseDelegate(() {}),
  );

  na.Window? get _main => _mainController.nativeWindow;
  na.Window? get _toolbar => _toolbarController.nativeWindow;

  int? _listenerId;
  bool _closing = false;

  @override
  void initState() {
    super.initState();

    final main = _main;
    final area = na.DisplayManager.instance.getPrimary()?.workArea;
    if (main != null && area != null) {
      // Leave room above the window for the toolbar.
      main.position = Offset(
        area.left + (area.width - _mainWindowSize.width) / 2,
        area.top + 120,
      );
    }

    final toolbar = _toolbar;
    if (toolbar != null) {
      // Everything that makes a window a floating toolbar, from Dart.
      toolbar.titleBarStyle = na.TitleBarStyle.hidden;
      toolbar.isWindowControlButtonsVisible = false;
      toolbar.backgroundColor = const Color(0x00000000);
      toolbar.hasShadow = false;
      toolbar.isResizable = false;
      toolbar.isMovable = false;
      toolbar.isVisibleInTaskbar = false;
      // Hiding the title bar keeps the frame; give the content its size back.
      toolbar.contentSize = _toolbarSize;
      _attach();
    }

    _listenerId = na.WindowManager.instance.addListener(_onWindowEvent);
  }

  void _attach() {
    final ok = _toolbar?.setParentWindow(_main) ?? false;
    if (ok) _placeToolbar();
    _model.update(() => _model.attached = ok);
    _model.note(
      ok ? 'Toolbar attached to the main window' : 'setParentWindow failed',
    );
  }

  void _detach() {
    _toolbar?.setParentWindow(null);
    _model.update(() => _model.attached = false);
    _model.note('Toolbar detached: it no longer follows');
  }

  /// Centres the toolbar above the main window.
  ///
  /// On macOS a child window already moves with its parent; elsewhere this is
  /// what makes it follow. It also keeps the toolbar centred when the main
  /// window is resized, which no platform does by itself.
  void _placeToolbar() {
    final main = _main;
    final toolbar = _toolbar;
    if (main == null || toolbar == null) return;
    final frame = main.bounds;
    final size = toolbar.bounds.size;
    toolbar.position = Offset(
      frame.left + (frame.width - size.width) / 2,
      frame.top - size.height - _toolbarGap,
    );
  }

  void _onWindowEvent(na.WindowEvent event) {
    if (_closing) return;
    final mainId = _main?.id;
    final toolbarId = _toolbar?.id;
    final name = event.windowId == mainId
        ? 'main'
        : event.windowId == toolbarId
        ? 'toolbar'
        : '#${event.windowId}';
    switch (event) {
      case na.WindowMovedEvent() || na.WindowResizedEvent():
        if (event.windowId == mainId && _model.attached) _placeToolbar();
      case na.WindowCreatedEvent():
        _model.note('created: $name');
      case na.WindowClosedEvent():
        _model.note('closed: $name');
      case na.WindowMinimizedEvent():
        _model.note('minimized: $name');
      case na.WindowRestoredEvent():
        _model.note('restored: $name');
        if (event.windowId == mainId && _model.attached) _placeToolbar();
      default:
        break;
    }
  }

  void _setToolbarVisible(bool visible) {
    final toolbar = _toolbar;
    if (toolbar == null) return;
    if (visible) {
      if (_model.attached) _placeToolbar();
      toolbar.showInactive();
    } else {
      toolbar.hide();
    }
    _model.update(() => _model.toolbarVisible = visible);
    _model.note(visible ? 'Toolbar shown' : 'Toolbar hidden');
  }

  /// Children first, then the parent: what closing a parent does to its
  /// children differs between platforms, closing them yourself does not.
  void _closeEverything() {
    if (_closing) return;
    _closing = true;
    final listenerId = _listenerId;
    if (listenerId != null) {
      na.WindowManager.instance.removeListener(listenerId);
    }
    _toolbar?.setParentWindow(null);
    setState(() {});
    // Destroy only once the frame that removes the views has been built.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _toolbarController.destroy();
      _mainController.destroy();
      ServicesBinding.instance.exitApplication(AppExitType.required);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_closing) return const ViewCollection(views: []);
    return ViewCollection(
      views: [
        fw.Window(
          controller: _mainController,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(colorSchemeSeed: Colors.indigo),
            home: MainPage(
              model: _model,
              onAttach: _attach,
              onDetach: _detach,
              onToolbarVisible: _setToolbarVisible,
            ),
          ),
        ),
        fw.Window(
          controller: _toolbarController,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorSchemeSeed: Colors.indigo,
              brightness: Brightness.dark,
            ),
            // Nothing opaque between the pill and the desktop.
            color: const Color(0x00000000),
            home: ToolbarPage(model: _model),
          ),
        ),
      ],
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({
    super.key,
    required this.model,
    required this.onAttach,
    required this.onDetach,
    required this.onToolbarVisible,
  });

  final ToolbarModel model;
  final VoidCallback onAttach;
  final VoidCallback onDetach;
  final ValueChanged<bool> onToolbarVisible;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Floating toolbar')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The pill above this window is a second Flutter window: '
                'transparent, frameless, and a child of this one. Move, resize '
                'or minimize this window and it comes along.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: model.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Stamps: ${model.stamps}',
                    key: const ValueKey('stamps'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: model.attached ? onDetach : onAttach,
                    child: Text(
                      model.attached ? 'Detach toolbar' : 'Attach toolbar',
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => onToolbarVisible(!model.toolbarVisible),
                    child: Text(
                      model.toolbarVisible ? 'Hide toolbar' : 'Show toolbar',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Log', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Expanded(
                child: ListView(
                  children: [
                    for (final line in model.log)
                      Text(line, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ToolbarPage extends StatelessWidget {
  const ToolbarPage({super.key, required this.model});

  final ToolbarModel model;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0x00000000),
        body: Center(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xF0202124),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final swatch in _swatches)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => model.pick(swatch),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: swatch,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: model.color == swatch
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: model.stamp,
                  icon: const Icon(Icons.approval, size: 18),
                  label: const Text('Stamp'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
