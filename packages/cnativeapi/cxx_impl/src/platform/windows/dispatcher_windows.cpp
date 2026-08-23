#include "../../foundation/dispatcher_platform.h"
#include "../../foundation/dispatcher_common.h"

#include <windows.h>

#include <mutex>

namespace nativeapi {
namespace dispatcher_platform {

namespace {

// Private message carrying a heap-allocated std::function* in lParam.
constexpr UINT kDispatchMessage = WM_APP + 0x51;
constexpr wchar_t kDispatchWindowClass[] = L"NativeApiDispatcherWindow";

HWND g_dispatch_window = nullptr;
std::once_flag g_dispatch_window_once;

LRESULT CALLBACK DispatchWndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
  if (msg == kDispatchMessage) {
    auto* work = reinterpret_cast<std::function<void()>*>(lparam);
    if (work) {
      (*work)();
      delete work;
    }
    return 0;
  }
  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

/**
 * Creates the message-only window that receives dispatched work.
 *
 * MUST run on the main thread: a window's messages are delivered to the message
 * queue of the thread that created it, so creating it anywhere else would defeat
 * the entire purpose. Callers are responsible for the thread check.
 *
 * Deliberately lazy rather than created during static initialization — under a
 * DLL build that would run inside the loader lock, where creating a window can
 * deadlock.
 */
void EnsureDispatchWindowOnMainThread() {
  std::call_once(g_dispatch_window_once, [] {
    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = DispatchWndProc;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = kDispatchWindowClass;
    RegisterClassExW(&wc);

    g_dispatch_window = CreateWindowExW(0, kDispatchWindowClass, L"", 0, 0, 0, 0, 0, HWND_MESSAGE,
                                        nullptr, wc.hInstance, nullptr);
  });
}

}  // namespace

bool PlatformIsMainThread() {
  const bool is_main = dispatcher_internal::IsMainThreadByCapturedId();
  if (is_main) {
    // Prime the dispatch window while we are provably on the right thread, so
    // that a later post from a worker thread has somewhere to go.
    EnsureDispatchWindowOnMainThread();
  }
  return is_main;
}

void PlatformSetMainThread() {
  dispatcher_internal::CaptureCallerAsMainThread();
  EnsureDispatchWindowOnMainThread();
}

bool PlatformIsMainThreadDispatchSupported() {
  return true;
}

bool PlatformRunOnMainThread(std::function<void()> fn) {
  if (!fn) {
    return true;
  }

  if (dispatcher_internal::IsMainThreadByCapturedId()) {
    EnsureDispatchWindowOnMainThread();
  }

  if (!g_dispatch_window) {
    // A worker thread asked to dispatch before the main thread ever touched the
    // library, so there is no window yet and we must not create one here.
    // Report the failure instead of silently dropping the work; callers should
    // call SetMainThread() during startup to make this impossible.
    return false;
  }

  auto* work = new std::function<void()>(std::move(fn));
  if (!PostMessageW(g_dispatch_window, kDispatchMessage, 0, reinterpret_cast<LPARAM>(work))) {
    delete work;
    return false;
  }
  return true;
}

bool PlatformRunMainThreadLoopFor(int timeout_ms) {
  const DWORD deadline = GetTickCount() + static_cast<DWORD>(timeout_ms);
  MSG msg;
  for (;;) {
    while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
      TranslateMessage(&msg);
      DispatchMessageW(&msg);
    }
    if (timeout_ms <= 0 || GetTickCount() >= deadline) {
      return true;
    }
    // Sleep until a message arrives or the budget expires, whichever is first.
    MsgWaitForMultipleObjects(0, nullptr, FALSE, deadline - GetTickCount(), QS_ALLINPUT);
  }
}

}  // namespace dispatcher_platform
}  // namespace nativeapi
