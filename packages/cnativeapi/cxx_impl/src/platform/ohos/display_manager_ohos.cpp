#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <iostream>
#include "../../display_manager.h"

// Temporarily disable logging to avoid macro conflicts
#define HILOG_WARN(...) ((void)0)

namespace nativeapi {

DisplayManager::DisplayManager() {}

DisplayManager::~DisplayManager() {}

std::vector<DisplayManager::NativeDisplayInfo> DisplayManager::EnumerateNativeDisplays() {
  // Stub: a single default display.
  return {{"primary", nullptr, true}};
}

Point DisplayManager::GetCursorPosition() {
  return Point{0, 0};
}

}  // namespace nativeapi
