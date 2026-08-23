#include "display_manager.h"

#include <utility>

namespace nativeapi {

DisplayManager& DisplayManager::GetInstance() {
  static DisplayManager instance;
  return instance;
}

std::vector<std::shared_ptr<Display>> DisplayManager::GetAll() {
  return Reconcile(EnumerateNativeDisplays(), nullptr, nullptr);
}

std::shared_ptr<Display> DisplayManager::GetPrimary() {
  auto natives = EnumerateNativeDisplays();
  auto displays = Reconcile(natives, nullptr, nullptr);
  for (size_t i = 0; i < natives.size(); ++i) {
    if (natives[i].is_primary) {
      return displays[i];
    }
  }
  return displays.empty() ? nullptr : displays.front();
}

std::vector<std::shared_ptr<Display>> DisplayManager::Reconcile(
    const std::vector<NativeDisplayInfo>& natives,
    std::vector<std::shared_ptr<Display>>* added,
    std::vector<std::shared_ptr<Display>>* removed) {
  std::vector<std::shared_ptr<Display>> current;
  current.reserve(natives.size());

  std::unordered_map<std::string, std::shared_ptr<Display>> next;
  next.reserve(natives.size());

  for (const auto& native : natives) {
    auto it = displays_.find(native.key);
    std::shared_ptr<Display> display;
    if (it != displays_.end()) {
      display = it->second;
    } else {
      display = std::make_shared<Display>(native.native);
      if (added) {
        added->push_back(display);
      }
    }
    next.emplace(native.key, display);
    current.push_back(std::move(display));
  }

  if (removed) {
    for (const auto& entry : displays_) {
      if (next.find(entry.first) == next.end()) {
        removed->push_back(entry.second);
      }
    }
  }

  displays_ = std::move(next);
  return current;
}

void DisplayManager::HandleDisplaysChanged() {
  std::vector<std::shared_ptr<Display>> added;
  std::vector<std::shared_ptr<Display>> removed;
  Reconcile(EnumerateNativeDisplays(), &added, &removed);
  for (const auto& display : added) {
    Emit<DisplayAddedEvent>(display);
  }
  for (const auto& display : removed) {
    Emit<DisplayRemovedEvent>(display);
  }
}

}  // namespace nativeapi
