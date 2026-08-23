#import <Cocoa/Cocoa.h>

#include "../../accessibility_manager.h"

namespace nativeapi {

void AccessibilityManager::Enable() {
  NSDictionary* options = @{(__bridge NSString*)kAXTrustedCheckOptionPrompt : @YES};
  AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
}

bool AccessibilityManager::IsEnabled() {
  return AXIsProcessTrustedWithOptions(nil);
}

}  // namespace nativeapi
