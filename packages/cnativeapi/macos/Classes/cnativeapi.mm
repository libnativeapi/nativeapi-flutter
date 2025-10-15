// Relative import to be able to reuse the C sources.
// See the comment in ../nativeapi.podspec for more information.

// Import Cocoa framework
#import <Cocoa/Cocoa.h>

// Include source files
#include "../../src/libnativeapi/src/capi/accessibility_manager_c.cpp"
#include "../../src/libnativeapi/src/capi/app_runner_c.cpp"
#include "../../src/libnativeapi/src/capi/display_c.cpp"
#include "../../src/libnativeapi/src/capi/display_manager_c.cpp"
#include "../../src/libnativeapi/src/capi/image_c.cpp"
#include "../../src/libnativeapi/src/capi/keyboard_monitor_c.cpp"
#include "../../src/libnativeapi/src/capi/menu_c.cpp"
#include "../../src/libnativeapi/src/capi/run_example_app_c.cpp"
#include "../../src/libnativeapi/src/capi/string_utils_c.cpp"
#include "../../src/libnativeapi/src/capi/tray_icon_c.cpp"
#include "../../src/libnativeapi/src/capi/tray_manager_c.cpp"
#include "../../src/libnativeapi/src/capi/window_c.cpp"
#include "../../src/libnativeapi/src/capi/window_manager_c.cpp"
#include "../../src/libnativeapi/src/platform/macos/accessibility_manager_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/app_runner_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/display_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/display_manager_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/image_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/keyboard_monitor_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/menu_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/tray_icon_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/tray_manager_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/window_macos.mm"
#include "../../src/libnativeapi/src/platform/macos/window_manager_macos.mm"
#include "../../src/libnativeapi/src/accessibility_manager.cpp"
#include "../../src/libnativeapi/src/app_runner.cpp"
#include "../../src/libnativeapi/src/display_manager.cpp"
#include "../../src/libnativeapi/src/foundation/event_emitter.cpp"
#include "../../src/libnativeapi/src/foundation/id_allocator.cpp"
#include "../../src/libnativeapi/src/menu.cpp"
#include "../../src/libnativeapi/src/tray_manager.cpp"
#include "../../src/libnativeapi/src/window_manager.cpp"
