#include "window_manager.h"

namespace nativeapi {

WindowManager& WindowManager::GetInstance() {
  static WindowManager instance;
  return instance;
}

}  // namespace nativeapi
