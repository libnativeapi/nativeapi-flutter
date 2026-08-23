#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#include <cstring>
#include <iostream>
#include <string>

#include "../../window.h"
#include "../../window_manager.h"
#include "../../window_registry.h"

// Forward declaration for the delegate
@class NativeAPIWindowManagerDelegate;

// External declaration of kWindowIdKey (defined in window_macos.mm)
extern const void* kWindowIdKey;

namespace nativeapi {

// Private implementation to hide Objective-C details
class WindowManager::Impl {
 public:
  Impl(WindowManager* manager);
  ~Impl();
  void StartEventListening();
  void StopEventListening();
  void OnWindowEvent(NSWindow* window, const std::string& event_type);

 private:
  WindowManager* manager_;
  NativeAPIWindowManagerDelegate* delegate_;

  // Optional pre-show/hide/close hooks
  std::optional<WindowManager::WindowWillShowHook> will_show_hook_;
  std::optional<WindowManager::WindowWillHideHook> will_hide_hook_;
  std::optional<WindowManager::WindowWillCloseHook> will_close_hook_;

  friend class WindowManager;
};

}  // namespace nativeapi

// MARK: - NSWindow Swizzling

// Swizzled implementations call into WindowManager hooks, then forward to original implementations
@interface NSWindow (NativeAPISwizzle)
- (void)na_swizzled_makeKeyAndOrderFront:(id)sender;
- (void)na_swizzled_orderOut:(id)sender;
- (void)na_swizzled_performClose:(id)sender;
@end

@implementation NSWindow (NativeAPISwizzle)

- (void)na_swizzled_makeKeyAndOrderFront:(id)sender {
  // Resolve window id and handle hook if present
  if (nativeapi::WindowManager::GetInstance().HasWillShowHook()) {
    auto windows = nativeapi::WindowManager::GetInstance().GetAll();
    for (const auto& window : windows) {
      if (window->GetNativeObject() == (__bridge void*)self) {
        nativeapi::WindowManager::GetInstance().HandleWillShow(window->GetId());
        // Hook handles all logic; never call original here
        return;
      }
    }
  }
  // No window found in registry, call original implementation (swapped)
  [self na_swizzled_makeKeyAndOrderFront:sender];
}

- (void)na_swizzled_orderOut:(id)sender {
  // Resolve window id and handle hook if present
  if (nativeapi::WindowManager::GetInstance().HasWillHideHook()) {
    auto windows = nativeapi::WindowManager::GetInstance().GetAll();
    for (const auto& window : windows) {
      if (window->GetNativeObject() == (__bridge void*)self) {
        nativeapi::WindowManager::GetInstance().HandleWillHide(window->GetId());
        return;
      }
    }
  }
  // No window found in registry, call original implementation (swapped)
  [self na_swizzled_orderOut:sender];
}

- (void)na_swizzled_performClose:(id)sender {
  // Resolve window id and handle hook if present
  if (nativeapi::WindowManager::GetInstance().HasWillCloseHook()) {
    auto windows = nativeapi::WindowManager::GetInstance().GetAll();
    for (const auto& window : windows) {
      if (window->GetNativeObject() == (__bridge void*)self) {
        nativeapi::WindowManager::GetInstance().HandleWillClose(window->GetId());
        // Hook handles all logic; never call original here
        return;
      }
    }
  }
  // No window found in registry, call original implementation (swapped)
  [self na_swizzled_performClose:sender];
}

@end

static void NativeAPIInstallNSWindowWillShowSwizzleOnce() {
  static dispatch_once_t onceTokenShow;
  dispatch_once(&onceTokenShow, ^{
    Class cls = [NSWindow class];
    SEL originalSel = @selector(makeKeyAndOrderFront:);
    SEL swizzledSel = @selector(na_swizzled_makeKeyAndOrderFront:);
    Method original = class_getInstanceMethod(cls, originalSel);
    Method swizzled = class_getInstanceMethod(cls, swizzledSel);
    if (original && swizzled) {
      method_exchangeImplementations(original, swizzled);
    }
  });
}

static void NativeAPIInstallNSWindowWillHideSwizzleOnce() {
  static dispatch_once_t onceTokenHide;
  dispatch_once(&onceTokenHide, ^{
    Class cls = [NSWindow class];
    SEL originalSel = @selector(orderOut:);
    SEL swizzledSel = @selector(na_swizzled_orderOut:);
    Method original = class_getInstanceMethod(cls, originalSel);
    Method swizzled = class_getInstanceMethod(cls, swizzledSel);
    if (original && swizzled) {
      method_exchangeImplementations(original, swizzled);
    }
  });
}

static void NativeAPIInstallNSWindowWillCloseSwizzleOnce() {
  static dispatch_once_t onceTokenClose;
  dispatch_once(&onceTokenClose, ^{
    Class cls = [NSWindow class];
    SEL originalSel = @selector(performClose:);
    SEL swizzledSel = @selector(na_swizzled_performClose:);
    Method original = class_getInstanceMethod(cls, originalSel);
    Method swizzled = class_getInstanceMethod(cls, swizzledSel);
    if (original && swizzled) {
      method_exchangeImplementations(original, swizzled);
    }
  });
}

// Objective-C delegate class to handle NSWindow notifications
@interface NativeAPIWindowManagerDelegate : NSObject
@property(nonatomic, assign) void* impl;  // Use void* instead of private class
- (instancetype)initWithImpl:(void*)impl;
@end

@implementation NativeAPIWindowManagerDelegate

- (instancetype)initWithImpl:(void*)impl {
  if (self = [super init]) {
    _impl = impl;
  }
  return self;
}

- (void)windowDidBecomeKey:(NSNotification*)notification {
  // NSWindow* window = [notification object];
  if (_impl) {
    //    static_cast<nativeapi::WindowManager::Impl*>(_impl)->OnWindowEvent(window, "focused");
  }
}

- (void)windowDidResignKey:(NSNotification*)notification {
  // NSWindow* window = [notification object];
  if (_impl) {
    //    static_cast<nativeapi::WindowManager::Impl*>(_impl)->OnWindowEvent(window, "blurred");
  }
}

- (void)windowDidMiniaturize:(NSNotification*)notification {
  // NSWindow* window = [notification object];
  if (_impl) {
    //    static_cast<nativeapi::WindowManager::Impl*>(_impl)->OnWindowEvent(window, "minimized");
  }
}

- (void)windowDidDeminiaturize:(NSNotification*)notification {
  // NSWindow* window = [notification object];
  if (_impl) {
    //    static_cast<nativeapi::WindowManager::Impl*>(_impl)->OnWindowEvent(window, "restored");
  }
}

- (void)windowDidResize:(NSNotification*)notification {
  // NSWindow* window = [notification object];
  if (_impl) {
    //    static_cast<nativeapi::WindowManager::Impl*>(_impl)->OnWindowEvent(window, "resized");
  }
}

- (void)windowDidMove:(NSNotification*)notification {
  // NSWindow* window = [notification object];
  if (_impl) {
    //    static_cast<nativeapi::WindowManager::Impl*>(_impl)->OnWindowEvent(window, "moved");
  }
}

- (void)windowWillClose:(NSNotification*)notification {
  // NSWindow* window = [notification object];
  if (_impl) {
    //    static_cast<nativeapi::WindowManager::Impl*>(_impl)->OnWindowEvent(window, "closing");
  }
}

@end

namespace nativeapi {

WindowManager::Impl::Impl(WindowManager* manager) : manager_(manager), delegate_(nullptr) {}

WindowManager::Impl::~Impl() {
  StopEventListening();
}

void WindowManager::Impl::StartEventListening() {
  if (!delegate_) {
    delegate_ = [[NativeAPIWindowManagerDelegate alloc] initWithImpl:this];

    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:delegate_
               selector:@selector(windowDidBecomeKey:)
                   name:NSWindowDidBecomeKeyNotification
                 object:nil];
    [center addObserver:delegate_
               selector:@selector(windowDidResignKey:)
                   name:NSWindowDidResignKeyNotification
                 object:nil];
    [center addObserver:delegate_
               selector:@selector(windowDidMiniaturize:)
                   name:NSWindowDidMiniaturizeNotification
                 object:nil];
    [center addObserver:delegate_
               selector:@selector(windowDidDeminiaturize:)
                   name:NSWindowDidDeminiaturizeNotification
                 object:nil];
    [center addObserver:delegate_
               selector:@selector(windowDidResize:)
                   name:NSWindowDidResizeNotification
                 object:nil];
    [center addObserver:delegate_
               selector:@selector(windowDidMove:)
                   name:NSWindowDidMoveNotification
                 object:nil];
    [center addObserver:delegate_
               selector:@selector(windowWillClose:)
                   name:NSWindowWillCloseNotification
                 object:nil];
  }
}

void WindowManager::Impl::StopEventListening() {
  if (delegate_) {
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:delegate_];
    delegate_ = nil;
  }
}

void WindowManager::Impl::OnWindowEvent(NSWindow* window, const std::string& event_type) {
  WindowId window_id = [window windowNumber];

  if (event_type == "focused") {
    WindowFocusedEvent event(window_id);
    manager_->DispatchWindowEvent(event);
  } else if (event_type == "blurred") {
    WindowBlurredEvent event(window_id);
    manager_->DispatchWindowEvent(event);
  } else if (event_type == "minimized") {
    WindowMinimizedEvent event(window_id);
    manager_->DispatchWindowEvent(event);
  } else if (event_type == "restored") {
    WindowRestoredEvent event(window_id);
    manager_->DispatchWindowEvent(event);
  } else if (event_type == "resized") {
    NSRect frame = [window frame];
    Size new_size = {frame.size.width, frame.size.height};
    WindowResizedEvent event(window_id, new_size);
    manager_->DispatchWindowEvent(event);
  } else if (event_type == "moved") {
    NSRect frame = [window frame];
    Point new_position = {frame.origin.x, frame.origin.y};
    WindowMovedEvent event(window_id, new_position);
    manager_->DispatchWindowEvent(event);
  } else if (event_type == "closing") {
    // Window closing event - no longer emitted
  }
}

WindowManager::WindowManager() : pimpl_(std::make_unique<Impl>(this)) {
  StartEventListening();
}

WindowManager::~WindowManager() {
  StopEventListening();
}

std::shared_ptr<Window> WindowManager::Get(WindowId id) {
  // First check if it's already in the registry
  auto window = WindowRegistry::GetInstance().Get(id);
  if (window) {
    return window;
  }

  // If not found, ensure all NSWindows are registered and try again
  GetAll();
  return WindowRegistry::GetInstance().Get(id);
}

std::vector<std::shared_ptr<Window>> WindowManager::GetAll() {
  NSArray* ns_windows = [[NSApplication sharedApplication] windows];

  // First, ensure all NSWindows are registered
  for (NSWindow* ns_window in ns_windows) {
    // Create or get Window wrapper - this will handle ID assignment via associated object
    auto window = std::make_shared<Window>((__bridge void*)ns_window);
    WindowId window_id = window->GetId();

    // Add to registry if not already present
    if (!WindowRegistry::GetInstance().Get(window_id)) {
      WindowRegistry::GetInstance().Add(window_id, window);
    }
  }

  // Then return all windows from registry (which now includes all NSWindows)
  return WindowRegistry::GetInstance().GetAll();
}

std::shared_ptr<Window> WindowManager::GetCurrent() {
  NSApplication* app = [NSApplication sharedApplication];
  NSArray* ns_windows = [[NSApplication sharedApplication] windows];
  NSWindow* ns_window = [app mainWindow];
  if (ns_window == nil && [ns_windows count] > 0) {
    ns_window = [ns_windows objectAtIndex:0];
  }
  if (ns_window != nil) {
    // First, try to get the window ID from the associated object
    NSNumber* existingIdNumber = objc_getAssociatedObject(ns_window, kWindowIdKey);
    if (existingIdNumber) {
      WindowId window_id = [existingIdNumber unsignedLongLongValue];

      // Try to get the existing Window from registry
      auto existing_window = WindowRegistry::GetInstance().Get(window_id);
      if (existing_window) {
        return existing_window;
      }
    }

    // If not found in registry, create a new Window wrapper
    auto window = std::make_shared<Window>((__bridge void*)ns_window);
    WindowId window_id = window->GetId();

    // Add to registry (temporary solution)
    WindowRegistry::GetInstance().Add(window_id, window);
    return window;
  }
  return nullptr;
}

void WindowManager::SetWillShowHook(std::optional<WindowWillShowHook> hook) {
  pimpl_->will_show_hook_ = std::move(hook);
  if (pimpl_->will_show_hook_) {
    NativeAPIInstallNSWindowWillShowSwizzleOnce();
  }
}

void WindowManager::SetWillHideHook(std::optional<WindowWillHideHook> hook) {
  pimpl_->will_hide_hook_ = std::move(hook);
  if (pimpl_->will_hide_hook_) {
    NativeAPIInstallNSWindowWillHideSwizzleOnce();
  }
}

void WindowManager::SetWillCloseHook(std::optional<WindowWillCloseHook> hook) {
  pimpl_->will_close_hook_ = std::move(hook);
  if (pimpl_->will_close_hook_) {
    NativeAPIInstallNSWindowWillCloseSwizzleOnce();
  }
}

bool WindowManager::HasWillShowHook() const {
  return pimpl_->will_show_hook_.has_value();
}

bool WindowManager::HasWillHideHook() const {
  return pimpl_->will_hide_hook_.has_value();
}

bool WindowManager::HasWillCloseHook() const {
  return pimpl_->will_close_hook_.has_value();
}

void WindowManager::HandleWillShow(WindowId id) {
  if (pimpl_->will_show_hook_) {
    (*pimpl_->will_show_hook_)(id);
  }
}

void WindowManager::HandleWillHide(WindowId id) {
  if (pimpl_->will_hide_hook_) {
    (*pimpl_->will_hide_hook_)(id);
  }
}

void WindowManager::HandleWillClose(WindowId id) {
  if (pimpl_->will_close_hook_) {
    (*pimpl_->will_close_hook_)(id);
  }
}

bool WindowManager::CallOriginalShow(WindowId id) {
  auto window = Get(id);
  if (!window) {
    return false;
  }
  void* native = window->GetNativeObject();
  if (!native) {
    return false;
  }
  NSWindow* ns_window = (__bridge NSWindow*)native;
  [ns_window na_swizzled_makeKeyAndOrderFront:nil];
  return true;
}

bool WindowManager::CallOriginalHide(WindowId id) {
  auto window = Get(id);
  if (!window) {
    return false;
  }
  void* native = window->GetNativeObject();
  if (!native) {
    return false;
  }
  NSWindow* ns_window = (__bridge NSWindow*)native;
  [ns_window na_swizzled_orderOut:nil];
  return true;
}

bool WindowManager::CallOriginalClose(WindowId id) {
  auto window = Get(id);
  if (!window) {
    return false;
  }
  void* native = window->GetNativeObject();
  if (!native) {
    return false;
  }
  NSWindow* ns_window = (__bridge NSWindow*)native;
  [ns_window na_swizzled_performClose:nil];
  return true;
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
