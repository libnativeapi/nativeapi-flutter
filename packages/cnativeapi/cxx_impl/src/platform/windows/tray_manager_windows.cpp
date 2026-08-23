#include <memory>
#include <mutex>

#include "../../tray_icon.h"
#include "../../tray_manager.h"

namespace nativeapi {

// Define the Impl class for Windows (empty for now, as Windows doesn't need
// platform-specific data)
class TrayManager::Impl {
 public:
  Impl() {}
  ~Impl() {}
};

TrayManager::TrayManager() : pimpl_(std::make_unique<Impl>()), next_tray_id_(1) {}

TrayManager::~TrayManager() {
  std::lock_guard<std::mutex> lock(mutex_);
  // Clean up all managed tray icons
  for (auto& pair : trays_) {
    auto tray = pair.second;
    if (tray) {
      // The TrayIcon destructor will handle cleanup of the tray icon
    }
  }
  trays_.clear();
}

bool TrayManager::IsSupported() {
  return true;  // Windows always supports system tray
}

std::shared_ptr<TrayIcon> TrayManager::Get(TrayIconId id) {
  std::lock_guard<std::mutex> lock(mutex_);

  auto it = trays_.find(id);
  if (it != trays_.end()) {
    return it->second;
  }
  return nullptr;
}

std::vector<std::shared_ptr<TrayIcon>> TrayManager::GetAll() {
  std::lock_guard<std::mutex> lock(mutex_);

  std::vector<std::shared_ptr<TrayIcon>> trays;
  for (const auto& pair : trays_) {
    trays.push_back(pair.second);
  }
  return trays;
}

}  // namespace nativeapi
