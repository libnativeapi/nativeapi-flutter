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

class _MyAppState extends State<MyApp> {
  late Display primaryDisplay;
  late List<Display> allDisplays;

  @override
  void initState() {
    super.initState();
    primaryDisplay = nativeapi.display.getPrimary();
    // allDisplays = nativeapi.display.getAll();
    allDisplays = [];
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
                  'allDisplays = $allDisplays',
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
