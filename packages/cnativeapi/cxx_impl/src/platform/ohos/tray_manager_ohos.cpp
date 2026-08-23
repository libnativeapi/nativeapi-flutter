#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>
#include "../../tray_manager.h"

#ifdef __OHOS__
#define LOG_CORE 0xD001700
// Note: LOG_TAG is defined in hilog/log.h as NULL,
// redefine to avoid warnings if needed
#undef LOG_TAG
#define LOG_TAG "NativeApi"
#endif

namespace nativeapi {

class TrayManager::Impl {
 public:
  Impl(TrayManager* manager) : manager_(manager) {}

  TrayManager* manager_;
};

TrayManager::TrayManager() : pimpl_(std::make_unique<Impl>(this)), next_tray_id_(1) {}

TrayManager::~TrayManager() = default;

bool TrayManager::IsSupported() {
  // Not implemented on OpenHarmony yet
  return false;
}

std::shared_ptr<TrayIcon> TrayManager::Get(TrayIconId id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = trays_.find(id);
  return (it != trays_.end()) ? it->second : nullptr;
}

std::vector<std::shared_ptr<TrayIcon>> TrayManager::GetAll() {
  std::lock_guard<std::mutex> lock(mutex_);
  std::vector<std::shared_ptr<TrayIcon>> result;
  result.reserve(trays_.size());
  for (const auto& [id, tray] : trays_) {
    result.push_back(tray);
  }
  return result;
}

}  // namespace nativeapi
