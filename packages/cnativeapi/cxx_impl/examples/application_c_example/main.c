#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "nativeapi.h"

void on_application_event(const native_application_event_t* event, void* user_data) {
  (void)user_data;
  switch (event->type) {
    case NATIVE_APPLICATION_EVENT_TYPE_STARTED:
      printf("Application started event received\n");
      break;
    case NATIVE_APPLICATION_EVENT_TYPE_EXITING:
      printf("Application exiting event received with exit code: %d\n",
             event->data.exiting.exit_code);
      break;
    case NATIVE_APPLICATION_EVENT_TYPE_ACTIVATED:
      printf("Application activated event received\n");
      break;
    case NATIVE_APPLICATION_EVENT_TYPE_DEACTIVATED:
      printf("Application deactivated event received\n");
      break;
    case NATIVE_APPLICATION_EVENT_TYPE_QUIT_REQUESTED:
      printf("Application quit requested event received\n");
      break;
    default:
      printf("Unknown application event type: %d\n", event->type);
      break;
  }
}

int main() {
  printf("Application C API Example\n");

  // Application is a singleton on the C++ side, so its C functions take no
  // receiver argument.
  printf("Single instance: %s\n", native_application_is_single_instance() ? "Yes" : "No");

  native_listener_id_t listener_id = native_application_add_listener(on_application_event, NULL);
  if (listener_id == NATIVE_INVALID_LISTENER_ID) {
    fprintf(stderr, "Failed to add event listener\n");
    return 1;
  }

  // Create a simple window with default settings
  native_window_t window = native_window_create();
  if (window == NATIVE_INVALID_WINDOW) {
    fprintf(stderr, "Failed to create window\n");
    return 1;
  }

  // Configure the window
  native_window_set_title(window, "Application C Example Window");
  native_size_t size = {400.0, 300.0};
  native_window_set_size(window, size, false);

  printf("Window created successfully\n");
  printf("Window ID: %u\n", native_window_get_id(window));

  // Show the window
  native_window_show(window);

  printf("Starting application event loop...\n");
  printf("Press Ctrl+C to quit\n");

  int exit_code = native_application_run();

  printf("Application exited with code: %d\n", exit_code);

  native_application_remove_listener(listener_id);
  native_window_free(window);

  return exit_code;
}
