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
  final List<String> _eventHistory = [];
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

  void _addToHistory(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _eventHistory.insert(0, '[$timestamp] $message');
      if (_eventHistory.length > 50) {
        _eventHistory.removeLast();
      }
    });
  }

  void _clearHistory() {
    setState(() {
      _eventHistory.clear();
    });
    _addToHistory('Event history cleared');
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
        title: 'Tray Icon ${_nextIconId - 1}',
        tooltip: 'Click me! (${_nextIconId - 1})',
      );

      // Set up event listeners
      trayIcon.on<TrayIconClickedEvent>((event) {
        setState(() {
          trayIconData.clickCount++;
        });
        _addToHistory('Tray icon ${trayIconData.id} clicked (${trayIconData.clickCount} times)');
      });

      trayIcon.on<TrayIconRightClickedEvent>((event) {
        setState(() {
          trayIconData.rightClickCount++;
        });
        _addToHistory('Tray icon ${trayIconData.id} right clicked (${trayIconData.rightClickCount} times)');
      });

      trayIcon.on<TrayIconDoubleClickedEvent>((event) {
        setState(() {
          trayIconData.doubleClickCount++;
        });
        _addToHistory('Tray icon ${trayIconData.id} double clicked (${trayIconData.doubleClickCount} times)');
      });

      // Set initial properties
      trayIcon.title = trayIconData.title;
      trayIcon.tooltip = trayIconData.tooltip;
      trayIcon.isVisible = trayIconData.isVisible;

      _trayIcons.add(trayIconData);

      _addToHistory('Tray icon ${trayIconData.id} created successfully');
    } catch (e) {
      _addToHistory('Error creating tray icon: $e');
    }
  }

  Menu _createContextMenu(TrayIcon trayIcon) {
    final contextMenu = Menu();

    // Listen to menu events
    contextMenu.addCallbackListener<MenuOpenedEvent>((event) {
      _addToHistory('Context menu opened for tray icon ${trayIcon.id}');
    });
    contextMenu.addCallbackListener<MenuClosedEvent>((event) {
      _addToHistory('Context menu closed for tray icon ${trayIcon.id}');
    });

    // Add menu items
    final showItem = MenuItem('Show Window');
    final hideItem = MenuItem('Hide Window');
    final separatorItem = MenuItem('', MenuItemType.separator);
    final toggleItem = MenuItem('Toggle Visibility');
    final separatorItem2 = MenuItem('', MenuItemType.separator);
    final aboutItem = MenuItem('About');
    final quitItem = MenuItem('Quit');

    // Add event listeners for menu items
    showItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Show Window clicked for tray icon ${trayIcon.id}');
    });

    hideItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Hide Window clicked for tray icon ${trayIcon.id}');
    });

    toggleItem.on<MenuItemClickedEvent>((event) {
      final trayIconData = _trayIcons.firstWhere(
        (data) => data.trayIcon.id == trayIcon.id,
        orElse: () => throw Exception('Tray icon not found'),
      );
      _toggleTrayIconVisibility(trayIconData.id);
    });

    aboutItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('About clicked for tray icon ${trayIcon.id}');
      _showAboutDialog();
    });

    quitItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Quit clicked for tray icon ${trayIcon.id}');
      // In a real app, you would close the application here
    });

    // Add items to menu
    contextMenu.addItem(showItem);
    contextMenu.addItem(hideItem);
    contextMenu.addItem(separatorItem);
    contextMenu.addItem(toggleItem);
    contextMenu.addItem(separatorItem2);
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
      _addToHistory('Tray icon $id removed');
    }
  }

  void _removeAllTrayIcons() {
    for (final trayIconData in _trayIcons) {
      trayIconData.dispose();
    }
    _trayIcons.clear();
    _addToHistory('All tray icons removed');
  }

  void _updateTrayIconTitle(int id, String title) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.trayIcon.title = title;
    trayIconData.title = title;
    _addToHistory('Title updated for tray icon $id: $title');
  }

  void _updateTrayIconTooltip(int id, String tooltip) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.trayIcon.tooltip = tooltip;
    trayIconData.tooltip = tooltip;
    _addToHistory('Tooltip updated for tray icon $id: $tooltip');
  }

  void _toggleTrayIconVisibility(int id) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.isVisible = !trayIconData.isVisible;
    trayIconData.trayIcon.isVisible = trayIconData.isVisible;
    _addToHistory('Visibility changed for tray icon $id: ${trayIconData.isVisible ? "visible" : "hidden"}');
  }

  void _openTrayIconContextMenu(int id) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.trayIcon.openContextMenu();
    _addToHistory('Context menu opened for tray icon $id');
  }

  void _resetTrayIconCounters(int id) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.clickCount = 0;
    trayIconData.rightClickCount = 0;
    trayIconData.doubleClickCount = 0;
    _addToHistory('Counters reset for tray icon $id');
  }

  void _resetAllCounters() {
    for (final trayIconData in _trayIcons) {
      trayIconData.clickCount = 0;
      trayIconData.rightClickCount = 0;
      trayIconData.doubleClickCount = 0;
    }
    _addToHistory('All counters reset');
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
        title: const Text('Tray Icon Example - Comprehensive Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearHistory,
            tooltip: 'Clear Event History',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side - Test controls
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tray Icon Overview Section
                  _buildSectionCard('Tray Icon Overview', [
                    Row(
                      children: [
                        Expanded(child: _buildInfoRow('Total Icons', '${_trayIcons.length}')),
                        Expanded(child: _buildInfoRow('Total Clicks', '${_trayIcons.fold(0, (sum, data) => sum + data.clickCount)}')),
                        Expanded(child: _buildInfoRow('Active', '${_trayIcons.where((data) => data.isVisible).length}')),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),
                  
                  // Global Controls Section
                  _buildSectionCard('Global Controls', [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactButton(Icons.add, 'Add Icon', _addTrayIcon),
                        _buildCompactButton(Icons.clear_all, 'Remove All', _removeAllTrayIcons),
                        _buildCompactButton(Icons.refresh, 'Reset Counters', _resetAllCounters),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),
                  
                  // Individual Tray Icons Section
                  if (_trayIcons.isEmpty)
                    _buildSectionCard('Tray Icons', [
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.touch_app, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'No tray icons created yet',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Click "Add Icon" to create your first tray icon',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ])
                  else
                    ...(_trayIcons.map((trayIconData) => _buildTrayIconCard(trayIconData))),
                  
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Right side - Event history
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(left: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Event History (${_eventHistory.length})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _eventHistory.isEmpty
                        ? const Center(
                            child: Text(
                              'No events yet\nInteract with tray icons to see events',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _eventHistory.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  _eventHistory[index],
                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton(IconData icon, String label, VoidCallback onPressed) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
      ),
    );
  }

  Widget _buildTrayIconCard(TrayIconData trayIconData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Tray Icon ${trayIconData.id}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trayIconData.isVisible ? Colors.green.shade50 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trayIconData.isVisible ? 'Visible' : 'Hidden',
                    style: TextStyle(
                      fontSize: 10,
                      color: trayIconData.isVisible ? Colors.green.shade700 : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeTrayIcon(trayIconData.id),
                  icon: const Icon(Icons.delete, size: 18),
                  tooltip: 'Remove this tray icon',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Click counters
            Row(
              children: [
                Expanded(
                  child: _buildCounterCard('Left', trayIconData.clickCount),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCounterCard('Right', trayIconData.rightClickCount),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCounterCard('Double', trayIconData.doubleClickCount),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Controls
            TextField(
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              controller: TextEditingController(text: trayIconData.title),
              onChanged: (value) => _updateTrayIconTitle(trayIconData.id, value),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tooltip',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              controller: TextEditingController(text: trayIconData.tooltip),
              onChanged: (value) => _updateTrayIconTooltip(trayIconData.id, value),
            ),
            const SizedBox(height: 12),
            
            // Action buttons
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildCompactButton(
                  trayIconData.isVisible ? Icons.visibility_off : Icons.visibility,
                  trayIconData.isVisible ? 'Hide' : 'Show',
                  () => _toggleTrayIconVisibility(trayIconData.id),
                ),
                _buildCompactButton(
                  Icons.menu,
                  'Open Menu',
                  () => _openTrayIconContextMenu(trayIconData.id),
                ),
                _buildCompactButton(
                  Icons.refresh,
                  'Reset',
                  () => _resetTrayIconCounters(trayIconData.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterCard(String label, int count) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.blue),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
