#include <string.h>
#include <iostream>

#include "accessibility_manager.h"
#include "libnativeapi/include/nativeapi.h"

using namespace nativeapi;

static AccessibilityManager g_accessibility_manager = AccessibilityManager();

FFI_PLUGIN_EXPORT
void accessibility_manager_enable() {
  g_accessibility_manager.Enable();
}

FFI_PLUGIN_EXPORT
bool accessibility_manager_is_enabled() {
  return g_accessibility_manager.IsEnabled();
}
