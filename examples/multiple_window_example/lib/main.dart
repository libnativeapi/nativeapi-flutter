// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:nativeapi/nativeapi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiple Window Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ViewCollection(views: [SecondaryWindow(), PrimaryWindow()]),
    );
  }
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
      child: Scaffold(
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
      child: Scaffold(
        appBar: AppBar(title: const Text('Secondary Window')),
        body: const Center(child: Text('Secondary Window')),
      ),
    );
  }
}
