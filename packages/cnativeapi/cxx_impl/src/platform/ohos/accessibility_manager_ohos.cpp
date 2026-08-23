#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <iostream>
#include "../../accessibility_manager.h"

#ifdef __OHOS__
#define HILOG_WARN(...) HILOG_WARN(LOG_CORE, LOG_TAG, __VA_ARGS__)
#else
#define HILOG_WARN(...) std::cerr << "[WARN] " << __VA_ARGS__ << std::endl
#endif

namespace nativeapi {

void AccessibilityManager::Enable() {
  enabled_ = true;
}

bool AccessibilityManager::IsEnabled() {
  return enabled_;
}

}  // namespace nativeapi
