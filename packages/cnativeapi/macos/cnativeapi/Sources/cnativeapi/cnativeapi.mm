// Relative import to be able to reuse the C sources.
// Swift Package Manager compatible includes

// Import Cocoa framework
#import <Cocoa/Cocoa.h>

// Include Carbon-based shortcut implementation before any platform translation units
// that introduce `using namespace nativeapi;`, otherwise Carbon's global `Point`
// collides with nativeapi::Point in this unified Objective-C++ translation unit.
#include "../../../../cxx_impl/src/platform/macos/shortcut_manager_macos.mm"

// NOTE: The C API translation units (cxx_impl/src/capi/*.cpp) are compiled in
// this unity translation unit. Their C++ <-> C conversion helpers are defined in
// the *_c.h header that owns each type, so every *_c.cpp shares one definition
// and merging them here raises no redefinition errors.

// Include source files
#include "../../../../cxx_impl/src/capi/accessibility_manager_c.cpp"
#include "../../../../cxx_impl/src/capi/application_c.cpp"
#include "../../../../cxx_impl/src/capi/color_c.cpp"
#include "../../../../cxx_impl/src/capi/dialog_c.cpp"
#include "../../../../cxx_impl/src/capi/display_c.cpp"
#include "../../../../cxx_impl/src/capi/display_manager_c.cpp"
#include "../../../../cxx_impl/src/capi/geometry_c.cpp"
#include "../../../../cxx_impl/src/capi/image_c.cpp"
#include "../../../../cxx_impl/src/capi/keyboard_c.cpp"
#include "../../../../cxx_impl/src/capi/keyboard_monitor_c.cpp"
#include "../../../../cxx_impl/src/capi/launch_at_login_c.cpp"
#include "../../../../cxx_impl/src/capi/menu_c.cpp"
#include "../../../../cxx_impl/src/capi/message_dialog_c.cpp"
#include "../../../../cxx_impl/src/capi/placement_c.cpp"
#include "../../../../cxx_impl/src/capi/positioning_strategy_c.cpp"
#include "../../../../cxx_impl/src/capi/preferences_c.cpp"
#include "../../../../cxx_impl/src/capi/secure_storage_c.cpp"
#include "../../../../cxx_impl/src/capi/shortcut_c.cpp"
#include "../../../../cxx_impl/src/capi/shortcut_manager_c.cpp"
#include "../../../../cxx_impl/src/capi/string_utils_c.cpp"
#include "../../../../cxx_impl/src/capi/tray_icon_c.cpp"
#include "../../../../cxx_impl/src/capi/tray_manager_c.cpp"
#include "../../../../cxx_impl/src/capi/url_opener_c.cpp"
#include "../../../../cxx_impl/src/capi/window_c.cpp"
#include "../../../../cxx_impl/src/capi/window_manager_c.cpp"
#include "../../../../cxx_impl/src/platform/macos/accessibility_manager_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/application_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/dispatcher_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/display_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/display_manager_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/image_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/keyboard_monitor_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/launch_at_login_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/menu_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/message_dialog_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/preferences_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/secure_storage_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/tray_icon_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/tray_manager_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/url_opener_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/window_macos.mm"
#include "../../../../cxx_impl/src/platform/macos/window_manager_macos.mm"
#include "../../../../cxx_impl/src/foundation/color.cpp"
#include "../../../../cxx_impl/src/foundation/dispatcher.cpp"
#include "../../../../cxx_impl/src/foundation/handle_table.cpp"
#include "../../../../cxx_impl/src/foundation/id_allocator.cpp"
#include "../../../../cxx_impl/src/foundation/keyboard.cpp"
#include "../../../../cxx_impl/src/accessibility_manager.cpp"
#include "../../../../cxx_impl/src/application.cpp"
#include "../../../../cxx_impl/src/dialog.cpp"
#include "../../../../cxx_impl/src/display_manager.cpp"
#include "../../../../cxx_impl/src/menu.cpp"
#include "../../../../cxx_impl/src/positioning_strategy.cpp"
#include "../../../../cxx_impl/src/preferences.cpp"
#include "../../../../cxx_impl/src/secure_storage.cpp"
#include "../../../../cxx_impl/src/shortcut.cpp"
#include "../../../../cxx_impl/src/shortcut_manager.cpp"
#include "../../../../cxx_impl/src/tray_manager.cpp"
#include "../../../../cxx_impl/src/url_opener.cpp"
#include "../../../../cxx_impl/src/window_manager.cpp"
#include "../../../../cxx_impl/src/window_registry.cpp"
