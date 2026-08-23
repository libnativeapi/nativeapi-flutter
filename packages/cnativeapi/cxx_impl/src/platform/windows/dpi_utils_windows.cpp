#include <windows.h>

namespace nativeapi {

// Internal: per-monitor DPI via Shcore when available
double GetScaleFactorForMonitor(HMONITOR hmonitor) {
  if (!hmonitor)
    return 1.0;
  typedef HRESULT(WINAPI * GetDpiForMonitorFunc)(HMONITOR, int, UINT*, UINT*);
  static GetDpiForMonitorFunc pGetDpiForMonitor = nullptr;
  static bool resolved = false;
  if (!resolved) {
    HMODULE hShcore = LoadLibraryW(L"Shcore.dll");
    if (hShcore) {
      pGetDpiForMonitor =
          reinterpret_cast<GetDpiForMonitorFunc>(GetProcAddress(hShcore, "GetDpiForMonitor"));
    }
    resolved = true;
  }
  if (pGetDpiForMonitor) {
    UINT dpiX = 96, dpiY = 96;
    if (SUCCEEDED(pGetDpiForMonitor(hmonitor, 0 /* MDT_EFFECTIVE_DPI */, &dpiX, &dpiY))) {
      return static_cast<double>(dpiX) / 96.0;
    }
  }
  return 1.0;
}

double GetScaleFactorForWindow(HWND hwnd) {
  if (hwnd) {
    // Prefer GetDpiForWindow if available
    typedef UINT(WINAPI * GetDpiForWindowFunc)(HWND);
    static GetDpiForWindowFunc pGetDpiForWindow = nullptr;
    static bool resolved_win = false;
    if (!resolved_win) {
      HMODULE hUser32 = LoadLibraryW(L"user32.dll");
      if (hUser32) {
        pGetDpiForWindow =
            reinterpret_cast<GetDpiForWindowFunc>(GetProcAddress(hUser32, "GetDpiForWindow"));
      }
      resolved_win = true;
    }
    if (pGetDpiForWindow) {
      UINT dpi = pGetDpiForWindow(hwnd);
      if (dpi > 0) {
        return static_cast<double>(dpi) / 96.0;
      }
    }

    // Fallback: per-monitor DPI
    HMONITOR hmonitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    double monitor_scale = GetScaleFactorForMonitor(hmonitor);
    if (monitor_scale > 0.0)
      return monitor_scale;
  }

  // Fallback: system DPI
  HDC hdc = GetDC(nullptr);
  if (hdc) {
    int dpiX = GetDeviceCaps(hdc, LOGPIXELSX);
    ReleaseDC(nullptr, hdc);
    if (dpiX > 0) {
      return static_cast<double>(dpiX) / 96.0;
    }
  }
  return 1.0;
}

}  // namespace nativeapi
