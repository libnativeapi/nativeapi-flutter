#include <dwmapi.h>
#include <windows.h>
#include <cmath>
#include <iostream>
#include "../../foundation/id_allocator.h"
#include "../../window.h"
#include "../../window_manager.h"
#include "../../window_registry.h"
#include "dpi_utils_windows.h"
#include "string_utils_windows.h"
#include "window_message_dispatcher.h"

#pragma comment(lib, "dwmapi.lib")

namespace nativeapi {

// Property name for storing window ID in HWND
static const wchar_t* kWindowIdProperty = L"NativeAPIWindowId";

// Forward declaration
static LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Private implementation class
class Window::Impl {
 public:
  Impl(HWND hwnd, WindowId id)
      : hwnd_(hwnd),
        window_id_(id),
        title_bar_style_(TitleBarStyle::Normal),
        visual_effect_(VisualEffect::None) {}
  HWND hwnd_;
  WindowId window_id_;
  TitleBarStyle title_bar_style_;
  VisualEffect visual_effect_;
  Size min_size_{0, 0};
  Size max_size_{0, 0};
  int min_max_handler_id_ = 0;
};

// Custom window procedure to handle window messages
static LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
  switch (uMsg) {
    case WM_WINDOWPOSCHANGING: {
      // Intercept visibility changes BEFORE they happen (pre-show/hide "swizzle")
      WINDOWPOS* pos = reinterpret_cast<WINDOWPOS*>(lParam);
      if (pos) {
        // Get window ID from window's custom property (stored during window creation)
        HANDLE prop_handle = GetPropW(hwnd, kWindowIdProperty);
        if (prop_handle) {
          WindowId window_id = static_cast<WindowId>(reinterpret_cast<uintptr_t>(prop_handle));
          if (window_id != IdAllocator::kInvalidId) {
            auto& manager = WindowManager::GetInstance();
            bool hook_handled = false;

            if (pos->flags & SWP_SHOWWINDOW) {
              if (manager.HasWillShowHook()) {
                manager.HandleWillShow(window_id);
                hook_handled = true;
              }
            }
            if (pos->flags & SWP_HIDEWINDOW) {
              if (manager.HasWillHideHook()) {
                manager.HandleWillHide(window_id);
                hook_handled = true;
              }
            }

            // If hook handled it, cancel the visibility change
            if (hook_handled) {
              pos->flags &= ~(SWP_SHOWWINDOW | SWP_HIDEWINDOW);
            }
          }
        }
      }
      return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    case WM_SHOWWINDOW:
      return DefWindowProc(hwnd, uMsg, wParam, lParam);
    case WM_CLOSE:
      DestroyWindow(hwnd);
      return 0;
    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;
    default:
      return DefWindowProc(hwnd, uMsg, wParam, lParam);
  }
}

Window::Window() {
  // Create a new window with default settings
  HINSTANCE hInstance = GetModuleHandle(nullptr);

  // Register window class if not already registered
  static bool class_registered = false;
  static std::wstring wclass_name = StringToWString("NativeAPIWindow");

  if (!class_registered) {
    WNDCLASSW wc = {};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = wclass_name.c_str();
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);

    if (RegisterClassW(&wc)) {
      class_registered = true;
    } else {
      DWORD error = GetLastError();
      if (error != ERROR_CLASS_ALREADY_EXISTS) {
        std::cerr << "Failed to register window class. Error: " << error << std::endl;
        // Allocate ID even for failed window creation to maintain consistency
        WindowId id = IdAllocator::Allocate<Window>();
        pimpl_ = std::make_unique<Impl>(nullptr, id);
        return;
      }
      class_registered = true;
    }
  }

  // Create the window
  DWORD style = WS_OVERLAPPEDWINDOW;
  DWORD exStyle = 0;

  HWND hwnd = CreateWindowExW(exStyle, wclass_name.c_str(), L"", style, CW_USEDEFAULT,
                              CW_USEDEFAULT, 800, 600, nullptr, nullptr, hInstance, nullptr);

  if (!hwnd) {
    std::cerr << "Failed to create window. Error: " << GetLastError() << std::endl;
    // Allocate ID even for failed window creation to maintain consistency
    WindowId id = IdAllocator::Allocate<Window>();
    pimpl_ = std::make_unique<Impl>(nullptr, id);
    return;
  }

  // Allocate window ID using IdAllocator
  WindowId id = IdAllocator::Allocate<Window>();
  if (id == IdAllocator::kInvalidId) {
    std::cerr << "Failed to allocate window ID" << std::endl;
    DestroyWindow(hwnd);
    pimpl_ = std::make_unique<Impl>(nullptr, IdAllocator::kInvalidId);
    return;
  }

  // Store window ID as a custom property in HWND for easy retrieval in WindowProc
  SetPropW(hwnd, kWindowIdProperty, reinterpret_cast<HANDLE>(static_cast<uintptr_t>(id)));

  // Create the instance with allocated ID
  pimpl_ = std::make_unique<Impl>(hwnd, id);

  // Note: Window registration in WindowRegistry is now handled by WindowManager::GetAll()
  // which uses EnumWindows to discover and register all windows dynamically
}

Window::Window(void* native_window) {
  HWND hwnd = static_cast<HWND>(native_window);

  if (!hwnd) {
    // Allocate ID even for null window to maintain consistency
    WindowId id = IdAllocator::Allocate<Window>();
    pimpl_ = std::make_unique<Impl>(nullptr, id);
    return;
  }

  // Check if window already has an ID stored as a custom property
  HANDLE prop_handle = GetPropW(hwnd, kWindowIdProperty);
  WindowId id = IdAllocator::kInvalidId;

  if (prop_handle) {
    id = static_cast<WindowId>(reinterpret_cast<uintptr_t>(prop_handle));
  }

  if (id == IdAllocator::kInvalidId || id == 0) {
    // Allocate new ID if window doesn't have one
    id = IdAllocator::Allocate<Window>();
    if (id == IdAllocator::kInvalidId) {
      std::cerr << "Failed to allocate window ID" << std::endl;
      pimpl_ = std::make_unique<Impl>(nullptr, IdAllocator::kInvalidId);
      return;
    }
    // Store the ID as a custom property in HWND
    SetPropW(hwnd, kWindowIdProperty, reinterpret_cast<HANDLE>(static_cast<uintptr_t>(id)));
  }

  pimpl_ = std::make_unique<Impl>(hwnd, id);

  // Note: Window registration in WindowRegistry is now handled by WindowManager::GetAll()
  // which uses EnumWindows to discover and register all windows dynamically
}

Window::~Window() {
  if (pimpl_ && pimpl_->window_id_ != IdAllocator::kInvalidId) {
    // Unregister WM_GETMINMAXINFO handler if registered
    if (pimpl_->min_max_handler_id_ != 0 && pimpl_->hwnd_) {
      WindowMessageDispatcher::GetInstance().UnregisterHandler(
          pimpl_->min_max_handler_id_);
    }

    // Remove window from registry on destruction
    WindowRegistry::GetInstance().Remove(pimpl_->window_id_);

    // Remove the custom property from HWND if window is still valid
    if (pimpl_->hwnd_) {
      RemovePropW(pimpl_->hwnd_, kWindowIdProperty);
    }
  }
}

void Window::Focus() {
  if (pimpl_->hwnd_) {
    SetForegroundWindow(pimpl_->hwnd_);
    SetFocus(pimpl_->hwnd_);
  }
}

void Window::Blur() {
  if (pimpl_->hwnd_) {
    SetFocus(nullptr);
  }
}

bool Window::IsFocused() const {
  return pimpl_->hwnd_ && GetForegroundWindow() == pimpl_->hwnd_;
}

void Window::Show() {
  if (pimpl_->hwnd_) {
    ShowWindow(pimpl_->hwnd_, SW_SHOW);
    SetForegroundWindow(pimpl_->hwnd_);
  }
}

void Window::ShowInactive() {
  if (pimpl_->hwnd_) {
    ShowWindow(pimpl_->hwnd_, SW_SHOWNOACTIVATE);
  }
}

void Window::Hide() {
  if (pimpl_->hwnd_) {
    ShowWindow(pimpl_->hwnd_, SW_HIDE);
  }
}

bool Window::IsVisible() const {
  return pimpl_->hwnd_ && IsWindowVisible(pimpl_->hwnd_);
}

void Window::Maximize() {
  if (pimpl_->hwnd_ && !IsMaximized()) {
    ShowWindow(pimpl_->hwnd_, SW_MAXIMIZE);
  }
}

void Window::Unmaximize() {
  if (pimpl_->hwnd_ && IsMaximized()) {
    ShowWindow(pimpl_->hwnd_, SW_RESTORE);
  }
}

bool Window::IsMaximized() const {
  if (!pimpl_->hwnd_)
    return false;
  WINDOWPLACEMENT wp = {};
  wp.length = sizeof(WINDOWPLACEMENT);
  GetWindowPlacement(pimpl_->hwnd_, &wp);
  return wp.showCmd == SW_MAXIMIZE;
}

void Window::Minimize() {
  if (pimpl_->hwnd_ && !IsMinimized()) {
    ShowWindow(pimpl_->hwnd_, SW_MINIMIZE);
  }
}

void Window::Restore() {
  if (pimpl_->hwnd_ && IsMinimized()) {
    ShowWindow(pimpl_->hwnd_, SW_RESTORE);
  }
}

bool Window::IsMinimized() const {
  if (!pimpl_->hwnd_)
    return false;
  WINDOWPLACEMENT wp = {};
  wp.length = sizeof(WINDOWPLACEMENT);
  GetWindowPlacement(pimpl_->hwnd_, &wp);
  return wp.showCmd == SW_MINIMIZE;
}

void Window::SetFullScreen(bool is_full_screen) {
  if (!pimpl_->hwnd_)
    return;

  static WINDOWPLACEMENT g_wpPrev = {sizeof(g_wpPrev)};
  static DWORD g_dwStyle = 0;
  static DWORD g_dwExStyle = 0;

  if (is_full_screen) {
    if (!IsFullScreen()) {
      // Save current window placement and style
      GetWindowPlacement(pimpl_->hwnd_, &g_wpPrev);
      g_dwStyle = GetWindowLong(pimpl_->hwnd_, GWL_STYLE);
      g_dwExStyle = GetWindowLong(pimpl_->hwnd_, GWL_EXSTYLE);

      // Remove window decorations
      SetWindowLong(pimpl_->hwnd_, GWL_STYLE, g_dwStyle & ~(WS_CAPTION | WS_THICKFRAME));
      SetWindowLong(pimpl_->hwnd_, GWL_EXSTYLE,
                    g_dwExStyle & ~(WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE |
                                    WS_EX_STATICEDGE));

      // Get monitor info
      MONITORINFO mi = {sizeof(mi)};
      GetMonitorInfo(MonitorFromWindow(pimpl_->hwnd_, MONITOR_DEFAULTTONEAREST), &mi);

      // Set window to cover entire monitor
      SetWindowPos(pimpl_->hwnd_, nullptr, mi.rcMonitor.left, mi.rcMonitor.top,
                   mi.rcMonitor.right - mi.rcMonitor.left, mi.rcMonitor.bottom - mi.rcMonitor.top,
                   SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    }
  } else {
    if (IsFullScreen()) {
      // Restore window style and placement
      SetWindowLong(pimpl_->hwnd_, GWL_STYLE, g_dwStyle);
      SetWindowLong(pimpl_->hwnd_, GWL_EXSTYLE, g_dwExStyle);
      SetWindowPlacement(pimpl_->hwnd_, &g_wpPrev);
      SetWindowPos(pimpl_->hwnd_, nullptr, 0, 0, 0, 0,
                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    }
  }
}

bool Window::IsFullScreen() const {
  if (!pimpl_->hwnd_)
    return false;

  RECT windowRect, monitorRect;
  GetWindowRect(pimpl_->hwnd_, &windowRect);

  MONITORINFO mi = {sizeof(mi)};
  GetMonitorInfo(MonitorFromWindow(pimpl_->hwnd_, MONITOR_DEFAULTTONEAREST), &mi);
  monitorRect = mi.rcMonitor;

  return (windowRect.left == monitorRect.left && windowRect.top == monitorRect.top &&
          windowRect.right == monitorRect.right && windowRect.bottom == monitorRect.bottom);
}

void Window::SetBounds(Rectangle bounds) {
  if (pimpl_->hwnd_) {
    double scale = GetScaleFactorForWindow(pimpl_->hwnd_);
    if (scale <= 0.0)
      scale = 1.0;
    SetWindowPos(pimpl_->hwnd_, nullptr,
                 static_cast<int>(std::lround(bounds.x * scale)),
                 static_cast<int>(std::lround(bounds.y * scale)),
                 static_cast<int>(std::lround(bounds.width * scale)),
                 static_cast<int>(std::lround(bounds.height * scale)), SWP_NOZORDER);
  }
}

Rectangle Window::GetBounds() const {
  Rectangle bounds = {0, 0, 0, 0};
  if (pimpl_->hwnd_) {
    RECT rect;
    GetWindowRect(pimpl_->hwnd_, &rect);
    double scale = GetScaleFactorForWindow(pimpl_->hwnd_);
    if (scale <= 0.0)
      scale = 1.0;
    bounds.x = static_cast<double>(rect.left) / scale;
    bounds.y = static_cast<double>(rect.top) / scale;
    bounds.width = static_cast<double>(rect.right - rect.left) / scale;
    bounds.height = static_cast<double>(rect.bottom - rect.top) / scale;
  }
  return bounds;
}

void Window::SetSize(Size size, bool animate) {
  if (pimpl_->hwnd_) {
    // Windows doesn't have built-in animation for window resizing
    // Animation would require custom implementation
    double scale = GetScaleFactorForWindow(pimpl_->hwnd_);
    if (scale <= 0.0)
      scale = 1.0;
    SetWindowPos(pimpl_->hwnd_, nullptr, 0, 0,
                 static_cast<int>(std::lround(size.width * scale)),
                 static_cast<int>(std::lround(size.height * scale)),
                 SWP_NOMOVE | SWP_NOZORDER);
  }
}

Size Window::GetSize() const {
  Size size = {0, 0};
  if (pimpl_->hwnd_) {
    RECT rect;
    GetWindowRect(pimpl_->hwnd_, &rect);
    double scale = GetScaleFactorForWindow(pimpl_->hwnd_);
    if (scale <= 0.0)
      scale = 1.0;
    size.width = static_cast<double>(rect.right - rect.left) / scale;
    size.height = static_cast<double>(rect.bottom - rect.top) / scale;
  }
  return size;
}

void Window::SetContentSize(Size size) {
  if (pimpl_->hwnd_) {
    RECT windowRect, clientRect;
    GetWindowRect(pimpl_->hwnd_, &windowRect);
    GetClientRect(pimpl_->hwnd_, &clientRect);

    // Calculate the difference between window and client area
    int borderWidth = (windowRect.right - windowRect.left) - clientRect.right;
    int borderHeight = (windowRect.bottom - windowRect.top) - clientRect.bottom;

    double scale = GetScaleFactorForWindow(pimpl_->hwnd_);
    if (scale <= 0.0)
      scale = 1.0;
    SetWindowPos(pimpl_->hwnd_, nullptr, 0, 0,
                 static_cast<int>(std::lround(size.width * scale)) + borderWidth,
                 static_cast<int>(std::lround(size.height * scale)) + borderHeight,
                 SWP_NOMOVE | SWP_NOZORDER);
  }
}

Size Window::GetContentSize() const {
  Size size = {0, 0};
  if (pimpl_->hwnd_) {
    RECT rect;
    GetClientRect(pimpl_->hwnd_, &rect);
    double scale = GetScaleFactorForWindow(pimpl_->hwnd_);
    if (scale <= 0.0)
      scale = 1.0;
    size.width = static_cast<double>(rect.right) / scale;
    size.height = static_cast<double>(rect.bottom) / scale;
  }
  return size;
}

void Window::SetContentBounds(Rectangle bounds) {
  if (pimpl_->hwnd_) {
    RECT windowRect, clientRect;
    GetWindowRect(pimpl_->hwnd_, &windowRect);
    GetClientRect(pimpl_->hwnd_, &clientRect);

    // Calculate the difference between window and client area
    int borderWidth = (windowRect.right - windowRect.left) - clientRect.right;
    int borderHeight = (windowRect.bottom - windowRect.top) - clientRect.bottom;

    // Get current client area position in screen coordinates
    POINT clientTopLeft = {0, 0};
    ClientToScreen(pimpl_->hwnd_, &clientTopLeft);

    // Calculate the offset from window top-left to client top-left
    int offsetX = clientTopLeft.x - windowRect.left;
    int offsetY = clientTopLeft.y - windowRect.top;

    double scale = GetScaleFactorForWindow(pimpl_->hwnd_);
    if (scale <= 0.0)
      scale = 1.0;

    // Calculate window position so that client area is at bounds position
    int windowX = static_cast<int>(std::lround(bounds.x * scale)) - offsetX;
    int windowY = static_cast<int>(std::lround(bounds.y * scale)) - offsetY;
    int windowWidth = static_cast<int>(std::lround(bounds.width * scale)) + borderWidth;
    int windowHeight = static_cast<int>(std::lround(bounds.height * scale)) + borderHeight;

    SetWindowPos(pimpl_->hwnd_, nullptr, windowX, windowY, windowWidth, windowHeight, SWP_NOZORDER);
  }
}

Rectangle Window::GetContentBounds() const {
  Rectangle bounds = {0, 0, 0, 0};
  if (pimpl_->hwnd_) {
    RECT clientRect;
    GetClientRect(pimpl_->hwnd_, &clientRect);

    // Convert client rect to screen coordinates (physical pixels)
    POINT topLeft = {clientRect.left, clientRect.top};
    POINT bottomRight = {clientRect.right, clientRect.bottom};
    ClientToScreen(pimpl_->hwnd_, &topLeft);
    ClientToScreen(pimpl_->hwnd_, &bottomRight);

    double scale = GetScaleFactorForWindow(pimpl_->hwnd_);
    if (scale <= 0.0)
      scale = 1.0;

    // Return logical pixels (DIP) by dividing by scale
    bounds.x = static_cast<double>(topLeft.x) / scale;
    bounds.y = static_cast<double>(topLeft.y) / scale;
    bounds.width = static_cast<double>(bottomRight.x - topLeft.x) / scale;
    bounds.height = static_cast<double>(bottomRight.y - topLeft.y) / scale;
  }
  return bounds;
}

// Helper function: registers a WM_GETMINMAXINFO handler for the given HWND
// via WindowMessageDispatcher if not already registered. Returns the handler ID.
static int RegisterMinMaxInfoHandler(HWND hwnd, int existing_handler_id) {
  if (existing_handler_id != 0) {
    return existing_handler_id;
  }
  if (!hwnd || !IsWindow(hwnd)) {
    return 0;
  }
  auto& dispatcher = WindowMessageDispatcher::GetInstance();
  return dispatcher.RegisterHandler(
      hwnd,
      [](HWND hwnd, UINT msg, WPARAM wparam,
         LPARAM lparam) -> std::optional<LRESULT> {
        if (msg == WM_GETMINMAXINFO) {
          HANDLE prop_handle = GetPropW(hwnd, kWindowIdProperty);
          if (prop_handle) {
            WindowId window_id = static_cast<WindowId>(
                reinterpret_cast<uintptr_t>(prop_handle));
            if (window_id != IdAllocator::kInvalidId) {
              auto window = WindowRegistry::GetInstance().Get(window_id);
              if (window) {
                auto minSize = window->GetMinimumSize();
                auto maxSize = window->GetMaximumSize();
                MINMAXINFO* mmi = reinterpret_cast<MINMAXINFO*>(lparam);
                double scale_mm = GetScaleFactorForWindow(hwnd);
                if (scale_mm <= 0.0)
                  scale_mm = 1.0;
                if (minSize.width > 0 && minSize.height > 0) {
                  mmi->ptMinTrackSize.x = static_cast<LONG>(std::lround(minSize.width * scale_mm));
                  mmi->ptMinTrackSize.y = static_cast<LONG>(std::lround(minSize.height * scale_mm));
                }
                if (maxSize.width > 0 && maxSize.height > 0) {
                  mmi->ptMaxTrackSize.x = static_cast<LONG>(std::lround(maxSize.width * scale_mm));
                  mmi->ptMaxTrackSize.y = static_cast<LONG>(std::lround(maxSize.height * scale_mm));
                }
                return std::make_optional(0);
              }
            }
          }
        }
        return std::nullopt;
      });
}

void Window::SetMinimumSize(Size size) {
  pimpl_->min_size_ = size;

  if (pimpl_->hwnd_) {
    pimpl_->min_max_handler_id_ =
        RegisterMinMaxInfoHandler(pimpl_->hwnd_, pimpl_->min_max_handler_id_);

    // Trigger the window to re-evaluate its size constraints
    SetWindowPos(pimpl_->hwnd_, nullptr, 0, 0, 0, 0,
                 SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);
  }
}

Size Window::GetMinimumSize() const {
  return pimpl_->min_size_;
}

void Window::SetMaximumSize(Size size) {
  pimpl_->max_size_ = size;

  if (pimpl_->hwnd_) {
    pimpl_->min_max_handler_id_ =
        RegisterMinMaxInfoHandler(pimpl_->hwnd_, pimpl_->min_max_handler_id_);

    // Trigger the window to re-evaluate its size constraints
    SetWindowPos(pimpl_->hwnd_, nullptr, 0, 0, 0, 0,
                 SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);
  }
}

Size Window::GetMaximumSize() const {
  return pimpl_->max_size_;
}

void Window::SetResizable(bool is_resizable) {
  if (pimpl_->hwnd_) {
    LONG style = GetWindowLong(pimpl_->hwnd_, GWL_STYLE);
    if (is_resizable) {
      style |= WS_THICKFRAME | WS_MAXIMIZEBOX;
    } else {
      style &= ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
    }
    SetWindowLong(pimpl_->hwnd_, GWL_STYLE, style);
    SetWindowPos(pimpl_->hwnd_, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
  }
}

bool Window::IsResizable() const {
  if (!pimpl_->hwnd_)
    return false;
  LONG style = GetWindowLong(pimpl_->hwnd_, GWL_STYLE);
  return (style & WS_THICKFRAME) != 0;
}

void Window::SetMovable(bool is_movable) {
  // Windows doesn't have a direct way to disable window movement
  // This would require custom window procedure handling
}

bool Window::IsMovable() const {
  // Windows windows are movable by default
  return true;
}

void Window::SetMinimizable(bool is_minimizable) {
  if (pimpl_->hwnd_) {
    LONG style = GetWindowLong(pimpl_->hwnd_, GWL_STYLE);
    if (is_minimizable) {
      style |= WS_MINIMIZEBOX;
    } else {
      style &= ~WS_MINIMIZEBOX;
    }
    SetWindowLong(pimpl_->hwnd_, GWL_STYLE, style);
    SetWindowPos(pimpl_->hwnd_, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
  }
}

bool Window::IsMinimizable() const {
  if (!pimpl_->hwnd_)
    return false;
  LONG style = GetWindowLong(pimpl_->hwnd_, GWL_STYLE);
  return (style & WS_MINIMIZEBOX) != 0;
}

void Window::SetMaximizable(bool is_maximizable) {
  if (pimpl_->hwnd_) {
    LONG style = GetWindowLong(pimpl_->hwnd_, GWL_STYLE);
    if (is_maximizable) {
      style |= WS_MAXIMIZEBOX;
    } else {
      style &= ~WS_MAXIMIZEBOX;
    }
    SetWindowLong(pimpl_->hwnd_, GWL_STYLE, style);
    SetWindowPos(pimpl_->hwnd_, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
  }
}

bool Window::IsMaximizable() const {
  if (!pimpl_->hwnd_)
    return false;
  LONG style = GetWindowLong(pimpl_->hwnd_, GWL_STYLE);
  return (style & WS_MAXIMIZEBOX) != 0;
}

void Window::SetFullScreenable(bool is_full_screenable) {
  // This is a concept more relevant to macOS
  // On Windows, any window can potentially go fullscreen
}

bool Window::IsFullScreenable() const {
  return true;  // All Windows windows can go fullscreen
}

void Window::SetClosable(bool is_closable) {
  if (pimpl_->hwnd_) {
    LONG style = GetWindowLong(pimpl_->hwnd_, GWL_STYLE);
    if (is_closable) {
      style |= WS_SYSMENU;
    } else {
      style &= ~WS_SYSMENU;
    }
    SetWindowLong(pimpl_->hwnd_, GWL_STYLE, style);
    SetWindowPos(pimpl_->hwnd_, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
  }
}

bool Window::IsClosable() const {
  if (!pimpl_->hwnd_)
    return false;
  LONG style = GetWindowLong(pimpl_->hwnd_, GWL_STYLE);
  return (style & WS_SYSMENU) != 0;
}

void Window::SetWindowControlButtonsVisible(bool is_visible) {
  // TODO: Implement for Windows
  // This would involve custom window chrome or DWM frame manipulation
}

bool Window::IsWindowControlButtonsVisible() const {
  // TODO: Implement for Windows
  return true;  // Default to visible
}

void Window::SetAlwaysOnTop(bool is_always_on_top) {
  if (pimpl_->hwnd_) {
    SetWindowPos(pimpl_->hwnd_, is_always_on_top ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE);
  }
}

bool Window::IsAlwaysOnTop() const {
  if (!pimpl_->hwnd_)
    return false;
  LONG exStyle = GetWindowLong(pimpl_->hwnd_, GWL_EXSTYLE);
  return (exStyle & WS_EX_TOPMOST) != 0;
}

void Window::SetPosition(Point point) {
  if (pimpl_->hwnd_) {
    double scale = GetScaleFactorForWindow(pimpl_->hwnd_);
    if (scale <= 0.0)
      scale = 1.0;
    SetWindowPos(pimpl_->hwnd_, nullptr,
                 static_cast<int>(std::lround(point.x * scale)),
                 static_cast<int>(std::lround(point.y * scale)),
                 0, 0, SWP_NOSIZE | SWP_NOZORDER);
  }
}

Point Window::GetPosition() const {
  Point point = {0, 0};
  if (pimpl_->hwnd_) {
    RECT rect;
    GetWindowRect(pimpl_->hwnd_, &rect);
    double scale = GetScaleFactorForWindow(pimpl_->hwnd_);
    if (scale <= 0.0)
      scale = 1.0;
    point.x = static_cast<double>(rect.left) / scale;
    point.y = static_cast<double>(rect.top) / scale;
  }
  return point;
}

void Window::Center() {
  if (!pimpl_->hwnd_)
    return;

  // Get the current window size
  RECT windowRect;
  GetWindowRect(pimpl_->hwnd_, &windowRect);
  int windowWidth = windowRect.right - windowRect.left;
  int windowHeight = windowRect.bottom - windowRect.top;

  // Get the monitor that the window is currently on
  HMONITOR monitor = MonitorFromWindow(pimpl_->hwnd_, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi = {sizeof(mi)};
  GetMonitorInfo(monitor, &mi);

  // Calculate the center position on the monitor's work area
  // All values here are in physical pixels (GetWindowRect and rcWork), so no DPI scaling needed
  int centerX = mi.rcWork.left + (mi.rcWork.right - mi.rcWork.left - windowWidth) / 2;
  int centerY = mi.rcWork.top + (mi.rcWork.bottom - mi.rcWork.top - windowHeight) / 2;

  // Set the window position to center
  SetWindowPos(pimpl_->hwnd_, nullptr, centerX, centerY, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
}

void Window::SetTitle(std::string title) {
  if (pimpl_->hwnd_) {
    std::wstring wtitle = StringToWString(title);
    SetWindowTextW(pimpl_->hwnd_, wtitle.c_str());
  }
}

std::string Window::GetTitle() const {
  if (!pimpl_->hwnd_)
    return "";

  int length = GetWindowTextLengthW(pimpl_->hwnd_);
  if (length == 0)
    return "";

  std::wstring wtitle(length + 1, L'\0');
  GetWindowTextW(pimpl_->hwnd_, &wtitle[0], length + 1);
  wtitle.resize(length);
  return WStringToString(wtitle);
}

void Window::SetTitleBarStyle(TitleBarStyle style) {
  if (!pimpl_->hwnd_)
    return;

  pimpl_->title_bar_style_ = style;

  // Get current window rect
  RECT rect;
  GetWindowRect(pimpl_->hwnd_, &rect);

  // Apply DWM frame extension based on style
  MARGINS margins = {0, 0, 0, 0};
  DwmExtendFrameIntoClientArea(pimpl_->hwnd_, &margins);

  // Trigger frame change to apply the new style
  SetWindowPos(pimpl_->hwnd_, nullptr, rect.left, rect.top, 0, 0,
               SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED);
}

TitleBarStyle Window::GetTitleBarStyle() const {
  return pimpl_->title_bar_style_;
}

void Window::SetHasShadow(bool has_shadow) {
  // Windows shadow is typically handled automatically
  // Custom shadow implementation would be complex
}

bool Window::HasShadow() const {
  return true;  // Windows typically have shadows by default
}

void Window::SetOpacity(float opacity) {
  if (pimpl_->hwnd_) {
    LONG exStyle = GetWindowLong(pimpl_->hwnd_, GWL_EXSTYLE);

    if (opacity < 1.0f) {
      // Enable layered window and set opacity
      SetWindowLong(pimpl_->hwnd_, GWL_EXSTYLE, exStyle | WS_EX_LAYERED);
      SetLayeredWindowAttributes(pimpl_->hwnd_, 0, static_cast<BYTE>(opacity * 255), LWA_ALPHA);
    } else {
      // Disable layered window
      SetWindowLong(pimpl_->hwnd_, GWL_EXSTYLE, exStyle & ~WS_EX_LAYERED);
    }
  }
}

float Window::GetOpacity() const {
  if (!pimpl_->hwnd_)
    return 1.0f;

  LONG exStyle = GetWindowLong(pimpl_->hwnd_, GWL_EXSTYLE);
  if (exStyle & WS_EX_LAYERED) {
    BYTE alpha;
    if (GetLayeredWindowAttributes(pimpl_->hwnd_, nullptr, &alpha, nullptr)) {
      return alpha / 255.0f;
    }
  }
  return 1.0f;
}

void Window::SetVisualEffect(VisualEffect effect) {
  if (!pimpl_->hwnd_ || pimpl_->visual_effect_ == effect)
    return;

  pimpl_->visual_effect_ = effect;

  // DWM_SYSTEMBACKDROP_TYPE is available in Windows 11 Build 22621+
  // DWMWA_SYSTEMBACKDROP_TYPE = 38
  int backdrop_type = 1;  // DWMSBT_NONE

  switch (effect) {
    case VisualEffect::None:
      backdrop_type = 1;  // DWMSBT_NONE
      break;
    case VisualEffect::Blur:
    case VisualEffect::Acrylic:
      backdrop_type = 3;  // DWMSBT_TRANSIENTWINDOW (Acrylic)
      break;
    case VisualEffect::Mica:
      backdrop_type = 2;  // DWMSBT_MAINWINDOW (Mica)
      break;
  }

  DwmSetWindowAttribute(pimpl_->hwnd_, 38, &backdrop_type, sizeof(backdrop_type));
}

VisualEffect Window::GetVisualEffect() const {
  return pimpl_->visual_effect_;
}

void Window::SetBackgroundColor(const Color& color) {
  if (!pimpl_->hwnd_)
    return;
  
  // Create new brush with the specified color
  COLORREF colorRef = RGB(color.r, color.g, color.b);
  HBRUSH brush = CreateSolidBrush(colorRef);
  
  // Get old brush to delete it later
  HBRUSH oldBrush = reinterpret_cast<HBRUSH>(
    SetClassLongPtr(pimpl_->hwnd_, GCLP_HBRBACKGROUND, 
                    reinterpret_cast<LONG_PTR>(brush)));
  
  // Delete old brush if it's not a system brush
  if (oldBrush && oldBrush != GetStockObject(NULL_BRUSH) &&
      oldBrush != GetStockObject(WHITE_BRUSH) &&
      oldBrush != GetStockObject(BLACK_BRUSH) &&
      oldBrush != GetStockObject(GRAY_BRUSH) &&
      oldBrush != GetStockObject(LTGRAY_BRUSH) &&
      oldBrush != GetStockObject(DKGRAY_BRUSH)) {
    DeleteObject(oldBrush);
  }
  
  // Force window to redraw with new background color
  InvalidateRect(pimpl_->hwnd_, nullptr, TRUE);
}

Color Window::GetBackgroundColor() const {
  if (!pimpl_->hwnd_)
    return Color::White;
  
  // Get the background brush from the window class
  HBRUSH brush = reinterpret_cast<HBRUSH>(
    GetClassLongPtr(pimpl_->hwnd_, GCLP_HBRBACKGROUND));
  
  if (!brush || brush == GetStockObject(NULL_BRUSH)) {
    return Color::White;
  }
  
  // Get the brush color using GetObject
  LOGBRUSH logBrush;
  if (GetObject(brush, sizeof(LOGBRUSH), &logBrush) == 0) {
    return Color::White;
  }
  
  // Extract RGB values from COLORREF
  COLORREF colorRef = logBrush.lbColor;
  return Color::FromRGBA(
    GetRValue(colorRef),
    GetGValue(colorRef),
    GetBValue(colorRef),
    255  // Windows doesn't store alpha in solid brush
  );
}

void Window::SetVisibleOnAllWorkspaces(bool is_visible_on_all_workspaces) {
  // Windows doesn't have the same concept of workspaces as macOS
  // This would require integration with virtual desktop APIs
}

bool Window::IsVisibleOnAllWorkspaces() const {
  return false;  // Not supported on Windows by default
}

void Window::SetIgnoreMouseEvents(bool is_ignore_mouse_events) {
  if (pimpl_->hwnd_) {
    LONG exStyle = GetWindowLong(pimpl_->hwnd_, GWL_EXSTYLE);
    if (is_ignore_mouse_events) {
      exStyle |= WS_EX_TRANSPARENT;
    } else {
      exStyle &= ~WS_EX_TRANSPARENT;
    }
    SetWindowLong(pimpl_->hwnd_, GWL_EXSTYLE, exStyle);
  }
}

bool Window::IsIgnoreMouseEvents() const {
  if (!pimpl_->hwnd_)
    return false;
  LONG exStyle = GetWindowLong(pimpl_->hwnd_, GWL_EXSTYLE);
  return (exStyle & WS_EX_TRANSPARENT) != 0;
}

void Window::SetFocusable(bool is_focusable) {
  // Windows focusability is typically controlled by window style
  // This is a simplified implementation
}

bool Window::IsFocusable() const {
  if (!pimpl_->hwnd_)
    return false;
  LONG style = GetWindowLong(pimpl_->hwnd_, GWL_STYLE);
  return (style & WS_DISABLED) == 0;
}

void Window::StartDragging() {
  if (pimpl_->hwnd_) {
    // Simulate dragging by sending WM_NCLBUTTONDOWN with HTCAPTION
    PostMessage(pimpl_->hwnd_, WM_NCLBUTTONDOWN, HTCAPTION, 0);
  }
}

void Window::StartResizing() {
  // Windows doesn't have a direct API to start resizing programmatically
  // This would require more complex implementation
}

WindowId Window::GetId() const {
  if (!pimpl_) {
    return IdAllocator::kInvalidId;
  }
  return pimpl_->window_id_;
}

void* Window::GetNativeObjectInternal() const {
  return pimpl_ ? reinterpret_cast<void*>(pimpl_->hwnd_) : nullptr;
}

}  // namespace nativeapi
