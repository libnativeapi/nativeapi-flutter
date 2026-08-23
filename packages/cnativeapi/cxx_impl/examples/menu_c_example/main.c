#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../../src/capi/application_c.h"
#include "../../src/capi/menu_c.h"
#include "../../src/capi/positioning_strategy_c.h"

// Event callback functions
//
// A menu or menu item emits one MenuEvent stream, tagged by concrete type, so
// a single listener covers clicks and submenu open/close alike.
void on_menu_event(const native_menu_event_t* event, void* user_data) {
  const char* name = (const char*)user_data;
  switch (event->type) {
    case NATIVE_MENU_EVENT_TYPE_ITEM_CLICKED:
      printf("[EVENT] Menu item clicked: %s (ID: %u)\n", name, event->data.item_clicked.item_id);
      break;
    case NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_OPENED:
      printf("[EVENT] Menu item submenu opened: %s (ID: %u)\n", name,
             event->data.item_submenu_opened.item_id);
      break;
    case NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_CLOSED:
      printf("[EVENT] Menu item submenu closed: %s (ID: %u)\n", name,
             event->data.item_submenu_closed.item_id);
      break;
    case NATIVE_MENU_EVENT_TYPE_OPENED:
      printf("[EVENT] Menu opened: %s (ID: %u)\n", name, event->data.opened.menu_id);
      break;
    case NATIVE_MENU_EVENT_TYPE_CLOSED:
      printf("[EVENT] Menu closed: %s (ID: %u)\n", name, event->data.closed.menu_id);
      break;
  }
}

int main() {
  printf("=== Menu C API Event System Example ===\n");

  // Create a menu
  native_menu_t menu = native_menu_create();
  if (menu == NATIVE_INVALID_MENU) {
    printf("Failed to create menu\n");
    return 1;
  }

  printf("Created menu successfully\n");

  // Create menu items
  native_menu_item_t file_item = native_menu_item_create_with_label_and_type("New File", NATIVE_MENU_ITEM_TYPE_NORMAL);
  native_menu_item_t checkbox_item =
      native_menu_item_create_with_label_and_type("Word Wrap", NATIVE_MENU_ITEM_TYPE_CHECKBOX);
  native_menu_item_t radio_item1 =
      native_menu_item_create_with_label_and_type("View Mode 1", NATIVE_MENU_ITEM_TYPE_RADIO);
  native_menu_item_t radio_item2 =
      native_menu_item_create_with_label_and_type("View Mode 2", NATIVE_MENU_ITEM_TYPE_RADIO);
  native_menu_item_t exit_item = native_menu_item_create_with_label_and_type("Exit", NATIVE_MENU_ITEM_TYPE_NORMAL);

  if (file_item == NATIVE_INVALID_MENU_ITEM || checkbox_item == NATIVE_INVALID_MENU_ITEM ||
      radio_item1 == NATIVE_INVALID_MENU_ITEM || radio_item2 == NATIVE_INVALID_MENU_ITEM ||
      exit_item == NATIVE_INVALID_MENU_ITEM) {
    printf("Failed to create menu items\n");
    native_menu_free(menu);
    return 1;
  }

  // Set up radio group
  native_menu_item_set_radio_group(radio_item1, 1);
  native_menu_item_set_radio_group(radio_item2, 1);
  native_menu_item_set_state(radio_item1, NATIVE_MENU_ITEM_STATE_CHECKED);

  // Set keyboard accelerators
  native_keyboard_accelerator_t ctrl_n = {NATIVE_MODIFIER_KEY_CTRL, "N"};
  native_keyboard_accelerator_t ctrl_q = {NATIVE_MODIFIER_KEY_CTRL, "Q"};
  native_menu_item_set_accelerator(file_item, &ctrl_n);
  native_menu_item_set_accelerator(exit_item, &ctrl_q);

  printf("Setting up event listeners using new event system...\n");

  // Add event listeners using the new event system
  native_listener_id_t file_listener =
      native_menu_item_add_listener(file_item, on_menu_event, (void*)"New File");

  native_listener_id_t checkbox_listener =
      native_menu_item_add_listener(checkbox_item, on_menu_event, (void*)"Word Wrap");

  native_listener_id_t exit_listener =
      native_menu_item_add_listener(exit_item, on_menu_event, (void*)"Exit");

  // Add menu event listeners
  native_listener_id_t menu_listener =
      native_menu_add_listener(menu, on_menu_event, (void*)"Main Menu");

  // Check if listeners were added successfully
  if (file_listener == NATIVE_INVALID_LISTENER_ID ||
      checkbox_listener == NATIVE_INVALID_LISTENER_ID ||
      exit_listener == NATIVE_INVALID_LISTENER_ID || menu_listener == NATIVE_INVALID_LISTENER_ID) {
    printf("Failed to add some event listeners\n");
  } else {
    printf("All event listeners added successfully\n");
    printf("Listener IDs: file=%llu, checkbox=%llu, exit=%llu, menu=%llu\n",
           (unsigned long long)file_listener, (unsigned long long)checkbox_listener,
           (unsigned long long)exit_listener, (unsigned long long)menu_listener);
  }

  // Add items to menu
  native_menu_add_item(menu, file_item);
  native_menu_add_separator(menu);
  native_menu_add_item(menu, checkbox_item);
  native_menu_add_separator(menu);
  native_menu_add_item(menu, radio_item1);
  native_menu_add_item(menu, radio_item2);
  native_menu_add_separator(menu);
  native_menu_add_item(menu, exit_item);

  printf("Menu created with %lu items\n", native_menu_get_item_count(menu));

  // Add submenu to demonstrate submenu events
  native_menu_t submenu = native_menu_create();
  native_menu_item_t submenu_item1 =
      native_menu_item_create_with_label_and_type("Submenu Item 1", NATIVE_MENU_ITEM_TYPE_NORMAL);
  native_menu_item_t submenu_item2 =
      native_menu_item_create_with_label_and_type("Submenu Item 2", NATIVE_MENU_ITEM_TYPE_NORMAL);

  native_menu_add_item(submenu, submenu_item1);
  native_menu_add_item(submenu, submenu_item2);

  native_menu_item_t submenu_parent =
      native_menu_item_create_with_label_and_type("Tools", NATIVE_MENU_ITEM_TYPE_SUBMENU);
  native_menu_item_set_submenu(submenu_parent, submenu);
  native_menu_add_item(menu, submenu_parent);

  // Add submenu event listener
  native_menu_item_add_listener(submenu_parent, on_menu_event, (void*)"Tools");

  printf("Added submenu with %lu items\n", native_menu_get_item_count(submenu));

  // Note: Programmatic event triggering is no longer available via trigger API.
  // Events can only be triggered through actual user interaction.
  printf("\n=== Programmatic Event Triggering Removed ===\n");
  printf(
      "Note: The trigger API has been removed. Events are now only "
      "triggered through user interaction.\n");

  // Demonstrate listener removal
  printf("\n=== Testing Listener Removal ===\n");

  printf("Removing checkbox click listener...\n");
  if (native_menu_item_remove_listener(checkbox_item, checkbox_listener)) {
    printf("Checkbox click listener removed successfully\n");
  } else {
    printf("Failed to remove checkbox click listener\n");
  }

  printf(
      "Checkbox item listener removed. Events will now only be triggered "
      "through user interaction.\n");

  // Open menu as context menu (this may not work in console applications)
  printf("\n=== Attempting to Open Context Menu ===\n");
  printf("Note: Context menu display may not work in console applications\n");

  native_point_t point = {100, 100};
  native_positioning_strategy_t strategy = native_positioning_strategy_absolute(point);
  if (native_menu_open(menu, strategy, NATIVE_PLACEMENT_BOTTOM_START)) {
    printf("Context menu opened successfully (BOTTOM_START placement)\n");
  } else {
    printf("Failed to open context menu (expected in console app)\n");
  }
  native_positioning_strategy_free(strategy);

  // Test additional functionality
  printf("\n=== Testing Additional Functionality ===\n");

  native_menu_item_t additional_item =
      native_menu_item_create_with_label_and_type("Additional Test", NATIVE_MENU_ITEM_TYPE_NORMAL);

  // Test that we can add multiple listeners for the same event
  native_listener_id_t additional_listener1 =
      native_menu_item_add_listener(additional_item, on_menu_event, (void*)"Additional Test 1");
  native_listener_id_t additional_listener2 =
      native_menu_item_add_listener(additional_item, on_menu_event, (void*)"Additional Test 2");
  (void)additional_listener2;

  printf("Added multiple listeners for the same event\n");
  printf("Multiple listeners can be registered for the same event type.\n");

  // Remove one listener
  native_menu_item_remove_listener(additional_item, additional_listener1);
  printf("Removed first listener. Remaining listener will receive events.\n");

  native_menu_item_free(additional_item);

  printf("\n=== Event System Demo Complete ===\n");
  printf("This example demonstrates:\n");
  printf("1. Creating menus and menu items with different types\n");
  printf(
      "2. Using the new event listener API with "
      "native_menu_item_add_listener()\n");
  printf("3. Handling NATIVE_MENU_EVENT_TYPE_ITEM_CLICKED\n");
  printf("4. Handling NATIVE_MENU_EVENT_TYPE_OPENED and NATIVE_MENU_EVENT_TYPE_CLOSED\n");
  printf(
      "5. Handling NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_OPENED and "
      "NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_CLOSED\n");
  printf("6. Event listener removal with native_menu_item_remove_listener()\n");
  printf("7. Multiple listeners for the same event type\n");
  printf("8. Manual state management for checkbox and radio items\n");
  printf("9. Submenu support with event handling\n");

  // Cleanup
  native_menu_item_free(file_item);
  native_menu_item_free(checkbox_item);
  native_menu_item_free(radio_item1);
  native_menu_item_free(radio_item2);
  native_menu_item_free(exit_item);
  native_menu_item_free(submenu_item1);
  native_menu_item_free(submenu_item2);
  native_menu_item_free(submenu_parent);
  native_menu_free(submenu);
  native_menu_free(menu);

  return 0;
}
