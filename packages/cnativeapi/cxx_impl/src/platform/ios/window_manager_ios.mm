#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "../../window_manager.h"
#include "../../window_registry.h"

namespace nativeapi {

class WindowManager::Impl {
 public:
  Impl(WindowManager* manager) : manager_(manager) {}
  WindowManager* manager_;
};

WindowManager::WindowManager() : pimpl_(std::make_unique<Impl>(this)) {
  StartEventListening();
}

WindowManager::~WindowManager() {
  StopEventListening();
}

std::shared_ptr<Window> WindowManager::Get(WindowId id) {
  return WindowRegistry::GetInstance().Get(id);
}

std::vector<std::shared_ptr<Window>> WindowManager::GetAll() {
  return WindowRegistry::GetInstance().GetAll();
}

std::shared_ptr<Window> WindowManager::GetCurrent() {
  // Find the first key window
  for (const auto& window : WindowRegistry::GetInstance().GetAll()) {
    if (window->IsFocused()) {
      return window;
    }
  }
  return nullptr;
}

void WindowManager::SetWillShowHook(std::optional<WindowWillShowHook> hook) {
  // Empty implementation
}

void WindowManager::SetWillHideHook(std::optional<WindowWillHideHook> hook) {
  // Empty implementation
}

bool WindowManager::HasWillShowHook() const {
  return false;
}

bool WindowManager::HasWillHideHook() const {
  return false;
}

void WindowManager::HandleWillShow(WindowId id) {
  // Empty implementation
}

void WindowManager::HandleWillHide(WindowId id) {
  // Empty implementation
}

bool WindowManager::CallOriginalShow(WindowId id) {
  // iOS doesn't support swizzling for window show/hide
  // Return false to indicate unsupported
  return false;
}

bool WindowManager::CallOriginalHide(WindowId id) {
  // iOS doesn't support swizzling for window show/hide
  // Return false to indicate unsupported
  return false;
}

void WindowManager::StartEventListening() {
  // iOS manages window events through UIKit
}

void WindowManager::StopEventListening() {
  // No cleanup needed
}

void WindowManager::DispatchWindowEvent(const WindowEvent& event) {
  Emit(event);
}

}  // namespace nativeapi
