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
- ✅ **Animated Icons** - Create pixel-perfect animated icons using canvas
  - Spinner animation (rotating loader)
  - Pulse animation (expanding/contracting circle)
  - Blink animation (on/off blinking dot)
  - Progress animation (filling progress bar)
  - Wave animation (moving wave pattern)
  - Rotating square animation

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

1. **Context Menu Demo**
   - Shows current menu state (item count, checkbox/radio states)
   - Placement selector for choosing menu placement strategy
   - Context menu region for right-click testing

2. **Item Management**
   - Add Item: adds new menu item at the end
   - Insert at Pos 2: inserts item at specific position
   - Insert Separator: adds visual divider
   - Remove First / Remove at Pos 2 / Remove Last: removes items

3. **Item Properties**
   - Update Label: changes menu item label dynamically
   - Checkbox Mixed: sets checkbox to indeterminate state
   - Add Submenu Item: adds item to submenu
   - Detach Submenu: toggles submenu attachment

4. **Icon Management**
   - Set Asset Icon: loads icon from asset file
   - Set Widget Icon: converts Flutter Icon to native icon
   - Remove Icon: removes icon from menu item

5. **Positioning**
   - Pos (100,100) / Pos (300,200): absolute positioning at specific coordinates
   - At Cursor: displays menu at current mouse position

6. **Test Cases**
   - Add 10 Items: adds multiple items at once
   - Rapid Open/Close: tests stability with fast operations
   - Top-Left Edge / Bottom-Right Edge: tests boundary handling

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

### Item Properties Testing
1. Click **Update Label** - label should update with timestamp
2. Click **Checkbox Mixed** - checkbox item shows indeterminate state
3. Click **Add Submenu Item** - adds a new item to the submenu
4. Click **Detach Submenu** - toggles submenu attachment on/off

### Item Management Testing
1. Click **Add Item** - item count should increase
2. Click **Insert at Pos 2** - new item appears at position 2
3. Click **Insert Separator** - separator appears at next position
4. Click **Remove First** / **Remove at Pos 2** / **Remove Last** - removes items

### Icon Management Testing
1. Click **Set Asset Icon** - first menu item displays icon from asset file
2. Right-click the context menu region to verify icon appears
3. Click **Set Widget Icon** - first menu item displays a star icon (converted from Material Icons)
4. Right-click to verify the widget-based icon appears
5. Click **Remove Icon** - icon should disappear
6. Right-click again to verify icon is removed

**Note:** The "Set Widget Icon" feature demonstrates converting Flutter's Material Icons to native menu icons using base64 encoding.

### Animated Icons Testing
1. Click **Spinner** - first menu item displays a rotating spinner animation
2. Right-click to see the animation in action
3. Click **Pulse** - switches to pulsing circle animation
4. Click **Blink** - switches to blinking dot animation
5. Click **Progress** - switches to filling progress bar animation
6. Click **Wave** - switches to moving wave pattern animation
7. Click **Rotate** - switches to rotating square animation
8. Click **Stop** - stops any running animation
9. Right-click to verify the icon updates in real-time

**Note:** The animated icons are generated pixel-by-pixel using Flutter's Canvas API and converted to native images. Each animation type provides different visual feedback suitable for loading states, notifications, or progress indicators.

### Positioning Testing
1. Click **Pos (100,100)** - menu appears at top-left coordinates
2. Click **Pos (300,200)** - menu appears at center-left coordinates
3. Click **At Cursor** - menu appears at mouse location

### Placement Testing
1. Click each placement button (topStart, bottomEnd, etc.)
2. Verify menu appears in correct position relative to anchor point
3. Test near screen edges to verify auto-adjustment

### Edge Cases Testing
1. Click **Add 10 Items** - verify menu handles many items
2. Click **Rapid Open/Close** - verify stability with fast operations
3. Click **Top-Left Edge** and **Bottom-Right Edge** buttons - verify boundary handling
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

### Using Animated Icons

Create pixel-perfect animated icons using the `AnimatedIconGenerator` class:

```dart
import 'animated_icon_generator.dart';

// Create an animated icon generator with high DPI support
final generator = AnimatedIconGenerator(
  size: 32,  // Higher resolution for better quality
  foregroundColor: Colors.blue,
);

// Create a menu item
final menuItem = MenuItem('Loading...');

// Start a spinner animation
generator.startSpinner(
  onFrame: (image) async {
    menuItem.icon = image;
  },
);

// Switch to pulse animation
generator.startPulse(
  onFrame: (image) async {
    menuItem.icon = image;
  },
);

// Stop animation when done
generator.stop();
```

Available animation types:
- `startSpinner()` - Rotating circular loader
- `startPulse()` - Expanding/contracting circle
- `startBlink()` - On/off blinking dot
- `startProgress()` - Filling progress bar
- `startWave()` - Moving wave pattern
- `startRotatingSquare()` - Rotating square icon

The animations are generated using Flutter's Canvas API and converted to native images, providing smooth pixel-perfect animations suitable for menu icons.

**High DPI Support:** The `AnimatedIconGenerator` automatically scales icons for high DPI displays (Retina, HiDPI). Default size is 32x32 logical pixels, which produces crisp icons on all displays including Retina displays (64x64 or 96x96 physical pixels).

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
    ├── _addToHistory() - Logs events to history
    ├── Item Management Methods
    │   ├── _addNewMenuItem() - Adds item to end
    │   ├── _insertMenuItemAtPosition() - Inserts item at specific position
    │   ├── _insertSeparatorAtPosition() - Inserts separator at position
    │   ├── _removeFirstMenuItem() - Removes first item
    │   ├── _removeMenuItemAtPosition() - Removes item at position
    │   └── _removeLastMenuItem() - Removes last item
    ├── Item Properties Methods
    │   ├── _changeDynamicLabel() - Changes menu item label
    │   ├── _setCheckboxMixed() - Sets checkbox to mixed state
    │   ├── _addSubmenuItem() - Adds item to submenu
    │   └── _toggleSubmenu() - Toggles submenu attachment
    ├── Icon Management Methods
    │   ├── _setIconOnFirstItem() - Sets icon from asset file
    │   ├── _setIconFromWidget() - Sets icon from Flutter Icon widget
    │   └── _removeIconFromFirstItem() - Removes icon from first item
    ├── Positioning Methods
    │   ├── _showMenuAtAbsolutePosition() - Shows menu at absolute coordinates
    │   └── _showMenuAtCursorPosition() - Shows menu at cursor position
    └── UI Sections
        ├── Context Menu Demo
        ├── Item Management
        ├── Item Properties
        ├── Icon Management
        ├── Positioning
        ├── Test Cases
        └── Event History Panel
```

## Related Documentation

- [Menu API Documentation](../../packages/nativeapi/lib/src/menu.dart)
- [Menu Events Documentation](../../packages/nativeapi/lib/src/menu_event.dart)
- [Test Plan](../../TEST_PLAN.md#3-menu菜单)

## License

This example is part of the nativeapi package and follows the same license.
