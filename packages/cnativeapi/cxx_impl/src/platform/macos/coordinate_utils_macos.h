#pragma once

// Import Cocoa and Core Graphics headers
#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

namespace nativeapi {

// NSRect extension-like helper for coordinate system conversion
struct NSRectExt {
  // Convert NSRect with bottom-left origin to topLeft point
  static CGPoint topLeft(NSRect rect) {
    NSRect primaryScreenFrame = [[NSScreen screens][0] frame];
    return CGPointMake(rect.origin.x,
                       primaryScreenFrame.size.height - rect.origin.y - rect.size.height);
  }

  // Convert NSRect with topLeft origin to NSRect with bottom-left origin
  static NSRect bottomLeft(NSRect rect) {
    NSRect primaryScreenFrame = [[NSScreen screens][0] frame];
    // Convert topLeft origin to bottom-left origin
    double bottomY = primaryScreenFrame.size.height - rect.origin.y - rect.size.height;
    return NSMakeRect(rect.origin.x, bottomY, rect.size.width, rect.size.height);
  }
};

// NSPoint extension-like helper for coordinate system conversion
struct NSPointExt {
  // Convert bottom-left point to top-left point
  static CGPoint topLeft(NSPoint point) {
    NSRect primaryScreenFrame = [[NSScreen screens][0] frame];
    return CGPointMake(point.x, primaryScreenFrame.size.height - point.y);
  }

  // Convert top-left point to bottom-left point
  // Note: For window positions, use bottomLeftForWindow instead, as it requires window height
  static NSPoint bottomLeft(CGPoint topLeftPoint) {
    NSRect primaryScreenFrame = [[NSScreen screens][0] frame];
    return NSMakePoint(topLeftPoint.x, primaryScreenFrame.size.height - topLeftPoint.y);
  }

  // Convert top-left window position to bottom-left window position
  // This is the correct method for converting window positions, as it accounts for window height
  static NSPoint bottomLeftForWindow(CGPoint topLeftPoint, CGFloat windowHeight) {
    NSRect primaryScreenFrame = [[NSScreen screens][0] frame];
    double bottomY = primaryScreenFrame.size.height - topLeftPoint.y - windowHeight;
    return NSMakePoint(topLeftPoint.x, bottomY);
  }
};

}  // namespace nativeapi
