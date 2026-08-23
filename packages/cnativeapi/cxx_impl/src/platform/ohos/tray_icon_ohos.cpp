#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <memory>
#include <optional>
#include <string>
#include "../../tray_icon.h"

#ifdef __OHOS__
#define LOG_CORE 0xD001700
// Note: LOG_TAG is defined in hilog/log.h as NULL,
// redefine to avoid warnings if needed
#undef LOG_TAG
#define LOG_TAG "NativeApi"
#endif

namespace nativeapi {

class TrayIcon::Impl {
 public:
  Impl() = default;

  void* native_tray_ = nullptr;
};

TrayIcon::TrayIcon() : pimpl_(std::make_unique<Impl>()) {}

TrayIcon::TrayIcon(void* tray) : pimpl_(std::make_unique<Impl>()) {
  pimpl_->native_tray_ = tray;
}

TrayIcon::~TrayIcon() = default;

TrayIconId TrayIcon::GetId() {
  return IdAllocator::kInvalidId;
}

void TrayIcon::SetIcon(std::shared_ptr<Image> image) {
  // Not implemented on OpenHarmony yet
}

std::shared_ptr<Image> TrayIcon::GetIcon() const {
  return nullptr;
}

void TrayIcon::SetTitle(std::optional<std::string> title) {
  // Not implemented on OpenHarmony yet
}

std::optional<std::string> TrayIcon::GetTitle() {
  return std::nullopt;
}

void TrayIcon::SetTooltip(std::optional<std::string> tooltip) {
  // Not implemented on OpenHarmony yet
}

std::optional<std::string> TrayIcon::GetTooltip() {
  return std::nullopt;
}

void TrayIcon::SetContextMenu(std::shared_ptr<Menu> menu) {
  // Not implemented on OpenHarmony yet
}

std::shared_ptr<Menu> TrayIcon::GetContextMenu() {
  return nullptr;
}

void TrayIcon::SetContextMenuTrigger(ContextMenuTrigger trigger) {
  // Not implemented on OpenHarmony yet
}

ContextMenuTrigger TrayIcon::GetContextMenuTrigger() {
  return ContextMenuTrigger::None;
}

Rectangle TrayIcon::GetBounds() {
  return Rectangle{0.0, 0.0, 0.0, 0.0};
}

bool TrayIcon::SetVisible(bool visible) {
  // Not implemented on OpenHarmony yet
  return false;
}

bool TrayIcon::IsVisible() {
  return false;
}

bool TrayIcon::OpenContextMenu() {
  // Not implemented on OpenHarmony yet
  return false;
}

bool TrayIcon::CloseContextMenu() {
  // Not implemented on OpenHarmony yet
  return false;
}

void TrayIcon::StartEventListening() {
  // Not implemented on OpenHarmony yet
}

void TrayIcon::StopEventListening() {
  // Not implemented on OpenHarmony yet
}

void* TrayIcon::GetNativeObjectInternal() const {
  return pimpl_->native_tray_;
}

}  // namespace nativeapi
