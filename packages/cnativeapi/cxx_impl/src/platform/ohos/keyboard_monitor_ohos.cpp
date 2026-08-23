#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <memory>
#include "../../keyboard_monitor.h"

#ifdef __OHOS__
#define LOG_CORE 0xD001700
// Note: LOG_TAG is defined in hilog/log.h as NULL,
// redefine to avoid warnings if needed
#undef LOG_TAG
#define LOG_TAG "NativeApi"
#endif

namespace nativeapi {

class KeyboardMonitor::Impl {
 public:
  Impl(KeyboardMonitor* monitor) : monitor_(monitor) {}

  KeyboardMonitor* monitor_;
};

KeyboardMonitor::KeyboardMonitor() : impl_(std::make_unique<Impl>(this)) {}

KeyboardMonitor::~KeyboardMonitor() {
  Stop();
}

void KeyboardMonitor::Start() {
  // Not implemented on OpenHarmony yet
}

void KeyboardMonitor::Stop() {
  // Not implemented on OpenHarmony yet
}

bool KeyboardMonitor::IsMonitoring() const {
  return false;
}

EventEmitter<KeyboardEvent>& KeyboardMonitor::GetInternalEventEmitter() {
  return *this;
}

}  // namespace nativeapi
