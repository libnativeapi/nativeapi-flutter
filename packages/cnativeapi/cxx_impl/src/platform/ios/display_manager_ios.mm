#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <string>
#include <vector>
#include "../../display_manager.h"

namespace nativeapi {

DisplayManager::DisplayManager() {
  // Prime the instance cache so the first change notification diffs against
  // the displays present at startup.
  GetAll();
}

DisplayManager::~DisplayManager() {}

std::vector<DisplayManager::NativeDisplayInfo> DisplayManager::EnumerateNativeDisplays() {
  std::vector<NativeDisplayInfo> natives;

  UIScreen* mainScreen = [UIScreen mainScreen];
  NSArray<UIScreen*>* screens = [UIScreen screens];
  for (UIScreen* screen in screens) {
    // A UIScreen object is stable for as long as the screen stays connected,
    // so its address serves as the identity key.
    natives.push_back({std::to_string(reinterpret_cast<uintptr_t>((__bridge void*)screen)),
                       (__bridge void*)screen, screen == mainScreen});
  }

  // If no screens found, add main screen
  if (natives.empty() && mainScreen) {
    natives.push_back({std::to_string(reinterpret_cast<uintptr_t>((__bridge void*)mainScreen)),
                       (__bridge void*)mainScreen, true});
  }

  return natives;
}

Point DisplayManager::GetCursorPosition() {
  // iOS doesn't have a cursor position concept
  return Point{0, 0};
}

}  // namespace nativeapi
