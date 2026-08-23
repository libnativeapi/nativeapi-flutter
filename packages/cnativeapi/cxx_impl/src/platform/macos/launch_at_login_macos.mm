#import <Foundation/Foundation.h>
#if __has_include(<ServiceManagement/SMAppService.h>)
#import <ServiceManagement/SMAppService.h>
#define NATIVEAPI_HAS_SM_APP_SERVICE 1
#else
#define NATIVEAPI_HAS_SM_APP_SERVICE 0
#endif
#include <limits.h>
#import <mach-o/dyld.h>
#include <unistd.h>

#include "../../launch_at_login.h"

namespace nativeapi {

namespace {

// Convert std::string <-> NSString helpers
static inline NSString* ToNSString(const std::string& s) {
  return [NSString stringWithUTF8String:s.c_str()];
}

static inline std::string ToStdString(NSString* s) {
  if (!s)
    return std::string();
  const char* cstr = [s UTF8String];
  return cstr ? std::string(cstr) : std::string();
}

// Best-effort default identifier: CFBundleIdentifier or
// "com.nativeapi.launch_at_login.<process-name>"
static std::string DetectDefaultId() {
  @autoreleasepool {
    NSString* bundleId = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleId.length > 0) {
      return ToStdString(bundleId);
    }
    NSString* processName = [[NSProcessInfo processInfo] processName];
    if (processName.length == 0) {
      processName = @"app";
    }
    NSString* fallback =
        [NSString stringWithFormat:@"com.nativeapi.launch_at_login.%@", processName];
    return ToStdString(fallback);
  }
}

// Best-effort default display name: CFBundleName or processName
static std::string DetectDefaultDisplayName() {
  @autoreleasepool {
    NSString* name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (name.length == 0) {
      name = [[NSProcessInfo processInfo] processName];
    }
    if (name.length == 0) {
      name = @"Application";
    }
    return ToStdString(name);
  }
}

// Resolve current executable path.
// Prefer NSProcessInfo.arguments[0]; fallback to _NSGetExecutablePath.
static std::string DetectDefaultProgramPath() {
  @autoreleasepool {
    NSString* arg0 = [[[NSProcessInfo processInfo] arguments] firstObject];
    if (arg0.length > 0) {
      // If arg0 is relative, attempt to get full path via file system resolution.
      NSString* resolved = [arg0 stringByStandardizingPath];
      if (![resolved isAbsolutePath]) {
        // Try to resolve via current directory (best-effort)
        char cwdBuff[PATH_MAX];
        if (getcwd(cwdBuff, sizeof(cwdBuff))) {
          NSString* cwd = [NSString stringWithUTF8String:cwdBuff];
          resolved = [cwd stringByAppendingPathComponent:arg0];
          resolved = [resolved stringByStandardizingPath];
        }
      }
      return ToStdString(resolved);
    }

    // Fallback to _NSGetExecutablePath
    uint32_t size = 0;
    _NSGetExecutablePath(nullptr, &size);
    if (size > 0) {
      std::string buffer(size + 1, '\0');
      if (_NSGetExecutablePath(buffer.data(), &size) == 0) {
        return std::string(buffer.c_str());
      }
    }

    return std::string();
  }
}

static bool IsCurrentProgram(const std::string& executable_path) {
  if (executable_path.empty()) {
    return true;
  }

  std::string current = DetectDefaultProgramPath();
  if (current.empty()) {
    return false;
  }

  @autoreleasepool {
    NSString* requested = [ToNSString(executable_path) stringByStandardizingPath];
    NSString* detected = [ToNSString(current) stringByStandardizingPath];
    return [requested isEqualToString:detected];
  }
}

}  // namespace

class LaunchAtLogin::Impl {
 public:
  static bool IsSupported() {
#if NATIVEAPI_HAS_SM_APP_SERVICE
    if (@available(macOS 13.0, *)) {
      return true;
    }
#endif
    return false;
  }

  Impl()
      : id_(DetectDefaultId()),
        display_name_(DetectDefaultDisplayName()),
        program_path_(DetectDefaultProgramPath()),
        default_id_(id_),
        default_program_path_(program_path_) {}

  explicit Impl(const std::string& id)
      : id_(id),
        display_name_(DetectDefaultDisplayName()),
        program_path_(DetectDefaultProgramPath()),
        default_id_(DetectDefaultId()),
        default_program_path_(program_path_) {}

  Impl(const std::string& id, const std::string& display_name)
      : id_(id),
        display_name_(display_name),
        program_path_(DetectDefaultProgramPath()),
        default_id_(DetectDefaultId()),
        default_program_path_(program_path_) {}

  ~Impl() = default;

  std::string GetId() const { return id_; }

  std::string GetDisplayName() const { return display_name_; }

  bool SetDisplayName(const std::string& display_name) {
    display_name_ = display_name;
    return true;
  }

  bool SetProgram(const std::string& executable_path, const std::vector<std::string>& arguments) {
    program_path_ = executable_path;
    arguments_ = arguments;
    return true;
  }

  std::string GetExecutablePath() const { return program_path_; }

  std::vector<std::string> GetArguments() const { return arguments_; }

  bool Enable() {
#if NATIVEAPI_HAS_SM_APP_SERVICE
    @autoreleasepool {
      if (@available(macOS 13.0, *)) {
        if (!CanUseConfiguredProgram()) {
          return false;
        }

        SMAppService* service = Service();
        if (!service) {
          return false;
        }

        SMAppServiceStatus status = service.status;
        if (status == SMAppServiceStatusEnabled) {
          return true;
        }
        if (status == SMAppServiceStatusRequiresApproval) {
          return false;
        }

        NSError* error = nil;
        return [service registerAndReturnError:&error] == YES;
      }
    }
#endif
    return false;
  }

  bool Disable() {
#if NATIVEAPI_HAS_SM_APP_SERVICE
    @autoreleasepool {
      if (@available(macOS 13.0, *)) {
        SMAppService* service = Service();
        if (!service) {
          return false;
        }

        if (service.status == SMAppServiceStatusNotRegistered) {
          return true;
        }

        NSError* error = nil;
        return [service unregisterAndReturnError:&error] == YES ||
               service.status == SMAppServiceStatusNotRegistered;
      }
    }
#endif
    return false;
  }

  bool IsEnabled() const {
#if NATIVEAPI_HAS_SM_APP_SERVICE
    @autoreleasepool {
      if (@available(macOS 13.0, *)) {
        SMAppService* service = Service();
        if (!service) {
          return false;
        }

        SMAppServiceStatus status = service.status;
        return status == SMAppServiceStatusEnabled;
      }
    }
#endif
    return false;
  }

 private:
#if NATIVEAPI_HAS_SM_APP_SERVICE
  SMAppService* Service() const API_AVAILABLE(macos(13.0)) {
    @autoreleasepool {
      if (id_.empty() || id_ == default_id_) {
        return [SMAppService mainAppService];
      }

      NSString* identifier = ToNSString(id_);
      if (identifier.length == 0) {
        return nil;
      }
      return [SMAppService loginItemServiceWithIdentifier:identifier];
    }
  }
#endif

  bool CanUseConfiguredProgram() const {
    // SMAppService registers the main app or bundled helpers. It cannot register
    // an arbitrary executable path or ProgramArguments like a legacy LaunchAgent.
    return arguments_.empty() &&
           (program_path_.empty() || program_path_ == default_program_path_ ||
            IsCurrentProgram(program_path_));
  }

 private:
  std::string id_;
  std::string display_name_;
  std::string program_path_;
  std::vector<std::string> arguments_;
  std::string default_id_;
  std::string default_program_path_;
};

// LaunchAtLogin public API implementations

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
