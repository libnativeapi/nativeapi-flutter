#include "../../preferences.h"

namespace nativeapi {

class Preferences::Impl {
 public:
  explicit Impl(const std::string& scope) : scope_(scope) {
    // Stub implementation - no initialization
  }

  ~Impl() = default;

  bool Set(const std::string& key, const std::string& value) {
    // Stub implementation
    return false;
  }

  std::string Get(const std::string& key, const std::string& default_value) const {
    // Stub implementation
    return default_value;
  }

  bool Remove(const std::string& key) {
    // Stub implementation
    return false;
  }

  bool Clear() {
    // Stub implementation
    return false;
  }

  bool Contains(const std::string& key) const {
    // Stub implementation
    return false;
  }

  std::vector<std::string> GetKeys() const {
    // Stub implementation
    return {};
  }

  size_t GetSize() const {
    // Stub implementation
    return 0;
  }

  std::map<std::string, std::string> GetAll() const {
    // Stub implementation
    return {};
  }

  const std::string& GetScope() const { return scope_; }

 private:
  std::string scope_;
};

// Constructor implementations
Preferences::Preferences() : Preferences("default") {}

Preferences::Preferences(const std::string& scope) : pimpl_(std::make_unique<Impl>(scope)) {}

Preferences::~Preferences() = default;

// Interface implementation
bool Preferences::Set(const std::string& key, const std::string& value) {
  return pimpl_->Set(key, value);
}

std::string Preferences::Get(const std::string& key, const std::string& default_value) const {
  return pimpl_->Get(key, default_value);
}

bool Preferences::Remove(const std::string& key) {
  return pimpl_->Remove(key);
}

bool Preferences::Clear() {
  return pimpl_->Clear();
}

bool Preferences::Contains(const std::string& key) const {
  return pimpl_->Contains(key);
}

std::vector<std::string> Preferences::GetKeys() const {
  return pimpl_->GetKeys();
}

size_t Preferences::GetSize() const {
  return pimpl_->GetSize();
}

std::map<std::string, std::string> Preferences::GetAll() const {
  return pimpl_->GetAll();
}

std::string Preferences::GetScope() const {
  return pimpl_->GetScope();
}

}  // namespace nativeapi
