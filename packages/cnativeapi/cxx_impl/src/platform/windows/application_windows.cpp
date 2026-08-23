// clang-format off
#include <windows.h>
#include <shellapi.h>
// clang-format on
#include <iostream>
#include <string>
#include <vector>

#include "../../application.h"
#include "../../menu.h"
#include "../../window_manager.h"

namespace nativeapi {

class Application::Impl {
 public:
  Impl(Application* app) : app_(app), hinstance_(GetModuleHandle(nullptr)) {}
  ~Impl() = default;

  bool Initialize() {
    // Initialize COM
    HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    if (FAILED(hr)) {
      return false;
    }

    return true;
  }

  int Run() {
    MSG msg = {};
    int exit_code = 0;

    while (true) {
      // Get message from the message queue
      BOOL result = GetMessage(&msg, nullptr, 0, 0);

      if (result == -1) {
        // Error occurred
        exit_code = -1;
        break;
      } else if (result == 0) {
        // WM_QUIT received
        exit_code = static_cast<int>(msg.wParam);
        break;
      } else {
        // Translate and dispatch the message
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      }
    }

    return exit_code;
  }

  int Run(std::shared_ptr<Window> window) {
    if (!window) {
      return -1;
    }

    // Set the window as primary window
    app_->SetPrimaryWindow(window);

    // Show the window
    window->Show();
    window->Focus();

    // Start the message loop
    MSG msg = {};
    int exit_code = 0;

    while (true) {
      // Get message from the message queue
      BOOL result = GetMessage(&msg, nullptr, 0, 0);

      if (result == -1) {
        // Error occurred
        exit_code = -1;
        break;
      } else if (result == 0) {
        // WM_QUIT received
        exit_code = static_cast<int>(msg.wParam);
        break;
      } else {
        // Translate and dispatch the message
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      }
    }

    return exit_code;
  }

  void Quit(int exit_code) { PostQuitMessage(exit_code); }

  bool SetIcon(const std::string& icon_path) {
    if (icon_path.empty()) {
      return false;
    }

    // Convert to wide string
    std::wstring wide_path(icon_path.begin(), icon_path.end());

    // Load icon from file using LoadImageW for wide strings
    HICON icon = static_cast<HICON>(
        LoadImageW(nullptr, wide_path.c_str(), IMAGE_ICON, 0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE));

    if (!icon) {
      return false;
    }

    // Set application icon
    SetClassLongPtr(GetConsoleWindow(), GCLP_HICON, reinterpret_cast<LONG_PTR>(icon));

    return true;
  }

  bool SetDockIconVisible(bool visible) {
    // Windows doesn't have a dock, so this is a no-op
    return true;
  }

  bool SetMenuBar(std::shared_ptr<Menu> menu) {
    if (!menu) {
      return false;
    }

    // Get the primary window
    auto primary_window = app_->GetPrimaryWindow();
    if (!primary_window) {
      return false;
    }

    // Get the native window handle
    HWND hwnd = static_cast<HWND>(primary_window->GetNativeObject());
    if (!hwnd) {
      return false;
    }

    // Get the native menu handle
    HMENU hmenu = static_cast<HMENU>(menu->GetNativeObject());
    if (!hmenu) {
      return false;
    }

    // Set the menu for the window
    SetMenu(hwnd, hmenu);

    return true;
  }

  void CleanupEventMonitoring() {
    // Clean up Windows-specific event monitoring
    if (mutex_) {
      CloseHandle(mutex_);
      mutex_ = nullptr;
    }

    CoUninitialize();
  }

 private:
  Application* app_;
  HINSTANCE hinstance_;
  HANDLE mutex_ = nullptr;
};

Application::Application()
    : initialized_(true), running_(false), exit_code_(0), pimpl_(std::make_unique<Impl>(this)) {
  // Perform platform-specific initialization automatically
  pimpl_->Initialize();

  // Emit application started event
  Emit<ApplicationStartedEvent>();
}

Application::~Application() {
  // Clean up platform-specific event monitoring
  pimpl_->CleanupEventMonitoring();
}

int Application::Run() {
  running_ = true;

  // Start the platform-specific main event loop
  int result = pimpl_->Run();

  running_ = false;

  // Emit exit event
  Emit<ApplicationExitingEvent>(result);

  return result;
}

int Application::Run(std::shared_ptr<Window> window) {
  if (!window) {
    return -1;  // Invalid window
  }

  running_ = true;

  // Start the platform-specific main event loop with window
  int result = pimpl_->Run(window);

  running_ = false;

  // Emit exit event
  Emit<ApplicationExitingEvent>(result);

  return result;
}

void Application::Quit(int exit_code) {
  exit_code_ = exit_code;

  // Emit quit requested event
  Emit<ApplicationQuitRequestedEvent>();

  // Request platform-specific quit
  pimpl_->Quit(exit_code);
}

bool Application::IsRunning() const {
  return running_;
}

bool Application::IsSingleInstance() const {
  return false;
}

bool Application::SetIcon(const std::string& icon_path) {
  return pimpl_->SetIcon(icon_path);
}

bool Application::SetDockIconVisible(bool visible) {
  return pimpl_->SetDockIconVisible(visible);
}

bool Application::SetMenuBar(std::shared_ptr<Menu> menu) {
  return pimpl_->SetMenuBar(menu);
}

std::shared_ptr<Window> Application::GetPrimaryWindow() const {
  return primary_window_;
}

void Application::SetPrimaryWindow(std::shared_ptr<Window> window) {
  primary_window_ = window;
}

std::vector<std::shared_ptr<Window>> Application::GetAllWindows() const {
  auto& window_manager = WindowManager::GetInstance();
  return window_manager.GetAll();
}

}  // namespace nativeapi
