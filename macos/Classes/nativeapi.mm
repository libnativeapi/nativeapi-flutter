// Relative import to be able to reuse the C sources.
// See the comment in ../nativeapi.podspec for more information.

// Import Cocoa framework
#import <Cocoa/Cocoa.h>

// Include source files
#include "../../src/libnativeapi/src/capi/accessibility_manager_c.cpp"
#include "../../src/libnativeapi/src/capi/display_c.c"
#include "../../src/libnativeapi/src/capi/display_manager_c.cpp"
#include "../../src/libnativeapi/src/platform/macos/accessibility_manager_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/display_manager_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/keyboard_monitor_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/tray_manager_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/window_manager_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/menu_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/tray_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/window_macos.mm"
#include "../../src/libnativeapi/src/accessibility_manager.cpp"
#include "../../src/libnativeapi/src/display_manager.cpp"
#include "../../src/libnativeapi/src/keyboard_monitor.cpp"

#include "../../src/nativeapi.cpp"
#include "../../src/keyboard_monitor.cpp"
#include "../../src/tray_manager.cpp"
#include "../../src/tray.cpp"
#include "../../src/window_manager.cpp"
#include "../../src/window.cpp"
