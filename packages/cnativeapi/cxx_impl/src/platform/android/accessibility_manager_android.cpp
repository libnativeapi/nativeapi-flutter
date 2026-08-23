#include "../../accessibility_manager.h"

namespace nativeapi {

void AccessibilityManager::Enable() {
  // On Android, accessibility features are controlled by system settings
  enabled_ = true;
}

bool AccessibilityManager::IsEnabled() {
  // On Android, accessibility features are controlled by system settings
  return enabled_;
}

}  // namespace nativeapi
