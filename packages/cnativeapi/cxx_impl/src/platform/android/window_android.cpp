#include <android/log.h>
#include <android/native_window.h>
#include <iostream>
#include "../../window.h"
#include "../../window_manager.h"

#define LOG_TAG "NativeApi"
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define ALOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

namespace nativeapi {

// Private implementation class
class Window::Impl {
 public:
  Impl(ANativeWindow* window) : native_window_(window), visual_effect_(VisualEffect::None) {}
  ANativeWindow* native_window_;
  VisualEffect visual_effect_;
};

Window::Window() : pimpl_(std::make_unique<Impl>(nullptr)) {}

Window::Window(void* window)
    : pimpl_(std::make_unique<Impl>(static_cast<ANativeWindow*>(window))) {}

Window::~Window() {}

WindowId Window::GetId() const {
  if (!pimpl_->native_window_) {
    return IdAllocator::kInvalidId;
  }

  // Store the allocated ID in a static map to ensure consistency
  static std::unordered_map<ANativeWindow*, WindowId> window_id_map;
  static std::mutex map_mutex;

  std::lock_guard<std::mutex> lock(map_mutex);
  auto it = window_id_map.find(pimpl_->native_window_);
  if (it != window_id_map.end()) {
    return it->second;
  }

  // Allocate new ID using the IdAllocator
  WindowId new_id = IdAllocator::Allocate<Window>();
  if (new_id != IdAllocator::kInvalidId) {
    window_id_map[pimpl_->native_window_] = new_id;
  }
  return new_id;
}

void Window::Focus() {
  if (pimpl_->native_window_) {
    // On Android, focus is managed by the Activity lifecycle
    // This is a no-op as the Activity manager handles focus
    ALOGI("Window focus requested");
  }
}

void Window::Blur() {
  if (pimpl_->native_window_) {
    // On Android, blur is managed by the Activity lifecycle
    ALOGI("Window blur requested");
  }
}

bool Window::IsFocused() const {
  // Android manages focus through the Activity lifecycle
  // We cannot reliably query focus state from NDK
  return pimpl_->native_window_ != nullptr;
}

void Window::Show() {
  if (pimpl_->native_window_) {
    // On Android, visibility is managed by the Activity lifecycle
    // This would typically trigger onWindowShown callback in Java
    ALOGI("Window show requested");
  }
}

void Window::ShowInactive() {
  if (pimpl_->native_window_) {
    // Same as Show on Android
    Show();
  }
}

void Window::Hide() {
  if (pimpl_->native_window_) {
    // On Android, visibility is managed by the Activity lifecycle
    ALOGI("Window hide requested");
  }
}

bool Window::IsVisible() const {
  return pimpl_->native_window_ != nullptr;
}

void Window::Maximize() {
  // Maximize is not applicable to Android Activities
  ALOGW("Maximize not supported on Android");
}

void Window::Unmaximize() {
  // Unmaximize is not applicable to Android Activities
  ALOGW("Unmaximize not supported on Android");
}

bool Window::IsMaximized() const {
  // Android Activities are typically fullscreen or windowed
  return false;
}

void Window::Minimize() {
  // On Android, this would move the Activity to background
  if (pimpl_->native_window_) {
    ALOGI("Window minimize requested");
  }
}

void Window::Restore() {
  // On Android, restore would bring Activity to foreground
  if (pimpl_->native_window_) {
    ALOGI("Window restore requested");
  }
}

bool Window::IsMinimized() const {
  // Cannot reliably determine minimized state from NDK
  return false;
}

void Window::SetFullScreen(bool is_full_screen) {
  // On Android, fullscreen is managed through Activity flags
  if (pimpl_->native_window_) {
    ALOGI("Fullscreen set to: %d", is_full_screen);
  }
}

bool Window::IsFullScreen() const {
  // Cannot reliably determine fullscreen state from NDK
  return false;
}

void Window::SetBounds(Rectangle bounds) {
  if (pimpl_->native_window_) {
    ALOGI("SetBounds called: x=%f, y=%f, w=%f, h=%f", bounds.x, bounds.y, bounds.width,
          bounds.height);
    // Android windows resize is handled by the system
  }
}

Rectangle Window::GetBounds() const {
  if (!pimpl_->native_window_) {
    return Rectangle{0.0, 0.0, 0.0, 0.0};
  }

  // Get window dimensions from ANativeWindow
  int32_t width = ANativeWindow_getWidth(pimpl_->native_window_);
  int32_t height = ANativeWindow_getHeight(pimpl_->native_window_);

  return Rectangle{0.0, 0.0, static_cast<double>(width), static_cast<double>(height)};
}

void Window::SetSize(Size size, bool animate) {
  if (pimpl_->native_window_) {
    ALOGI("SetSize called: w=%f, h=%f", size.width, size.height);
    // Size is managed by the Activity/View system
  }
}

Size Window::GetSize() const {
  if (!pimpl_->native_window_) {
    return Size{0.0, 0.0};
  }

  int32_t width = ANativeWindow_getWidth(pimpl_->native_window_);
  int32_t height = ANativeWindow_getHeight(pimpl_->native_window_);

  return Size{static_cast<double>(width), static_cast<double>(height)};
}

void Window::SetContentSize(Size size) {
  // On Android, content size is the same as window size
  SetSize(size, false);
}

Size Window::GetContentSize() const {
  return GetSize();
}

void Window::SetContentBounds(Rectangle bounds) {
  // On Android, content bounds is the same as window bounds
  SetBounds(bounds);
}

Rectangle Window::GetContentBounds() const {
  // On Android, content bounds is the same as window bounds
  return GetBounds();
}

void Window::SetMinimumSize(Size size) {
  ALOGW("SetMinimumSize not fully supported on Android");
}

Size Window::GetMinimumSize() const {
  return Size{0, 0};
}

void Window::SetMaximumSize(Size size) {
  ALOGW("SetMaximumSize not fully supported on Android");
}

Size Window::GetMaximumSize() const {
  return Size{0, 0};
}

void Window::SetResizable(bool is_resizable) {
  ALOGW("SetResizable not supported on Android");
}

bool Window::IsResizable() const {
  return false;
}

void Window::SetMovable(bool is_movable) {
  ALOGW("SetMovable not supported on Android");
}

bool Window::IsMovable() const {
  return false;
}

void Window::SetMinimizable(bool is_minimizable) {
  ALOGW("SetMinimizable not supported on Android");
}

bool Window::IsMinimizable() const {
  return true;
}

void Window::SetMaximizable(bool is_maximizable) {
  ALOGW("SetMaximizable not supported on Android");
}

bool Window::IsMaximizable() const {
  return false;
}

void Window::SetFullScreenable(bool is_full_screenable) {
  ALOGW("SetFullScreenable not supported on Android");
}

bool Window::IsFullScreenable() const {
  return true;
}

void Window::SetClosable(bool is_closable) {
  ALOGW("SetClosable not supported on Android");
}

bool Window::IsClosable() const {
  return true;
}

void Window::SetWindowControlButtonsVisible(bool is_visible) {
  // Not applicable to Android - mobile apps don't have window control buttons
}

bool Window::IsWindowControlButtonsVisible() const {
  // Not applicable to Android - mobile apps don't have window control buttons
  return false;
}

void Window::SetAlwaysOnTop(bool is_always_on_top) {
  ALOGW("SetAlwaysOnTop not fully supported on Android");
}

bool Window::IsAlwaysOnTop() const {
  return false;
}

void Window::SetPosition(Point point) {
  ALOGW("SetPosition not supported on Android");
}

Point Window::GetPosition() const {
  return Point{0, 0};
}

void Window::Center() {
  // On Android, window positioning is not supported
  // Activities are automatically managed by the system
  ALOGW("Center not supported on Android - Activities are managed by the system");
}

void Window::SetTitle(std::string title) {
  ALOGW("SetTitle not supported on Android (use Activity title)");
}

std::string Window::GetTitle() const {
  return "";
}

void Window::SetTitleBarStyle(TitleBarStyle style) {
  ALOGW("SetTitleBarStyle not supported on Android (use system UI visibility flags)");
}

TitleBarStyle Window::GetTitleBarStyle() const {
  return TitleBarStyle::Normal;
}

void Window::SetHasShadow(bool has_shadow) {
  ALOGW("SetHasShadow not supported on Android");
}

bool Window::HasShadow() const {
  return false;
}

void Window::SetOpacity(float opacity) {
  ALOGW("SetOpacity not supported on Android");
}

float Window::GetOpacity() const {
  return 1.0f;
}

void Window::SetVisualEffect(VisualEffect effect) {
  pimpl_->visual_effect_ = effect;
  ALOGW("SetVisualEffect not supported on Android");
}

VisualEffect Window::GetVisualEffect() const {
  return pimpl_->visual_effect_;
}

void Window::SetBackgroundColor(const Color& color) {
  ALOGW("SetBackgroundColor not supported on Android");
}

Color Window::GetBackgroundColor() const {
  return Color::White;
}

void Window::SetVisibleOnAllWorkspaces(bool is_visible_on_all_workspaces) {
  ALOGW("SetVisibleOnAllWorkspaces not supported on Android");
}

bool Window::IsVisibleOnAllWorkspaces() const {
  return false;
}

void Window::SetIgnoreMouseEvents(bool is_ignore_mouse_events) {
  ALOGW("SetIgnoreMouseEvents not supported on Android");
}

bool Window::IsIgnoreMouseEvents() const {
  return false;
}

void Window::SetFocusable(bool is_focusable) {
  ALOGW("SetFocusable not supported on Android");
}

bool Window::IsFocusable() const {
  return true;
}

void Window::StartDragging() {
  ALOGW("StartDragging not supported on Android");
}

void Window::StartResizing() {
  ALOGW("StartResizing not supported on Android");
}

void* Window::GetNativeObjectInternal() const {
  return static_cast<void*>(pimpl_->native_window_);
}

}  // namespace nativeapi
