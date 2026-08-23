#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <string>
#include "../../application.h"
#include "../../window_manager.h"

namespace nativeapi {

class Application::Impl {
 public:
  Impl() {}
};

Application::Application() : pimpl_(std::make_unique<Impl>()) {}
Application::~Application() {}

int Application::Run() {
  // On iOS, application lifecycle is managed by UIApplication
  // This is typically handled in the AppDelegate
  return 0;
}

int Application::Run(std::shared_ptr<Window> window) {
  // iOS manages app lifecycle through UIApplication
  return 0;
}

void Application::Quit(int exit_code) {
  // On iOS, apps don't exit programmatically
  // The system manages app lifecycle
}

bool Application::IsRunning() const {
  UIApplication* app = [UIApplication sharedApplication];
  return app != nil;
}

bool Application::IsSingleInstance() const {
  return true;  // iOS apps are always single instance
}

bool Application::SetIcon(const std::string& icon_path) {
  // iOS app icons are set in Info.plist
  return false;
}

bool Application::SetDockIconVisible(bool visible) {
  // Not applicable to iOS
  return false;
}

bool Application::SetMenuBar(std::shared_ptr<Menu> menu) {
  // iOS doesn't have a menu bar
  return false;
}

std::shared_ptr<Window> Application::GetPrimaryWindow() const {
  return nullptr;
}

void Application::SetPrimaryWindow(std::shared_ptr<Window> window) {
  // iOS manages primary window through UIApplication
}

std::vector<std::shared_ptr<Window>> Application::GetAllWindows() const {
  auto& window_manager = WindowManager::GetInstance();
  return window_manager.GetAll();
}

}  // namespace nativeapi
