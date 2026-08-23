#include <stdio.h>
#include <stdlib.h>

// Include only C API headers
#include "../../src/capi/display_c.h"
#include "../../src/capi/display_manager_c.h"
#include "../../src/capi/geometry_c.h"
#include "../../src/capi/string_utils_c.h"

int main() {
  printf("=== Native API C Display Example ===\n\n");

  // Test getting all displays
  native_display_list_t display_list = native_display_manager_get_all();

  if (display_list.displays != NULL && display_list.count > 0) {
    printf("Found %ld display(s):\n\n", display_list.count);

    for (size_t i = 0; i < display_list.count; i++) {
      native_display_t display = display_list.displays[i];

      printf("Display %zu:\n", i + 1);

      // Use getter functions for all properties
      char* name = native_display_get_name(display);
      printf("  Name: %s\n", name ? name : "Unknown");
      free_c_str(name);

      native_display_id_t id = native_display_get_id(display);
      printf("  ID: %u\n", id);

      native_point_t position = native_display_get_position(display);
      printf("  Position: (%.0f, %.0f)\n", position.x, position.y);

      native_size_t size = native_display_get_size(display);
      printf("  Size: %.0f x %.0f\n", size.width, size.height);

      native_rectangle_t work_area = native_display_get_work_area(display);
      printf("  Work Area: (%.0f, %.0f) %.0f x %.0f\n", work_area.x, work_area.y, work_area.width,
             work_area.height);

      double scale_factor = native_display_get_scale_factor(display);
      printf("  Scale Factor: %.2f\n", scale_factor);

      bool is_primary = native_display_is_primary(display);
      printf("  Primary: %s\n", is_primary ? "Yes" : "No");

      // Display orientation
      printf("  Orientation: ");
      native_display_orientation_t orientation = native_display_get_orientation(display);
      switch (orientation) {
        case NATIVE_DISPLAY_ORIENTATION_PORTRAIT:
          printf("Portrait (0°)");
          break;
        case NATIVE_DISPLAY_ORIENTATION_LANDSCAPE:
          printf("Landscape (90°)");
          break;
        case NATIVE_DISPLAY_ORIENTATION_PORTRAIT_FLIPPED:
          printf("Portrait Flipped (180°)");
          break;
        case NATIVE_DISPLAY_ORIENTATION_LANDSCAPE_FLIPPED:
          printf("Landscape Flipped (270°)");
          break;
        default:
          printf("Unknown");
          break;
      }
      printf("\n");

      int refresh_rate = native_display_get_refresh_rate(display);
      printf("  Refresh Rate: %d Hz\n", refresh_rate);

      int bit_depth = native_display_get_bit_depth(display);
      printf("  Bit Depth: %d bits\n", bit_depth);

      printf("\n");
    }

    // Clean up memory
    native_display_list_free(&display_list);
  } else {
    printf("No displays found or error occurred\n");
  }

  // Test getting primary display
  printf("=== Primary Display ===\n");
  native_display_t primary = native_display_manager_get_primary();
  if (primary) {
    char* name = native_display_get_name(primary);
    printf("Primary display: %s\n", name ? name : "Unknown");
    free_c_str(name);

    native_size_t size = native_display_get_size(primary);
    printf("Size: %.0f x %.0f\n", size.width, size.height);

    // Free the primary display handle
    native_display_free(primary);
  } else {
    printf("Failed to get primary display\n");
  }

  // Test getting cursor position
  printf("\n=== Cursor Position ===\n");
  native_point_t cursor_pos = native_display_manager_get_cursor_position();
  printf("Cursor position: (%.0f, %.0f)\n", cursor_pos.x, cursor_pos.y);

  return 0;
}
