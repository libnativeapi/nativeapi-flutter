import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:nativeapi/nativeapi.dart';
import 'animated_icon_generator.dart';

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

class _MenuExamplePageState extends State<MenuExamplePage> {
  late final Menu _contextMenu;
  late final Menu _positioningMenu;

  final List<MenuItem> _menuItems = [];
  final List<String> _eventHistory = [];

  bool _checkboxState = false;
  String _radioSelection = 'Option 1';
  String _currentLabel = 'Dynamic Label Item';
  Placement _selectedPlacement = Placement.bottomStart;

  int _menuItemCount = 0;

  // Store references to menu items for state management
  late final MenuItem _checkboxItem;
  late final MenuItem _radio1;
  late final MenuItem _radio2;
  late final MenuItem _radio3;
  late final MenuItem _submenuItem;
  late final Menu _submenu;

  // Store icon for demonstration
  Image? _testIcon;
  Image? _iconFromWidget;

  // Animated icon generator
  AnimatedIconGenerator? _animatedIconGenerator;
  MenuItem? _animatedMenuItem;

  @override
  void initState() {
    super.initState();
    _loadTestIcon();
    _setupContextMenu();
    _setupPositioningMenu();
    _setupAnimatedIconGenerator();
  }

  void _setupAnimatedIconGenerator() {
    _animatedIconGenerator = AnimatedIconGenerator(
      size: 32, // Higher resolution for better quality
      foregroundColor: Colors.blue,
    );
  }

  void _loadTestIcon() {
    // Try to load a test icon from assets
    _testIcon = Image.fromAsset('images/flutter_logo.png');
    if (_testIcon != null) {
      _addToHistory('Test icon loaded successfully');
    } else {
      _addToHistory('Test icon not found, icon features will be limited');
    }
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

  void _setupContextMenu() {
    _contextMenu = Menu();

    // Listen to menu events
    _contextMenu.addCallbackListener<MenuOpenedEvent>((event) {
      _addToHistory('Menu opened (ID: ${event.menuId})');
    });
    _contextMenu.addCallbackListener<MenuClosedEvent>((event) {
      _addToHistory('Menu closed (ID: ${event.menuId})');
    });

    // 1. Normal menu item
    final normalItem = MenuItem('Normal Menu Item', MenuItemType.normal);
    normalItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Normal item clicked (ID: ${event.menuItemId})');
    });
    _contextMenu.addItem(normalItem);
    _menuItems.add(normalItem);

    // 2. Separator
    _contextMenu.addSeparator();

    // 3. Checkbox menu item
    _checkboxItem = MenuItem('Checkbox Item', MenuItemType.checkbox);
    _checkboxItem.state = MenuItemState.unchecked;
    _checkboxItem.on<MenuItemClickedEvent>((event) {
      setState(() {
        _checkboxState = !_checkboxState;
        _checkboxItem.state = _checkboxState
            ? MenuItemState.checked
            : MenuItemState.unchecked;
      });
      _addToHistory(
        'Checkbox clicked - State: $_checkboxState (ID: ${event.menuItemId})',
      );
    });
    _contextMenu.addItem(_checkboxItem);
    _menuItems.add(_checkboxItem);

    // 4. Radio menu items (grouped together)
    _radio1 = MenuItem('Radio Option 1', MenuItemType.radio);
    _radio1.radioGroup = 1; // Set radio group ID
    _radio1.state = MenuItemState.checked; // Default selection
    _radio1.on<MenuItemClickedEvent>((event) {
      setState(() {
        _radioSelection = 'Option 1';
        _radio1.state = MenuItemState.checked;
        _radio2.state = MenuItemState.unchecked;
        _radio3.state = MenuItemState.unchecked;
      });
      _addToHistory('Radio Option 1 selected (ID: ${event.menuItemId})');
    });
    _contextMenu.addItem(_radio1);
    _menuItems.add(_radio1);

    _radio2 = MenuItem('Radio Option 2', MenuItemType.radio);
    _radio2.radioGroup = 1; // Same radio group
    _radio2.state = MenuItemState.unchecked;
    _radio2.on<MenuItemClickedEvent>((event) {
      setState(() {
        _radioSelection = 'Option 2';
        _radio1.state = MenuItemState.unchecked;
        _radio2.state = MenuItemState.checked;
        _radio3.state = MenuItemState.unchecked;
      });
      _addToHistory('Radio Option 2 selected (ID: ${event.menuItemId})');
    });
    _contextMenu.addItem(_radio2);
    _menuItems.add(_radio2);

    _radio3 = MenuItem('Radio Option 3', MenuItemType.radio);
    _radio3.radioGroup = 1; // Same radio group
    _radio3.state = MenuItemState.unchecked;
    _radio3.on<MenuItemClickedEvent>((event) {
      setState(() {
        _radioSelection = 'Option 3';
        _radio1.state = MenuItemState.unchecked;
        _radio2.state = MenuItemState.unchecked;
        _radio3.state = MenuItemState.checked;
      });
      _addToHistory('Radio Option 3 selected (ID: ${event.menuItemId})');
    });
    _contextMenu.addItem(_radio3);
    _menuItems.add(_radio3);

    // 5. Separator
    _contextMenu.addSeparator();

    // 6. Menu item with dynamic label
    final dynamicLabelItem = MenuItem(_currentLabel);
    dynamicLabelItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Dynamic label item clicked (ID: ${event.menuItemId})');
    });
    _contextMenu.addItem(dynamicLabelItem);
    _menuItems.add(dynamicLabelItem);

    // 7. Menu item with tooltip
    final tooltipItem = MenuItem('Item with Tooltip');
    tooltipItem.tooltip = 'This is a helpful tooltip message';
    tooltipItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Tooltip item clicked (ID: ${event.menuItemId})');
    });
    _contextMenu.addItem(tooltipItem);
    _menuItems.add(tooltipItem);

    // 8. Separator
    _contextMenu.addSeparator();

    // 9. Submenu
    _submenu = Menu();
    _submenuItem = MenuItem('Submenu', MenuItemType.submenu);

    _submenuItem.on<MenuItemSubmenuOpenedEvent>((event) {
      _addToHistory('Submenu opened (ID: ${event.menuItemId})');
    });
    _submenuItem.on<MenuItemSubmenuClosedEvent>((event) {
      _addToHistory('Submenu closed (ID: ${event.menuItemId})');
    });

    // Add items to submenu
    final subItem1 = MenuItem('Submenu Item 1');
    subItem1.on<MenuItemClickedEvent>((event) {
      _addToHistory('Submenu Item 1 clicked (ID: ${event.menuItemId})');
    });
    _submenu.addItem(subItem1);

    final subItem2 = MenuItem('Submenu Item 2');
    subItem2.on<MenuItemClickedEvent>((event) {
      _addToHistory('Submenu Item 2 clicked (ID: ${event.menuItemId})');
    });
    _submenu.addItem(subItem2);

    _submenu.addSeparator();

    final subItem3 = MenuItem('Submenu Item 3');
    subItem3.on<MenuItemClickedEvent>((event) {
      _addToHistory('Submenu Item 3 clicked (ID: ${event.menuItemId})');
    });
    _submenu.addItem(subItem3);

    // Associate the submenu with the menu item
    _submenuItem.submenu = _submenu;

    _contextMenu.addItem(_submenuItem);
    _menuItems.add(_submenuItem);

    // 10. Separator
    _contextMenu.addSeparator();

    // 11. Menu items with special characters
    final specialCharsItem = MenuItem('Special: 中文 日本語 🎉 @#\$%');
    specialCharsItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Special chars item clicked (ID: ${event.menuItemId})');
    });
    _contextMenu.addItem(specialCharsItem);
    _menuItems.add(specialCharsItem);

    _updateMenuItemCount();
  }

  void _setupPositioningMenu() {
    _positioningMenu = Menu();

    _positioningMenu.addCallbackListener<MenuOpenedEvent>((event) {
      _addToHistory('Positioning menu opened');
    });
    _positioningMenu.addCallbackListener<MenuClosedEvent>((event) {
      _addToHistory('Positioning menu closed');
    });

    final item1 = MenuItem('Positioning Menu Item 1');
    item1.on<MenuItemClickedEvent>((event) {
      _addToHistory('Positioning menu item 1 clicked');
    });
    _positioningMenu.addItem(item1);

    final item2 = MenuItem('Positioning Menu Item 2');
    item2.on<MenuItemClickedEvent>((event) {
      _addToHistory('Positioning menu item 2 clicked');
    });
    _positioningMenu.addItem(item2);
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

  void _updateMenuItemCount() {
    setState(() {
      _menuItemCount = _contextMenu.itemCount;
    });
  }

  void _changeDynamicLabel() {
    setState(() {
      _currentLabel =
          'Updated at ${DateTime.now().toString().substring(11, 19)}';
      if (_menuItems.length > 5) {
        _menuItems[5].label = _currentLabel;
      }
    });
    _addToHistory('Menu item label changed to: $_currentLabel');
  }

  void _setCheckboxMixed() {
    setState(() {
      _checkboxItem.state = MenuItemState.mixed;
    });
    _addToHistory('Checkbox state set to Mixed (indeterminate)');
  }

  void _addSubmenuItem() {
    final newSubItem = MenuItem(
      'Dynamic Submenu Item ${_submenu.itemCount + 1}',
    );
    newSubItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Dynamic submenu item clicked (ID: ${event.menuItemId})');
    });
    _submenu.addItem(newSubItem);
    _addToHistory('Added new item to submenu (Total: ${_submenu.itemCount})');
  }

  void _toggleSubmenu() {
    setState(() {
      if (_submenuItem.submenu != null) {
        _submenuItem.submenu = null;
        _addToHistory('Submenu detached from menu item');
      } else {
        _submenuItem.submenu = _submenu;
        _addToHistory('Submenu attached to menu item');
      }
    });
  }

  void _addNewMenuItem() {
    final newItem = MenuItem('New Item ${_menuItems.length + 1}');
    newItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('New item ${_menuItems.length} clicked');
    });
    _contextMenu.addItem(newItem);
    _menuItems.add(newItem);
    _updateMenuItemCount();
    _addToHistory('Added new menu item');
  }

  void _insertMenuItemAtPosition() {
    final insertItem = MenuItem('Inserted Item');
    insertItem.on<MenuItemClickedEvent>((event) {
      _addToHistory('Inserted item clicked');
    });
    _contextMenu.insertItem(2, insertItem);
    _menuItems.insert(2, insertItem);
    _updateMenuItemCount();
    _addToHistory('Inserted menu item at position 2');
  }

  void _insertSeparatorAtPosition() {
    _contextMenu.insertSeparator(3);
    _updateMenuItemCount();
    _addToHistory('Inserted separator at position 3');
  }

  void _setIconOnFirstItem() {
    if (_menuItems.isEmpty) {
      _addToHistory('No menu items available to set icon');
      return;
    }

    if (_testIcon != null) {
      _menuItems[0].icon = _testIcon;
      _addToHistory('Icon set on first menu item');
    } else {
      _addToHistory('No icon available to set');
    }
  }

  void _removeIconFromFirstItem() {
    if (_menuItems.isEmpty) {
      _addToHistory('No menu items available to remove icon from');
      return;
    }

    _menuItems[0].icon = null;
    _addToHistory('Icon removed from first menu item');
  }

  // Animated icon methods
  Future<void> _startSpinnerAnimation() async {
    if (_menuItems.isEmpty) {
      _addToHistory('No menu items available for animation');
      return;
    }

    _animatedMenuItem = _menuItems[0];
    await _animatedIconGenerator?.startSpinner(
      onFrame: (image) async {
        _animatedMenuItem?.icon = image;
      },
    );
    _addToHistory('Started spinner animation');
  }

  Future<void> _startPulseAnimation() async {
    if (_menuItems.isEmpty) {
      _addToHistory('No menu items available for animation');
      return;
    }

    _animatedMenuItem = _menuItems[0];
    await _animatedIconGenerator?.startPulse(
      onFrame: (image) async {
        _animatedMenuItem?.icon = image;
      },
    );
    _addToHistory('Started pulse animation');
  }

  Future<void> _startBlinkAnimation() async {
    if (_menuItems.isEmpty) {
      _addToHistory('No menu items available for animation');
      return;
    }

    _animatedMenuItem = _menuItems[0];
    await _animatedIconGenerator?.startBlink(
      onFrame: (image) async {
        _animatedMenuItem?.icon = image;
      },
    );
    _addToHistory('Started blink animation');
  }

  Future<void> _startProgressAnimation() async {
    if (_menuItems.isEmpty) {
      _addToHistory('No menu items available for animation');
      return;
    }

    _animatedMenuItem = _menuItems[0];
    await _animatedIconGenerator?.startProgress(
      onFrame: (image) async {
        _animatedMenuItem?.icon = image;
      },
    );
    _addToHistory('Started progress animation');
  }

  Future<void> _startWaveAnimation() async {
    if (_menuItems.isEmpty) {
      _addToHistory('No menu items available for animation');
      return;
    }

    _animatedMenuItem = _menuItems[0];
    await _animatedIconGenerator?.startWave(
      onFrame: (image) async {
        _animatedMenuItem?.icon = image;
      },
    );
    _addToHistory('Started wave animation');
  }

  Future<void> _startRotatingSquareAnimation() async {
    if (_menuItems.isEmpty) {
      _addToHistory('No menu items available for animation');
      return;
    }

    _animatedMenuItem = _menuItems[0];
    await _animatedIconGenerator?.startRotatingSquare(
      onFrame: (image) async {
        _animatedMenuItem?.icon = image;
      },
    );
    _addToHistory('Started rotating square animation');
  }

  void _stopAnimation() {
    _animatedIconGenerator?.stop();
    _addToHistory('Stopped animation');
  }

  Future<void> _setIconFromWidget() async {
    if (_menuItems.isEmpty) {
      _addToHistory('No menu items available to set icon');
      return;
    }

    _addToHistory('Converting Flutter Icon to image...');

    // Convert Material Icons.star to image
    _iconFromWidget = await _iconToImage(
      Icons.star,
      size: 16.0,
      color: Colors.amber,
    );

    if (_iconFromWidget != null) {
      _menuItems[0].icon = _iconFromWidget;
      _addToHistory('Icon from widget set on first menu item');
    } else {
      _addToHistory('Failed to convert icon from widget');
    }
  }

  void _removeFirstMenuItem() {
    if (_menuItems.isEmpty) {
      _addToHistory('No menu items to remove');
      return;
    }

    final item = _menuItems[0];
    final success = _contextMenu.removeItem(item);

    if (success) {
      _menuItems.removeAt(0);
      _updateMenuItemCount();
      _addToHistory('Removed first menu item');
    } else {
      _addToHistory('Failed to remove first menu item');
    }
  }

  void _removeMenuItemAtPosition() {
    const position = 2;
    if (_menuItems.length <= position) {
      _addToHistory('No menu item at position $position to remove');
      return;
    }

    final success = _contextMenu.removeItemAt(position);

    if (success) {
      _menuItems.removeAt(position);
      _updateMenuItemCount();
      _addToHistory('Removed menu item at position $position');
    } else {
      _addToHistory('Failed to remove menu item at position $position');
    }
  }

  void _removeLastMenuItem() {
    if (_menuItems.isEmpty) {
      _addToHistory('No menu items to remove');
      return;
    }

    final lastIndex = _menuItems.length - 1;
    final success = _contextMenu.removeItemAt(lastIndex);

    if (success) {
      _menuItems.removeLast();
      _updateMenuItemCount();
      _addToHistory('Removed last menu item');
    } else {
      _addToHistory('Failed to remove last menu item');
    }
  }

  void _showMenuAtAbsolutePosition(Offset position) {
    _positioningMenu.open(PositioningStrategy.absolute(position));
    _addToHistory('Opened menu at absolute position: $position');
  }

  void _showMenuAtCursorPosition() {
    _positioningMenu.open(PositioningStrategy.cursorPosition());
    _addToHistory('Opened menu at cursor position');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Example - Comprehensive Test'),
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
                  // Context Menu Demo Section
                  _buildSectionCard('Context Menu Demo', [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow('Items', '$_menuItemCount'),
                        ),
                        Expanded(
                          child: _buildInfoRow('Checkbox', '$_checkboxState'),
                        ),
                        Expanded(
                          child: _buildInfoRow('Radio', _radioSelection),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Placement:',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<Placement>(
                            value: _selectedPlacement,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: Placement.topStart,
                                child: const Text('Top Start'),
                              ),
                              DropdownMenuItem(
                                value: Placement.topEnd,
                                child: const Text('Top End'),
                              ),
                              DropdownMenuItem(
                                value: Placement.bottomStart,
                                child: const Text('Bottom Start'),
                              ),
                              DropdownMenuItem(
                                value: Placement.bottomEnd,
                                child: const Text('Bottom End'),
                              ),
                              DropdownMenuItem(
                                value: Placement.leftStart,
                                child: const Text('Left Start'),
                              ),
                              DropdownMenuItem(
                                value: Placement.leftEnd,
                                child: const Text('Left End'),
                              ),
                              DropdownMenuItem(
                                value: Placement.rightStart,
                                child: const Text('Right Start'),
                              ),
                              DropdownMenuItem(
                                value: Placement.rightEnd,
                                child: const Text('Right End'),
                              ),
                            ],
                            onChanged: (Placement? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPlacement = value;
                                });
                                _addToHistory(
                                  'Placement changed to: ${value.toString().split('.').last}',
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ContextMenuRegion(
                      menu: _contextMenu,
                      placement: _selectedPlacement,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 32,
                                color: Colors.blue,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Right-click here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Item Management Section
                  _buildSectionCard('Item Management', [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactButton(
                          Icons.add,
                          'Add Item',
                          _addNewMenuItem,
                        ),
                        _buildCompactButton(
                          Icons.insert_drive_file,
                          'Insert at Pos 2',
                          _insertMenuItemAtPosition,
                        ),
                        _buildCompactButton(
                          Icons.horizontal_rule,
                          'Insert Separator',
                          _insertSeparatorAtPosition,
                        ),
                        _buildCompactButton(
                          Icons.remove_circle,
                          'Remove First',
                          _removeFirstMenuItem,
                        ),
                        _buildCompactButton(
                          Icons.delete,
                          'Remove at Pos 2',
                          _removeMenuItemAtPosition,
                        ),
                        _buildCompactButton(
                          Icons.delete_forever,
                          'Remove Last',
                          _removeLastMenuItem,
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Item Properties Section
                  _buildSectionCard('Item Properties', [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactButton(
                          Icons.edit,
                          'Update Label',
                          _changeDynamicLabel,
                        ),
                        _buildCompactButton(
                          Icons.indeterminate_check_box,
                          'Checkbox Mixed',
                          _setCheckboxMixed,
                        ),
                        _buildCompactButton(
                          Icons.add_box,
                          'Add Submenu Item',
                          _addSubmenuItem,
                        ),
                        _buildCompactButton(
                          Icons.swap_horiz,
                          'Detach Submenu',
                          _toggleSubmenu,
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Icon Management Section
                  _buildSectionCard('Icon Management', [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactButton(
                          Icons.image,
                          'Set Asset Icon',
                          _setIconOnFirstItem,
                        ),
                        _buildCompactButton(
                          Icons.star,
                          'Set Widget Icon',
                          _setIconFromWidget,
                        ),
                        _buildCompactButton(
                          Icons.hide_image,
                          'Remove Icon',
                          _removeIconFromFirstItem,
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Animated Icon Section
                  _buildSectionCard('Animated Icons', [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactButton(
                          Icons.refresh,
                          'Spinner',
                          _startSpinnerAnimation,
                        ),
                        _buildCompactButton(
                          Icons.circle,
                          'Pulse',
                          _startPulseAnimation,
                        ),
                        _buildCompactButton(
                          Icons.radio_button_unchecked,
                          'Blink',
                          _startBlinkAnimation,
                        ),
                        _buildCompactButton(
                          Icons.trending_up,
                          'Progress',
                          _startProgressAnimation,
                        ),
                        _buildCompactButton(
                          Icons.music_note,
                          'Wave',
                          _startWaveAnimation,
                        ),
                        _buildCompactButton(
                          Icons.crop_square,
                          'Rotate',
                          _startRotatingSquareAnimation,
                        ),
                        _buildCompactButton(Icons.stop, 'Stop', _stopAnimation),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Positioning Section
                  _buildSectionCard('Positioning', [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactButton(
                          Icons.location_on,
                          'Pos (100,100)',
                          () => _showMenuAtAbsolutePosition(
                            const Offset(100, 100),
                          ),
                        ),
                        _buildCompactButton(
                          Icons.location_on,
                          'Pos (300,200)',
                          () => _showMenuAtAbsolutePosition(
                            const Offset(300, 200),
                          ),
                        ),
                        _buildCompactButton(
                          Icons.mouse,
                          'At Cursor',
                          _showMenuAtCursorPosition,
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Test Cases Section
                  _buildSectionCard('Test Cases', [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactButton(
                          Icons.add_circle_outline,
                          'Add 10 Items',
                          () {
                            for (int i = 0; i < 10; i++) _addNewMenuItem();
                          },
                        ),
                        _buildCompactButton(
                          Icons.flash_on,
                          'Rapid Open/Close',
                          () {
                            for (int i = 0; i < 5; i++) {
                              _showMenuAtAbsolutePosition(
                                Offset(100.0 + i * 50, 100.0 + i * 50),
                              );
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () => _contextMenu.close(),
                              );
                            }
                          },
                        ),
                        _buildCompactButton(
                          Icons.border_outer,
                          'Top-Left Edge',
                          () {
                            _showMenuAtAbsolutePosition(const Offset(10, 10));
                            _addToHistory(
                              'Testing menu near screen edge (top-left)',
                            );
                          },
                        ),
                        _buildCompactButton(
                          Icons.border_outer,
                          'Bottom-Right Edge',
                          () {
                            _showMenuAtAbsolutePosition(
                              const Offset(1500, 900),
                            );
                            _addToHistory(
                              'Testing menu near screen edge (bottom-right)',
                            );
                          },
                        ),
                      ],
                    ),
                  ]),
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
                              'No events yet\nInteract with menus to see events',
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

  @override
  void dispose() {
    _animatedIconGenerator?.dispose();
    _contextMenu.dispose();
    _positioningMenu.dispose();
    for (var item in _menuItems) {
      item.dispose();
    }
    super.dispose();
  }
}
