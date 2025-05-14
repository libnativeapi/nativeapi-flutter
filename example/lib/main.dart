import 'package:flutter/material.dart' hide KeyboardListener;
import 'package:nativeapi/nativeapi.dart';

final accessibilityManager = AccessibilityManager.instance;
final broadcastCenter = BroadcastCenter.instance;
final displayManager = DisplayManager.instance;
final trayManager = TrayManager.instance;
final windowManager = WindowManager.instance;
final keyboardMonitor = KeyboardMonitor.instance;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with DisplayListener, BroadcastReceiver, KeyboardListener {
  late Display primaryDisplay;
  List<Display> allDisplays = [];

  Size currentWindowSize = Size(0, 0);

  @override
  void initState() {
    super.initState();
    primaryDisplay = displayManager.getPrimary();
    displayManager.addListener(this);
    broadcastCenter.registerReceiver('com.example.myNotification', this);
    keyboardMonitor.addListener(this);
    // allDisplays = nativeapi.display.getAll();
    allDisplays = [];
  }

  @override
  void dispose() {
    displayManager.removeListener(this);
    broadcastCenter.unregisterReceiver('com.example.myNotification', this);
    keyboardMonitor.removeListener(this);
    super.dispose();
  }

  @override
  void onBroadcastReceived(String topic, String message) {
    print('>>>>> received $topic -> $message');
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
  void onKeyPressed(int keyCode) {
    print('>>>>> keyPressed $keyCode');
  }

  @override
  void onKeyReleased(int keyCode) {
    print('>>>>> keyReleased $keyCode');
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
                TextButton(
                  onPressed: () {
                    final windows = windowManager.getAll();
                    print(
                        'windows = ${windows.length}, ${windows.map((e) => e.id).join(',')}');

                    final firstWindow = windows.first;
                    firstWindow.setSize(Size(100, 100), animate: true);
                  },
                  child: const Text('All Windows'),
                ),
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
                    bool isEnabled = accessibilityManager.isEnabled();
                    if (!isEnabled) {
                      accessibilityManager.enable();
                    }
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Accessibility'),
                        content: Text('isEnabled = $isEnabled'),
                      ),
                    );
                  },
                  child: const Text('Enable Accessibility'),
                ),
                TextButton(
                  onPressed: () {
                    keyboardMonitor.start();
                  },
                  child: const Text('Start Keyboard Monitor'),
                ),
                TextButton(
                  onPressed: () {
                    keyboardMonitor.stop();
                  },
                  child: const Text('Stop Keyboard Monitor'),
                ),
                TextButton(
                  onPressed: () {
                    final currentWindow = windowManager.getCurrent();
                    currentWindow.setSize(Size(100, 100), animate: true);
                  },
                  child: const Text('Set size'),
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
                    log +=
                        'is always on top = ${currentWindow.isAlwaysOnTop()}\n';
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
                ToggleButtons(
                  isSelected: [false, false],
                  onPressed: (index) {
                    final currentWindow = windowManager.getCurrent();
                    if (index == 0) {
                      currentWindow.setOpacity(0.5);
                    } else {
                      currentWindow.setOpacity(1.0);
                    }
                  },
                  children: const [
                    Text('Set Opacity'),
                    Text('Clear Opacity'),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    final currentWindow = windowManager.getCurrent();
                    currentWindow.setPosition(Offset(100, 100));
                  },
                  child: const Text('Set Current Window Position'),
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
                TextButton(
                  onPressed: () {
                    final tray = trayManager.create();
                    print('tray = $tray');
                    tray.setTitle('Hello World');
                    tray.setIcon('assets/icon.png');
                    tray.setTooltip('This is a tooltip');
                  },
                  child: const Text('Create Tray'),
                ),
                TextButton(
                  onPressed: () {
                    broadcastCenter.sendBroadcast(
                      'com.example.myNotification',
                      'Hello World, from Dart!',
                    );
                  },
                  child: const Text('Send Broadcast'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
