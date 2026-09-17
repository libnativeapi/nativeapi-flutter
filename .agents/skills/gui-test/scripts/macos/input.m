// Synthetic mouse input and window queries for macOS. Run it through the
// `input` wrapper next to this file, which compiles it on first use.
//
//   input windows <pid>                 AX windows: title<TAB>x y w h
//   input owner <x> <y>                 pid owning the frontmost window at a point
//   input activate <pid> [soft]         bring the app and all its windows forward; soft: just make
//                                       it the active app, without raising its windows
//   input raise <pid>                   raise the app's windows above other apps' without activating it
//   input front                         pid of the frontmost application
//   input pos
//   input idle [ms]                     exit 1 if the cursor moves within ms (default 1500)
//   input move <x> <y> <ms>             eased move, no buttons
//   input click <x> <y>
//   input drag <x> <y> [<x> <y> <ms>]…  press at the first point, glide through the rest
//   input scroll <x> <y> <lines>
//
// Coordinates are screen points with a top-left origin.

#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>

static CGPoint Current(void) {
  CGEventRef e = CGEventCreate(NULL);
  CGPoint p = CGEventGetLocation(e);
  CFRelease(e);
  return p;
}

static void Post(CGEventType type, CGPoint p) {
  CGEventRef e = CGEventCreateMouseEvent(NULL, type, p, kCGMouseButtonLeft);
  CGEventPost(kCGHIDEventTap, e);
  CFRelease(e);
}

static double Ease(double t) {
  return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
}

// Moves from the current position to `to` over `ms`, as `type` events.
static void Glide(CGPoint to, int ms, CGEventType type) {
  CGPoint from = Current();
  int steps = MAX(1, ms / 8);
  for (int i = 1; i <= steps; i++) {
    double t = Ease((double)i / steps);
    Post(type, CGPointMake(from.x + (to.x - from.x) * t, from.y + (to.y - from.y) * t));
    usleep((useconds_t)(ms * 1000 / steps));
  }
}

int main(int argc, char** argv) {
  @autoreleasepool {
    if (argc < 2) return 2;
    NSString* cmd = @(argv[1]);

    if ([cmd isEqual:@"windows"]) {
      AXUIElementRef app = AXUIElementCreateApplication(atoi(argv[2]));
      CFTypeRef windows = NULL;
      AXUIElementCopyAttributeValue(app, kAXWindowsAttribute, &windows);
      for (id w in (__bridge NSArray*)windows) {
        AXUIElementRef el = (__bridge AXUIElementRef)w;
        CFTypeRef title = NULL, pos = NULL, size = NULL;
        AXUIElementCopyAttributeValue(el, kAXTitleAttribute, &title);
        AXUIElementCopyAttributeValue(el, kAXPositionAttribute, &pos);
        AXUIElementCopyAttributeValue(el, kAXSizeAttribute, &size);
        CGPoint p = CGPointZero;
        CGSize s = CGSizeZero;
        if (pos) AXValueGetValue(pos, kAXValueTypeCGPoint, &p);
        if (size) AXValueGetValue(size, kAXValueTypeCGSize, &s);
        printf("%s\t%d %d %d %d\n", title ? [(__bridge NSString*)title UTF8String] : "",
               (int)p.x, (int)p.y, (int)s.width, (int)s.height);
      }
      return 0;
    }
    if ([cmd isEqual:@"owner"]) {
      double x = atof(argv[2]), y = atof(argv[3]);
      NSArray* list = CFBridgingRelease(
          CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID));
      for (NSDictionary* w in list) {
        if ([w[(id)kCGWindowLayer] intValue] != 0) continue;
        CGRect r;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)w[(id)kCGWindowBounds], &r);
        if (CGRectContainsPoint(r, CGPointMake(x, y))) {
          printf("%d\n", [w[(id)kCGWindowOwnerPID] intValue]);
          return 0;
        }
      }
      printf("0\n");
      return 0;
    }
    if ([cmd isEqual:@"activate"]) {
      NSRunningApplication* app =
          [NSRunningApplication runningApplicationWithProcessIdentifier:atoi(argv[2])];
      if (argc > 3 && strcmp(argv[3], "soft") == 0) {
        [app activateWithOptions:0];
        AXUIElementRef soft = AXUIElementCreateApplication(atoi(argv[2]));
        AXUIElementSetAttributeValue(soft, kAXFrontmostAttribute, kCFBooleanTrue);
        return 0;
      }
      [app activateWithOptions:NSApplicationActivateAllWindows];
      // Activation requests from a background tool are often ignored (cooperative
      // activation, macOS 14+). Accessibility can still bring the app and its windows forward.
      AXUIElementRef ax = AXUIElementCreateApplication(atoi(argv[2]));
      AXUIElementSetAttributeValue(ax, kAXFrontmostAttribute, kCFBooleanTrue);
      CFTypeRef windows = NULL;
      AXUIElementCopyAttributeValue(ax, kAXWindowsAttribute, &windows);
      for (id w in (__bridge NSArray*)windows) {
        AXUIElementPerformAction((__bridge AXUIElementRef)w, kAXRaiseAction);
      }
      return 0;
    }
    if ([cmd isEqual:@"raise"]) {
      AXUIElementRef ax = AXUIElementCreateApplication(atoi(argv[2]));
      CFTypeRef windows = NULL;
      AXUIElementCopyAttributeValue(ax, kAXWindowsAttribute, &windows);
      for (id w in (__bridge NSArray*)windows) {
        AXUIElementPerformAction((__bridge AXUIElementRef)w, kAXRaiseAction);
      }
      return 0;
    }
    if ([cmd isEqual:@"front"]) {
      printf("%d\n", NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier);
      return 0;
    }
    if ([cmd isEqual:@"pos"]) {
      CGPoint p = Current();
      printf("%d %d\n", (int)p.x, (int)p.y);
      return 0;
    }
    if ([cmd isEqual:@"idle"]) {
      // Somebody moving the mouse means the machine is in use: do not take over.
      CGPoint before = Current();
      usleep((useconds_t)((argc > 2 ? atoi(argv[2]) : 1500) * 1000));
      CGPoint after = Current();
      return (before.x == after.x && before.y == after.y) ? 0 : 1;
    }
    if ([cmd isEqual:@"move"]) {
      Glide(CGPointMake(atof(argv[2]), atof(argv[3])), atoi(argv[4]), kCGEventMouseMoved);
      return 0;
    }
    if ([cmd isEqual:@"click"]) {
      CGPoint p = CGPointMake(atof(argv[2]), atof(argv[3]));
      Post(kCGEventLeftMouseDown, p);
      usleep(70000);
      Post(kCGEventLeftMouseUp, p);
      return 0;
    }
    if ([cmd isEqual:@"drag"]) {
      CGPoint start = CGPointMake(atof(argv[2]), atof(argv[3]));
      Post(kCGEventMouseMoved, start);
      Post(kCGEventLeftMouseDown, start);
      usleep(180000);
      for (int i = 4; i + 2 < argc; i += 3) {
        Glide(CGPointMake(atof(argv[i]), atof(argv[i + 1])), atoi(argv[i + 2]),
              kCGEventLeftMouseDragged);
        usleep(120000);
      }
      usleep(200000);
      Post(kCGEventLeftMouseUp, Current());
      return 0;
    }
    if ([cmd isEqual:@"scroll"]) {
      Post(kCGEventMouseMoved, CGPointMake(atof(argv[2]), atof(argv[3])));
      int lines = atoi(argv[4]);
      for (int i = 0; i < abs(lines) * 4; i++) {
        CGEventRef e =
            CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 1, lines > 0 ? -12 : 12);
        CGEventPost(kCGHIDEventTap, e);
        CFRelease(e);
        usleep(16000);
      }
      return 0;
    }
    fprintf(stderr, "unknown command %s\n", argv[1]);
    return 2;
  }
}
