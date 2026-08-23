#include <android/log.h>
#include "../../menu.h"

#define LOG_TAG "NativeApi"
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

namespace nativeapi {

class MenuItem::Impl {
 public:
  Impl() {}
};

MenuItem::MenuItem(const std::string& label, MenuItemType type) : pimpl_(std::make_unique<Impl>()) {
  ALOGW("MenuItem created on Android");
}

MenuItem::MenuItem(void* native_item) : pimpl_(std::make_unique<Impl>()) {}

MenuItem::~MenuItem() {}

void* MenuItem::GetNativeObjectInternal() const {
  return nullptr;
}

MenuItemId MenuItem::GetId() const {
  return IdAllocator::kInvalidId;
}

MenuItemType MenuItem::GetType() const {
  return MenuItemType::Normal;
}

void MenuItem::SetLabel(const std::optional<std::string>& label) {
  ALOGW("MenuItem::SetLabel not implemented on Android");
}

std::optional<std::string> MenuItem::GetLabel() const {
  return std::nullopt;
}

void MenuItem::SetIcon(std::shared_ptr<Image> image) {
  ALOGW("MenuItem::SetIcon not implemented on Android");
}

std::shared_ptr<Image> MenuItem::GetIcon() const {
  return nullptr;
}

void MenuItem::SetTooltip(const std::optional<std::string>& tooltip) {
  ALOGW("MenuItem::SetTooltip not implemented on Android");
}

std::optional<std::string> MenuItem::GetTooltip() const {
  return std::nullopt;
}

void MenuItem::SetAccelerator(const std::optional<KeyboardAccelerator>& accelerator) {
  ALOGW("MenuItem::SetAccelerator not implemented on Android");
}

KeyboardAccelerator MenuItem::GetAccelerator() const {
  return KeyboardAccelerator("");
}

void MenuItem::SetEnabled(bool enabled) {
  ALOGW("MenuItem::SetEnabled not implemented on Android");
}

bool MenuItem::IsEnabled() const {
  return true;
}

void MenuItem::SetState(MenuItemState state) {
  ALOGW("MenuItem::SetState not implemented on Android");
}

MenuItemState MenuItem::GetState() const {
  return MenuItemState::Unchecked;
}

void MenuItem::SetRadioGroup(int group_id) {
  ALOGW("MenuItem::SetRadioGroup not implemented on Android");
}

int MenuItem::GetRadioGroup() const {
  return -1;
}

void MenuItem::SetSubmenu(std::shared_ptr<Menu> submenu) {
  ALOGW("MenuItem::SetSubmenu not implemented on Android");
}

std::shared_ptr<Menu> MenuItem::GetSubmenu() const {
  return nullptr;
}

}  // namespace nativeapi
