#include <android/log.h>
#include "../../tray_manager.h"

#define LOG_TAG "NativeApi"
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

namespace nativeapi {

class TrayManager::Impl {
 public:
  Impl(TrayManager* manager) : manager_(manager) {}
  TrayManager* manager_;
};

TrayManager::TrayManager() : pimpl_(std::make_unique<Impl>(this)), next_tray_id_(1) {}
TrayManager::~TrayManager() {}

bool TrayManager::IsSupported() {
  ALOGW("TrayManager::IsSupported - uses Android notifications");
  return true;
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
