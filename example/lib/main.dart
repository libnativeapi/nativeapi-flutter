import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

final nativeapi = NativeApi.instance;

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

  @override
  void initState() {
    super.initState();
    primaryDisplay = nativeapi.display.getPrimary();
    nativeapi.display.addListener(this);
    // allDisplays = nativeapi.display.getAll();
    allDisplays = [];
  }

  @override
  void dispose() {
    nativeapi.display.removeListener(this);
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
