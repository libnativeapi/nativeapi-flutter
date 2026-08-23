#include "../../shortcut_manager.h"

namespace nativeapi {

class ShortcutManagerImpl final : public ShortcutManager::Impl {
 public:
  explicit ShortcutManagerImpl(ShortcutManager* manager) : manager_(manager) {}
  ~ShortcutManagerImpl() override = default;

  bool IsSupported() override { return false; }
  bool RegisterShortcut(const std::shared_ptr<Shortcut>& /*shortcut*/) override { return false; }
  bool UnregisterShortcut(const std::shared_ptr<Shortcut>& /*shortcut*/) override { return false; }
  void SetupEventMonitoring() override {}
  void CleanupEventMonitoring() override {}

 private:
  ShortcutManager* manager_;
};

ShortcutManager::ShortcutManager()
    : pimpl_(std::make_unique<ShortcutManagerImpl>(this)), next_shortcut_id_(1), enabled_(true) {}

ShortcutManager::~ShortcutManager() {
  UnregisterAll();
}

}  // namespace nativeapi
