#include "event_loop.h"

#include <windows.h>

namespace nativeapi_js {

void ShowPrimaryWindow(uint64_t window);

void StartEventLoop(uint64_t window) {
  ShowPrimaryWindow(window);
}

int PumpEventLoop() {
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

}  // namespace nativeapi_js
