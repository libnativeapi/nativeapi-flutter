#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <string>
#include "../../tray_icon.h"

namespace nativeapi {

class TrayIcon::Impl {
 public:
  Impl() {}
};

TrayIcon::TrayIcon() : pimpl_(std::make_unique<Impl>()) {}
TrayIcon::TrayIcon(void* tray) : pimpl_(std::make_unique<Impl>()) {}
TrayIcon::~TrayIcon() {}

TrayIconId TrayIcon::GetId() {
  return IdAllocator::kInvalidId;
}

void TrayIcon::SetIcon(std::shared_ptr<Image> image) {
  // iOS doesn't have system tray icons
}

std::shared_ptr<Image> TrayIcon::GetIcon() const {
  return nullptr;
}

void TrayIcon::SetTitle(std::optional<std::string> title) {
  // Not applicable to iOS
}

std::optional<std::string> TrayIcon::GetTitle() {
  return std::nullopt;
}

void TrayIcon::SetTooltip(std::optional<std::string> tooltip) {
  // Not applicable to iOS
}

std::optional<std::string> TrayIcon::GetTooltip() {
  return std::nullopt;
}

void TrayIcon::SetContextMenu(std::shared_ptr<Menu> menu) {
  // Not applicable to iOS
}

std::shared_ptr<Menu> TrayIcon::GetContextMenu() {
  return nullptr;
}

void TrayIcon::SetContextMenuTrigger(ContextMenuTrigger trigger) {
  // Not applicable to iOS
}

ContextMenuTrigger TrayIcon::GetContextMenuTrigger() {
  return ContextMenuTrigger::None;
}

Rectangle TrayIcon::GetBounds() {
  return Rectangle{0, 0, 0, 0};
}

bool TrayIcon::SetVisible(bool visible) {
  return false;
}

bool TrayIcon::IsVisible() {
  return false;
}

bool TrayIcon::OpenContextMenu() {
  return false;
}

bool TrayIcon::CloseContextMenu() {
  return false;
}

void TrayIcon::StartEventListening() {
  // No event monitoring needed on iOS
}

void TrayIcon::StopEventListening() {
  // No cleanup needed
}

void* TrayIcon::GetNativeObjectInternal() const {
  return nullptr;
}

}  // namespace nativeapi
