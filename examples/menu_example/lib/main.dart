import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menu Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MenuExamplePage(),
    );
  }
}

class MenuExamplePage extends StatefulWidget {
  const MenuExamplePage({super.key});

  @override
  State<MenuExamplePage> createState() => _MenuExamplePageState();
}

class _MenuExamplePageState extends State<MenuExamplePage>
    with TickerProviderStateMixin {
  late final Menu _contextMenu;
  late final AnimationController _rotationController;

  String _lastAction = 'No action yet';
  List<String> _actionHistory = [];

  @override
  void initState() {
    super.initState();
    _setupMenus();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  void _setupMenus() {
    // 设置上下文菜单
    _contextMenu = Menu();
    _contextMenu.addCallbackListener<MenuOpenedEvent>((event) {
      _addToHistory('Context menu opened');
    });
    _contextMenu.addCallbackListener<MenuClosedEvent>((event) {
      _addToHistory('Context menu closed');
    });

    // Normal menu item
    final normalItem = MenuItem('Normal Menu Item');
    normalItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Normal menu item clicked');
    });
    _contextMenu.addItem(normalItem);

    // Separator
    _contextMenu.addSeparator();

    // More menu items
    final item2 = MenuItem('Menu Item 2');
    item2.on<MenuItemClickedEvent>((event) {
      _addToHistory('Menu item 2 clicked');
    });
    _contextMenu.addItem(item2);

    final item3 = MenuItem('Menu Item 3');
    item3.on<MenuItemClickedEvent>((event) {
      _addToHistory('Menu item 3 clicked');
    });
    _contextMenu.addItem(item3);

    // Separator
    _contextMenu.addSeparator();

    // Menu item with icon
    final iconItem = MenuItem('Menu Item with Icon');
    // iconItem.icon = 'assets/icon.png'; // If icon resource is available
    iconItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Menu item with icon clicked');
    });
    _contextMenu.addItem(iconItem);

    // Menu item with tooltip
    final tooltipItem = MenuItem('Menu Item with Tooltip');
    tooltipItem.tooltip = 'This is a tooltip message';
    tooltipItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Menu item with tooltip clicked');
    });
    _contextMenu.addItem(tooltipItem);
  }

  void _addToHistory(String action) {
    setState(() {
      _lastAction = action;
      _actionHistory.insert(
        0,
        '${DateTime.now().toString().substring(11, 19)}: $action',
      );
      if (_actionHistory.length > 10) {
        _actionHistory.removeLast();
      }
    });
  }

  void _showMenuAtPosition(Offset position) {
    _contextMenu.open(PositioningStrategy.absolute(position));
  }

  void _clearHistory() {
    setState(() {
      _actionHistory.clear();
      _lastAction = 'History cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearHistory,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题和说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Native Menu Demo',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Right-click on the area below or use buttons to show native menus. The menu contains normal menu items, separators, menu items with icons, and menu items with tooltips.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 菜单区域
            Expanded(
              child: Row(
                children: [
                  // 左侧：菜单演示区域
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Text(
                          'Menu Demo Area',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ContextMenuRegion(
                            menu: _contextMenu,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                border: Border.all(color: Colors.blue.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.menu,
                                      size: 48,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Right-click here\nor use buttons below',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 旋转的正方形
                        Center(
                          child: RotationTransition(
                            turns: _rotationController,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade300,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.square,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _showMenuAtPosition(const Offset(200, 200)),
                                icon: const Icon(Icons.menu),
                                label: const Text('Show Menu'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _showMenuAtPosition(const Offset(400, 300)),
                                icon: const Icon(Icons.menu_open),
                                label: const Text('Show Menu (Position 2)'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 右侧：状态和历史
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Text(
                          'Current State',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Menu Items: ${_contextMenu.itemCount}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Divider(),
                                Text(
                                  'Last Action:',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                Text(
                                  _lastAction,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Action History',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Card(
                            child: ListView.builder(
                              itemCount: _actionHistory.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 4.0,
                                  ),
                                  child: Text(
                                    _actionHistory[index],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contextMenu.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}
