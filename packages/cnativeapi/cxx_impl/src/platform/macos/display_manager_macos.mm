#include <string>
#include <vector>

#include "../../display.h"
#include "../../display_manager.h"
#include "coordinate_utils_macos.h"

// Import Cocoa and Core Graphics headers
#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

namespace nativeapi {

id displayObserver_;

DisplayManager::DisplayManager() {
  // Prime the instance cache so the first change notification diffs against
  // the displays present at startup.
  GetAll();
  // Set up display configuration change observer
  displayObserver_ = [[NSNotificationCenter defaultCenter]
      addObserverForName:NSApplicationDidChangeScreenParametersNotification
                  object:nil
                   queue:[NSOperationQueue mainQueue]
              usingBlock:^(NSNotification* notification) {
                HandleDisplaysChanged();
              }];
}

DisplayManager::~DisplayManager() {
  if (displayObserver_) {
    [[NSNotificationCenter defaultCenter] removeObserver:displayObserver_];
  }
}

std::vector<DisplayManager::NativeDisplayInfo> DisplayManager::EnumerateNativeDisplays() {
  std::vector<NativeDisplayInfo> natives;
  NSArray<NSScreen*>* screens = [NSScreen screens];
  bool isPrimary = true;  // Only the first NSScreen is the primary display
  for (NSScreen* screen in screens) {
    CGDirectDisplayID displayID =
        [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
    natives.push_back({std::to_string(displayID), (__bridge void*)screen, isPrimary});
    isPrimary = false;
  }
  return natives;
}

Point DisplayManager::GetCursorPosition() {
  NSPoint mouseLocation = [NSEvent mouseLocation];

  // Convert from bottom-left (macOS default) to top-left coordinate system
  CGPoint topLeftPoint = NSPointExt::topLeft(mouseLocation);

  Point point;
  point.x = topLeftPoint.x;
  point.y = topLeftPoint.y;
  return point;
}

}  // namespace nativeapi
