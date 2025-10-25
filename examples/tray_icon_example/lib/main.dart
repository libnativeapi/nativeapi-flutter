import 'package:flutter/material.dart' hide Image;
import 'package:nativeapi/nativeapi.dart';

class TrayIconData {
  final int id;
  final TrayIcon trayIcon;
  final Menu contextMenu;
  int clickCount;
  int rightClickCount;
  int doubleClickCount;
  bool isVisible;
  String title;
  String tooltip;

  TrayIconData({
    required this.id,
    required this.trayIcon,
    required this.contextMenu,
    this.clickCount = 0,
    this.rightClickCount = 0,
    this.doubleClickCount = 0,
    this.isVisible = true,
    this.title = 'Tray Icon',
    this.tooltip = 'Click me!',
  });

  void dispose() {
    trayIcon.dispose();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tray Icon Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TrayIconExamplePage(),
    );
  }
}

class TrayIconExamplePage extends StatefulWidget {
  const TrayIconExamplePage({super.key});

  @override
  State<TrayIconExamplePage> createState() => _TrayIconExamplePageState();
}

class _TrayIconExamplePageState extends State<TrayIconExamplePage> {
  final List<TrayIconData> _trayIcons = [];
  String _status = 'No tray icons created';
  int _nextIconId = 1;

  @override
  void initState() {
    super.initState();
    _addTrayIcon();
  }

  @override
  void dispose() {
    for (final trayIconData in _trayIcons) {
      trayIconData.dispose();
    }
    super.dispose();
  }

  void _addTrayIcon() {
    try {
      final trayIcon = TrayIcon();

      final icon = Image.fromAsset('images/tray_icon.png');
      if (icon != null) {
        trayIcon.icon = icon;
      }

      final contextMenu = _createContextMenu(trayIcon);

      final trayIconData = TrayIconData(
        id: _nextIconId++,
        trayIcon: trayIcon,
        contextMenu: contextMenu,
        title: 'Tray Icon $_nextIconId',
        tooltip: 'Click me! ($_nextIconId)',
      );

      // Set up event listeners
      trayIcon.on<TrayIconClickedEvent>((event) {
        setState(() {
          trayIconData.clickCount++;
          _status =
              'Tray icon ${trayIconData.id} clicked (${trayIconData.clickCount} times)';
        });
      });

      trayIcon.on<TrayIconRightClickedEvent>((event) {
        setState(() {
          trayIconData.rightClickCount++;
          _status =
              'Tray icon ${trayIconData.id} right clicked (${trayIconData.rightClickCount} times)';
        });
      });

      trayIcon.on<TrayIconDoubleClickedEvent>((event) {
        setState(() {
          trayIconData.doubleClickCount++;
          _status =
              'Tray icon ${trayIconData.id} double clicked (${trayIconData.doubleClickCount} times)';
        });
      });

      // Set initial properties
      trayIcon.title = trayIconData.title;
      trayIcon.tooltip = trayIconData.tooltip;
      trayIcon.isVisible = trayIconData.isVisible;

      _trayIcons.add(trayIconData);

      setState(() {
        _status = 'Tray icon ${trayIconData.id} created successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error creating tray icon: $e';
      });
    }
  }

  Menu _createContextMenu(TrayIcon trayIcon) {
    final contextMenu = Menu();

    // Add menu items
    final showItem = MenuItem('Show Window');
    final hideItem = MenuItem('Hide Window');
    final separatorItem = MenuItem('', MenuItemType.separator);
    final aboutItem = MenuItem('About');
    final quitItem = MenuItem('Quit');

    // Add event listeners for menu items
    showItem.on<MenuItemClickedEvent>((event) {
      setState(() {
        _status = 'Show Window clicked for tray icon ${trayIcon.id}';
      });
    });

    hideItem.on<MenuItemClickedEvent>((event) {
      setState(() {
        _status = 'Hide Window clicked for tray icon ${trayIcon.id}';
      });
    });

    aboutItem.on<MenuItemClickedEvent>((event) {
      setState(() {
        _status = 'About clicked for tray icon ${trayIcon.id}';
      });
      _showAboutDialog();
    });

    quitItem.on<MenuItemClickedEvent>((event) {
      setState(() {
        _status = 'Quit clicked for tray icon ${trayIcon.id}';
      });
      // In a real app, you would close the application here
    });

    // Add items to menu
    contextMenu.addItem(showItem);
    contextMenu.addItem(hideItem);
    contextMenu.addItem(separatorItem);
    contextMenu.addItem(aboutItem);
    contextMenu.addItem(quitItem);

    // Set the context menu
    trayIcon.contextMenu = contextMenu;

    return contextMenu;
  }

  void _removeTrayIcon(int id) {
    final index = _trayIcons.indexWhere(
      (trayIconData) => trayIconData.id == id,
    );
    if (index != -1) {
      final trayIconData = _trayIcons.removeAt(index);
      trayIconData.dispose();
      setState(() {
        _status = 'Tray icon $id removed';
      });
    }
  }

  void _removeAllTrayIcons() {
    for (final trayIconData in _trayIcons) {
      trayIconData.dispose();
    }
    _trayIcons.clear();
    setState(() {
      _status = 'All tray icons removed';
    });
  }

  void _updateTrayIconTitle(int id, String title) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.trayIcon.title = title;
    trayIconData.title = title;
    setState(() {
      _status = 'Title updated for tray icon $id: $title';
    });
  }

  void _updateTrayIconTooltip(int id, String tooltip) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.trayIcon.tooltip = tooltip;
    trayIconData.tooltip = tooltip;
    setState(() {
      _status = 'Tooltip updated for tray icon $id: $tooltip';
    });
  }

  void _toggleTrayIconVisibility(int id) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.isVisible = !trayIconData.isVisible;
    trayIconData.trayIcon.isVisible = trayIconData.isVisible;
    setState(() {
      _status =
          'Visibility changed for tray icon $id: ${trayIconData.isVisible ? "visible" : "hidden"}';
    });
  }

  void _openTrayIconContextMenu(int id) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.trayIcon.openContextMenu();
    setState(() {
      _status = 'Context menu opened for tray icon $id';
    });
  }

  void _resetTrayIconCounters(int id) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.clickCount = 0;
    trayIconData.rightClickCount = 0;
    trayIconData.doubleClickCount = 0;
    setState(() {
      _status = 'Counters reset for tray icon $id';
    });
  }

  void _resetAllCounters() {
    for (final trayIconData in _trayIcons) {
      trayIconData.clickCount = 0;
      trayIconData.rightClickCount = 0;
      trayIconData.doubleClickCount = 0;
    }
    setState(() {
      _status = 'All counters reset';
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Tray Icon Example'),
        content: const Text(
          'This is a comprehensive example of the TrayIcon functionality '
          'from the nativeapi package. It demonstrates:\n\n'
          '• Creating and managing multiple tray icons\n'
          '• Context menus with multiple items\n'
          '• Event handling for clicks\n'
          '• Dynamic property updates\n'
          '• Visibility control\n'
          '• Individual icon management',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple Tray Icons Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(_status),
                        const SizedBox(height: 16),
                        Text(
                          'Total Tray Icons: ${_trayIcons.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Global controls section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Global Controls',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),

                        // Action buttons
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _addTrayIcon,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Tray Icon'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _trayIcons.isNotEmpty
                                  ? _removeAllTrayIcons
                                  : null,
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Remove All'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _trayIcons.isNotEmpty
                                  ? _resetAllCounters
                                  : null,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset All Counters'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Individual tray icons section
            Expanded(
              child: _trayIcons.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tray icons created yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Click "Add Tray Icon" to create your first tray icon',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _trayIcons.length,
                      itemBuilder: (context, index) {
                        final trayIconData = _trayIcons[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Tray Icon ${trayIconData.id}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () =>
                                          _removeTrayIcon(trayIconData.id),
                                      icon: const Icon(Icons.delete),
                                      tooltip: 'Remove this tray icon',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Click counters
                                Text(
                                  'Click Counters',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCounterCard(
                                        'Left',
                                        trayIconData.clickCount,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCounterCard(
                                        'Right',
                                        trayIconData.rightClickCount,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCounterCard(
                                        'Double',
                                        trayIconData.doubleClickCount,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Controls for this tray icon
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: TextEditingController(
                                    text: trayIconData.title,
                                  ),
                                  onChanged: (value) => _updateTrayIconTitle(
                                    trayIconData.id,
                                    value,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Tooltip',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: TextEditingController(
                                    text: trayIconData.tooltip,
                                  ),
                                  onChanged: (value) => _updateTrayIconTooltip(
                                    trayIconData.id,
                                    value,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Action buttons for this tray icon
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _toggleTrayIconVisibility(
                                            trayIconData.id,
                                          ),
                                      icon: Icon(
                                        trayIconData.isVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      label: Text(
                                        trayIconData.isVisible
                                            ? 'Hide'
                                            : 'Show',
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _openTrayIconContextMenu(
                                        trayIconData.id,
                                      ),
                                      icon: const Icon(Icons.menu),
                                      label: const Text('Open Menu'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _resetTrayIconCounters(
                                        trayIconData.id,
                                      ),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Reset'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterCard(String label, int count) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
