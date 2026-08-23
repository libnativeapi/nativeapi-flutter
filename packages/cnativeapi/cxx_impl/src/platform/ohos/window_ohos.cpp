#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <iostream>
#include <memory>
#include <mutex>
#include <unordered_map>
#include "../../foundation/id_allocator.h"
#include "../../window.h"
#include "../../window_manager.h"

namespace nativeapi {

// Private implementation class
class Window::Impl {
 public:
  Impl(void* window) : native_window_(window), visual_effect_(VisualEffect::None) {}
  void* native_window_;
  VisualEffect visual_effect_;
};

Window::Window() : pimpl_(std::make_unique<Impl>(nullptr)) {}

Window::Window(void* window) : pimpl_(std::make_unique<Impl>(window)) {}

Window::~Window() {}

WindowId Window::GetId() const {
  if (!pimpl_->native_window_) {
    return IdAllocator::kInvalidId;
  }

  // Store the allocated ID in a static map to ensure consistency
  static std::unordered_map<void*, WindowId> window_id_map;
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
    // On OpenHarmony, focus is managed by the Ability lifecycle
    // Window focus requested
  }
}

void Window::Blur() {
  if (pimpl_->native_window_) {
    // On OpenHarmony, blur is managed by the Ability lifecycle
    // Window blur requested
  }
}

bool Window::IsFocused() const {
  // OpenHarmony manages focus through the Ability lifecycle
  return pimpl_->native_window_ != nullptr;
}

void Window::Show() {
  if (pimpl_->native_window_) {
    // On OpenHarmony, visibility is managed by the Ability lifecycle
    // Window show requested
  }
}

void Window::ShowInactive() {
  if (pimpl_->native_window_) {
    Show();
  }
}

void Window::Hide() {
  if (pimpl_->native_window_) {
    // On OpenHarmony, visibility is managed by the Ability lifecycle
    // Window hide requested
  }
}

bool Window::IsVisible() const {
  return pimpl_->native_window_ != nullptr;
}

void Window::Maximize() {
  // Maximize is not applicable to OpenHarmony Abilities
  // Maximize not supported on OpenHarmony
}

void Window::Unmaximize() {
  // Unmaximize is not applicable to OpenHarmony Abilities
  // Unmaximize not supported on OpenHarmony
}

bool Window::IsMaximized() const {
  return false;
}

void Window::Minimize() {
  // On OpenHarmony, this would move the Ability to background
  if (pimpl_->native_window_) {
    // Window minimize requested
  }
}

void Window::Restore() {
  // On OpenHarmony, restore would bring Ability to foreground
  if (pimpl_->native_window_) {
    // Window restore requested
  }
}

bool Window::IsMinimized() const {
  return false;
}

void Window::SetFullScreen(bool is_full_screen) {
  // On OpenHarmony, fullscreen is managed through window properties
  if (pimpl_->native_window_) {
    // Fullscreen set
  }
}

bool Window::IsFullScreen() const {
  return false;
}

void Window::SetBounds(Rectangle bounds) {
  if (pimpl_->native_window_) {
    // SetBounds called
  }
}

Rectangle Window::GetBounds() const {
  if (!pimpl_->native_window_) {
    return Rectangle{0.0, 0.0, 0.0, 0.0};
  }

  // Default bounds for OpenHarmony
  return Rectangle{0.0, 0.0, 360.0, 780.0};
}

void Window::SetSize(Size size, bool animate) {
  if (pimpl_->native_window_) {
    // SetSize called
  }
}

Size Window::GetSize() const {
  if (!pimpl_->native_window_) {
    return Size{0.0, 0.0};
  }

  return Size{360.0, 780.0};
}

void Window::SetContentSize(Size size) {
  SetSize(size, false);
}

Size Window::GetContentSize() const {
  return GetSize();
}

void Window::SetContentBounds(Rectangle bounds) {
  // On OpenHarmony, content bounds is the same as window bounds
  SetBounds(bounds);
}

Rectangle Window::GetContentBounds() const {
  // On OpenHarmony, content bounds is the same as window bounds
  return GetBounds();
}

void Window::SetMinimumSize(Size size) {
  // SetMinimumSize not fully supported on OpenHarmony
}

Size Window::GetMinimumSize() const {
  return Size{0, 0};
}

void Window::SetMaximumSize(Size size) {
  // SetMaximumSize not fully supported on OpenHarmony
}

Size Window::GetMaximumSize() const {
  return Size{0, 0};
}

void Window::SetResizable(bool is_resizable) {
  // SetResizable not supported on OpenHarmony
}

bool Window::IsResizable() const {
  return false;
}

void Window::SetMovable(bool is_movable) {
  // SetMovable not supported on OpenHarmony
}

bool Window::IsMovable() const {
  return false;
}

void Window::SetMinimizable(bool is_minimizable) {
  // SetMinimizable not supported on OpenHarmony
}

bool Window::IsMinimizable() const {
  return true;
}

void Window::SetMaximizable(bool is_maximizable) {
  // SetMaximizable not supported on OpenHarmony
}

bool Window::IsMaximizable() const {
  return false;
}

void Window::SetFullScreenable(bool is_full_screenable) {
  // SetFullScreenable not supported on OpenHarmony
}

bool Window::IsFullScreenable() const {
  return true;
}

void Window::SetClosable(bool is_closable) {
  // SetClosable not supported on OpenHarmony
}

bool Window::IsClosable() const {
  return true;
}

void Window::SetWindowControlButtonsVisible(bool is_visible) {
  // Not applicable to OpenHarmony - mobile apps don't have window control buttons
}

bool Window::IsWindowControlButtonsVisible() const {
  // Not applicable to OpenHarmony - mobile apps don't have window control buttons
  return false;
}

void Window::SetAlwaysOnTop(bool is_always_on_top) {
  // SetAlwaysOnTop not fully supported on OpenHarmony
}

bool Window::IsAlwaysOnTop() const {
  return false;
}

void Window::SetPosition(Point point) {
  // SetPosition not supported on OpenHarmony
}

Point Window::GetPosition() const {
  return Point{0, 0};
}

void Window::Center() {
  // On OpenHarmony, window positioning is not supported
  // Abilities are automatically managed by the system
  if (pimpl_->native_window_) {
    // Center not supported on OpenHarmony - Abilities are managed by the system
  }
}

void Window::SetTitle(std::string title) {
  // SetTitle not supported on OpenHarmony (use Ability title)
}

std::string Window::GetTitle() const {
  return "";
}

void Window::SetTitleBarStyle(TitleBarStyle style) {
  // SetTitleBarStyle not supported on OpenHarmony (use system bar APIs)
}

TitleBarStyle Window::GetTitleBarStyle() const {
  return TitleBarStyle::Normal;
}

void Window::SetHasShadow(bool has_shadow) {
  // SetHasShadow not supported on OpenHarmony
}

bool Window::HasShadow() const {
  return false;
}

void Window::SetOpacity(float opacity) {
  // SetOpacity not supported on OpenHarmony
}

float Window::GetOpacity() const {
  return 1.0f;
}

void Window::SetVisualEffect(VisualEffect effect) {
  pimpl_->visual_effect_ = effect;
  // SetVisualEffect not supported on OpenHarmony
}

VisualEffect Window::GetVisualEffect() const {
  return pimpl_->visual_effect_;
}

void Window::SetBackgroundColor(const Color& color) {
  // SetBackgroundColor not supported on OpenHarmony
}

Color Window::GetBackgroundColor() const {
  return Color::White;
}

void Window::SetVisibleOnAllWorkspaces(bool is_visible_on_all_workspaces) {
  // SetVisibleOnAllWorkspaces not supported on OpenHarmony
}

bool Window::IsVisibleOnAllWorkspaces() const {
  return false;
}

void Window::SetIgnoreMouseEvents(bool is_ignore_mouse_events) {
  // SetIgnoreMouseEvents not supported on OpenHarmony
}

bool Window::IsIgnoreMouseEvents() const {
  return false;
}

void Window::SetFocusable(bool is_focusable) {
  // SetFocusable not supported on OpenHarmony
}

bool Window::IsFocusable() const {
  return true;
}

void Window::StartDragging() {
  // StartDragging not supported on OpenHarmony
}

void Window::StartResizing() {
  // StartResizing not supported on OpenHarmony
}

void* Window::GetNativeObjectInternal() const {
  return pimpl_->native_window_;
}

}  // namespace nativeapi
