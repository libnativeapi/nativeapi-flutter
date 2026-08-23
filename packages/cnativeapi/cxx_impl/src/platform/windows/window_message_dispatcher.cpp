#include "window_message_dispatcher.h"
#include <algorithm>
#include <vector>

namespace nativeapi {

WindowMessageDispatcher& WindowMessageDispatcher::GetInstance() {
  // Use heap allocation to avoid static destruction order issues
  // The instance is never destroyed to ensure it remains valid during
  // the entire program lifetime, including during static destruction
  static auto* instance = new WindowMessageDispatcher();
  return *instance;
}

WindowMessageDispatcher::~WindowMessageDispatcher() {
  std::lock_guard<std::mutex> lock(mutex_);

  // Destroy host window if it exists
  if (host_window_) {
    DestroyWindow(host_window_);
    host_window_ = nullptr;
  }

  // Uninstall all hooks before destruction
  for (const auto& [hwnd, _] : original_procs_) {
    UninstallHook(hwnd);
  }
  original_procs_.clear();
}

int WindowMessageDispatcher::RegisterHandler(WindowMessageHandler handler) {
  std::lock_guard<std::mutex> lock(mutex_);

  int id = next_id_++;
  handlers_[id] = {std::move(handler), HWND(0)};  // HWND(0) for global handler
  return id;
}

int WindowMessageDispatcher::RegisterHandler(HWND hwnd, WindowMessageHandler handler) {
  // Check if hook needs to be installed (outside of lock to avoid deadlock)
  bool needs_hook = false;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    needs_hook = (original_procs_.find(hwnd) == original_procs_.end());
  }

  // Install hook if needed (outside of lock)
  if (needs_hook) {
    InstallHook(hwnd);
  }

  // Register the handler (inside lock)
  std::lock_guard<std::mutex> lock(mutex_);
  int id = next_id_++;
  handlers_[id] = {std::move(handler), hwnd};

  return id;
}

bool WindowMessageDispatcher::UnregisterHandler(int id) {
  HWND target_hwnd = HWND(0);
  bool should_uninstall = false;

  {
    std::lock_guard<std::mutex> lock(mutex_);

    auto it = handlers_.find(id);
    if (it == handlers_.end()) {
      return false;
    }

    target_hwnd = it->second.target_hwnd;
    handlers_.erase(it);

    // Check if this was the last handler for this window
    if (target_hwnd != HWND(0)) {
      bool has_other_handlers = std::any_of(
          handlers_.begin(), handlers_.end(),
          [target_hwnd](const auto& pair) { return pair.second.target_hwnd == target_hwnd; });

      should_uninstall = !has_other_handlers;
    }
  }

  // Uninstall hook if needed (outside of lock to avoid deadlock)
  if (should_uninstall) {
    UninstallHook(target_hwnd);
  }

  return true;
}

LRESULT CALLBACK WindowMessageDispatcher::DispatchWindowProc(HWND hwnd,
                                                             UINT msg,
                                                             WPARAM wparam,
                                                             LPARAM lparam) {
  auto& dispatcher = GetInstance();

  // Get original window procedure and copy handlers while holding lock
  WNDPROC original_proc = nullptr;
  std::vector<std::pair<int, HandlerEntry>> handlers_vector;

  {
    std::lock_guard<std::mutex> lock(dispatcher.mutex_);

    // Get original window procedure
    auto proc_it = dispatcher.original_procs_.find(hwnd);
    if (proc_it == dispatcher.original_procs_.end()) {
      return DefWindowProc(hwnd, msg, wparam, lparam);
    }

    original_proc = proc_it->second;

    // Copy handlers while holding lock (to avoid deadlock when handlers call
    // back)
    handlers_vector.assign(dispatcher.handlers_.begin(), dispatcher.handlers_.end());
  }

  // Try handlers in reverse order (most recently registered first)
  // Process handlers without holding the mutex to avoid deadlock
  for (auto it = handlers_vector.rbegin(); it != handlers_vector.rend(); ++it) {
    const auto& [id, entry] = *it;

    // Check if this handler applies to this window
    if (entry.target_hwnd == HWND(0) || entry.target_hwnd == hwnd) {
      auto result = entry.handler(hwnd, msg, wparam, lparam);
      if (result.has_value()) {
        return result.value();
      }
    }
  }

  // No handler consumed the message, call original procedure
  return CallWindowProc(original_proc, hwnd, msg, wparam, lparam);
}

bool WindowMessageDispatcher::InstallHook(HWND hwnd) {
  if (!hwnd || !IsWindow(hwnd)) {
    return false;
  }

  // Get current window procedure
  WNDPROC current_proc = reinterpret_cast<WNDPROC>(GetWindowLongPtr(hwnd, GWLP_WNDPROC));
  if (!current_proc) {
    return false;
  }

  // If the window already has DispatchWindowProc, don't install it again
  if (current_proc == DispatchWindowProc) {
    return true;  // Already installed
  }

  // Store original procedure
  original_procs_[hwnd] = current_proc;

  // Install our dispatcher as the new window procedure
  SetWindowLongPtr(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(DispatchWindowProc));

  return true;
}

void WindowMessageDispatcher::UninstallHook(HWND hwnd) {
  auto it = original_procs_.find(hwnd);
  if (it == original_procs_.end()) {
    return;
  }

  WNDPROC original_proc = it->second;

  // Don't restore window procedure for host window - it should keep DispatchWindowProc
  if (hwnd != host_window_) {
    // Restore original window procedure
    SetWindowLongPtr(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(original_proc));
  }

  // Remove from our tracking
  original_procs_.erase(it);
}

HWND WindowMessageDispatcher::GetHostWindow() {
  // Check if host window already exists (without holding lock to avoid deadlock)
  if (host_window_ && IsWindow(host_window_)) {
    return host_window_;
  }

  // Create a hidden window class for hosting
  static const wchar_t* class_name = L"NativeApiHostWindow";

  WNDCLASSW wc = {};
  wc.lpfnWndProc = DispatchWindowProc;  // Use dispatcher for host window
  wc.hInstance = GetModuleHandle(nullptr);
  wc.lpszClassName = class_name;

  // Register the window class (only once)
  static bool class_registered = false;
  if (!class_registered) {
    if (RegisterClassW(&wc)) {
      class_registered = true;
    } else {
      return nullptr;
    }
  }

  // Create the hidden host window (outside of lock to avoid deadlock)
  HWND new_host_window = CreateWindowExW(WS_EX_TOOLWINDOW,   // Extended style: tool window
                                         class_name,         // Window class
                                         L"NativeApi Host",  // Window title
                                         WS_OVERLAPPED,      // Window style: overlapped window
                                         0, 0,               // Position
                                         1, 1,               // Size (minimal)
                                         HWND_MESSAGE,       // Parent: message-only window
                                         nullptr,            // Menu
                                         GetModuleHandle(nullptr),  // Instance
                                         nullptr                    // Additional data
  );

  if (new_host_window) {
    // Ensure the window is hidden
    ShowWindow(new_host_window, SW_HIDE);

    // Now acquire lock to register the window
    std::lock_guard<std::mutex> lock(mutex_);

    // Double-check if another thread created the window while we were creating it
    if (host_window_ && IsWindow(host_window_)) {
      // Another thread won, destroy our window and use theirs
      DestroyWindow(new_host_window);
      return host_window_;
    }

    // Register the host window in original_procs_ with DefWindowProc as fallback
    host_window_ = new_host_window;
    original_procs_[host_window_] = DefWindowProcW;
  }

  return host_window_;
}

}  // namespace nativeapi
