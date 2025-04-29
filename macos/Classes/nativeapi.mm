// Relative import to be able to reuse the C sources.
// See the comment in ../nativeapi.podspec for more information.

// Import Cocoa framework
#import <Cocoa/Cocoa.h>

// Include source files
#include "../../src/libnativeapi/src/accessibility_manager.cpp"
#include "../../src/libnativeapi/src/accessibility_manager_macos.mm"
#include "../../src/libnativeapi/src/broadcast_center.cpp"
#include "../../src/libnativeapi/src/broadcast_center_macos.mm"
#include "../../src/libnativeapi/src/display_manager.cpp"
#include "../../src/libnativeapi/src/display_manager_macos.mm"
#include "../../src/libnativeapi/src/keyboard_monitor.cpp"
#include "../../src/libnativeapi/src/keyboard_monitor_macos.mm"
#include "../../src/libnativeapi/src/tray_macos.mm"
#include "../../src/libnativeapi/src/tray_manager_macos.mm"
#include "../../src/libnativeapi/src/window_macos.mm"
#include "../../src/libnativeapi/src/window_manager_macos.mm"

#include "../../src/nativeapi.cpp"
#include "../../src/accessibility_manager.cpp"
#include "../../src/broadcast_center.cpp"
#include "../../src/display_manager.cpp"
#include "../../src/keyboard_monitor.cpp"
#include "../../src/tray_manager.cpp"
#include "../../src/tray.cpp"
#include "../../src/window_manager.cpp"
#include "../../src/window.cpp"