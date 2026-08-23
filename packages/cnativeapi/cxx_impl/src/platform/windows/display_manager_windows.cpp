#include <windows.h>
#include <string>
#include <vector>

#include "../../display.h"
#include "../../display_manager.h"
#include "dpi_utils_windows.h"
#include "string_utils_windows.h"

namespace nativeapi {

DisplayManager::DisplayManager() {
  // Prime the instance cache so the first change notification diffs against
  // the displays present at startup.
  GetAll();
  // TODO: Set up display configuration change monitoring
  // On Windows, you would typically register for WM_DISPLAYCHANGE messages
  // and call HandleDisplaysChanged() from the handler.
}

DisplayManager::~DisplayManager() {
  // TODO: Clean up display change monitoring
}

std::vector<DisplayManager::NativeDisplayInfo> DisplayManager::EnumerateNativeDisplays() {
  std::vector<NativeDisplayInfo> natives;
  auto enumProc = [](HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor,
                     LPARAM dwData) -> BOOL {
    auto* out = reinterpret_cast<std::vector<NativeDisplayInfo>*>(dwData);

    MONITORINFOEXW monitorInfo;
    monitorInfo.cbSize = sizeof(MONITORINFOEXW);

    if (GetMonitorInfoW(hMonitor, &monitorInfo)) {
      bool isPrimary = (monitorInfo.dwFlags & MONITORINFOF_PRIMARY) != 0;
      // The device name is stable across configuration changes, unlike the
      // HMONITOR value, so it serves as the identity key.
      out->push_back({WCharArrayToString(monitorInfo.szDevice), hMonitor, isPrimary});
    }

    return TRUE;
  };
  EnumDisplayMonitors(nullptr, nullptr, enumProc, reinterpret_cast<LPARAM>(&natives));
  return natives;
}

Point DisplayManager::GetCursorPosition() {
  POINT cursorPos;
  if (GetCursorPos(&cursorPos)) {
    // Determine which monitor the cursor is on for DPI scaling
    HMONITOR hMonitor =
        MonitorFromPoint(cursorPos, MONITOR_DEFAULTTONEAREST);
    double scale = GetScaleFactorForMonitor(hMonitor);
    if (scale <= 0.0)
      scale = 1.0;
    return {static_cast<double>(cursorPos.x) / scale,
            static_cast<double>(cursorPos.y) / scale};
  }
  return {0.0, 0.0};
}

}  // namespace nativeapi
