#include "shortcut.h"

namespace nativeapi {

Shortcut::Shortcut(ShortcutId id, const ShortcutOptions& options)
    : id_(id),
      accelerator_(options.accelerator),
      description_(options.description),
      scope_(options.scope),
      enabled_(options.enabled),
      callback_(options.callback) {}

Shortcut::Shortcut(ShortcutId id, const std::string& accelerator, std::function<void()> callback)
    : id_(id),
      accelerator_(accelerator),
      description_(""),
      scope_(ShortcutScope::Global),
      enabled_(true),
      callback_(callback) {}

Shortcut::~Shortcut() = default;

ShortcutId Shortcut::GetId() const {
  return id_;
}

std::string Shortcut::GetAccelerator() const {
  return accelerator_;
}

std::string Shortcut::GetDescription() const {
  return description_;
}

void Shortcut::SetDescription(const std::string& description) {
  description_ = description;
}

ShortcutScope Shortcut::GetScope() const {
  return scope_;
}

void Shortcut::SetEnabled(bool enabled) {
  enabled_ = enabled;
}

bool Shortcut::IsEnabled() const {
  return enabled_;
}

void Shortcut::Invoke() {
  if (enabled_ && callback_) {
    callback_();
  }
}

void Shortcut::SetCallback(std::function<void()> callback) {
  callback_ = callback;
}

std::function<void()> Shortcut::GetCallback() const {
  return callback_;
}

}  // namespace nativeapi
