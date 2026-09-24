// Synthetic mouse input and window queries for macOS. Run it through the
// `input` wrapper next to this file, which compiles it on first use.
//
//   input windows <pid>                 AX windows: title<TAB>x y w h
//   input owner <x> <y> [menus]         pid owning the frontmost window at a point; menus: also
//                                       count pop-up menu windows (layers above the normal one)
//   input menus <pid>                   the app's open menus (AX), one item per line:
//                                       depth<TAB>title<TAB>x y w h<TAB>flags<TAB>mark
//                                       flags: e = enabled, s = has a submenu, - = separator,
//                                       M = not an item: the frame of the menu window itself
//   input activate <pid> [soft]         bring the app and all its windows forward; soft: just make
//                                       it the active app, without raising its windows
//   input setframe <pid> <x> <y> <w> <h> [title]  move and resize the app's first window, or the one titled so (AX)
//   input raise <pid>                   raise the app's windows above other apps' without activating it
//   input visible <x> <y>               visible frame (no menu bar, no Dock) of the screen at a point
//   input front                         pid of the frontmost application
//   input pos
//   input idle [ms]                     exit 1 if the cursor moves within ms (default 1500)
//   input move <x> <y> <ms>             eased move, no buttons
//   input click <x> <y>
//   input rclick <x> <y>                secondary (right) click
//   input dblclick <x> <y>              two clicks the system counts as a double click
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

static NSString* Role(AXUIElementRef el) {
  CFTypeRef role = NULL;
  AXUIElementCopyAttributeValue(el, kAXRoleAttribute, &role);
  return CFBridgingRelease(role);
}

static id Attr(AXUIElementRef el, CFStringRef name) {
  CFTypeRef value = NULL;
  AXUIElementCopyAttributeValue(el, name, &value);
  return CFBridgingRelease(value);
}

// Prints the items of one open menu at the given depth (0 = the menu, 1 = its submenu, …).
static void DumpMenu(AXUIElementRef menu, int depth) {
  for (id i in (NSArray*)Attr(menu, kAXChildrenAttribute)) {
    AXUIElementRef item = (__bridge AXUIElementRef)i;
    if (![Role(item) isEqual:@"AXMenuItem"]) continue;
    NSString* title = Attr(item, kAXTitleAttribute) ?: @"";
    CGPoint p = CGPointZero;
    CGSize s = CGSizeZero;
    id pos = Attr(item, kAXPositionAttribute), size = Attr(item, kAXSizeAttribute);
    if (pos) AXValueGetValue((__bridge AXValueRef)pos, kAXValueTypeCGPoint, &p);
    if (size) AXValueGetValue((__bridge AXValueRef)size, kAXValueTypeCGSize, &s);
    NSMutableString* flags = [NSMutableString string];
    if ([Attr(item, kAXEnabledAttribute) boolValue]) [flags appendString:@"e"];
    if ([(NSArray*)Attr(item, kAXChildrenAttribute) count]) [flags appendString:@"s"];
    // Separators have no title and a short, fixed height.
    if (title.length == 0 && s.height < 15) [flags appendString:@"-"];
    NSString* mark = Attr(item, kAXMenuItemMarkCharAttribute) ?: @"";
    printf("%d\t%s\t%d %d %d %d\t%s\t%s\n", depth, title.UTF8String, (int)p.x, (int)p.y,
           (int)s.width, (int)s.height, flags.UTF8String, mark.UTF8String);
  }
}

// The app's open menus. AppKit does not list pop-up menus among the application's AX
// children, so find the app's pop-up menu windows and hit-test inside each one.
static void DumpOpenMenus(pid_t pid) {
  NSArray* list = CFBridgingRelease(
      CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID));
  AXUIElementRef system = AXUIElementCreateSystemWide();
  NSMutableArray* menus = [NSMutableArray array];  // [depth, element]
  for (NSDictionary* w in list) {
    if ([w[(id)kCGWindowOwnerPID] intValue] != pid) continue;
    if ([w[(id)kCGWindowLayer] intValue] != kCGPopUpMenuWindowLevel) continue;
    CGRect r;
    CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)w[(id)kCGWindowBounds], &r);
    AXUIElementRef hit = NULL;
    if (AXUIElementCopyElementAtPosition(system, CGRectGetMidX(r), CGRectGetMidY(r), &hit) != 0 ||
        !hit) {
      continue;
    }
    // Walk up to the menu; its depth is the number of menus above it.
    id el = CFBridgingRelease(hit), menu = nil;
    int depth = -1;
    while (el) {
      if ([Role((__bridge AXUIElementRef)el) isEqual:@"AXMenu"]) {
        if (!menu) menu = el;
        depth++;
      }
      el = Attr((__bridge AXUIElementRef)el, kAXParentAttribute);
    }
    if (menu) [menus addObject:@[ @(depth), menu, [NSValue valueWithRect:NSRectFromCGRect(r)] ]];
  }
  CFRelease(system);
  [menus sortUsingComparator:^(NSArray* a, NSArray* b) { return [a[0] compare:b[0]]; }];
  for (NSArray* m in menus) {
    CGRect r = NSRectToCGRect([m[2] rectValue]);
    printf("%d\t\t%d %d %d %d\tM\t\n", [m[0] intValue], (int)r.origin.x, (int)r.origin.y,
           (int)r.size.width, (int)r.size.height);
    DumpMenu((__bridge AXUIElementRef)m[1], [m[0] intValue]);
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
      bool menus = argc > 4 && strcmp(argv[4], "menus") == 0;
      NSArray* list = CFBridgingRelease(
          CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID));
      for (NSDictionary* w in list) {
        int layer = [w[(id)kCGWindowLayer] intValue];
        // Pop-up menus live at kCGPopUpMenuWindowLevel (101); the menu bar, Dock and
        // overlays sit on other levels and never count.
        if (layer != 0 && !(menus && layer == kCGPopUpMenuWindowLevel)) continue;
        if ([w[(id)kCGWindowAlpha] doubleValue] <= 0) continue;
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
    if ([cmd isEqual:@"menus"]) {
      DumpOpenMenus(atoi(argv[2]));
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
    if ([cmd isEqual:@"setframe"]) {
      AXUIElementRef ax = AXUIElementCreateApplication(atoi(argv[2]));
      NSArray* windows = Attr(ax, kAXWindowsAttribute);
      if (!windows.count) return 1;
      id target = windows[0];
      if (argc > 7) {
        // An app with several windows: the one with this title, not whichever is first
        target = nil;
        NSString* wanted = [NSString stringWithUTF8String:argv[7]];
        for (id candidate in windows) {
          if ([Attr((__bridge AXUIElementRef)candidate, kAXTitleAttribute) isEqual:wanted]) {
            target = candidate;
            break;
          }
        }
        if (!target) return 1;
      }
      AXUIElementRef w = (__bridge AXUIElementRef)target;
      CGPoint p = CGPointMake(atof(argv[3]), atof(argv[4]));
      CGSize s = CGSizeMake(atof(argv[5]), atof(argv[6]));
      AXValueRef pos = AXValueCreate(kAXValueTypeCGPoint, &p);
      AXValueRef size = AXValueCreate(kAXValueTypeCGSize, &s);
      AXUIElementSetAttributeValue(w, kAXPositionAttribute, pos);
      AXUIElementSetAttributeValue(w, kAXSizeAttribute, size);
      CFRelease(pos);
      CFRelease(size);
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
    if ([cmd isEqual:@"visible"]) {
      // Screens use a bottom-left origin at the primary screen's bottom edge.
      CGFloat primary = NSScreen.screens.firstObject.frame.size.height;
      NSPoint p = NSMakePoint(atof(argv[2]), primary - atof(argv[3]));
      for (NSScreen* screen in NSScreen.screens) {
        if (!NSPointInRect(p, screen.frame)) continue;
        NSRect v = screen.visibleFrame;
        printf("%d %d %d %d\n", (int)v.origin.x, (int)(primary - NSMaxY(v)), (int)v.size.width,
               (int)v.size.height);
        return 0;
      }
      return 1;
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
    if ([cmd isEqual:@"rclick"]) {
      CGPoint p = CGPointMake(atof(argv[2]), atof(argv[3]));
      CGEventRef down = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, p, kCGMouseButtonRight);
      CGEventPost(kCGHIDEventTap, down);
      CFRelease(down);
      usleep(70000);
      CGEventRef up = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, p, kCGMouseButtonRight);
      CGEventPost(kCGHIDEventTap, up);
      CFRelease(up);
      return 0;
    }
    if ([cmd isEqual:@"dblclick"]) {
      CGPoint p = CGPointMake(atof(argv[2]), atof(argv[3]));
      for (int64_t n = 1; n <= 2; n++) {
        for (int up = 0; up < 2; up++) {
          CGEventRef e = CGEventCreateMouseEvent(
              NULL, up ? kCGEventLeftMouseUp : kCGEventLeftMouseDown, p, kCGMouseButtonLeft);
          CGEventSetIntegerValueField(e, kCGMouseEventClickState, n);  // NSEvent.clickCount
          CGEventPost(kCGHIDEventTap, e);
          CFRelease(e);
          usleep(up ? 90000 : 60000);
        }
      }
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
