#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <memory>
#include <optional>
#include <string>
#include "../../menu.h"

#ifdef __OHOS__
#define LOG_CORE 0xD001700
// Note: LOG_TAG is defined in hilog/log.h as NULL,
// redefine to avoid warnings if needed
#undef LOG_TAG
#define LOG_TAG "NativeApi"
#endif

namespace nativeapi {

class MenuItem::Impl {
 public:
  Impl() = default;

  void* native_item_ = nullptr;
  std::string label_;
  MenuItemType type_ = MenuItemType::Normal;
};

MenuItem::MenuItem(const std::string& label, MenuItemType type) : pimpl_(std::make_unique<Impl>()) {
  pimpl_->label_ = label;
  pimpl_->type_ = type;
}

MenuItem::MenuItem(void* native_item) : pimpl_(std::make_unique<Impl>()) {
  pimpl_->native_item_ = native_item;
}

MenuItem::~MenuItem() = default;

MenuItemId MenuItem::GetId() const {
  return IdAllocator::kInvalidId;
}

MenuItemType MenuItem::GetType() const {
  return pimpl_->type_;
}

void MenuItem::SetLabel(const std::optional<std::string>& label) {
  pimpl_->label_ = label.has_value() ? label.value() : "";
}

std::optional<std::string> MenuItem::GetLabel() const {
  return pimpl_->label_.empty() ? std::nullopt : std::make_optional(pimpl_->label_);
}

void MenuItem::SetIcon(std::shared_ptr<Image> image) {
  // Not implemented on OpenHarmony yet
}

std::shared_ptr<Image> MenuItem::GetIcon() const {
  return nullptr;
}

void MenuItem::SetTooltip(const std::optional<std::string>& tooltip) {
  // Not implemented on OpenHarmony yet
}

std::optional<std::string> MenuItem::GetTooltip() const {
  return std::nullopt;
}

void MenuItem::SetAccelerator(const std::optional<KeyboardAccelerator>& accelerator) {
  // Not implemented on OpenHarmony yet
}

KeyboardAccelerator MenuItem::GetAccelerator() const {
  return KeyboardAccelerator("");
}

void MenuItem::SetEnabled(bool enabled) {
  // Not implemented on OpenHarmony yet
}

bool MenuItem::IsEnabled() const {
  return true;
}

void MenuItem::SetState(MenuItemState state) {
  // Not implemented on OpenHarmony yet
}

MenuItemState MenuItem::GetState() const {
  return MenuItemState::Unchecked;
}

void MenuItem::SetRadioGroup(int group_id) {
  // Not implemented on OpenHarmony yet
}

int MenuItem::GetRadioGroup() const {
  return -1;
}

void MenuItem::SetSubmenu(std::shared_ptr<Menu> submenu) {
  // Not implemented on OpenHarmony yet
}

std::shared_ptr<Menu> MenuItem::GetSubmenu() const {
  return nullptr;
}

void* MenuItem::GetNativeObjectInternal() const {
  return pimpl_->native_item_;
}

}  // namespace nativeapi
