#include <nativeapi.h>
#include <stdio.h>
#include <stdlib.h>

int main(void) {
  printf("LaunchAtLogin C API Example\n");
  printf("=======================\n\n");

  /* Check if launch-at-login is supported on this platform */
  if (!native_launch_at_login_is_supported()) {
    printf("LaunchAtLogin is not supported on this platform.\n");
    return 0;
  }

  printf("LaunchAtLogin is supported on this platform.\n\n");

#if defined(__APPLE__)
  /*
   * On macOS, the default constructor registers the main app with SMAppService.
   * Custom identifiers are for bundled login item helpers.
   */
  native_launch_at_login_t launch_at_login = native_launch_at_login_create();
#else
  /* Create a LaunchAtLogin manager with a custom identifier and display name */
  native_launch_at_login_t launch_at_login =
      native_launch_at_login_create_with_id_and_display_name("com.example.myapp.c",
                                                             "My C Example App");
#endif
  if (launch_at_login == NATIVE_INVALID_LAUNCH_AT_LOGIN) {
    printf("Failed to create LaunchAtLogin instance.\n");
    return 1;
  }

  /* Display current configuration */
  char* id = native_launch_at_login_get_id(launch_at_login);
  char* display_name = native_launch_at_login_get_display_name(launch_at_login);
  char* executable = native_launch_at_login_get_executable_path(launch_at_login);

  printf("LaunchAtLogin configuration:\n");
  printf("  ID:           %s\n", id ? id : "(null)");
  printf("  Display name: %s\n", display_name ? display_name : "(null)");
  printf("  Executable:   %s\n\n", executable ? executable : "(null)");

  free_c_str(id);
  free_c_str(display_name);

#if !defined(__APPLE__)
  /* Set a custom program path and arguments */
  char* argument_items[] = {"--minimized", "--launch_at_login"};
  native_string_list_t arguments = {argument_items, 2};
  native_launch_at_login_set_program(launch_at_login, executable ? executable : "", arguments);
#endif
  free_c_str(executable);

  /* Retrieve and display the updated executable path */
  char* exec_path = native_launch_at_login_get_executable_path(launch_at_login);
  printf("After SetProgram:\n");
  printf("  Executable: %s\n", exec_path ? exec_path : "(null)");
#if defined(__APPLE__)
  printf("  Arguments:  (not supported by macOS SMAppService main-app login items)\n\n");
#else
  printf("  Arguments:  --minimized --launch_at_login\n\n");
#endif
  free_c_str(exec_path);

  /* Check current state before enabling */
  printf("Is enabled (before Enable): %s\n",
         native_launch_at_login_is_enabled(launch_at_login) ? "yes" : "no");

  /* Enable launch-at-login */
  printf("Enabling launch-at-login...\n");
  if (native_launch_at_login_enable(launch_at_login)) {
    printf("Launch-at-login enabled successfully.\n");
  } else {
    printf("Failed to enable launch-at-login.\n");
    native_launch_at_login_free(launch_at_login);
    return 1;
  }

  /* Verify it is now enabled */
  printf("Is enabled (after Enable):  %s\n\n",
         native_launch_at_login_is_enabled(launch_at_login) ? "yes" : "no");

  /* Update the display name and re-enable to update the stored entry */
  native_launch_at_login_set_display_name(launch_at_login, "My C Example App (Updated)");
  char* updated_name = native_launch_at_login_get_display_name(launch_at_login);
  printf("Updated display name to: %s\n", updated_name ? updated_name : "(null)");
  free_c_str(updated_name);
  native_launch_at_login_enable(launch_at_login);

  /* Disable launch-at-login */
  printf("\nDisabling launch-at-login...\n");
  if (native_launch_at_login_disable(launch_at_login)) {
    printf("Launch-at-login disabled successfully.\n");
  } else {
    printf("Failed to disable launch-at-login.\n");
    native_launch_at_login_free(launch_at_login);
    return 1;
  }

  /* Verify it is now disabled */
  printf("Is enabled (after Disable): %s\n\n",
         native_launch_at_login_is_enabled(launch_at_login) ? "yes" : "no");

  /* Clean up */
  native_launch_at_login_free(launch_at_login);

  printf("Example completed successfully!\n\n");
  printf("This example demonstrated:\n");
  printf("  * native_launch_at_login_is_supported()              - Check platform support\n");
  printf("  * native_launch_at_login_create_with_id_and_display_name() - Create with ID and name\n");
  printf("  * native_launch_at_login_get_id()                    - Get identifier\n");
  printf("  * native_launch_at_login_get_display_name()          - Get display name\n");
  printf("  * native_launch_at_login_set_display_name()          - Update display name\n");
  printf("  * native_launch_at_login_set_program()               - Set executable and arguments\n");
  printf("  * native_launch_at_login_get_executable_path()       - Get configured executable\n");
  printf(
      "  * native_launch_at_login_enable()                    - Register launch-at-login with the "
      "OS\n");
  printf(
      "  * native_launch_at_login_disable()                   - Remove launch-at-login from the "
      "OS\n");
  printf(
      "  * native_launch_at_login_is_enabled()                - Query current registration "
      "state\n");
  printf("  * native_launch_at_login_free()                   - Free resources\n");

  return 0;
}
