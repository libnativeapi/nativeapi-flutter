#include "tray_manager.h"

namespace nativeapi {

TrayManager& TrayManager::GetInstance() {
  static TrayManager instance;
  return instance;
}

}  // namespace nativeapi
