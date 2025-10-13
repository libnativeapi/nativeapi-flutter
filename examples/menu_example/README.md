# Menu Example

This is a sample application demonstrating the nativeapi menu functionality.

## Features

- **Native Menu**: Uses nativeapi package to create native system menus
- **Right-click Context Menu**: Right-click on specified areas to display menus
- **Menu Item Types**: Supports normal menu items, separators, menu items with icons, and menu items with tooltips
- **Event Handling**: Listens to menu open/close events and menu item click events
- **Real-time Status Display**: Shows current menu status and operation history

## Usage

1. **Right-click Menu**: Right-click on the blue menu demo area to show native context menu
2. **Button Trigger**: Click "Show Menu" button to display menu at specified position
3. **View Status**: Right panel shows menu item count and last executed action
4. **Action History**: View detailed history of all menu operations
5. **Clear History**: Click the clear button in the app bar to clear operation history

## Menu Item Description

- **Normal Menu Item**: Basic menu item that records clicks in history
- **Separator**: Used to separate different groups of menu items
- **Menu Item with Icon**: Menu item that supports setting icons (requires icon resources)
- **Menu Item with Tooltip**: Menu item that supports setting tooltips

## Technical Implementation

- Uses `Menu` class to create menus
- Uses `MenuItem` class to create menu items
- Uses `ContextMenuRegion` wrapper to implement right-click menus
- Uses event listeners to handle menu events
- Uses `MenuOpenedEvent` and `MenuClosedEvent` to listen to menu status
- Uses `MenuItemClickedEvent` to listen to menu item clicks

## Requirements

- Flutter SDK 3.9.2+
- macOS platform (native menu functionality)
- nativeapi package dependency

## Run Command

```bash
flutter run -d macos
```

## Notes

- This example is primarily targeted at macOS platform's native menu functionality
- Menu item state management (such as checkboxes, radio buttons) needs to be implemented according to actual requirements
- Icon resources need to be properly configured in the project