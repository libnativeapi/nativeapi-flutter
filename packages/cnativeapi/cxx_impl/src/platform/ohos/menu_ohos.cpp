#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <memory>
#include <string>
#include <vector>
#include "../../menu.h"

#ifdef __OHOS__
#define LOG_CORE 0xD001700
// Note: LOG_TAG is defined in hilog/log.h as NULL,
// redefine to avoid warnings if needed
#undef LOG_TAG
#define LOG_TAG "NativeApi"
#endif

namespace nativeapi {

class Menu::Impl {
 public:
  Impl() = default;

  void* native_menu_ = nullptr;
};

Menu::Menu() : pimpl_(std::make_unique<Impl>()) {}

Menu::Menu(void* native_menu) : pimpl_(std::make_unique<Impl>()) {
  pimpl_->native_menu_ = native_menu;
}

Menu::~Menu() = default;

MenuId Menu::GetId() const {
  return IdAllocator::kInvalidId;
}

void Menu::AddItem(std::shared_ptr<MenuItem> item) {
  // Not implemented on OpenHarmony yet
}

void Menu::InsertItem(size_t index, std::shared_ptr<MenuItem> item) {
  // Not implemented on OpenHarmony yet
}

bool Menu::RemoveItem(std::shared_ptr<MenuItem> item) {
  // Not implemented on OpenHarmony yet
  return false;
}

bool Menu::RemoveItemById(MenuItemId item_id) {
  // Not implemented on OpenHarmony yet
  return false;
}

bool Menu::RemoveItemAt(size_t index) {
  // Not implemented on OpenHarmony yet
  return false;
}

void Menu::Clear() {
  // Not implemented on OpenHarmony yet
}

void Menu::AddSeparator() {
  // Not implemented on OpenHarmony yet
}

void Menu::InsertSeparator(size_t index) {
  // Not implemented on OpenHarmony yet
}

size_t Menu::GetItemCount() const {
  return 0;
}

std::shared_ptr<MenuItem> Menu::GetItemAt(size_t index) const {
  return nullptr;
}

std::shared_ptr<MenuItem> Menu::GetItemById(MenuItemId item_id) const {
  return nullptr;
}

std::vector<std::shared_ptr<MenuItem>> Menu::GetAllItems() const {
  return {};
}

bool Menu::Open(const PositioningStrategy& strategy, Placement placement) {
  // Not implemented on OpenHarmony yet
  return false;
}

bool Menu::Close() {
  // Not implemented on OpenHarmony yet
  return false;
}

void* Menu::GetNativeObjectInternal() const {
  return pimpl_->native_menu_;
}

}  // namespace nativeapi
