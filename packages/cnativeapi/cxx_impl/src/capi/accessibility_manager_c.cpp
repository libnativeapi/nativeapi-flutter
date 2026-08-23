// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "accessibility_manager_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../accessibility_manager.h"

void native_accessibility_manager_enable(void) {
  try {
    nativeapi::AccessibilityManager::GetInstance().Enable();
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_accessibility_manager_enable");
    return;
  }
}

bool native_accessibility_manager_is_enabled(void) {
  try {
    return nativeapi::AccessibilityManager::GetInstance().IsEnabled();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_accessibility_manager_is_enabled");
    return false;
  }
}

