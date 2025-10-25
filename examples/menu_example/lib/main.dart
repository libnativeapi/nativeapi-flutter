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

class _MenuExamplePageState extends State<MenuExamplePage> {
  late final Menu _contextMenu;
  late final Menu _positioningMenu;
  late final Menu _placementMenu;
  
  final List<MenuItem> _menuItems = [];
  final List<String> _eventHistory = [];
  
  bool _checkboxState = false;
  String _radioSelection = 'Option 1';
  String _currentLabel = 'Dynamic Label Item';
  
  int _menuItemCount = 0;
  
  // Store references to menu items for state management
  late final MenuItem _checkboxItem;
  late final MenuItem _radio1;
  late final MenuItem _radio2;
  late final MenuItem _radio3;
  late final MenuItem _submenuItem;
  late final Menu _submenu;

  @override
  void initState() {
    super.initState();
    _setupContextMenu();
    _setupPositioningMenu();
    _setupPlacementMenu();
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
        _checkboxItem.state = _checkboxState ? MenuItemState.checked : MenuItemState.unchecked;
      });
      _addToHistory('Checkbox clicked - State: $_checkboxState (ID: ${event.menuItemId})');
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

    final item1 = MenuItem('Absolute Position Item');
    item1.on<MenuItemClickedEvent>((event) {
      _addToHistory('Absolute position item clicked');
    });
    _positioningMenu.addItem(item1);

    final item2 = MenuItem('Another Item');
    item2.on<MenuItemClickedEvent>((event) {
      _addToHistory('Another item clicked');
    });
    _positioningMenu.addItem(item2);
  }

  void _setupPlacementMenu() {
    _placementMenu = Menu();
    
    _placementMenu.addCallbackListener<MenuOpenedEvent>((event) {
      _addToHistory('Placement menu opened');
    });
    _placementMenu.addCallbackListener<MenuClosedEvent>((event) {
      _addToHistory('Placement menu closed');
    });

    final item1 = MenuItem('Placement Test Item 1');
    item1.on<MenuItemClickedEvent>((event) {
      _addToHistory('Placement test item 1 clicked');
    });
    _placementMenu.addItem(item1);

    final item2 = MenuItem('Placement Test Item 2');
    item2.on<MenuItemClickedEvent>((event) {
      _addToHistory('Placement test item 2 clicked');
    });
    _placementMenu.addItem(item2);
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
      _currentLabel = 'Updated at ${DateTime.now().toString().substring(11, 19)}';
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
    final newSubItem = MenuItem('Dynamic Submenu Item ${_submenu.itemCount + 1}');
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

  void _showMenuAtAbsolutePosition(Offset position) {
    _positioningMenu.open(PositioningStrategy.absolute(position));
    _addToHistory('Opened menu at absolute position: $position');
  }

  void _showMenuAtCursorPosition() {
    _positioningMenu.open(PositioningStrategy.cursorPosition());
    _addToHistory('Opened menu at cursor position');
  }

  void _showMenuWithPlacement(Placement placement) {
    _placementMenu.open(
      PositioningStrategy.absolute(const Offset(400, 300)),
      placement,
    );
    _addToHistory('Opened menu with placement: ${placement.toString()}');
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
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionCard(
                    'Menu Creation & Display',
                    [
                      _buildInfoRow('Menu Item Count', '$_menuItemCount'),
                      _buildInfoRow('Checkbox State', '$_checkboxState'),
                      _buildInfoRow('Radio Selection', _radioSelection),
                      const SizedBox(height: 8),
                      const Text(
                        'Right-click the area below to show context menu:',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ContextMenuRegion(
                        menu: _contextMenu,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.touch_app, size: 32, color: Colors.blue),
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    'Menu Item Operations',
                    [
                      ElevatedButton.icon(
                        onPressed: _changeDynamicLabel,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Change Dynamic Label'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _setCheckboxMixed,
                        icon: const Icon(Icons.indeterminate_check_box, size: 18),
                        label: const Text('Set Checkbox to Mixed State'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addSubmenuItem,
                        icon: const Icon(Icons.add_box, size: 18),
                        label: const Text('Add Item to Submenu'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _toggleSubmenu,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Toggle Submenu Attachment'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addNewMenuItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add New Menu Item'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _insertMenuItemAtPosition,
                        icon: const Icon(Icons.insert_drive_file, size: 18),
                        label: const Text('Insert Item at Position 2'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _insertSeparatorAtPosition,
                        icon: const Icon(Icons.horizontal_rule, size: 18),
                        label: const Text('Insert Separator at Position 3'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    'Positioning Strategy Tests',
                    [
                      const Text(
                        'Test different positioning strategies:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showMenuAtAbsolutePosition(const Offset(100, 100)),
                        icon: const Icon(Icons.location_on, size: 18),
                        label: const Text('Absolute (100, 100)'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showMenuAtAbsolutePosition(const Offset(300, 200)),
                        icon: const Icon(Icons.location_on, size: 18),
                        label: const Text('Absolute (300, 200)'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showMenuAtCursorPosition,
                        icon: const Icon(Icons.mouse, size: 18),
                        label: const Text('Cursor Position'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    'Placement Tests',
                    [
                      const Text(
                        'Test different menu placements:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPlacementButton(Placement.topStart),
                          _buildPlacementButton(Placement.topEnd),
                          _buildPlacementButton(Placement.bottomStart),
                          _buildPlacementButton(Placement.bottomEnd),
                          _buildPlacementButton(Placement.leftStart),
                          _buildPlacementButton(Placement.leftEnd),
                          _buildPlacementButton(Placement.rightStart),
                          _buildPlacementButton(Placement.rightEnd),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    'Edge Cases & Stress Tests',
                    [
                      ElevatedButton.icon(
                        onPressed: () {
                          for (int i = 0; i < 10; i++) {
                            _addNewMenuItem();
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Add 10 Items (Stress Test)'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          for (int i = 0; i < 5; i++) {
                            _showMenuAtAbsolutePosition(Offset(100.0 + i * 50, 100.0 + i * 50));
                            Future.delayed(const Duration(milliseconds: 100), () {
                              _contextMenu.close();
                            });
                          }
                        },
                        icon: const Icon(Icons.flash_on, size: 18),
                        label: const Text('Rapid Open/Close Test'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Test menu at screen edges
                          _showMenuAtAbsolutePosition(const Offset(10, 10));
                          _addToHistory('Testing menu near screen edge (top-left)');
                        },
                        icon: const Icon(Icons.border_outer, size: 18),
                        label: const Text('Test Screen Edge (Top-Left)'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Test menu at screen edges
                          _showMenuAtAbsolutePosition(const Offset(1500, 900));
                          _addToHistory('Testing menu near screen edge (bottom-right)');
                        },
                        icon: const Icon(Icons.border_outer, size: 18),
                        label: const Text('Test Screen Edge (Bottom-Right)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Right side - Event history
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
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
                            fontSize: 16,
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
                                fontSize: 14,
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
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade200),
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementButton(Placement placement) {
    String placementName = placement.toString().split('.').last;
    return SizedBox(
      width: 110,
      child: ElevatedButton(
        onPressed: () => _showMenuWithPlacement(placement),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          textStyle: const TextStyle(fontSize: 11),
        ),
        child: Text(placementName),
      ),
    );
  }

  @override
  void dispose() {
    _contextMenu.dispose();
    _positioningMenu.dispose();
    _placementMenu.dispose();
    for (var item in _menuItems) {
      item.dispose();
    }
    super.dispose();
  }
}
