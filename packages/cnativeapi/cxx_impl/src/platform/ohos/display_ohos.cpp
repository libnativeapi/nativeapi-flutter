#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <memory>
#include <string>
#include <utility>
#include "../../display.h"

#ifdef __OHOS__
#define LOG_CORE 0xD001700
// Note: LOG_TAG is defined in hilog/log.h as NULL,
// redefine to avoid warnings if needed
#undef LOG_TAG
#define LOG_TAG "NativeApi"
#endif

namespace nativeapi {

class Display::Impl {
 public:
  Impl() = default;
  Impl(void* display) : native_display_(display) {}

  const DisplayId id_ = IdAllocator::Allocate<Display>();
  void* native_display_ = nullptr;
};

Display::Display(void* display) : pimpl_(std::make_unique<Impl>(display)) {}

Display::~Display() = default;

void* Display::GetNativeObjectInternal() const {
  return pimpl_->native_display_;
}

DisplayId Display::GetId() const {
  return pimpl_->id_;
}

std::string Display::GetName() const {
  return "Primary Display";
}

Point Display::GetPosition() const {
  return {0.0, 0.0};
}

Size Display::GetSize() const {
  // Default display size for OpenHarmony devices
  return {360.0, 780.0};
}

Rectangle Display::GetWorkArea() const {
  // Default work area matches display size
  Size size = GetSize();
  return {0.0, 0.0, size.width, size.height};
}

double Display::GetScaleFactor() const {
  return 1.0;
}

bool Display::IsPrimary() const {
  return true;
}

DisplayOrientation Display::GetOrientation() const {
  return DisplayOrientation::kPortrait;
}

int Display::GetRefreshRate() const {
  return 60;
}

int Display::GetBitDepth() const {
  return 32;
}

}  // namespace nativeapi
