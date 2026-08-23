#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <iostream>
#include "../../application.h"
#include "../../window_manager.h"

// Temporarily disable logging to avoid macro conflicts
#define HILOG_WARN(...) ((void)0)

namespace nativeapi {

class Application::Impl {
 public:
  Impl() {}
};

Application::Application() : pimpl_(std::make_unique<Impl>()) {}
Application::~Application() {}

int Application::Run() {
  HILOG_WARN("Application::Run not applicable on OpenHarmony (handled by Ability lifecycle)");
  return 0;
}

int Application::Run(std::shared_ptr<Window> window) {
  HILOG_WARN("Application::Run with window not applicable on OpenHarmony");
  return 0;
}

void Application::Quit(int exit_code) {
  HILOG_WARN("Application::Quit requests Ability terminate");
}

bool Application::IsRunning() const {
  return true;
}

bool Application::IsSingleInstance() const {
  return false;
}

bool Application::SetIcon(const std::string& icon_path) {
  HILOG_WARN("Application::SetIcon not implemented on OpenHarmony");
  return false;
}

bool Application::SetDockIconVisible(bool visible) {
  HILOG_WARN("Application::SetDockIconVisible not applicable on OpenHarmony");
  return false;
}

bool Application::SetMenuBar(std::shared_ptr<Menu> menu) {
  HILOG_WARN("Application::SetMenuBar not implemented on OpenHarmony");
  return false;
}

std::shared_ptr<Window> Application::GetPrimaryWindow() const {
  return nullptr;
}

void Application::SetPrimaryWindow(std::shared_ptr<Window> window) {
  HILOG_WARN("Application::SetPrimaryWindow not implemented on OpenHarmony");
}

std::vector<std::shared_ptr<Window>> Application::GetAllWindows() const {
  auto& window_manager = WindowManager::GetInstance();
  return window_manager.GetAll();
}

}  // namespace nativeapi
