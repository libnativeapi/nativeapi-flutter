#include "application.h"

namespace nativeapi {

Application& Application::GetInstance() {
  static Application instance;
  return instance;
}

int RunApp(std::shared_ptr<Window> window) {
  return Application::GetInstance().Run(window);
}

}  // namespace nativeapi
