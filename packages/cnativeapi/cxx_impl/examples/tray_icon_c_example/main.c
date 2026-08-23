#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

// Include individual C API headers instead of the full nativeapi.h
#include "../../src/capi/application_c.h"
#include "../../src/capi/menu_c.h"
#include "../../src/capi/string_utils_c.h"
#include "../../src/capi/tray_icon_c.h"
#include "../../src/capi/tray_manager_c.h"

// Menu item IDs (stored globally for identification)
static native_menu_item_id_t exit_item_id = 0;
static native_menu_item_id_t show_message_item_id = 0;

// Event callback functions
//
// Each emitter takes a single listener now; the event carries a tag saying
// which concrete event arrived.
void on_menu_event(const native_menu_event_t* event, void* user_data) {
  (void)user_data;
  switch (event->type) {
    case NATIVE_MENU_EVENT_TYPE_ITEM_CLICKED: {
      native_menu_item_id_t item_id = event->data.item_clicked.item_id;
      printf("Menu item clicked: ID=%u\n", item_id);
      if (item_id == exit_item_id) {
        printf("Exiting application...\n");
        exit(0);
      } else if (item_id == show_message_item_id) {
        printf("Hello from tray menu!\n");
      }
      break;
    }
    case NATIVE_MENU_EVENT_TYPE_OPENED:
      printf("Menu opened: ID=%u\n", event->data.opened.menu_id);
      break;
    case NATIVE_MENU_EVENT_TYPE_CLOSED:
      printf("Menu closed: ID=%u\n", event->data.closed.menu_id);
      break;
    default:
      break;
  }
}

void on_tray_event(const native_tray_icon_event_t* event, void* user_data) {
  (void)user_data;
  switch (event->type) {
    case NATIVE_TRAY_ICON_EVENT_TYPE_CLICKED:
      printf("Tray icon clicked! ID=%u\n", event->data.clicked.tray_icon_id);
      break;
    case NATIVE_TRAY_ICON_EVENT_TYPE_RIGHT_CLICKED:
      printf("Tray icon right clicked! ID=%u\n", event->data.right_clicked.tray_icon_id);
      break;
    case NATIVE_TRAY_ICON_EVENT_TYPE_DOUBLE_CLICKED:
      printf("Tray icon double clicked! ID=%u\n", event->data.double_clicked.tray_icon_id);
      break;
  }
}

int main() {
  printf("=== Tray Menu C API Example ===\n");

  // Check if system tray is supported
  if (!native_tray_manager_is_supported()) {
    printf("Error: System tray is not supported on this platform!\n");
    return 1;
  }

  printf("System tray is supported.\n");

  // Create a menu
  native_menu_t menu = native_menu_create();
  if (menu == NATIVE_INVALID_MENU) {
    printf("Error: Failed to create menu!\n");
    return 1;
  }

  printf("Created menu with ID: %u\n", native_menu_get_id(menu));

  // Create menu items
  native_menu_item_t item1 = native_menu_item_create_with_label_and_type("Show Message", NATIVE_MENU_ITEM_TYPE_NORMAL);
  native_menu_item_t item2 = native_menu_item_create_with_label_and_type("Settings", NATIVE_MENU_ITEM_TYPE_NORMAL);
  native_menu_item_t checkbox =
      native_menu_item_create_with_label_and_type("Enable Notifications", NATIVE_MENU_ITEM_TYPE_CHECKBOX);
  native_menu_item_t exit_item = native_menu_item_create_with_label_and_type("Exit", NATIVE_MENU_ITEM_TYPE_NORMAL);

  if (item1 == NATIVE_INVALID_MENU_ITEM || item2 == NATIVE_INVALID_MENU_ITEM ||
      checkbox == NATIVE_INVALID_MENU_ITEM || exit_item == NATIVE_INVALID_MENU_ITEM) {
    printf("Error: Failed to create menu items!\n");
    native_menu_free(menu);
    return 1;
  }

  // Store menu item IDs for later identification
  show_message_item_id = native_menu_item_get_id(item1);
  exit_item_id = native_menu_item_get_id(exit_item);

  // Set up menu item properties
  native_menu_item_set_enabled(item1, true);
  native_menu_item_set_tooltip(item1, "Click to show a message");

  // Set up keyboard accelerator for exit item
  native_keyboard_accelerator_t exit_accel = {.modifiers = NATIVE_MODIFIER_KEY_CTRL, .key = "Q"};
  native_menu_item_set_accelerator(exit_item, &exit_accel);

  // Set checkbox state
  native_menu_item_set_state(checkbox, NATIVE_MENU_ITEM_STATE_CHECKED);

  // Set up event listeners using new API
  native_menu_item_add_listener(item1, on_menu_event, NULL);
  native_menu_item_add_listener(item2, on_menu_event, NULL);
  native_menu_item_add_listener(exit_item, on_menu_event, NULL);
  native_menu_item_add_listener(checkbox, on_menu_event, NULL);

  // Add items to menu
  native_menu_add_item(menu, item1);
  native_menu_add_item(menu, item2);
  native_menu_add_item(menu, checkbox);
  native_menu_add_separator(menu);
  native_menu_add_item(menu, exit_item);

  printf("Added %lu items to menu\n", native_menu_get_item_count(menu));

  // Set menu event listeners using new API
  native_menu_add_listener(menu, on_menu_event, NULL);

  // Create a submenu example
  native_menu_t submenu = native_menu_create();
  if (submenu != NATIVE_INVALID_MENU) {
    native_menu_item_t sub_item1 =
        native_menu_item_create_with_label_and_type("Sub Item 1", NATIVE_MENU_ITEM_TYPE_NORMAL);
    native_menu_item_t sub_item2 =
        native_menu_item_create_with_label_and_type("Sub Item 2", NATIVE_MENU_ITEM_TYPE_NORMAL);

    if (sub_item1 != NATIVE_INVALID_MENU_ITEM && sub_item2 != NATIVE_INVALID_MENU_ITEM) {
      native_menu_add_item(submenu, sub_item1);
      native_menu_add_item(submenu, sub_item2);

      // Create submenu item and add to main menu
      native_menu_item_t submenu_item =
          native_menu_item_create_with_label_and_type("More Options", NATIVE_MENU_ITEM_TYPE_SUBMENU);
      if (submenu_item != NATIVE_INVALID_MENU_ITEM) {
        native_menu_item_set_submenu(submenu_item, submenu);
        native_menu_add_item(menu, submenu_item);
        printf("Created submenu with %lu items\n", native_menu_get_item_count(submenu));
      }
    }
  }

  // Create tray icon
  native_tray_icon_t tray_icon = native_tray_icon_create();
  if (tray_icon == NATIVE_INVALID_TRAY_ICON) {
    printf("Error: Failed to create tray icon!\n");
    native_menu_free(menu);
    return 1;
  }

  printf("Created tray icon with ID: %u\n", native_tray_icon_get_id(tray_icon));

  // Set up tray icon properties
  native_tray_icon_set_title(tray_icon, "My App");
  native_tray_icon_set_tooltip(tray_icon, "My Application - Right click for menu");

  // Set the context menu
  native_tray_icon_set_context_menu(tray_icon, menu);

  // Set context menu trigger to automatically show menu on right click
  native_tray_icon_set_context_menu_trigger(tray_icon, NATIVE_CONTEXT_MENU_TRIGGER_RIGHT_CLICKED);

  // Get and display the current trigger mode
  native_context_menu_trigger_t current_trigger =
      native_tray_icon_get_context_menu_trigger(tray_icon);
  printf("Context menu trigger mode: ");
  switch (current_trigger) {
    case NATIVE_CONTEXT_MENU_TRIGGER_NONE:
      printf("None (manual control)\n");
      break;
    case NATIVE_CONTEXT_MENU_TRIGGER_CLICKED:
      printf("Left Click\n");
      break;
    case NATIVE_CONTEXT_MENU_TRIGGER_RIGHT_CLICKED:
      printf("Right Click\n");
      break;
    case NATIVE_CONTEXT_MENU_TRIGGER_DOUBLE_CLICKED:
      printf("Double Click\n");
      break;
  }

  // Set up tray icon event listeners using new API
  native_tray_icon_add_listener(tray_icon, on_tray_event, NULL);

  // Show the tray icon
  if (native_tray_icon_set_visible(tray_icon, true)) {
    printf("Tray icon is now visible\n");
  } else {
    printf("Warning: Failed to show tray icon\n");
  }

  // Get tray icon bounds
  native_rectangle_t bounds = native_tray_icon_get_bounds(tray_icon);
  printf("Tray icon bounds: x=%.1f, y=%.1f, width=%.1f, height=%.1f\n", bounds.x, bounds.y,
         bounds.width, bounds.height);

  // Show all managed tray icons
  native_tray_icon_list_t tray_list = native_tray_manager_get_all();
  printf("Total managed tray icons: %ld\n", tray_list.count);
  native_tray_icon_list_free(&tray_list);

  printf("\n=== Tray icon and menu are now active ===\n");
  printf("- Click the tray icon to see click message\n");
  printf("- Right click the tray icon to auto-open context menu\n");
  printf("- Double click the tray icon to see double click message\n");
  printf("- Use menu items to interact with the application\n");
  printf("- Click 'Exit' to quit\n");
  printf("\nNote: Context menu automatically shows on right-click\n");
  printf("      because we set NATIVE_CONTEXT_MENU_TRIGGER_RIGHT_CLICKED.\n");
  printf("\nRunning... (Press Ctrl+C to force quit)\n");

  // Run the application event loop
  int exit_code = native_application_run();

  return exit_code;
}
