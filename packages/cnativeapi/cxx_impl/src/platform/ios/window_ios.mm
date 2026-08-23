#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <string>
#include "../../window.h"
#include "../../window_manager.h"

namespace nativeapi {

// Private implementation class
class Window::Impl {
 public:
  Impl(UIWindow* window) : ui_window_(window), visual_effect_(VisualEffect::None) {}
  UIWindow* ui_window_;
  VisualEffect visual_effect_;
};

Window::Window() : pimpl_(std::make_unique<Impl>(nil)) {}

Window::Window(void* window) : pimpl_(std::make_unique<Impl>((__bridge UIWindow*)window)) {}

Window::~Window() {}

WindowId Window::GetId() const {
  if (!pimpl_->ui_window_) {
    return IdAllocator::kInvalidId;
  }

  // Store the allocated ID in a static map to ensure consistency
  // Note: Use void* as the key to avoid hashing issues for ObjC pointers with libc++ on iOS
  static std::unordered_map<void*, WindowId> window_id_map;
  static std::mutex map_mutex;

  std::lock_guard<std::mutex> lock(map_mutex);
  auto it = window_id_map.find((__bridge void*)pimpl_->ui_window_);
  if (it != window_id_map.end()) {
    return it->second;
  }

  // Allocate new ID using the IdAllocator
  WindowId new_id = IdAllocator::Allocate<Window>();
  if (new_id != IdAllocator::kInvalidId) {
    window_id_map[(__bridge void*)pimpl_->ui_window_] = new_id;
  }
  return new_id;
}

void Window::Focus() {
  if (pimpl_->ui_window_) {
    // On iOS, focus is managed by the view controller and system
    [pimpl_->ui_window_ makeKeyWindow];
  }
}

void Window::Blur() {
  if (pimpl_->ui_window_) {
    // On iOS, blur is managed by the system
    [pimpl_->ui_window_ resignKeyWindow];
  }
}

bool Window::IsFocused() const {
  return pimpl_->ui_window_ && [pimpl_->ui_window_ isKeyWindow];
}

void Window::Show() {
  if (pimpl_->ui_window_) {
    // On iOS, windows are typically shown through view controllers
    pimpl_->ui_window_.hidden = NO;
    [pimpl_->ui_window_ makeKeyAndVisible];
  }
}

void Window::ShowInactive() {
  if (pimpl_->ui_window_) {
    // Same as Show on iOS
    Show();
  }
}

void Window::Hide() {
  if (pimpl_->ui_window_) {
    pimpl_->ui_window_.hidden = YES;
  }
}

bool Window::IsVisible() const {
  return pimpl_->ui_window_ && !pimpl_->ui_window_.hidden;
}

void Window::Maximize() {
  // Maximize is not applicable to iOS (fullscreen is used instead)
}

void Window::Unmaximize() {
  // Unmaximize is not applicable to iOS
}

bool Window::IsMaximized() const {
  return false;
}

void Window::Minimize() {
  // On iOS, minimize sends app to background
  if (pimpl_->ui_window_) {
    // This would trigger application background mode
  }
}

void Window::Restore() {
  // On iOS, restore brings app to foreground
  if (pimpl_->ui_window_) {
    [pimpl_->ui_window_ makeKeyAndVisible];
  }
}

bool Window::IsMinimized() const {
  // Cannot reliably determine minimized state on iOS
  return false;
}

void Window::SetFullScreen(bool is_full_screen) {
  // On iOS, fullscreen is managed through view controller
  if (pimpl_->ui_window_) {
    UIViewController* rootVC = pimpl_->ui_window_.rootViewController;
    if (rootVC) {
      rootVC.modalPresentationStyle =
          is_full_screen ? UIModalPresentationFullScreen : UIModalPresentationPageSheet;
    }
  }
}

bool Window::IsFullScreen() const {
  if (!pimpl_->ui_window_) {
    return false;
  }

  UIViewController* rootVC = pimpl_->ui_window_.rootViewController;
  return rootVC && rootVC.modalPresentationStyle == UIModalPresentationFullScreen;
}

void Window::SetBounds(Rectangle bounds) {
  if (pimpl_->ui_window_) {
    pimpl_->ui_window_.frame = CGRectMake(bounds.x, bounds.y, bounds.width, bounds.height);
  }
}

Rectangle Window::GetBounds() const {
  if (!pimpl_->ui_window_) {
    return Rectangle{0.0, 0.0, 0.0, 0.0};
  }

  CGRect frame = pimpl_->ui_window_.frame;
  return Rectangle{static_cast<double>(frame.origin.x), static_cast<double>(frame.origin.y),
                   static_cast<double>(frame.size.width), static_cast<double>(frame.size.height)};
}

void Window::SetSize(Size size, bool animate) {
  if (pimpl_->ui_window_) {
    CGRect frame = pimpl_->ui_window_.frame;
    frame.size.width = size.width;
    frame.size.height = size.height;

    if (animate) {
      [UIView animateWithDuration:0.3
                       animations:^{
                         pimpl_->ui_window_.frame = frame;
                       }];
    } else {
      pimpl_->ui_window_.frame = frame;
    }
  }
}

Size Window::GetSize() const {
  if (!pimpl_->ui_window_) {
    return Size{0.0, 0.0};
  }

  CGSize size = pimpl_->ui_window_.frame.size;
  return Size{static_cast<double>(size.width), static_cast<double>(size.height)};
}

void Window::SetContentSize(Size size) {
  // On iOS, content size is the same as window size
  SetSize(size, false);
}

Size Window::GetContentSize() const {
  return GetSize();
}

void Window::SetContentBounds(Rectangle bounds) {
  // On iOS, content bounds is the same as window bounds
  SetBounds(bounds);
}

Rectangle Window::GetContentBounds() const {
  // On iOS, content bounds is the same as window bounds
  return GetBounds();
}

void Window::SetMinimumSize(Size size) {
  // Not applicable to iOS windows
}

Size Window::GetMinimumSize() const {
  return Size{0, 0};
}

void Window::SetMaximumSize(Size size) {
  // Not applicable to iOS windows
}

Size Window::GetMaximumSize() const {
  return Size{0, 0};
}

void Window::SetResizable(bool is_resizable) {
  // iOS windows are not resizable by users
}

bool Window::IsResizable() const {
  return false;
}

void Window::SetMovable(bool is_movable) {
  // iOS windows are not movable by users
}

bool Window::IsMovable() const {
  return false;
}

void Window::SetMinimizable(bool is_minimizable) {
  // iOS manages minimization automatically
}

bool Window::IsMinimizable() const {
  return true;
}

void Window::SetMaximizable(bool is_maximizable) {
  // Maximization is not applicable to iOS
}

bool Window::IsMaximizable() const {
  return false;
}

void Window::SetFullScreenable(bool is_full_screenable) {
  // Fullscreen is controlled by view controller presentation style
}

bool Window::IsFullScreenable() const {
  return true;
}

void Window::SetClosable(bool is_closable) {
  // iOS manages app lifecycle automatically
}

bool Window::IsClosable() const {
  return true;
}

void Window::SetWindowControlButtonsVisible(bool is_visible) {
  // Not applicable to iOS - mobile apps don't have window control buttons
}

bool Window::IsWindowControlButtonsVisible() const {
  // Not applicable to iOS - mobile apps don't have window control buttons
  return false;
}

void Window::SetAlwaysOnTop(bool is_always_on_top) {
  // Not applicable to iOS (no multi-window in traditional sense)
}

bool Window::IsAlwaysOnTop() const {
  return false;
}

void Window::SetPosition(Point point) {
  if (pimpl_->ui_window_) {
    CGRect frame = pimpl_->ui_window_.frame;
    frame.origin.x = point.x;
    frame.origin.y = point.y;
    pimpl_->ui_window_.frame = frame;
  }
}

Point Window::GetPosition() const {
  if (!pimpl_->ui_window_) {
    return Point{0, 0};
  }

  CGPoint origin = pimpl_->ui_window_.frame.origin;
  return Point{static_cast<double>(origin.x), static_cast<double>(origin.y)};
}

void Window::Center() {
  if (!pimpl_->ui_window_)
    return;

  // Get the screen bounds
  UIScreen* screen = pimpl_->ui_window_.screen ?: [UIScreen mainScreen];
  CGRect screenBounds = screen.bounds;

  // Get the current window size
  CGRect windowFrame = pimpl_->ui_window_.frame;

  // Calculate center position
  CGFloat centerX = (screenBounds.size.width - windowFrame.size.width) / 2.0;
  CGFloat centerY = (screenBounds.size.height - windowFrame.size.height) / 2.0;

  // Set the centered frame
  windowFrame.origin.x = centerX;
  windowFrame.origin.y = centerY;
  pimpl_->ui_window_.frame = windowFrame;
}

void Window::SetTitle(std::string title) {
  // iOS windows don't have titles (use view controller title)
  if (pimpl_->ui_window_) {
    UIViewController* rootVC = pimpl_->ui_window_.rootViewController;
    if (rootVC) {
      rootVC.title = [NSString stringWithUTF8String:title.c_str()];
    }
  }
}

std::string Window::GetTitle() const {
  if (!pimpl_->ui_window_) {
    return "";
  }

  UIViewController* rootVC = pimpl_->ui_window_.rootViewController;
  if (rootVC && rootVC.title) {
    return std::string([rootVC.title UTF8String]);
  }
  return "";
}

void Window::SetTitleBarStyle(TitleBarStyle style) {
  // iOS doesn't have traditional title bars
  // Use UIViewController.prefersStatusBarHidden or navigation bar appearance instead
  NSLog(@"SetTitleBarStyle not applicable on iOS (use status bar or navigation bar APIs)");
}

TitleBarStyle Window::GetTitleBarStyle() const {
  return TitleBarStyle::Normal;
}

void Window::SetHasShadow(bool has_shadow) {
  // iOS manages shadow automatically
}

bool Window::HasShadow() const {
  return true;
}

void Window::SetOpacity(float opacity) {
  if (pimpl_->ui_window_) {
    pimpl_->ui_window_.alpha = opacity;
  }
}

float Window::GetOpacity() const {
  return pimpl_->ui_window_ ? pimpl_->ui_window_.alpha : 1.0f;
}

void Window::SetVisualEffect(VisualEffect effect) {
  pimpl_->visual_effect_ = effect;
  NSLog(@"SetVisualEffect not supported on iOS");
}

VisualEffect Window::GetVisualEffect() const {
  return pimpl_->visual_effect_;
}

void Window::SetBackgroundColor(const Color& color) {
  // Not applicable to iOS
}

Color Window::GetBackgroundColor() const {
  return Color::White;
}

void Window::SetVisibleOnAllWorkspaces(bool is_visible_on_all_workspaces) {
  // Not applicable to iOS
}

bool Window::IsVisibleOnAllWorkspaces() const {
  return false;
}

void Window::SetIgnoreMouseEvents(bool is_ignore_mouse_events) {
  // Not applicable to iOS
}

bool Window::IsIgnoreMouseEvents() const {
  return false;
}

void Window::SetFocusable(bool is_focusable) {
  // iOS manages focus automatically
}

bool Window::IsFocusable() const {
  return true;
}

void Window::StartDragging() {
  // Not applicable to iOS
}

void Window::StartResizing() {
  // Not applicable to iOS
}

void* Window::GetNativeObjectInternal() const {
  return (__bridge void*)pimpl_->ui_window_;
}

}  // namespace nativeapi
