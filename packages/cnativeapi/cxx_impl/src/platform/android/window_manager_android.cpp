#include <android/log.h>
#include <android/native_activity.h>
#include <android/native_window.h>
#include <iostream>
#include <mutex>
#include <unordered_map>
#include "../../window.h"
#include "../../window_manager.h"
#include "../../window_registry.h"

#define LOG_TAG "NativeApi"
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define ALOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

namespace nativeapi {

// Helper function to manage mapping between ANativeWindow pointers and WindowIds
static WindowId GetOrCreateWindowId(ANativeWindow* native_window) {
  if (!native_window) {
    return IdAllocator::kInvalidId;
  }

  static std::unordered_map<ANativeWindow*, WindowId> window_id_map;
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

// Helper function to find ANativeWindow by WindowId
static ANativeWindow* FindNativeWindowById(WindowId id) {
  static std::unordered_map<ANativeWindow*, WindowId> window_id_map;
  static std::mutex map_mutex;

  std::lock_guard<std::mutex> lock(map_mutex);
  for (const auto& pair : window_id_map) {
    if (pair.second == id) {
      return pair.first;
    }
  }
  return nullptr;
}

// Private implementation for Android
class WindowManager::Impl {
 public:
  Impl(WindowManager* manager) : manager_(manager) {}
  ~Impl() {}

  void StartEventListening() {
    // On Android, event monitoring is done through Activity callbacks
    // Setup will be handled by the Activity lifecycle
    ALOGI("Window event monitoring setup");
  }

  void StopEventListening() { ALOGI("Window event monitoring cleanup"); }

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
  ANativeWindow* native_window = FindNativeWindowById(id);
  if (native_window) {
    auto window = std::make_shared<Window>(static_cast<void*>(native_window));
    WindowRegistry::GetInstance().Add(id, window);
    return window;
  }

  return nullptr;
}

std::vector<std::shared_ptr<Window>> WindowManager::GetAll() {
  return WindowRegistry::GetInstance().GetAll();
}

std::shared_ptr<Window> WindowManager::GetCurrent() {
  // On Android, the current window is typically the Activity's native window
  // This would need to be set by the Activity lifecycle callbacks
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
  // Android doesn't support swizzling for window show/hide
  // Return false to indicate unsupported
  return false;
}

bool WindowManager::CallOriginalHide(WindowId id) {
  // Android doesn't support swizzling for window show/hide
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
