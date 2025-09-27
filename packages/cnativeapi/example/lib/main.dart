import 'package:flutter/material.dart' hide KeyboardListener;
import 'package:cnativeapi/cnativeapi.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    native_display_list_t displayList =
                        cnativeApiBindings.native_display_manager_get_all();

                    for (int i = 0; i < displayList.count; i++) {
                      print('Display ${i + 1}');
                    }
                  },
                  child: const Text('All Displays'),
                ),
                spacerSmall,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
