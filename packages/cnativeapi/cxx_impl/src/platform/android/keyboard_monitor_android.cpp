#include <android/log.h>
#include "../../keyboard_monitor.h"

#define LOG_TAG "NativeApi"
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

namespace nativeapi {

class KeyboardMonitor::Impl {
 public:
  Impl(KeyboardMonitor* monitor) : monitor_(monitor) {}
  KeyboardMonitor* monitor_;
};

KeyboardMonitor::KeyboardMonitor() : impl_(std::make_unique<Impl>(this)) {}
KeyboardMonitor::~KeyboardMonitor() {}

void KeyboardMonitor::Start() {
  ALOGW("KeyboardMonitor::Start requires AccessibilityService on Android");
}

void KeyboardMonitor::Stop() {
  ALOGW("KeyboardMonitor::Stop stops monitoring");
}

bool KeyboardMonitor::IsMonitoring() const {
  return false;
}

EventEmitter<KeyboardEvent>& KeyboardMonitor::GetInternalEventEmitter() {
  return *this;
}

}  // namespace nativeapi
