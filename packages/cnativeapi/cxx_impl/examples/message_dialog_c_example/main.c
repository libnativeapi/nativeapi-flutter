#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../../src/capi/message_dialog_c.h"
#include "../../src/capi/string_utils_c.h"

int main() {
  printf("=== MessageDialog C API Example ===\n\n");

  // Example 1: Create a simple informational dialog
  printf("1. Creating a simple informational dialog...\n");
  native_message_dialog_t info_dialog = native_message_dialog_create(
      "Information",
      "This is an informational message dialog.\n\n"
      "MessageDialog can be used to display various types of messages to users.");

  if (info_dialog == NATIVE_INVALID_MESSAGE_DIALOG) {
    fprintf(stderr, "Failed to create informational dialog\n");
    return 1;
  }

  // Get and print dialog properties
  char* title = native_message_dialog_get_title(info_dialog);
  char* message = native_message_dialog_get_message(info_dialog);
  if (title) {
    printf("Dialog title: %s\n", title);
    free_c_str(title);
  }
  if (message) {
    printf("Dialog message: %s\n", message);
    free_c_str(message);
  }

  // Set modality to Application modal
  native_message_dialog_set_modality(info_dialog, NATIVE_DIALOG_MODALITY_APPLICATION);
  native_dialog_modality_t modality = native_message_dialog_get_modality(info_dialog);
  printf("Modality: %s\n",
         modality == NATIVE_DIALOG_MODALITY_APPLICATION ? "Application" : "Unknown");

  printf("Opening dialog...\n");
  if (native_message_dialog_open(info_dialog)) {
    printf("Dialog was opened successfully\n\n");
  } else {
    printf("Failed to open dialog\n\n");
  }

  // Clean up first dialog
  native_message_dialog_free(info_dialog);

  // Example 2: Create a warning dialog
  printf("2. Creating a warning dialog...\n");
  native_message_dialog_t warning_dialog = native_message_dialog_create(
      "Warning",
      "This is a warning message.\n\n"
      "Warning dialogs are used to alert users about potential issues.");

  if (warning_dialog != NATIVE_INVALID_MESSAGE_DIALOG) {
    native_message_dialog_set_modality(warning_dialog, NATIVE_DIALOG_MODALITY_APPLICATION);
    native_message_dialog_open(warning_dialog);
    native_message_dialog_free(warning_dialog);
  }
  printf("\n");

  // Example 3: Create a dialog with updated content
  printf("3. Creating a dialog with updated content...\n");
  native_message_dialog_t dynamic_dialog =
      native_message_dialog_create("Update Available", "Initial message");

  if (dynamic_dialog != NATIVE_INVALID_MESSAGE_DIALOG) {
    // Update the title and message before opening
    native_message_dialog_set_title(dynamic_dialog, "System Update");
    native_message_dialog_set_message(dynamic_dialog,
                                      "A new version of the application is available.\n\n"
                                      "Version 2.0 includes:\n"
                                      "• Improved performance\n"
                                      "• New features\n"
                                      "• Bug fixes\n\n"
                                      "Would you like to update now?");

    title = native_message_dialog_get_title(dynamic_dialog);
    if (title) {
      printf("Updated title: %s\n", title);
      free_c_str(title);
    }

    native_message_dialog_set_modality(dynamic_dialog, NATIVE_DIALOG_MODALITY_APPLICATION);
    printf("Opening updated dialog...\n");
    native_message_dialog_open(dynamic_dialog);
    native_message_dialog_free(dynamic_dialog);
  }
  printf("\n");

  // Example 4: Demonstrate different modality types
  printf("4. Demonstrating different modality types...\n");

  // Non-modal dialog
  native_message_dialog_t non_modal_dialog = native_message_dialog_create(
      "Non-Modal Dialog",
      "This dialog does not block interaction.\n\n"
      "The application continues running and users can interact with other windows.");
  if (non_modal_dialog != NATIVE_INVALID_MESSAGE_DIALOG) {
    native_message_dialog_set_modality(non_modal_dialog, NATIVE_DIALOG_MODALITY_NONE);
    modality = native_message_dialog_get_modality(non_modal_dialog);
    printf("Modality: %s (non-modal)\n",
           modality == NATIVE_DIALOG_MODALITY_NONE ? "None" : "Unknown");
    native_message_dialog_open(non_modal_dialog);
    native_message_dialog_free(non_modal_dialog);
  }

  // Application modal dialog
  native_message_dialog_t app_modal_dialog = native_message_dialog_create(
      "Application Modal",
      "This dialog blocks interaction with all windows in the current application.");
  if (app_modal_dialog != NATIVE_INVALID_MESSAGE_DIALOG) {
    native_message_dialog_set_modality(app_modal_dialog, NATIVE_DIALOG_MODALITY_APPLICATION);
    modality = native_message_dialog_get_modality(app_modal_dialog);
    printf("Modality: %s\n",
           modality == NATIVE_DIALOG_MODALITY_APPLICATION ? "Application" : "Unknown");
    native_message_dialog_open(app_modal_dialog);
    native_message_dialog_free(app_modal_dialog);
  }

  // Window modal dialog (behaves as Application on macOS)
  native_message_dialog_t window_modal_dialog = native_message_dialog_create(
      "Window Modal",
      "This dialog blocks interaction with a specific parent window.\n\n"
      "Note: On macOS, this behaves as Application.");
  if (window_modal_dialog != NATIVE_INVALID_MESSAGE_DIALOG) {
    native_message_dialog_set_modality(window_modal_dialog, NATIVE_DIALOG_MODALITY_WINDOW);
    modality = native_message_dialog_get_modality(window_modal_dialog);
    printf("Modality: %s\n", modality == NATIVE_DIALOG_MODALITY_WINDOW ? "Window" : "Unknown");
    native_message_dialog_open(window_modal_dialog);
    native_message_dialog_free(window_modal_dialog);
  }

  printf("\n=== MessageDialog C API Example Complete ===\n");
  printf("This example demonstrated:\n");
  printf("1. Creating MessageDialog instances\n");
  printf("2. Setting and getting title and message\n");
  printf("3. Updating dialog content programmatically\n");
  printf("4. Opening dialogs with different modality types (None, Application, Window)\n");
  printf("5. Modal vs non-modal dialog behavior\n");
  printf("6. Proper cleanup of dialog resources\n");

  printf("\nExiting MessageDialog C API Example...\n");
  return 0;
}
