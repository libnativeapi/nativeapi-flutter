#include <android/log.h>
#include "../../menu.h"

#define LOG_TAG "NativeApi"
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

namespace nativeapi {

class Menu::Impl {
 public:
  Impl() {}
};

Menu::Menu() : pimpl_(std::make_unique<Impl>()) {}
Menu::Menu(void* native_menu) : pimpl_(std::make_unique<Impl>()) {}
Menu::~Menu() {}

void* Menu::GetNativeObjectInternal() const {
  return nullptr;
}

MenuId Menu::GetId() const {
  return IdAllocator::kInvalidId;
}

void Menu::AddItem(std::shared_ptr<MenuItem> item) {
  ALOGW("Menu::AddItem not fully implemented on Android");
}

void Menu::InsertItem(size_t index, std::shared_ptr<MenuItem> item) {
  ALOGW("Menu::InsertItem not implemented on Android");
}

bool Menu::RemoveItem(std::shared_ptr<MenuItem> item) {
  ALOGW("Menu::RemoveItem not implemented on Android");
  return false;
}

bool Menu::RemoveItemById(MenuItemId item_id) {
  ALOGW("Menu::RemoveItemById not implemented on Android");
  return false;
}

bool Menu::RemoveItemAt(size_t index) {
  ALOGW("Menu::RemoveItemAt not implemented on Android");
  return false;
}

void Menu::Clear() {
  ALOGW("Menu::Clear not implemented on Android");
}

void Menu::AddSeparator() {
  ALOGW("Menu::AddSeparator not implemented on Android");
}

void Menu::InsertSeparator(size_t index) {
  ALOGW("Menu::InsertSeparator not implemented on Android");
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
  ALOGW("Menu::Open not implemented on Android");
  return false;
}

bool Menu::Close() {
  ALOGW("Menu::Close not implemented on Android");
  return false;
}

}  // namespace nativeapi
