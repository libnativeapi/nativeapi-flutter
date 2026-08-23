#include <android/log.h>
#include "../../tray_icon.h"

#define LOG_TAG "NativeApi"
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

namespace nativeapi {

class TrayIcon::Impl {
 public:
  Impl() {}
};

TrayIcon::TrayIcon() : pimpl_(std::make_unique<Impl>()) {}
TrayIcon::TrayIcon(void* tray) : pimpl_(std::make_unique<Impl>()) {}
TrayIcon::~TrayIcon() {}

void* TrayIcon::GetNativeObjectInternal() const {
  return nullptr;
}

TrayIconId TrayIcon::GetId() {
  return IdAllocator::kInvalidId;
}

void TrayIcon::SetIcon(std::shared_ptr<Image> image) {
  ALOGW("TrayIcon::SetIcon uses Android notifications");
}

std::shared_ptr<Image> TrayIcon::GetIcon() const {
  return nullptr;
}

void TrayIcon::SetTitle(std::optional<std::string> title) {
  ALOGW("TrayIcon::SetTitle uses Android notification title");
}

std::optional<std::string> TrayIcon::GetTitle() {
  return std::nullopt;
}

void TrayIcon::SetTooltip(std::optional<std::string> tooltip) {
  ALOGW("TrayIcon::SetTooltip uses Android notification content");
}

std::optional<std::string> TrayIcon::GetTooltip() {
  return std::nullopt;
}

void TrayIcon::SetContextMenu(std::shared_ptr<Menu> menu) {
  ALOGW("TrayIcon::SetContextMenu uses Android notification actions");
}

std::shared_ptr<Menu> TrayIcon::GetContextMenu() {
  return nullptr;
}

void TrayIcon::SetContextMenuTrigger(ContextMenuTrigger trigger) {
  ALOGW("TrayIcon::SetContextMenuTrigger not applicable on Android");
}

ContextMenuTrigger TrayIcon::GetContextMenuTrigger() {
  return ContextMenuTrigger::None;
}

Rectangle TrayIcon::GetBounds() {
  return Rectangle{0.0, 0.0, 0.0, 0.0};
}

bool TrayIcon::SetVisible(bool visible) {
  ALOGW("TrayIcon::SetVisible controls Android notification visibility");
  return true;
}

bool TrayIcon::IsVisible() {
  return false;
}

bool TrayIcon::OpenContextMenu() {
  ALOGW("TrayIcon::OpenContextMenu not applicable on Android");
  return false;
}

void TrayIcon::StartEventListening() {
  ALOGW("TrayIcon::StartEventListening not implemented on Android");
}

void TrayIcon::StopEventListening() {
  ALOGW("TrayIcon::StopEventListening not implemented on Android");
}

bool TrayIcon::CloseContextMenu() {
  ALOGW("TrayIcon::CloseContextMenu not applicable on Android");
  return false;
}

}  // namespace nativeapi
