#include "event_loop.h"

#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <thread>

#include <windows.h>

#include "capi/application_c.h"
#include "foundation/dispatcher.h"

bool cnativeapi_run_ui_thread(void (*entry)(void)) {
  static std::atomic<bool> started{false};
  if (entry == nullptr || started.exchange(true)) {
    return false;
  }
  // Win32 windows belong to the thread that creates them: any thread can be
  // the UI thread, as long as it stays the same one.
  std::thread([entry] {
    nativeapi::SetMainThread();
    entry();
    cnativeapi_exit(0);
  }).detach();
  return true;
}

void cnativeapi_start_event_loop(void) {
  (void)native_application_is_running();
}

int cnativeapi_pump_event_loop(int timeout_ms) {
  MSG msg;
  if (!PeekMessageW(&msg, nullptr, 0, 0, PM_NOREMOVE)) {
    MsgWaitForMultipleObjectsEx(0, nullptr, static_cast<DWORD>(timeout_ms), QS_ALLINPUT,
                                MWMO_INPUTAVAILABLE);
  }
  while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
    // Application::Quit() posts WM_QUIT, exactly as it would to Run().
    if (msg.message == WM_QUIT) {
      return static_cast<int>(msg.wParam);
    }
    TranslateMessage(&msg);
    DispatchMessageW(&msg);
  }
  return -1;
}

void cnativeapi_exit(int exit_code) {
  fflush(nullptr);
  _Exit(exit_code);
}
