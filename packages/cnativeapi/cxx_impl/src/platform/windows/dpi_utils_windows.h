#pragma once
#include <windows.h>

namespace nativeapi {

// Returns the DPI scale factor for the given window (1.0 at 96 DPI)
double GetScaleFactorForWindow(HWND hwnd);

// Returns the DPI scale factor for the given monitor (1.0 at 96 DPI)
double GetScaleFactorForMonitor(HMONITOR hmonitor);

}  // namespace nativeapi
