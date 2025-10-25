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
- ✅ Set icons on menu items
- ✅ Display icons correctly
- ✅ Dynamically change icons
- ✅ Remove icons and restore normal display

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

3. **Positioning Strategy Tests**
   - Absolute positioning at different coordinates
   - Cursor position testing

4. **Placement Tests**
   - Buttons for all 8 placement options
   - Visual feedback for each placement

5. **Edge Cases & Stress Tests**
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

## Platform-Specific Notes

### macOS
- Native NSMenu used for rendering
- Tooltips may not display (macOS limitation)
- Keyboard shortcuts can be added to menu items

### Windows
- Native Win32 menus used
- Full tooltip support
- Menu animations follow system settings

### Linux
- GTK menus used for rendering
- Appearance follows GTK theme
- Tooltip support depends on GTK version

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
    ├── _setupContextMenu() - Creates main context menu
    ├── _setupPositioningMenu() - Creates positioning test menu
    ├── _setupPlacementMenu() - Creates placement test menu
    ├── _addToHistory() - Logs events to history
    └── UI Sections
        ├── Menu Creation & Display
        ├── Menu Item Operations
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
