#include "../../accessibility_manager.h"

#include <cstdlib>
#include <iostream>

// Import GTK headers for accessibility support
#include <glib.h>
#include <gtk/gtk.h>

namespace nativeapi {

void AccessibilityManager::Enable() {
  // On Linux, accessibility is primarily handled by AT-SPI (Assistive
  // Technology Service Provider Interface) Applications typically don't need to
  // explicitly "enable" accessibility - it's handled by the system However, we
  // can ensure GTK accessibility features are available

  // Initialize GTK if not already initialized (for accessibility bridge)
  if (!gdk_display_get_default()) {
    // Try to initialize GTK silently if not already done
    gtk_init_check(nullptr, nullptr);
  }

  // The accessibility bridge in GTK is automatically enabled when accessibility
  // is needed No explicit action needed - this is a no-op on Linux as
  // accessibility is system-managed
}

bool AccessibilityManager::IsEnabled() {
  // Check if accessibility features are enabled on the Linux system

  // Method 1: Check if AT-SPI accessibility bus is running
  // This is the most reliable way to detect if accessibility is active
  const char* at_spi_bus = g_getenv("AT_SPI_BUS");
  if (at_spi_bus && strlen(at_spi_bus) > 0) {
    return true;
  }

  // Method 2: Check for common accessibility environment variables
  const char* accessibility_enabled = g_getenv("GNOME_ACCESSIBILITY");
  if (accessibility_enabled && g_ascii_strcasecmp(accessibility_enabled, "1") == 0) {
    return true;
  }

  // Method 3: Check if screen reader (Orca) is running
  // This is a fallback method for older systems
  if (system("pgrep -x orca > /dev/null 2>&1") == 0) {
    return true;
  }

  // Method 4: Check GTK accessibility settings if available
  // Some desktop environments set this when accessibility is enabled
  const char* gtk_modules = g_getenv("GTK_MODULES");
  if (gtk_modules && strstr(gtk_modules, "gail") != nullptr) {
    return true;
  }

  // If none of the above methods detect accessibility, assume it's disabled
  return false;
}

}  // namespace nativeapi