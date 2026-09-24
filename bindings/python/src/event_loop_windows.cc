#include "event_loop.h"

#include <windows.h>

void nativeapi_py_start_event_loop(uint64_t window) {
  nativeapi_py::ShowPrimaryWindow(window);
}

int nativeapi_py_pump_event_loop(void) {
  MSG msg;
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
