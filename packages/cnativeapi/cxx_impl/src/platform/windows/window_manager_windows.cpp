#include <windows.h>
#include <iostream>
#include <string>

#include <psapi.h>
#include "../../window.h"
#include "../../window_manager.h"
#include "../../window_registry.h"
#include "string_utils_windows.h"

#pragma comment(lib, "psapi.lib")

namespace nativeapi {

// Property name for storing window ID in HWND (must match window_windows.cpp)
static const wchar_t* kWindowIdProperty = L"NativeAPIWindowId";

// Helper function to get window ID from HWND
// First tries to read from custom property, then creates Window object if needed
static WindowId GetWindowIdFromHwnd(HWND hwnd) {
  if (!hwnd) {
    return IdAllocator::kInvalidId;
  }

  // First, try to get window ID from HWND's custom property
  HANDLE prop_handle = GetPropW(hwnd, kWindowIdProperty);
  if (prop_handle) {
    WindowId window_id = static_cast<WindowId>(reinterpret_cast<uintptr_t>(prop_handle));
    if (window_id != IdAllocator::kInvalidId && window_id != 0) {
      return window_id;
    }
  }

  // If property doesn't exist, create a new Window object and register it
  // Use shared_ptr so it can be properly registered in WindowRegistry
  auto window = std::make_shared<Window>(hwnd);
  WindowId window_id = window->GetId();

  // Register the window manually since constructor's shared_from_this() fails
  // during construction (shared_ptr control block not fully initialized yet)
  if (window_id != IdAllocator::kInvalidId) {
    WindowRegistry::GetInstance().Add(window_id, window);
  }

  return window_id;
}

namespace {

using PFN_ShowWindow = BOOL(WINAPI*)(HWND, int);
using PFN_ShowWindowAsync = BOOL(WINAPI*)(HWND, int);

static PFN_ShowWindow g_original_show_window = nullptr;
static PFN_ShowWindowAsync g_original_show_window_async = nullptr;
static bool g_hooks_installed = false;

static bool IsShowCommand(int cmd) {
  switch (cmd) {
    case SW_SHOW:
    case SW_SHOWNORMAL:
    case SW_SHOWDEFAULT:
    case SW_SHOWMAXIMIZED:
    case SW_SHOWNOACTIVATE:
    case SW_RESTORE:
      return true;
    default:
      return false;
  }
}

// Intercept show/hide commands and invoke hooks if registered
// Returns true if hook handled the operation (skip original implementation)
static bool TryHandleWithHook(HWND hwnd, int cmd) {
  WindowId window_id = GetWindowIdFromHwnd(hwnd);
  if (window_id == IdAllocator::kInvalidId) {
    return false;
  }

  auto& manager = WindowManager::GetInstance();

  if (cmd == SW_HIDE && manager.HasWillHideHook()) {
    manager.HandleWillHide(window_id);
    return true;
  }

  if (IsShowCommand(cmd) && manager.HasWillShowHook()) {
    manager.HandleWillShow(window_id);
    return true;
  }

  return false;
}

static BOOL WINAPI HookedShowWindow(HWND hwnd, int nCmdShow) {
  if (TryHandleWithHook(hwnd, nCmdShow)) {
    return TRUE;
  }

  if (g_original_show_window) {
    return g_original_show_window(hwnd, nCmdShow);
  }

  auto p = reinterpret_cast<PFN_ShowWindow>(
      GetProcAddress(GetModuleHandleW(L"user32.dll"), "ShowWindow"));
  return p ? p(hwnd, nCmdShow) : FALSE;
}

static BOOL WINAPI HookedShowWindowAsync(HWND hwnd, int nCmdShow) {
  if (TryHandleWithHook(hwnd, nCmdShow)) {
    return TRUE;
  }

  if (g_original_show_window_async) {
    return g_original_show_window_async(hwnd, nCmdShow);
  }

  auto p = reinterpret_cast<PFN_ShowWindowAsync>(
      GetProcAddress(GetModuleHandleW(L"user32.dll"), "ShowWindowAsync"));
  return p ? p(hwnd, nCmdShow) : FALSE;
}

static bool CaseInsensitiveEquals(const char* a, const char* b) {
  if (!a || !b)
    return false;
  while (*a && *b) {
    char ca = (*a >= 'A' && *a <= 'Z') ? *a + 32 : *a;
    char cb = (*b >= 'A' && *b <= 'Z') ? *b + 32 : *b;
    if (ca != cb)
      return false;
    ++a;
    ++b;
  }
  return *a == *b;
}

static void PatchIATInModule(HMODULE module,
                             FARPROC target,
                             FARPROC replacement,
                             const char* func_name) {
  if (!module)
    return;

  auto base = reinterpret_cast<BYTE*>(module);
  auto dos = reinterpret_cast<PIMAGE_DOS_HEADER>(base);
  if (!dos || dos->e_magic != IMAGE_DOS_SIGNATURE)
    return;

  auto nt = reinterpret_cast<PIMAGE_NT_HEADERS>(base + dos->e_lfanew);
  if (!nt || nt->Signature != IMAGE_NT_SIGNATURE)
    return;

  auto& import_dir = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
  if (import_dir.VirtualAddress == 0)
    return;

  auto import_desc = reinterpret_cast<PIMAGE_IMPORT_DESCRIPTOR>(base + import_dir.VirtualAddress);
  for (; import_desc->Name != 0; ++import_desc) {
    auto dll_name = reinterpret_cast<const char*>(base + import_desc->Name);
    // Only hook USER32.dll to reduce risk
    if (!dll_name)
      continue;
    if (!(CaseInsensitiveEquals(dll_name, "user32.dll")))
      continue;

    auto orig_thunk = reinterpret_cast<PIMAGE_THUNK_DATA>(base + import_desc->OriginalFirstThunk);
    auto thunk = reinterpret_cast<PIMAGE_THUNK_DATA>(base + import_desc->FirstThunk);
    if (!orig_thunk || !thunk)
      continue;

    for (; orig_thunk->u1.AddressOfData != 0; ++orig_thunk, ++thunk) {
      if (IMAGE_SNAP_BY_ORDINAL(orig_thunk->u1.Ordinal)) {
        continue;  // Skip ordinals
      }
      auto import = reinterpret_cast<PIMAGE_IMPORT_BY_NAME>(base + orig_thunk->u1.AddressOfData);
      if (!import || !import->Name)
        continue;
      const char* name = reinterpret_cast<const char*>(import->Name);
      if (!CaseInsensitiveEquals(name, func_name))
        continue;

      // Change protection and write new function pointer
      DWORD old_protect;
      if (VirtualProtect(&thunk->u1.Function, sizeof(void*), PAGE_READWRITE, &old_protect)) {
        // Store original (first time only)
        (void)target;  // target kept for symmetry; not used here
        thunk->u1.Function = reinterpret_cast<ULONG_PTR>(replacement);
        VirtualProtect(&thunk->u1.Function, sizeof(void*), old_protect, &old_protect);
        FlushInstructionCache(GetCurrentProcess(), &thunk->u1.Function, sizeof(void*));
      }
    }
  }
}

static void RestoreIATInModule(HMODULE module, FARPROC original, const char* func_name) {
  if (!module || !original)
    return;

  auto base = reinterpret_cast<BYTE*>(module);
  auto dos = reinterpret_cast<PIMAGE_DOS_HEADER>(base);
  if (!dos || dos->e_magic != IMAGE_DOS_SIGNATURE)
    return;

  auto nt = reinterpret_cast<PIMAGE_NT_HEADERS>(base + dos->e_lfanew);
  if (!nt || nt->Signature != IMAGE_NT_SIGNATURE)
    return;

  auto& import_dir = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
  if (import_dir.VirtualAddress == 0)
    return;

  auto import_desc = reinterpret_cast<PIMAGE_IMPORT_DESCRIPTOR>(base + import_dir.VirtualAddress);
  for (; import_desc->Name != 0; ++import_desc) {
    auto dll_name = reinterpret_cast<const char*>(base + import_desc->Name);
    if (!dll_name)
      continue;
    if (!(CaseInsensitiveEquals(dll_name, "user32.dll")))
      continue;

    auto orig_thunk = reinterpret_cast<PIMAGE_THUNK_DATA>(base + import_desc->OriginalFirstThunk);
    auto thunk = reinterpret_cast<PIMAGE_THUNK_DATA>(base + import_desc->FirstThunk);
    if (!orig_thunk || !thunk)
      continue;

    for (; orig_thunk->u1.AddressOfData != 0; ++orig_thunk, ++thunk) {
      if (IMAGE_SNAP_BY_ORDINAL(orig_thunk->u1.Ordinal)) {
        continue;
      }
      auto import = reinterpret_cast<PIMAGE_IMPORT_BY_NAME>(base + orig_thunk->u1.AddressOfData);
      if (!import || !import->Name)
        continue;
      const char* name = reinterpret_cast<const char*>(import->Name);
      if (!CaseInsensitiveEquals(name, func_name))
        continue;

      DWORD old_protect;
      if (VirtualProtect(&thunk->u1.Function, sizeof(void*), PAGE_READWRITE, &old_protect)) {
        thunk->u1.Function = reinterpret_cast<ULONG_PTR>(original);
        VirtualProtect(&thunk->u1.Function, sizeof(void*), old_protect, &old_protect);
        FlushInstructionCache(GetCurrentProcess(), &thunk->u1.Function, sizeof(void*));
      }
    }
  }
}

static void ForEachProcessModule(std::function<void(HMODULE)> fn) {
  HMODULE modules[1024];
  DWORD bytes_needed = 0;
  if (!EnumProcessModules(GetCurrentProcess(), modules, sizeof(modules), &bytes_needed)) {
    // Fallback: at least patch main module
    fn(GetModuleHandle(nullptr));
    return;
  }
  size_t count = bytes_needed / sizeof(HMODULE);
  for (size_t i = 0; i < count; ++i) {
    fn(modules[i]);
  }
}

static void InstallHooks() {
  if (g_hooks_installed)
    return;

  HMODULE user32 = GetModuleHandleW(L"user32.dll");
  if (!user32)
    user32 = LoadLibraryW(L"user32.dll");
  if (!user32)
    return;

  g_original_show_window = reinterpret_cast<PFN_ShowWindow>(GetProcAddress(user32, "ShowWindow"));
  g_original_show_window_async =
      reinterpret_cast<PFN_ShowWindowAsync>(GetProcAddress(user32, "ShowWindowAsync"));
  if (!g_original_show_window)
    return;

  ForEachProcessModule([](HMODULE m) {
    PatchIATInModule(m, reinterpret_cast<FARPROC>(g_original_show_window),
                     reinterpret_cast<FARPROC>(HookedShowWindow), "ShowWindow");
    if (g_original_show_window_async) {
      PatchIATInModule(m, reinterpret_cast<FARPROC>(g_original_show_window_async),
                       reinterpret_cast<FARPROC>(HookedShowWindowAsync), "ShowWindowAsync");
    }
  });

  g_hooks_installed = true;
}

static void UninstallHooks() {
  if (!g_hooks_installed)
    return;

  ForEachProcessModule([](HMODULE m) {
    if (g_original_show_window) {
      RestoreIATInModule(m, reinterpret_cast<FARPROC>(g_original_show_window), "ShowWindow");
    }
    if (g_original_show_window_async) {
      RestoreIATInModule(m, reinterpret_cast<FARPROC>(g_original_show_window_async),
                         "ShowWindowAsync");
    }
  });
  g_hooks_installed = false;
}

}  // namespace

// Private implementation to hide Windows-specific details
class WindowManager::Impl {
 public:
  Impl(WindowManager* manager) : manager_(manager) {}
  ~Impl() {}

  void StartEventListening() {
    // Windows event monitoring would typically be done through:
    // - SetWinEventHook for system-wide window events
    // - Window subclassing for specific window events
    // This is a placeholder implementation
  }

  void StopEventListening() {
    // Clean up any event hooks or monitoring
  }

  void OnWindowEvent(HWND hwnd, const std::string& event_type) {
    // Get window ID, first trying custom property, then creating Window if needed
    WindowId window_id = GetWindowIdFromHwnd(hwnd);
    if (window_id == IdAllocator::kInvalidId) {
      return;
    }

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
      RECT rect;
      GetWindowRect(hwnd, &rect);
      Size new_size = {static_cast<double>(rect.right - rect.left),
                       static_cast<double>(rect.bottom - rect.top)};
      WindowResizedEvent event(window_id, new_size);
      manager_->DispatchWindowEvent(event);
    } else if (event_type == "moved") {
      RECT rect;
      GetWindowRect(hwnd, &rect);
      Point new_position = {static_cast<double>(rect.left), static_cast<double>(rect.top)};
      WindowMovedEvent event(window_id, new_position);
      manager_->DispatchWindowEvent(event);
    } else if (event_type == "closing") {
      // Window closing event - no longer emitted
    }
  }

 private:
  WindowManager* manager_;
  // Optional pre-show/hide/close hooks
  std::optional<WindowManager::WindowWillShowHook> will_show_hook_;
  std::optional<WindowManager::WindowWillHideHook> will_hide_hook_;
  std::optional<WindowManager::WindowWillCloseHook> will_close_hook_;

  friend class WindowManager;
};

WindowManager::WindowManager() : pimpl_(std::make_unique<Impl>(this)) {
  StartEventListening();
}

WindowManager::~WindowManager() {
  StopEventListening();
}

std::shared_ptr<Window> WindowManager::Get(WindowId id) {
  // First try to get from registry
  auto window = WindowRegistry::GetInstance().Get(id);
  if (window) {
    return window;
  }

  // If not in registry, enumerate all windows to find it
  // This will create and register the window if it exists
  GetAll();

  // Try again after enumeration
  return WindowRegistry::GetInstance().Get(id);
}

// Callback for EnumWindows to collect all top-level windows
static BOOL CALLBACK EnumWindowsCallback(HWND hwnd, LPARAM lParam) {
  auto* windows = reinterpret_cast<std::vector<HWND>*>(lParam);

  // Only include visible windows that are not minimized to taskbar
  // and have a title (filters out many background windows)
  if (IsWindowVisible(hwnd)) {
    int length = GetWindowTextLengthW(hwnd);
    if (length > 0) {
      // Check if it's a normal window (not tool window, etc.)
      LONG exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
      if (!(exStyle & WS_EX_TOOLWINDOW)) {
        windows->push_back(hwnd);
      }
    }
  }

  return TRUE;  // Continue enumeration
}

std::vector<std::shared_ptr<Window>> WindowManager::GetAll() {
  std::vector<HWND> hwnds;

  // Enumerate all top-level windows
  EnumWindows(EnumWindowsCallback, reinterpret_cast<LPARAM>(&hwnds));

  std::vector<std::shared_ptr<Window>> windows;
  windows.reserve(hwnds.size());

  for (HWND hwnd : hwnds) {
    // Get window ID from HWND, creating Window object if needed
    WindowId window_id = GetWindowIdFromHwnd(hwnd);

    if (window_id != IdAllocator::kInvalidId) {
      // Try to get existing window from registry
      auto window = WindowRegistry::GetInstance().Get(window_id);
      if (window) {
        windows.push_back(window);
      }
    }
  }

  return windows;
}

std::shared_ptr<Window> WindowManager::GetCurrent() {
  HWND hwnd = GetActiveWindow();
  if (hwnd) {
    WindowId window_id = GetWindowIdFromHwnd(hwnd);
    if (window_id != IdAllocator::kInvalidId) {
      return Get(window_id);
    }
  }
  return nullptr;
}

void WindowManager::SetWillShowHook(std::optional<WindowWillShowHook> hook) {
  pimpl_->will_show_hook_ = std::move(hook);

  bool has_any_hook = pimpl_->will_show_hook_.has_value() || pimpl_->will_hide_hook_.has_value();
  has_any_hook ? InstallHooks() : UninstallHooks();
}

void WindowManager::SetWillHideHook(std::optional<WindowWillHideHook> hook) {
  pimpl_->will_hide_hook_ = std::move(hook);

  bool has_any_hook = pimpl_->will_show_hook_.has_value() || pimpl_->will_hide_hook_.has_value();
  has_any_hook ? InstallHooks() : UninstallHooks();
}

void WindowManager::SetWillCloseHook(std::optional<WindowWillCloseHook> hook) {
  pimpl_->will_close_hook_ = std::move(hook);
  // ponytail: Windows close-interceptie vereist een WH_CBT hook of window
  // subclassing op WM_CLOSE — niet geïmplementeerd in deze iteratie.
  // De hook wordt wel opgeslagen zodat HandleWillClose werkt zodra de
  // event-monitoring dit signaal oppakt.
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
  HWND hwnd = static_cast<HWND>(native);
  // On Windows, call the original ShowWindow through the function pointer
  if (g_original_show_window) {
    return g_original_show_window(hwnd, SW_SHOW) != FALSE;
  }
  return false;
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
  HWND hwnd = static_cast<HWND>(native);
  // On Windows, call the original ShowWindow through the function pointer
  if (g_original_show_window) {
    return g_original_show_window(hwnd, SW_HIDE) != FALSE;
  }
  return false;
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
  HWND hwnd = static_cast<HWND>(native);
  // On Windows, send WM_CLOSE to trigger the normal close path
  PostMessage(hwnd, WM_CLOSE, 0, 0);
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
