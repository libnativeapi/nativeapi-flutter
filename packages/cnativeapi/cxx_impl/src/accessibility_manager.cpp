#include "accessibility_manager.h"

namespace nativeapi {

AccessibilityManager& AccessibilityManager::GetInstance() {
  static AccessibilityManager instance;
  return instance;
}

AccessibilityManager::AccessibilityManager() : enabled_(false) {}

AccessibilityManager::~AccessibilityManager() {}

}  // namespace nativeapi
