import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

final displayManager = DisplayManager.instance;
final windowManager = WindowManager.instance;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with DisplayListener {
  late Display primaryDisplay;
  List<Display> allDisplays = [];

  Size currentWindowSize = Size(0, 0);

  @override
  void initState() {
    super.initState();
    primaryDisplay = displayManager.getPrimary();
    displayManager.addListener(this);
    // allDisplays = nativeapi.display.getAll();
    allDisplays = [];
  }

  @override
  void dispose() {
    displayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onDisplayAdded(Display display) {
    print('>>>>> added $display');
    setState(() {
      allDisplays.add(display);
    });
  }

  @override
  void onDisplayRemoved(Display display) {
    print('>>>>> removed $display');
    setState(() {
      allDisplays.remove(display);
    });
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native API'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                spacerSmall,
                Text(
                  'primaryDisplay = ${primaryDisplay.id} ${primaryDisplay.name} ${primaryDisplay.size} ${primaryDisplay.scaleFactor}',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'allDisplays',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                for (var display in allDisplays)
                  Text(
                    '${display.id} ${display.name} ${display.size} ${display.scaleFactor}',
                    style: textStyle,
                    textAlign: TextAlign.center,
                  ),
                TextButton(
                  onPressed: () {
                    final currentWindow = windowManager.getCurrent();

                    String log = '';

                    log += 'size = ${currentWindow.getSize()}\n';
                    log += 'position = ${currentWindow.getPosition()}\n';
                    log += 'title = ${currentWindow.getTitle()}\n';
                    log += 'is focused = ${currentWindow.isFocused()}\n';
                    log += 'is visible = ${currentWindow.isVisible()}\n';
                    log += 'is always on top = ${currentWindow.isAlwaysOnTop()}\n';
                    log += 'is full screen = ${currentWindow.isFullScreen()}\n';
                    log += 'is minimized = ${currentWindow.isMinimized()}\n';
                    log += 'is maximized = ${currentWindow.isMaximized()}\n';

                    print(log);

                    setState(() {
                      currentWindowSize = currentWindow.getSize();
                    });
                  },
                  child: const Text('Get Current Window'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      currentWindowSize = Size(0, 0);
                    });
                  },
                  child: const Text('Clear Current Window Size'),
                ),
                TextButton(
                  onPressed: () {
                    final allWindows = windowManager.getAll();
                    print('allWindows = $allWindows');
                  },
                  child: const Text('Get All Windows'),
                ),
                Text(
                  'currentWindowSize = $currentWindowSize',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
