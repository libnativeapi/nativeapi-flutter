// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:nativeapi/nativeapi.dart';

void main() {
  Display? primaryDisplay = DisplayManager.instance.getPrimary();
  WindowManager.instance.setWillShowHook((windowId) {
    Window? window = WindowManager.instance.getById(windowId);
    if (window != null && primaryDisplay != null) {
      switch (window.title) {
        case 'Primary Window':
          // Top row, centered, full width (60% of work area)
          _positionPrimaryWindow(window, primaryDisplay);
          break;
        case 'Secondary Window':
          // Bottom left (half of 60% of work area)
          _positionSecondaryWindow(window, primaryDisplay);
          break;
        case 'Tertiary Window':
          // Bottom right (half of 60% of work area)
          _positionTertiaryWindow(window, primaryDisplay);
          break;
      }
    }
    return true;
  });
  WindowManager.instance.setWillHideHook((windowId) {
    print('[Dart] will hide hook $windowId');
    return true;
  });
  runWidget(
    ViewCollection(
      views: [TertiaryWindow(), SecondaryWindow(), PrimaryWindow()],
    ),
  );
}

void _positionPrimaryWindow(Window window, Display display) {
  final workArea = display.workArea;

  // Calculate 60% of work area dimensions
  final totalWidth = workArea.width * 0.6;
  final totalHeight = workArea.height * 0.6;

  // Calculate starting position to center the layout
  final startX = workArea.left + (workArea.width - totalWidth) / 2;
  final startY = workArea.top + (workArea.height - totalHeight) / 2;

  // Top row height: 50% of total height
  final topRowHeight = totalHeight * 0.5;

  // Top row, centered, full width
  window.setSize(totalWidth, topRowHeight);
  window.setPosition(startX, startY);
}

void _positionSecondaryWindow(Window window, Display display) {
  final workArea = display.workArea;

  // Calculate 60% of work area dimensions
  final totalWidth = workArea.width * 0.6;
  final totalHeight = workArea.height * 0.6;

  // Calculate starting position to center the layout
  final startX = workArea.left + (workArea.width - totalWidth) / 2;
  final startY = workArea.top + (workArea.height - totalHeight) / 2;

  // Top row height: 50% of total height
  final topRowHeight = totalHeight * 0.5;
  // Bottom row height: 50% of total height
  final bottomRowHeight = totalHeight * 0.5;

  // Bottom row: two windows side by side, each takes 50% width
  final bottomWindowWidth = totalWidth * 0.5;

  // Bottom left
  window.setSize(bottomWindowWidth, bottomRowHeight);
  window.setPosition(startX, startY + topRowHeight);
}

void _positionTertiaryWindow(Window window, Display display) {
  final workArea = display.workArea;

  // Calculate 60% of work area dimensions
  final totalWidth = workArea.width * 0.6;
  final totalHeight = workArea.height * 0.6;

  // Calculate starting position to center the layout
  final startX = workArea.left + (workArea.width - totalWidth) / 2;
  final startY = workArea.top + (workArea.height - totalHeight) / 2;

  // Top row height: 50% of total height
  final topRowHeight = totalHeight * 0.5;
  // Bottom row height: 50% of total height
  final bottomRowHeight = totalHeight * 0.5;

  // Bottom row: two windows side by side, each takes 50% width
  final bottomWindowWidth = totalWidth * 0.5;

  // Bottom right
  window.setSize(bottomWindowWidth, bottomRowHeight);
  window.setPosition(startX + bottomWindowWidth, startY + topRowHeight);
}

class PrimaryWindow extends StatefulWidget {
  const PrimaryWindow({super.key});

  @override
  State<PrimaryWindow> createState() => _PrimaryWindowState();
}

class _PrimaryWindowState extends State<PrimaryWindow> {
  final _windowController = RegularWindowController(
    preferredSize: const Size(800, 600),
    title: 'Primary Window',
  );

  @override
  Widget build(BuildContext context) {
    return RegularWindow(
      controller: _windowController,
      child: MaterialApp(
        title: 'Primary Window',
        home: Scaffold(
          appBar: AppBar(title: const Text('Primary Window')),
          body: Center(
            child: Column(
              children: [
                FilledButton(
                  onPressed: () {
                    Window? primaryWindow;
                    final windows = WindowManager.instance.getAll();
                    for (var window in windows) {
                      if (window.title == 'Primary Window') {
                        primaryWindow = window;
                        break;
                      }
                    }
                    if (primaryWindow != null) {
                      primaryWindow.setSize(1000, 1000);
                      primaryWindow.show();
                    }
                  },
                  child: const Text('A Window'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryWindow extends StatefulWidget {
  const SecondaryWindow({super.key});

  @override
  State<SecondaryWindow> createState() => _SecondaryWindowState();
}

class _SecondaryWindowState extends State<SecondaryWindow> {
  final _windowController = RegularWindowController(
    preferredSize: const Size(800, 600),
    title: 'Secondary Window',
  );

  @override
  Widget build(BuildContext context) {
    return RegularWindow(
      controller: _windowController,
      child: MaterialApp(
        title: 'Secondary Window',
        home: Scaffold(
          appBar: AppBar(title: const Text('Secondary Window')),
          body: const Center(child: Text('Secondary Window')),
        ),
      ),
    );
  }
}

class TertiaryWindow extends StatefulWidget {
  const TertiaryWindow({super.key});

  @override
  State<TertiaryWindow> createState() => _TertiaryWindowState();
}

class _TertiaryWindowState extends State<TertiaryWindow> {
  final _windowController = RegularWindowController(
    preferredSize: const Size(800, 600),
    title: 'Tertiary Window',
  );

  @override
  Widget build(BuildContext context) {
    return RegularWindow(
      controller: _windowController,
      child: MaterialApp(
        title: 'Tertiary Window',
        home: Scaffold(
          appBar: AppBar(title: const Text('Tertiary Window')),
          body: const Center(child: Text('Tertiary Window')),
        ),
      ),
    );
  }
}
