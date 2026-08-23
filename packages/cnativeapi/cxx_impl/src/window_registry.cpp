#include "window_registry.h"
#include "foundation/object_registry.h"
#include "window.h"

namespace nativeapi {

class WindowRegistry::Impl {
 public:
  ObjectRegistry<Window, WindowId> registry_;
};

WindowRegistry& WindowRegistry::GetInstance() {
  static WindowRegistry instance;
  return instance;
}

WindowRegistry::WindowRegistry() : pimpl_(std::make_unique<Impl>()) {}
WindowRegistry::~WindowRegistry() = default;

void WindowRegistry::Add(WindowId id, const std::shared_ptr<Window>& window) {
  pimpl_->registry_.Add(id, window);
}

std::shared_ptr<Window> WindowRegistry::Get(WindowId id) const {
  return pimpl_->registry_.Get(id);
}

std::vector<std::shared_ptr<Window>> WindowRegistry::GetAll() const {
  return pimpl_->registry_.GetAll();
}

bool WindowRegistry::Contains(WindowId id) const {
  return pimpl_->registry_.Contains(id);
}

bool WindowRegistry::Remove(WindowId id) {
  return pimpl_->registry_.Remove(id);
}

void WindowRegistry::Clear() {
  pimpl_->registry_.Clear();
}

}  // namespace nativeapi
