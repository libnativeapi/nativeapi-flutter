#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "../../keyboard_monitor.h"

namespace nativeapi {

class KeyboardMonitor::Impl {
 public:
  Impl() {}
};

KeyboardMonitor::KeyboardMonitor() : impl_(std::make_unique<Impl>()) {}
KeyboardMonitor::~KeyboardMonitor() {}

void KeyboardMonitor::Start() {
  // iOS keyboard monitoring requires special permissions
  // Implementation would need accessibility services
}

void KeyboardMonitor::Stop() {
  // Stop monitoring
}

bool KeyboardMonitor::IsMonitoring() const {
  return false;
}

}  // namespace nativeapi
