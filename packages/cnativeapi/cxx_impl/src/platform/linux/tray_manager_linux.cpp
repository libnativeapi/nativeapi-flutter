#include <gio/gio.h>
#include <memory>
#include <mutex>

#include "../../tray_icon.h"
#include "../../tray_manager.h"

namespace nativeapi {

class TrayManager::Impl {
 public:
  Impl() {}
  ~Impl() {}
};

TrayManager::TrayManager() : next_tray_id_(1), pimpl_(std::make_unique<Impl>()) {}

TrayManager::~TrayManager() {
  std::lock_guard<std::mutex> lock(mutex_);
  trays_.clear();
}

bool TrayManager::IsSupported() {
  // Cache the result: session bus availability does not change during runtime.
  static bool checked = false;
  static bool supported = false;
  if (!checked) {
    GDBusConnection* conn = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
    if (conn) {
      g_object_unref(conn);
      supported = true;
    }
    checked = true;
  }
  return supported;
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
