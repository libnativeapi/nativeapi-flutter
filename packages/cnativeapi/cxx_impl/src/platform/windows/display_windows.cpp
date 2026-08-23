#include "../../display.h"

#include <windows.h>
#include "dpi_utils_windows.h"
#include "string_utils_windows.h"

namespace nativeapi {

// Private implementation class
class Display::Impl {
 public:
  Impl() = default;
  Impl(HMONITOR monitor) : h_monitor_(monitor) {}

  const DisplayId id_ = IdAllocator::Allocate<Display>();
  HMONITOR h_monitor_ = nullptr;
};

Display::Display(void* display) : pimpl_(std::make_unique<Impl>()) {
  if (display) {
    pimpl_->h_monitor_ = (HMONITOR)display;
  }
}

Display::~Display() = default;

void* Display::GetNativeObjectInternal() const {
  return pimpl_->h_monitor_;
}

// Helper function to get monitor info
MONITORINFOEXW GetMonitorInfoEx(HMONITOR hMonitor) {
  MONITORINFOEXW monitorInfo;
  monitorInfo.cbSize = sizeof(MONITORINFOEXW);
  GetMonitorInfoW(hMonitor, &monitorInfo);
  return monitorInfo;
}

// Getters - directly read from HMONITOR
DisplayId Display::GetId() const {
  return pimpl_->id_;
}

std::string Display::GetName() const {
  if (!pimpl_->h_monitor_)
    return "";
  MONITORINFOEXW monitorInfo = GetMonitorInfoEx(pimpl_->h_monitor_);
  return WCharArrayToString(monitorInfo.szDevice);
}

Point Display::GetPosition() const {
  if (!pimpl_->h_monitor_)
    return {0.0, 0.0};
  MONITORINFOEXW monitorInfo = GetMonitorInfoEx(pimpl_->h_monitor_);
  RECT rect = monitorInfo.rcMonitor;
  double scale = GetScaleFactorForMonitor(pimpl_->h_monitor_);
  if (scale <= 0.0)
    scale = 1.0;
  return {static_cast<double>(rect.left) / scale,
          static_cast<double>(rect.top) / scale};
}

Size Display::GetSize() const {
  if (!pimpl_->h_monitor_)
    return {0.0, 0.0};
  MONITORINFOEXW monitorInfo = GetMonitorInfoEx(pimpl_->h_monitor_);
  RECT rect = monitorInfo.rcMonitor;
  double scale = GetScaleFactorForMonitor(pimpl_->h_monitor_);
  if (scale <= 0.0)
    scale = 1.0;
  return {static_cast<double>(rect.right - rect.left) / scale,
          static_cast<double>(rect.bottom - rect.top) / scale};
}

Rectangle Display::GetWorkArea() const {
  if (!pimpl_->h_monitor_)
    return {0.0, 0.0, 0.0, 0.0};
  MONITORINFOEXW monitorInfo = GetMonitorInfoEx(pimpl_->h_monitor_);
  RECT workRect = monitorInfo.rcWork;
  double scale = GetScaleFactorForMonitor(pimpl_->h_monitor_);
  if (scale <= 0.0)
    scale = 1.0;
  return {static_cast<double>(workRect.left) / scale,
          static_cast<double>(workRect.top) / scale,
          static_cast<double>(workRect.right - workRect.left) / scale,
          static_cast<double>(workRect.bottom - workRect.top) / scale};
}

double Display::GetScaleFactor() const {
  if (!pimpl_->h_monitor_)
    return 1.0;
  double scale = GetScaleFactorForMonitor(pimpl_->h_monitor_);
  return (scale > 0.0) ? scale : 1.0;
}

bool Display::IsPrimary() const {
  if (!pimpl_->h_monitor_)
    return false;
  MONITORINFOEXW monitorInfo = GetMonitorInfoEx(pimpl_->h_monitor_);
  return (monitorInfo.dwFlags & MONITORINFOF_PRIMARY) != 0;
}

DisplayOrientation Display::GetOrientation() const {
  if (!pimpl_->h_monitor_)
    return DisplayOrientation::kPortrait;
  Size size = GetSize();
  return (size.width > size.height) ? DisplayOrientation::kLandscape
                                    : DisplayOrientation::kPortrait;
}

int Display::GetRefreshRate() const {
  return 60;  // Default refresh rate, would need additional Windows APIs to get
              // actual value
}

int Display::GetBitDepth() const {
  return 32;  // Default bit depth for modern displays
}

}  // namespace nativeapi
