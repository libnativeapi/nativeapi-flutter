# Menu Example

A comprehensive Flutter application demonstrating all menu functionality provided by the `nativeapi` package. This example covers all test cases from the Menu test plan.

## Features Demonstrated

### 1. Menu Creation & Display (Section 3.1)

#### Basic Menu Functionality
- ✅ Create menu objects
- ✅ Display context menu on right-click
- ✅ Display menu at specific positions using buttons
- ✅ Verify menu positioning accuracy

#### Menu Item Types
- ✅ **Normal** - Standard clickable menu items
- ✅ **Separator** - Visual dividers between menu items
- ✅ **Checkbox** - Toggle items with checked/unchecked states
- ✅ **Radio** - Mutually exclusive selection items
- ✅ **Submenu** - Nested menus with multiple levels

### 2. Menu Item Properties (Section 3.2)

#### Labels
- ✅ Display menu item labels correctly
- ✅ Dynamically modify labels at runtime
- ✅ Support multi-language characters (Chinese, Japanese)
- ✅ Support special characters and symbols (emojis, @#$%)

#### Icons
- ✅ Set icons on menu items (from assets)
- ✅ Set icons from Flutter Icon widgets (converted to base64)
- ✅ Display icons correctly
- ✅ Dynamically change icons
- ✅ Remove icons and restore normal display
- ✅ Load icons from Flutter assets
- ✅ Convert Material Icons to native menu icons

#### Tooltips
- ✅ Set tooltips on menu items
- ✅ Display tooltips on hover (platform-dependent)
- ✅ Show correct tooltip text

### 3. Menu Events (Section 3.3)

#### Menu Events
- ✅ `MenuOpenedEvent` - Triggered when menu opens
- ✅ `MenuClosedEvent` - Triggered when menu closes
- ✅ Event listeners receive events correctly
- ✅ Event history displays all events

#### Menu Item Click Events
- ✅ `MenuItemClickedEvent` - Triggered on normal item clicks
- ✅ Checkbox items toggle state on click
- ✅ Radio items toggle state on click
- ✅ Events contain correct menu item IDs
- ✅ Multiple clicks trigger events correctly

#### Submenu Events
- ✅ `MenuItemSubmenuOpenedEvent` - Triggered when submenu opens
- ✅ `MenuItemSubmenuClosedEvent` - Triggered when submenu closes

### 4. Menu Operations (Section 3.4)

#### Adding Menu Items
- ✅ Add items to menu end
- ✅ Insert items at specific positions
- ✅ Add separators
- ✅ Insert separators at specific positions
- ✅ Track item count (`itemCount`)

#### Removing Menu Items
- ✅ Remove items by reference (`removeItem`)
- ✅ Remove items by ID (`removeItemById`)
- ✅ Remove items by index (`removeItemAt`)
- ✅ Update item count after removal

#### Positioning Strategy
- ✅ **Absolute** - Display at specific coordinates
- ✅ **Cursor Position** - Display at mouse cursor
- ✅ **Relative** - Display relative to a region

#### Menu Placement
- ✅ Test all placement options:
  - `topStart`, `topEnd`
  - `bottomStart`, `bottomEnd`
  - `leftStart`, `leftEnd`
  - `rightStart`, `rightEnd`
- ✅ Auto-adjust when menu exceeds screen boundaries

### 5. ContextMenuRegion Widget (Section 3.5)

- ✅ Right-click region displays context menu
- ✅ Menu displays at correct position
- ✅ Multiple regions work independently

### 6. Edge Cases (Section 3.6)

- ✅ Handle empty menus (no items)
- ✅ Display and scroll with many menu items
- ✅ Rapid open/close operations don't crash
- ✅ Handle focus changes while menu is open
- ✅ Clear event history functionality

## UI Layout

The application is divided into two main sections:

### Left Panel - Test Controls
Contains multiple test sections organized in cards:

1. **Menu Creation & Display**
   - Shows current menu state (item count, checkbox/radio states)
   - Context menu region for right-click testing

2. **Menu Item Operations**
   - Change dynamic label
   - Add new menu items
   - Insert items at specific positions
   - Insert separators at specific positions

3. **Icon Management**
   - Set icon from asset file
   - Set icon from Flutter Icon widget (Material Icons)
   - Remove icon from menu item

4. **Menu Item Removal**
   - Remove first menu item
   - Remove item at specific position
   - Remove last menu item

5. **Positioning Strategy Tests**
   - Absolute positioning at different coordinates
   - Cursor position testing

6. **Placement Tests**
   - Buttons for all 8 placement options
   - Visual feedback for each placement

7. **Edge Cases & Stress Tests**
   - Add multiple items at once
   - Rapid open/close testing
   - Screen edge boundary testing

### Right Panel - Event History
- Real-time event log with timestamps
- Shows all menu and menu item events
- Displays event IDs for verification
- Scrollable history (keeps last 50 events)
- Clear button in app bar

## How to Run

```bash
# Navigate to the example directory
cd examples/menu_example

# Get dependencies
flutter pub get

# Run on macOS
flutter run -d macos

# Run on Windows
flutter run -d windows

# Run on Linux
flutter run -d linux
```

## Testing Guide

### Basic Testing
1. **Right-click** on the blue context menu region
2. Verify all menu item types display correctly
3. Click different items and observe events in the history

### Menu Item Types Testing
1. Click **Normal Menu Item** - should log click event
2. Click **Checkbox Item** - should toggle state and log event
3. Click **Radio Options** - should switch selection and log event
4. Hover over **Submenu** - should expand and log open event
5. Click items in submenu - should log submenu item clicks

### Dynamic Operations Testing
1. Click **Change Dynamic Label** - label should update with timestamp
2. Click **Add New Menu Item** - item count should increase
3. Click **Insert Item at Position 2** - new item appears at position 2
4. Click **Insert Separator at Position 3** - separator appears at position 3

### Icon Management Testing
1. Click **Set Icon from Asset** - first menu item displays icon from asset file
2. Right-click the context menu region to verify icon appears
3. Click **Set Icon from Widget** - first menu item displays a star icon (converted from Material Icons)
4. Right-click to verify the widget-based icon appears
5. Click **Remove Icon from First Item** - icon should disappear
6. Right-click again to verify icon is removed

**Note:** The "Set Icon from Widget" feature demonstrates converting Flutter's Material Icons to native menu icons using base64 encoding.

### Menu Item Removal Testing
1. Click **Remove First Menu Item** - first item should be removed, count decreases
2. Click **Remove Item at Position 2** - item at position 2 removed
3. Click **Remove Last Menu Item** - last item removed
4. Verify item count updates correctly after each removal
5. Right-click to verify items are actually removed from menu

### Positioning Testing
1. Click **Absolute (100, 100)** - menu appears at top-left
2. Click **Absolute (300, 200)** - menu appears at center-left
3. Click **Cursor Position** - menu appears at mouse location

### Placement Testing
1. Click each placement button (topStart, bottomEnd, etc.)
2. Verify menu appears in correct position relative to anchor point
3. Test near screen edges to verify auto-adjustment

### Edge Cases Testing
1. Click **Add 10 Items** - verify menu handles many items
2. Click **Rapid Open/Close Test** - verify stability
3. Click **Test Screen Edge** buttons - verify boundary handling
4. Open menu, switch window focus, return - verify menu state

### Event Verification
- All interactions should log events with timestamps
- Event IDs should be consistent for same menu items
- Event history should update in real-time
- Clear button should remove all history entries

## Expected Behavior

### Menu Display
- Context menu appears on right-click
- Menus appear at correct positions
- Separators display as horizontal lines
- Checkboxes show check marks when selected
- Radio buttons show selection indicator
- Submenus show arrow indicator and expand on hover

### Event Flow
```
1. Right-click → MenuOpenedEvent
2. Click item → MenuItemClickedEvent
3. Menu closes → MenuClosedEvent
4. Hover submenu → MenuItemSubmenuOpenedEvent
5. Leave submenu → MenuItemSubmenuClosedEvent
```

### State Management
- Checkbox state persists between menu opens
- Radio selection persists and is mutually exclusive
- Dynamic label changes reflect immediately
- Item count updates when items are added/removed

## Technical Features

### Icon Conversion from Flutter Widgets

The example demonstrates converting Flutter Icon widgets (like Material Icons) to native menu icons:

```dart
Future<Image?> _iconToImage(IconData iconData, {
  double size = 24.0,
  Color color = Colors.black,
}) async {
  // 1. Create a picture recorder to draw the icon
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // 2. Use TextPainter to render the icon glyph
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
  
  // 3. Convert to PNG image
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  
  // 4. Encode to base64 and create nativeapi Image
  final pngBytes = byteData.buffer.asUint8List();
  final base64String = 'data:image/png;base64,${base64Encode(pngBytes)}';
  return Image.fromBase64(base64String);
}
```

This allows you to use any Flutter Icon (Material Icons, Cupertino Icons, custom icon fonts) as native menu icons.

## Platform-Specific Notes

### macOS
- Native NSMenu used for rendering
- Tooltips may not display (macOS limitation)
- Keyboard shortcuts can be added to menu items
- Icon rendering supports base64 PNG images

### Windows
- Native Win32 menus used
- Full tooltip support
- Menu animations follow system settings
- Icon rendering supports base64 PNG images

### Linux
- GTK menus used for rendering
- Appearance follows GTK theme
- Tooltip support depends on GTK version
- Icon rendering supports base64 PNG images

## Troubleshooting

### Menu doesn't appear
- Ensure you're right-clicking on the blue region
- Try using the button-based menu triggers
- Check event history for error messages

### Events not logging
- Verify event listeners are set up correctly
- Check console for any error messages
- Ensure menu items are properly initialized

### Items not updating
- Dynamic changes require menu to be closed and reopened
- Some platforms cache menu state
- Try recreating the menu if issues persist

## Code Structure

```
main.dart
├── MyApp - Root application widget
└── MenuExamplePage - Main example page
    ├── _loadTestIcon() - Loads test icon from assets
    ├── _iconToImage() - Converts Flutter Icon widget to base64 image
    ├── _setupContextMenu() - Creates main context menu
    ├── _setupPositioningMenu() - Creates positioning test menu
    ├── _setupPlacementMenu() - Creates placement test menu
    ├── _addToHistory() - Logs events to history
    ├── Icon Management Methods
    │   ├── _setIconOnFirstItem() - Sets icon from asset file
    │   ├── _setIconFromWidget() - Sets icon from Flutter Icon widget
    │   └── _removeIconFromFirstItem() - Removes icon from first item
    ├── Menu Item Removal Methods
    │   ├── _removeFirstMenuItem() - Removes first item
    │   ├── _removeMenuItemAtPosition() - Removes item at position 2
    │   └── _removeLastMenuItem() - Removes last item
    └── UI Sections
        ├── Menu Creation & Display
        ├── Menu Item Operations
        ├── Icon Management
        ├── Menu Item Removal
        ├── Positioning Strategy Tests
        ├── Placement Tests
        ├── Edge Cases & Stress Tests
        └── Event History Panel
```

## Related Documentation

- [Menu API Documentation](../../packages/nativeapi/lib/src/menu.dart)
- [Menu Events Documentation](../../packages/nativeapi/lib/src/menu_event.dart)
- [Test Plan](../../TEST_PLAN.md#3-menu菜单)

## License

This example is part of the nativeapi package and follows the same license.
