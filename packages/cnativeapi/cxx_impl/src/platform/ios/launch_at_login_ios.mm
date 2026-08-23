#import <TargetConditionals.h>

#include "../../launch_at_login.h"

namespace nativeapi {

/**
 * iOS stub implementation for LaunchAtLogin.
 *
 * Auto-start at user login is not supported on iOS. All operations that would
 * enable/disable or configure launch-at-login return false. Getters return the
 * locally stored values (typically empty), while setters return false and do
 * not modify state.
 */
class LaunchAtLogin::Impl {
 public:
  // Unsupported platform semantics
  static bool IsSupported() { return false; }

  Impl() = default;

  explicit Impl(const std::string& id) : id_(id) {}

  Impl(const std::string& id, const std::string& display_name)
      : id_(id), display_name_(display_name) {}

  ~Impl() = default;

  // Getters return whatever is locally available (likely empty)
  std::string GetId() const { return id_; }
  std::string GetDisplayName() const { return display_name_; }

  // No-op setter; returns false to indicate unsupported
  bool SetDisplayName(const std::string& /*display_name*/) { return false; }

  bool SetProgram(const std::string& /*executable_path*/,
                  const std::vector<std::string>& /*arguments*/) {
    return false;
  }

  std::string GetExecutablePath() const { return program_path_; }
  std::vector<std::string> GetArguments() const { return arguments_; }

  bool Enable() { return false; }
  bool Disable() { return false; }
  bool IsEnabled() const { return false; }

 private:
  std::string id_;
  std::string display_name_;
  std::string program_path_;
  std::vector<std::string> arguments_;
};

// LaunchAtLogin public API forwarding to Impl

LaunchAtLogin::LaunchAtLogin() : pimpl_(std::make_unique<Impl>()) {}

LaunchAtLogin::LaunchAtLogin(const std::string& id) : pimpl_(std::make_unique<Impl>(id)) {}

LaunchAtLogin::LaunchAtLogin(const std::string& id, const std::string& display_name)
    : pimpl_(std::make_unique<Impl>(id, display_name)) {}

LaunchAtLogin::~LaunchAtLogin() = default;

bool LaunchAtLogin::IsSupported() {
  return Impl::IsSupported();
}

std::string LaunchAtLogin::GetId() const {
  return pimpl_->GetId();
}

std::string LaunchAtLogin::GetDisplayName() const {
  return pimpl_->GetDisplayName();
}

bool LaunchAtLogin::SetDisplayName(const std::string& display_name) {
  return pimpl_->SetDisplayName(display_name);
}

bool LaunchAtLogin::SetProgram(const std::string& executable_path,
                               const std::vector<std::string>& arguments) {
  return pimpl_->SetProgram(executable_path, arguments);
}

std::string LaunchAtLogin::GetExecutablePath() const {
  return pimpl_->GetExecutablePath();
}

std::vector<std::string> LaunchAtLogin::GetArguments() const {
  return pimpl_->GetArguments();
}

bool LaunchAtLogin::Enable() {
  return pimpl_->Enable();
}

bool LaunchAtLogin::Disable() {
  return pimpl_->Disable();
}

bool LaunchAtLogin::IsEnabled() const {
  return pimpl_->IsEnabled();
}

}  // namespace nativeapi
