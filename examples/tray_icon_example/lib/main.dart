import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:nativeapi/nativeapi.dart';
import 'animated_icon_generator.dart';

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
  ContextMenuTrigger contextMenuTrigger;
  AnimatedIconGenerator? animatedIconGenerator;

  TrayIconData({
    required this.id,
    required this.trayIcon,
    required this.contextMenu,
    this.clickCount = 0,
    this.rightClickCount = 0,
    this.doubleClickCount = 0,
    this.isVisible = true,
    this.title = '',
    this.tooltip = '',
    this.contextMenuTrigger = ContextMenuTrigger.none,
  });

  void dispose() {
    animatedIconGenerator?.dispose();
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
    // _addTrayIcon(); // Don't add tray icon on initialization
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
      final trayIcon = TrayIcon.create()!;

      final icon = ImageAsset.fromAsset('images/tray_icon.png');
      if (icon != null) {
        trayIcon.icon = icon;
      }

      final contextMenu = _createContextMenu(trayIcon);

      final trayIconData = TrayIconData(
        id: _nextIconId++,
        trayIcon: trayIcon,
        contextMenu: contextMenu,
        // title and tooltip are empty by default
      );

      // Create animated icon generator
      trayIconData.animatedIconGenerator = AnimatedIconGenerator(
        size: 32,
        foregroundColor: Colors.blue,
      );

      // Set up event listeners
      trayIcon.addListener((event) {
      if (event is! TrayIconClickedEvent) return;
        setState(() {
          trayIconData.clickCount++;
        });
        _addToHistory(
          'Tray icon ${trayIconData.id} clicked (${trayIconData.clickCount} times)',
        );
      });

      trayIcon.addListener((event) {
      if (event is! TrayIconRightClickedEvent) return;
        setState(() {
          trayIconData.rightClickCount++;
        });
        _addToHistory(
          'Tray icon ${trayIconData.id} right clicked (${trayIconData.rightClickCount} times)',
        );
      });

      trayIcon.addListener((event) {
      if (event is! TrayIconDoubleClickedEvent) return;
        setState(() {
          trayIconData.doubleClickCount++;
        });
        _addToHistory(
          'Tray icon ${trayIconData.id} double clicked (${trayIconData.doubleClickCount} times)',
        );
      });

      // Set initial properties
      // trayIcon.setTitle(trayIconData.title); // Set via UI
      // trayIcon.setTooltip(trayIconData.tooltip); // Set via UI
      trayIcon.setVisible(trayIconData.isVisible);
      trayIcon.setContextMenuTrigger(trayIconData.contextMenuTrigger);

      _trayIcons.add(trayIconData);

      _addToHistory('Tray icon ${trayIconData.id} created successfully');
    } catch (e) {
      _addToHistory('Error creating tray icon: $e');
    }
  }

  Menu _createContextMenu(TrayIcon trayIcon) {
    final contextMenu = Menu.create()!;

    // Listen to menu events
    contextMenu.addListener((event) {
      if (event is! MenuOpenedEvent) return;
      _addToHistory('Context menu opened for tray icon ${trayIcon.getId()}');
    });
    contextMenu.addListener((event) {
      if (event is! MenuClosedEvent) return;
      _addToHistory('Context menu closed for tray icon ${trayIcon.getId()}');
    });

    // Add menu items
    final showItem = MenuItem.createWithLabelAndType('Show Window', MenuItemType.normal)!;
    final hideItem = MenuItem.createWithLabelAndType('Hide Window', MenuItemType.normal)!;
    final separatorItem = MenuItem.createWithLabelAndType('', MenuItemType.separator)!;
    final toggleItem = MenuItem.createWithLabelAndType('Toggle Visibility', MenuItemType.normal)!;
    final separatorItem2 = MenuItem.createWithLabelAndType('', MenuItemType.separator)!;

    // Create submenu
    final submenuMenu = Menu.create()!;
    final submenuItem1 = MenuItem.createWithLabelAndType('Submenu Item 1', MenuItemType.normal)!;
    final submenuItem2 = MenuItem.createWithLabelAndType('Submenu Item 2', MenuItemType.normal)!;
    final submenuItem3 = MenuItem.createWithLabelAndType('Submenu Item 3', MenuItemType.normal)!;

    // Add submenu items
    submenuMenu.addItem(submenuItem1);
    submenuMenu.addItem(submenuItem2);
    submenuMenu.addItem(submenuItem3);

    // Create submenu menu item
    final submenuMenuItem = MenuItem.createWithLabelAndType('More Options', MenuItemType.submenu)!;
    submenuMenuItem.submenu = submenuMenu;

    // Listen to submenu open/close events
    submenuMenuItem.addListener((event) {
      if (event is! MenuItemSubmenuOpenedEvent) return;
      _addToHistory('Submenu opened for tray icon ${trayIcon.getId()}');
    });

    submenuMenuItem.addListener((event) {
      if (event is! MenuItemSubmenuClosedEvent) return;
      _addToHistory('Submenu closed for tray icon ${trayIcon.getId()}');
    });

    // Add event listeners for submenu items
    submenuItem1.addListener((event) {
      if (event is! MenuItemClickedEvent) return;
      _addToHistory('Submenu Item 1 clicked for tray icon ${trayIcon.getId()}');
    });

    submenuItem2.addListener((event) {
      if (event is! MenuItemClickedEvent) return;
      _addToHistory('Submenu Item 2 clicked for tray icon ${trayIcon.getId()}');
    });

    submenuItem3.addListener((event) {
      if (event is! MenuItemClickedEvent) return;
      _addToHistory('Submenu Item 3 clicked for tray icon ${trayIcon.getId()}');
    });

    final separatorItem3 = MenuItem.createWithLabelAndType('', MenuItemType.separator)!;
    final aboutItem = MenuItem.createWithLabelAndType('About', MenuItemType.normal)!;
    final quitItem = MenuItem.createWithLabelAndType('Quit', MenuItemType.normal)!;

    // Add event listeners for menu items
    showItem.addListener((event) {
      if (event is! MenuItemClickedEvent) return;
      _addToHistory('Show Window clicked for tray icon ${trayIcon.getId()}');
    });

    hideItem.addListener((event) {
      if (event is! MenuItemClickedEvent) return;
      _addToHistory('Hide Window clicked for tray icon ${trayIcon.getId()}');
    });

    toggleItem.addListener((event) {
      if (event is! MenuItemClickedEvent) return;
      final trayIconData = _trayIcons.firstWhere(
        (data) => data.trayIcon.getId() == trayIcon.getId(),
        orElse: () => throw Exception('Tray icon not found'),
      );
      _toggleTrayIconVisibility(trayIconData.id);
    });

    aboutItem.addListener((event) {
      if (event is! MenuItemClickedEvent) return;
      _addToHistory('About clicked for tray icon ${trayIcon.getId()}');
      _showAboutDialog();
    });

    quitItem.addListener((event) {
      if (event is! MenuItemClickedEvent) return;
      _addToHistory('Quit clicked for tray icon ${trayIcon.getId()}');
      // In a real app, you would close the application here
    });

    // Add items to menu
    contextMenu.addItem(showItem);
    contextMenu.addItem(hideItem);
    contextMenu.addItem(separatorItem);
    contextMenu.addItem(toggleItem);
    contextMenu.addItem(separatorItem2);
    contextMenu.addItem(submenuMenuItem);
    contextMenu.addItem(separatorItem3);
    contextMenu.addItem(aboutItem);
    contextMenu.addItem(quitItem);

    // Set the context menu
    trayIcon.setContextMenu(contextMenu);

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
    trayIconData.trayIcon.setTitle(title);
    trayIconData.title = title;
    _addToHistory('Title updated for tray icon $id: $title');
  }

  void _updateTrayIconTooltip(int id, String tooltip) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.trayIcon.setTooltip(tooltip);
    trayIconData.tooltip = tooltip;
    _addToHistory('Tooltip updated for tray icon $id: $tooltip');
  }

  void _updateTrayIconContextMenuTrigger(int id, ContextMenuTrigger trigger) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.trayIcon.setContextMenuTrigger(trigger);
    trayIconData.contextMenuTrigger = trigger;
    final triggerName = _getTriggerName(trigger);
    _addToHistory(
      'Context menu trigger updated for tray icon $id: $triggerName',
    );
  }

  String _getTriggerName(ContextMenuTrigger trigger) {
    switch (trigger) {
      case ContextMenuTrigger.none:
        return 'None (Manual)';
      case ContextMenuTrigger.clicked:
        return 'Left Click';
      case ContextMenuTrigger.rightClicked:
        return 'Right Click';
      case ContextMenuTrigger.doubleClicked:
        return 'Double Click';
    }
  }

  void _toggleTrayIconVisibility(int id) {
    final trayIconData = _trayIcons.firstWhere(
      (trayIconData) => trayIconData.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );
    trayIconData.isVisible = !trayIconData.isVisible;
    trayIconData.trayIcon.setVisible(trayIconData.isVisible);
    _addToHistory(
      'Visibility changed for tray icon $id: ${trayIconData.isVisible ? "visible" : "hidden"}',
    );
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

  /// Convert a Flutter Icon widget to a base64 image
  Future<Image?> _iconToImage(
    IconData iconData, {
    double size = 24.0,
    Color color = Colors.black,
  }) async {
    try {
      // Create a picture recorder to draw the icon
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Create a text painter to render the icon
      final textPainter = TextPainter(textDirection: TextDirection.ltr);

      textPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: color,
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset.zero);

      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return null;
      }

      // Convert to base64
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final base64String = 'data:image/png;base64,${base64Encode(pngBytes)}';

      // Use base64 to create nativeapi Image
      return Image.fromBase64(base64String);
    } catch (e) {
      _addToHistory('Error converting icon to image: $e');
      return null;
    }
  }

  // Animated icon methods
  Future<void> _startSpinnerAnimation(int id) async {
    final trayIconData = _trayIcons.firstWhere(
      (data) => data.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );

    await trayIconData.animatedIconGenerator?.startSpinner(
      onFrame: (image) async {
        trayIconData.trayIcon.icon = image;
      },
    );
    _addToHistory('Started spinner animation for tray icon $id');
  }

  Future<void> _startPulseAnimation(int id) async {
    final trayIconData = _trayIcons.firstWhere(
      (data) => data.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );

    await trayIconData.animatedIconGenerator?.startPulse(
      onFrame: (image) async {
        trayIconData.trayIcon.icon = image;
      },
    );
    _addToHistory('Started pulse animation for tray icon $id');
  }

  Future<void> _startBlinkAnimation(int id) async {
    final trayIconData = _trayIcons.firstWhere(
      (data) => data.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );

    await trayIconData.animatedIconGenerator?.startBlink(
      onFrame: (image) async {
        trayIconData.trayIcon.icon = image;
      },
    );
    _addToHistory('Started blink animation for tray icon $id');
  }

  Future<void> _startProgressAnimation(int id) async {
    final trayIconData = _trayIcons.firstWhere(
      (data) => data.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );

    await trayIconData.animatedIconGenerator?.startProgress(
      onFrame: (image) async {
        trayIconData.trayIcon.icon = image;
      },
    );
    _addToHistory('Started progress animation for tray icon $id');
  }

  Future<void> _startWaveAnimation(int id) async {
    final trayIconData = _trayIcons.firstWhere(
      (data) => data.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );

    await trayIconData.animatedIconGenerator?.startWave(
      onFrame: (image) async {
        trayIconData.trayIcon.icon = image;
      },
    );
    _addToHistory('Started wave animation for tray icon $id');
  }

  Future<void> _startRotatingSquareAnimation(int id) async {
    final trayIconData = _trayIcons.firstWhere(
      (data) => data.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );

    await trayIconData.animatedIconGenerator?.startRotatingSquare(
      onFrame: (image) async {
        trayIconData.trayIcon.icon = image;
      },
    );
    _addToHistory('Started rotating square animation for tray icon $id');
  }

  void _stopAnimation(int id) {
    final trayIconData = _trayIcons.firstWhere(
      (data) => data.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );

    trayIconData.animatedIconGenerator?.stop();
    _addToHistory('Stopped animation for tray icon $id');
  }

  Future<void> _setIconFromWidget(int id) async {
    final trayIconData = _trayIcons.firstWhere(
      (data) => data.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );

    _addToHistory('Converting Flutter Icon to image for tray icon $id...');

    // Convert Material Icons.star to image
    final iconFromWidget = await _iconToImage(
      Icons.star,
      size: 32.0,
      color: Colors.amber,
    );

    if (iconFromWidget != null) {
      trayIconData.trayIcon.icon = iconFromWidget;
      _addToHistory('Icon from widget set on tray icon $id');
    } else {
      _addToHistory('Failed to convert icon from widget');
    }
  }

  void _setAssetIcon(int id) {
    final trayIconData = _trayIcons.firstWhere(
      (data) => data.id == id,
      orElse: () => throw Exception('Tray icon not found'),
    );

    final icon = ImageAsset.fromAsset('images/tray_icon.png');
    if (icon != null) {
      trayIconData.trayIcon.icon = icon;
      _addToHistory('Asset icon set on tray icon $id');
    } else {
      _addToHistory('Asset icon not found');
    }
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
                        Expanded(
                          child: _buildInfoRow(
                            'Total Icons',
                            '${_trayIcons.length}',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoRow(
                            'Total Clicks',
                            '${_trayIcons.fold(0, (sum, data) => sum + data.clickCount)}',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoRow(
                            'Active',
                            '${_trayIcons.where((data) => data.isVisible).length}',
                          ),
                        ),
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
                        _buildCompactButton(
                          Icons.add,
                          'Add Icon',
                          _addTrayIcon,
                        ),
                        _buildCompactButton(
                          Icons.clear_all,
                          'Remove All',
                          _removeAllTrayIcons,
                        ),
                        _buildCompactButton(
                          Icons.refresh,
                          'Reset Counters',
                          _resetAllCounters,
                        ),
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
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Click "Add Icon" to create your first tray icon',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ])
                  else
                    ...(_trayIcons.map(
                      (trayIconData) => _buildTrayIconCard(trayIconData),
                    )),

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
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Event History (${_eventHistory.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _eventHistory.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Text(
                                  _eventHistory[index],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
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
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

  Widget _buildCompactButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trayIconData.isVisible
                        ? Colors.green.shade50
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trayIconData.isVisible ? 'Visible' : 'Hidden',
                    style: TextStyle(
                      fontSize: 10,
                      color: trayIconData.isVisible
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
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
                  child: _buildCounterCard(
                    'Right',
                    trayIconData.rightClickCount,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCounterCard(
                    'Double',
                    trayIconData.doubleClickCount,
                  ),
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              controller: TextEditingController(text: trayIconData.title),
              onChanged: (value) =>
                  _updateTrayIconTitle(trayIconData.id, value),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tooltip',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              controller: TextEditingController(text: trayIconData.tooltip),
              onChanged: (value) =>
                  _updateTrayIconTooltip(trayIconData.id, value),
            ),
            const SizedBox(height: 12),

            // Context Menu Trigger Section
            const Text(
              'Context Menu Trigger',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<ContextMenuTrigger>(
                value: trayIconData.contextMenuTrigger,
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                    value: ContextMenuTrigger.none,
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app, size: 16),
                        const SizedBox(width: 8),
                        const Text('None (Manual)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ContextMenuTrigger.clicked,
                    child: Row(
                      children: [
                        const Icon(Icons.mouse, size: 16),
                        const SizedBox(width: 8),
                        const Text('Left Click'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ContextMenuTrigger.rightClicked,
                    child: Row(
                      children: [
                        const Icon(Icons.mouse_outlined, size: 16),
                        const SizedBox(width: 8),
                        const Text('Right Click'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ContextMenuTrigger.doubleClicked,
                    child: Row(
                      children: [
                        const Icon(Icons.double_arrow, size: 16),
                        const SizedBox(width: 8),
                        const Text('Double Click'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateTrayIconContextMenuTrigger(trayIconData.id, value);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // Icon Management Section
            const Text(
              'Icon Management',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildCompactButton(
                  Icons.image,
                  'Asset',
                  () => _setAssetIcon(trayIconData.id),
                ),
                _buildCompactButton(
                  Icons.star,
                  'Widget',
                  () => _setIconFromWidget(trayIconData.id),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Animated Icons Section
            const Text(
              'Animated Icons',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildCompactButton(
                  Icons.refresh,
                  'Spinner',
                  () => _startSpinnerAnimation(trayIconData.id),
                ),
                _buildCompactButton(
                  Icons.circle,
                  'Pulse',
                  () => _startPulseAnimation(trayIconData.id),
                ),
                _buildCompactButton(
                  Icons.radio_button_unchecked,
                  'Blink',
                  () => _startBlinkAnimation(trayIconData.id),
                ),
                _buildCompactButton(
                  Icons.trending_up,
                  'Progress',
                  () => _startProgressAnimation(trayIconData.id),
                ),
                _buildCompactButton(
                  Icons.music_note,
                  'Wave',
                  () => _startWaveAnimation(trayIconData.id),
                ),
                _buildCompactButton(
                  Icons.crop_square,
                  'Rotate',
                  () => _startRotatingSquareAnimation(trayIconData.id),
                ),
                _buildCompactButton(
                  Icons.stop,
                  'Stop',
                  () => _stopAnimation(trayIconData.id),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildCompactButton(
                  trayIconData.isVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
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
