#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <iostream>
#include <memory>
#include <mutex>
#include <unordered_map>
#include "../../window.h"
#include "../../window_manager.h"
#include "../../window_registry.h"

namespace nativeapi {

// Helper function to manage mapping between window pointers and WindowIds
static WindowId GetOrCreateWindowId(void* native_window) {
  if (!native_window) {
    return IdAllocator::kInvalidId;
  }

  static std::unordered_map<void*, WindowId> window_id_map;
  static std::mutex map_mutex;

  std::lock_guard<std::mutex> lock(map_mutex);
  auto it = window_id_map.find(native_window);
  if (it != window_id_map.end()) {
    return it->second;
  }

  // Allocate new ID using the IdAllocator
  WindowId new_id = IdAllocator::Allocate<Window>();
  if (new_id != IdAllocator::kInvalidId) {
    window_id_map[native_window] = new_id;
  }
  return new_id;
}

// Helper function to find window by WindowId
static void* FindNativeWindowById(WindowId id) {
  static std::unordered_map<void*, WindowId> window_id_map;
  static std::mutex map_mutex;

  std::lock_guard<std::mutex> lock(map_mutex);
  for (const auto& pair : window_id_map) {
    if (pair.second == id) {
      return pair.first;
    }
  }
  return nullptr;
}

// Private implementation for OpenHarmony
class WindowManager::Impl {
 public:
  Impl(WindowManager* manager) : manager_(manager) {}
  ~Impl() {}

  void StartEventListening() {
    // On OpenHarmony, event monitoring is done through Ability callbacks
    // Window event monitoring setup
  }

  void StopEventListening() {
    // Window event monitoring cleanup
  }

 private:
  WindowManager* manager_;
};

WindowManager::WindowManager() : pimpl_(std::make_unique<Impl>(this)) {
  StartEventListening();
}

WindowManager::~WindowManager() {
  StopEventListening();
}

std::shared_ptr<Window> WindowManager::Get(WindowId id) {
  auto cached = WindowRegistry::GetInstance().Get(id);
  if (cached) {
    return cached;
  }

  // Try to find the window by ID
  void* native_window = FindNativeWindowById(id);
  if (native_window) {
    auto window = std::make_shared<Window>(native_window);
    WindowRegistry::GetInstance().Add(id, window);
    return window;
  }

  return nullptr;
}

std::vector<std::shared_ptr<Window>> WindowManager::GetAll() {
  return WindowRegistry::GetInstance().GetAll();
}

std::shared_ptr<Window> WindowManager::GetCurrent() {
  // On OpenHarmony, the current window is typically the Ability's window
  auto all = WindowRegistry::GetInstance().GetAll();
  return all.empty() ? nullptr : all.front();
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
  // OpenHarmony doesn't support swizzling for window show/hide
  // Return false to indicate unsupported
  return false;
}

bool WindowManager::CallOriginalHide(WindowId id) {
  // OpenHarmony doesn't support swizzling for window show/hide
  // Return false to indicate unsupported
  return false;
}

void WindowManager::StartEventListening() {
  pimpl_->StartEventListening();
}

void WindowManager::StopEventListening() {
  pimpl_->StopEventListening();
}

void WindowManager::DispatchWindowEvent(const WindowEvent& event) {
  Emit(event);
}

}  // namespace nativeapi
