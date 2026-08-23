#include <nativeapi.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#include <windows.h>
#define SLEEP_MS(ms) Sleep(ms)
#else
#include <unistd.h>
#define SLEEP_MS(ms) usleep((ms) * 1000)
#endif

// Shortcut callback function
void on_shortcut_activated(void* user_data) {
  const char* name = (const char*)user_data;
  printf("Shortcut activated: %s\n", name);
}

// Event callback function
void on_shortcut_event(const native_shortcut_event_t* event, void* user_data) {
  (void)user_data;
  const char* event_type_name = "";

  switch (event->type) {
    case NATIVE_SHORTCUT_EVENT_TYPE_ACTIVATED:
      event_type_name = "ACTIVATED";
      break;
    case NATIVE_SHORTCUT_EVENT_TYPE_REGISTERED:
      event_type_name = "REGISTERED";
      break;
    case NATIVE_SHORTCUT_EVENT_TYPE_UNREGISTERED:
      event_type_name = "UNREGISTERED";
      break;
    case NATIVE_SHORTCUT_EVENT_TYPE_REGISTRATION_FAILED:
      event_type_name = "REGISTRATION_FAILED";
      if (event->data.registration_failed.error_message) {
        printf("Shortcut event: %s - %s (ID: %u) - Error: %s\n", event_type_name,
               event->accelerator, event->shortcut_id,
               event->data.registration_failed.error_message);
        return;
      }
      break;
  }

  printf("Shortcut event: %s - %s (ID: %u)\n", event_type_name, event->accelerator,
         event->shortcut_id);
}

int main(void) {
  printf("Shortcut Manager C API Example\n");
  printf("==============================\n\n");

  // Check if shortcuts are supported
  if (!native_shortcut_manager_is_supported()) {
    printf("Global shortcuts are not supported on this platform\n");
    return 1;
  }

  printf("Global shortcuts are supported\n\n");

  // Register event callback
  native_listener_id_t event_listener =
      native_shortcut_manager_add_listener(on_shortcut_event, NULL);
  if (event_listener == NATIVE_INVALID_LISTENER_ID) {
    printf("Failed to register event callback\n");
    return 1;
  }

  printf("Event callback registered (ID: %llu)\n\n", (unsigned long long)event_listener);

  // Register shortcuts
  printf("Registering shortcuts...\n");

  // Simple registration
  native_shortcut_t shortcut1 = native_shortcut_manager_register_with_accelerator_and_callback(
      "Ctrl+Shift+A", on_shortcut_activated, (void*)"Shortcut 1");

  if (shortcut1 == NATIVE_INVALID_SHORTCUT) {
    printf("Failed to register shortcut 1\n");
  } else {
    char* accel1 = native_shortcut_get_accelerator(shortcut1);
    printf("Registered shortcut 1: %s\n", accel1);
    free_c_str(accel1);
  }

  // Registration with options
  native_shortcut_options_t options = {0};
  options.accelerator = "Ctrl+Shift+B";
  options.description = "Test shortcut 2";
  options.scope = NATIVE_SHORTCUT_SCOPE_GLOBAL;
  options.enabled = true;
  options.callback = on_shortcut_activated;
  options.callback_user_data = (void*)"Shortcut 2";

  native_shortcut_t shortcut2 = native_shortcut_manager_register_with_options(options);

  if (shortcut2 == NATIVE_INVALID_SHORTCUT) {
    printf("Failed to register shortcut 2\n");
  } else {
    char* accel2 = native_shortcut_get_accelerator(shortcut2);
    char* desc2 = native_shortcut_get_description(shortcut2);
    printf("Registered shortcut 2: %s - %s\n", accel2, desc2);
    free_c_str(accel2);
    free_c_str(desc2);
  }

  // Register application-local shortcut
  options.accelerator = "Ctrl+Shift+C";
  options.description = "Application-local shortcut";
  options.scope = NATIVE_SHORTCUT_SCOPE_APPLICATION;
  options.callback_user_data = (void*)"Shortcut 3";

  native_shortcut_t shortcut3 = native_shortcut_manager_register_with_options(options);

  if (shortcut3 == NATIVE_INVALID_SHORTCUT) {
    printf("Failed to register shortcut 3\n");
  } else {
    char* accel3 = native_shortcut_get_accelerator(shortcut3);
    printf("Registered shortcut 3: %s (scope: %s)\n", accel3,
           native_shortcut_get_scope(shortcut3) == NATIVE_SHORTCUT_SCOPE_GLOBAL ? "Global"
                                                                                : "Application");
    free_c_str(accel3);
  }

  printf("\n");

  // Get all shortcuts
  native_shortcut_list_t all_shortcuts = native_shortcut_manager_get_all();
  printf("Total shortcuts registered: %ld\n", all_shortcuts.count);

  for (long i = 0; i < all_shortcuts.count; i++) {
    native_shortcut_t shortcut = all_shortcuts.shortcuts[i];
    char* accel = native_shortcut_get_accelerator(shortcut);
    printf("  - %s (ID: %u, enabled: %s)\n", accel, native_shortcut_get_id(shortcut),
           native_shortcut_is_enabled(shortcut) ? "yes" : "no");
    free_c_str(accel);
  }

  native_shortcut_list_free(&all_shortcuts);

  printf("\n");

  // Get shortcuts by scope
  native_shortcut_list_t global_shortcuts =
      native_shortcut_manager_get_by_scope(NATIVE_SHORTCUT_SCOPE_GLOBAL);
  printf("Global shortcuts: %ld\n", global_shortcuts.count);
  native_shortcut_list_free(&global_shortcuts);

  native_shortcut_list_t app_shortcuts =
      native_shortcut_manager_get_by_scope(NATIVE_SHORTCUT_SCOPE_APPLICATION);
  printf("Application shortcuts: %ld\n", app_shortcuts.count);
  native_shortcut_list_free(&app_shortcuts);

  printf("\n");

  // Test shortcut operations
  if (shortcut2 != NATIVE_INVALID_SHORTCUT) {
    printf("Testing shortcut operations on shortcut 2...\n");

    // Disable shortcut
    printf("Disabling shortcut 2...\n");
    native_shortcut_set_enabled(shortcut2, false);
    printf("Shortcut 2 enabled: %s\n", native_shortcut_is_enabled(shortcut2) ? "yes" : "no");

    // Re-enable shortcut
    printf("Re-enabling shortcut 2...\n");
    native_shortcut_set_enabled(shortcut2, true);
    printf("Shortcut 2 enabled: %s\n", native_shortcut_is_enabled(shortcut2) ? "yes" : "no");

    // Update description
    native_shortcut_set_description(shortcut2, "Updated description");
    char* updated_desc = native_shortcut_get_description(shortcut2);
    printf("Shortcut 2 description: %s\n", updated_desc);
    free_c_str(updated_desc);

    printf("\n");
  }

  // Test accelerator validation
  printf("Testing accelerator validation...\n");
  printf("Is 'Ctrl+Shift+D' valid? %s\n",
         native_shortcut_manager_is_valid_accelerator("Ctrl+Shift+D") ? "yes" : "no");
  printf("Is 'InvalidKey' valid? %s\n",
         native_shortcut_manager_is_valid_accelerator("InvalidKey") ? "yes" : "no");
  printf("Is 'Ctrl+Shift+A' available? %s\n",
         native_shortcut_manager_is_available("Ctrl+Shift+A") ? "yes" : "no");
  printf("Is 'Ctrl+Shift+Z' available? %s\n",
         native_shortcut_manager_is_available("Ctrl+Shift+Z") ? "yes" : "no");

  printf("\n");

  // Wait for shortcuts to be triggered
  printf("Press the registered shortcuts to test them:\n");
  printf("  - Ctrl+Shift+A (Shortcut 1)\n");
  printf("  - Ctrl+Shift+B (Shortcut 2)\n");
  printf("  - Ctrl+Shift+C (Shortcut 3 - application-local)\n");
  printf("\nPress Ctrl+C to exit...\n\n");

  // Keep the program running to receive shortcut events
  for (int i = 0; i < 60; i++) {
    SLEEP_MS(1000);
  }

  // Cleanup
  printf("\nCleaning up...\n");

  // Unregister shortcuts
  if (shortcut1 != NATIVE_INVALID_SHORTCUT) {
    native_shortcut_id_t id = native_shortcut_get_id(shortcut1);
    if (native_shortcut_manager_unregister_with_id(id)) {
      printf("Unregistered shortcut 1\n");
    }
  }

  if (shortcut2 != NATIVE_INVALID_SHORTCUT) {
    if (native_shortcut_manager_unregister_with_accelerator("Ctrl+Shift+B")) {
      printf("Unregistered shortcut 2\n");
    }
  }

  // Unregister all remaining shortcuts
  int count = native_shortcut_manager_unregister_all();
  printf("Unregistered %d remaining shortcuts\n", count);

  // Unregister event callback
  if (native_shortcut_manager_remove_listener(event_listener)) {
    printf("Event callback unregistered\n");
  }

  printf("\nDone!\n");
  return 0;
}
