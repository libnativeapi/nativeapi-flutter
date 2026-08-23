#include "../../display.h"
#include "coordinate_utils_macos.h"

// Import Cocoa and Core Graphics headers
#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

namespace nativeapi {

static NSScreen* FindScreenByDisplayID(CGDirectDisplayID display_id) {
  NSArray<NSScreen*>* screens = [NSScreen screens];
  for (NSScreen* screen in screens) {
    CGDirectDisplayID screenDisplayID =
        [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
    if (screenDisplayID == display_id) {
      return screen;
    }
  }
  return nil;
}

// Private implementation class
class Display::Impl {
 public:
  Impl() = default;

  // Display instances are long-lived identity objects, but NSScreen objects
  // are recreated on configuration changes. Resolve the screen by its
  // CGDirectDisplayID on every access so getters always read live state,
  // falling back to the wrapped screen for objects not in [NSScreen screens].
  NSScreen* Screen() const {
    if (display_id_ != 0) {
      NSScreen* screen = FindScreenByDisplayID(display_id_);
      if (screen) {
        return screen;
      }
    }
    return ns_screen_;
  }

  const DisplayId id_ = IdAllocator::Allocate<Display>();
  NSScreen* ns_screen_ = nil;
  CGDirectDisplayID display_id_ = 0;
};

Display::Display(void* display) : pimpl_(std::make_unique<Impl>()) {
  if (display) {
    // Assume the void* is either NSScreen* or CGDirectDisplayID*
    // Try NSScreen first
    NSScreen* screen = (__bridge NSScreen*)display;
    if (screen && [screen isKindOfClass:[NSScreen class]]) {
      pimpl_->ns_screen_ = screen;
      pimpl_->display_id_ =
          [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
    } else {
      // Try CGDirectDisplayID
      CGDirectDisplayID displayID = *(CGDirectDisplayID*)display;
      pimpl_->display_id_ = displayID;
      pimpl_->ns_screen_ = FindScreenByDisplayID(displayID);
    }
  }
}

Display::~Display() = default;

void* Display::GetNativeObjectInternal() const {
  return (__bridge void*)pimpl_->Screen();
}

// Getters - directly read from NSScreen
DisplayId Display::GetId() const {
  return pimpl_->id_;
}

std::string Display::GetName() const {
  NSScreen* screen = pimpl_->Screen();
  if (!screen)
    return "";
  NSString* displayName;
  if (@available(macOS 10.15, *)) {
    displayName = [screen localizedName];
  } else {
    displayName = [NSString stringWithFormat:@"Display %@", @(pimpl_->display_id_)];
  }
  return [displayName UTF8String];
}

Point Display::GetPosition() const {
  NSScreen* screen = pimpl_->Screen();
  if (!screen)
    return {0.0, 0.0};
  NSRect frame = [screen frame];

  // Convert from bottom-left (macOS default) to top-left coordinate system
  CGPoint topLeft = NSRectExt::topLeft(frame);

  return {topLeft.x, topLeft.y};
}

Size Display::GetSize() const {
  NSScreen* screen = pimpl_->Screen();
  if (!screen)
    return {0.0, 0.0};
  NSRect frame = [screen frame];
  return {frame.size.width, frame.size.height};
}

Rectangle Display::GetWorkArea() const {
  NSScreen* screen = pimpl_->Screen();
  if (!screen)
    return {0.0, 0.0, 0.0, 0.0};
  NSRect visibleFrame = [screen visibleFrame];

  // Convert from bottom-left (macOS default) to top-left coordinate system
  CGPoint topLeft = NSRectExt::topLeft(visibleFrame);

  return {topLeft.x, topLeft.y, visibleFrame.size.width, visibleFrame.size.height};
}

double Display::GetScaleFactor() const {
  NSScreen* screen = pimpl_->Screen();
  if (!screen)
    return 1.0;
  return [screen backingScaleFactor];
}

bool Display::IsPrimary() const {
  NSScreen* screen = pimpl_->Screen();
  if (!screen)
    return false;
  NSArray<NSScreen*>* screens = [NSScreen screens];
  return screens.count > 0 && screens[0] == screen;
}

DisplayOrientation Display::GetOrientation() const {
  NSScreen* screen = pimpl_->Screen();
  if (!screen)
    return DisplayOrientation::kPortrait;
  NSRect frame = [screen frame];
  return (frame.size.width > frame.size.height) ? DisplayOrientation::kLandscape
                                                : DisplayOrientation::kPortrait;
}

int Display::GetRefreshRate() const {
  if (!pimpl_->Screen())
    return 60;
  CGDisplayModeRef displayMode = CGDisplayCopyDisplayMode(pimpl_->display_id_);
  if (displayMode) {
    double refreshRate = CGDisplayModeGetRefreshRate(displayMode);
    CGDisplayModeRelease(displayMode);
    return refreshRate > 0 ? (int)refreshRate : 60;
  }
  return 60;
}

int Display::GetBitDepth() const {
  return 32;  // Default for modern displays
}

}  // namespace nativeapi
