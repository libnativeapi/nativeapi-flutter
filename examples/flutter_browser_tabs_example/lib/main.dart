// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:ui' show AppExitType;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:nativeapi_flutter/nativeapi_flutter.dart' as na;

import 'src/browser_window.dart';
import 'src/tabs_controller.dart';

void main() {
  // The stable channel does not offer `flutter config --enable-windowing`,
  // so turn the experimental windowing API on before the binding starts.
  isWindowingEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();
  runWidget(const BrowserTabsApp());
}

final ThemeData _theme = ThemeData(
  colorSchemeSeed: Colors.blueGrey,
  useMaterial3: true,
  visualDensity: VisualDensity.compact,
);

class BrowserTabsApp extends StatefulWidget {
  const BrowserTabsApp({super.key});

  @override
  State<BrowserTabsApp> createState() => _BrowserTabsAppState();
}

class _BrowserTabsAppState extends State<BrowserTabsApp> {
  late final TabsController _controller = TabsController(
    onLastWindowClosed: () =>
        ServicesBinding.instance.exitApplication(AppExitType.required),
  );

  @override
  void initState() {
    super.initState();
    final first = _controller.openWindow([
      for (var i = 0; i < 4; i++) _controller.createTab(),
    ]);
    final second = _controller.openWindow([
      for (var i = 0; i < 2; i++) _controller.createTab(),
    ]);
    _placeSideBySide([first, second]);
  }

  void _placeSideBySide(List<BrowserWindow> windows) {
    final area = na.DisplayManager.instance.getPrimary()?.workArea.toRect();
    if (area == null) return;
    for (var i = 0; i < windows.length; i++) {
      final native = windows[i].nativeWindow;
      if (native == null) continue;
      final width = native.bounds.width;
      final step = ((area.width - width) / (windows.length - 1)).clamp(
        0.0,
        width + 24,
      );
      final left =
          area.left +
          (area.width - width - step * (windows.length - 1)) / 2 +
          step * i;
      native.position = Offset(left, area.top + 80 + 60.0 * i).toNative();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabsScope(
      controller: _controller,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => ViewCollection(
          views: [
            for (final window in _controller.windows)
              fw.RegularWindow(
                key: ObjectKey(window.controller),
                controller: window.controller,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: _theme,
                  home: BrowserWindowPage(window: window),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
