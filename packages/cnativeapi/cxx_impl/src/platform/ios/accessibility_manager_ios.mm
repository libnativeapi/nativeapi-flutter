#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "../../accessibility_manager.h"

namespace nativeapi {

void AccessibilityManager::Enable() {
  // On iOS, accessibility features are controlled by system settings
  // This method sets the internal flag
  enabled_ = true;
}

bool AccessibilityManager::IsEnabled() {
  // Return the internal enabled state
  return enabled_;
}

}  // namespace nativeapi
