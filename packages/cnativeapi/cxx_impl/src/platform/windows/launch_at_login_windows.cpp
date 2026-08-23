#include <windows.h>

#include <algorithm>
#include <cctype>
#include <sstream>
#include <string>
#include <vector>

#include "../../launch_at_login.h"

namespace nativeapi {

namespace {

// Get the absolute path to the current executable (ANSI).
static std::string DetectDefaultProgramPath() {
  char path[MAX_PATH] = {0};
  DWORD len = GetModuleFileNameA(nullptr, path, static_cast<DWORD>(sizeof(path)));
  if (len == 0 || len >= sizeof(path)) {
    return std::string();
  }
  return std::string(path, len);
}

static std::string Basename(const std::string& path) {
  if (path.empty())
    return std::string();
  size_t pos = path.find_last_of("\\/");
  if (pos == std::string::npos)
    return path;
  if (pos + 1 >= path.size())
    return path;  // trailing slash
  return path.substr(pos + 1);
}

static std::string StripExtension(const std::string& name) {
  size_t pos = name.find_last_of('.');
  if (pos == std::string::npos)
    return name;
  return name.substr(0, pos);
}

// Default identifier for Windows; consistent with other platforms' pattern.
static std::string DetectDefaultId() {
  std::string prog = DetectDefaultProgramPath();
  std::string name = StripExtension(Basename(prog));
  if (name.empty())
    name = "app";
  return "com.nativeapi.launch_at_login." + name;
}

static std::string DetectDefaultDisplayName() {
  std::string prog = DetectDefaultProgramPath();
  std::string name = StripExtension(Basename(prog));
  if (name.empty())
    name = "Application";
  return name;
}

// Determine if a Windows command argument needs quoting.
static bool NeedsQuoting(const std::string& s) {
  if (s.empty())
    return true;
  for (char c : s) {
    if (std::isspace(static_cast<unsigned char>(c)) || c == '"' || c == '\t') {
      return true;
    }
  }
  return false;
}

// Quote a single argument for Windows command-line per CRT parsing rules.
// Reference: https://learn.microsoft.com/en-us/cpp/cpp/parsing-c-command-line-arguments
static std::string QuoteArgWindows(const std::string& arg) {
  if (!NeedsQuoting(arg)) {
    return arg;
  }

  std::string result;
  result.push_back('"');

  size_t i = 0;
  while (i < arg.size()) {
    // Count number of backslashes before next character
    size_t backslash_count = 0;
    while (i < arg.size() && arg[i] == '\\') {
      ++backslash_count;
      ++i;
    }

    if (i == arg.size()) {
      // Escape all backslashes at the end
      result.append(backslash_count * 2, '\\');
      break;
    }

    if (arg[i] == '"') {
      // Escape all backslashes (double them), then escape the quote
      result.append(backslash_count * 2 + 1, '\\');
      result.push_back('"');
    } else {
      // Just copy the backslashes
      result.append(backslash_count, '\\');
      result.push_back(arg[i]);
    }
    ++i;
  }

  result.push_back('"');
  return result;
}

// Build full command line: "C:\Path To\app.exe" "arg1" "arg 2"
static std::string BuildCommandLine(const std::string& program,
                                    const std::vector<std::string>& args) {
  std::ostringstream oss;
  oss << QuoteArgWindows(program);
  for (const auto& a : args) {
    oss << ' ' << QuoteArgWindows(a);
  }
  return oss.str();
}

// Open (or create) HKCU\Software\Microsoft\Windows\CurrentVersion\Run key for write.
static bool OpenRunKeyWrite(HKEY& hkey) {
  const char* kRunKey = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";
  DWORD disposition = 0;
  LONG res = RegCreateKeyExA(HKEY_CURRENT_USER, kRunKey, 0, NULL, REG_OPTION_NON_VOLATILE,
                             KEY_SET_VALUE | KEY_WRITE, NULL, &hkey, &disposition);
  return res == ERROR_SUCCESS;
}

// Open HKCU\Software\Microsoft\Windows\CurrentVersion\Run for read.
static bool OpenRunKeyRead(HKEY& hkey) {
  const char* kRunKey = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";
  LONG res = RegOpenKeyExA(HKEY_CURRENT_USER, kRunKey, 0, KEY_READ, &hkey);
  return res == ERROR_SUCCESS;
}

}  // namespace

class LaunchAtLogin::Impl {
 public:
  static bool IsSupported() { return true; }

  Impl()
      : id_(DetectDefaultId()),
        display_name_(DetectDefaultDisplayName()),
        program_path_(DetectDefaultProgramPath()) {}

  explicit Impl(const std::string& id)
      : id_(id),
        display_name_(DetectDefaultDisplayName()),
        program_path_(DetectDefaultProgramPath()) {}

  Impl(const std::string& id, const std::string& display_name)
      : id_(id), display_name_(display_name), program_path_(DetectDefaultProgramPath()) {}

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
    if (program_path_.empty()) {
      program_path_ = DetectDefaultProgramPath();
      if (program_path_.empty()) {
        return false;
      }
    }

    const std::string cmd = BuildCommandLine(program_path_, arguments_);

    HKEY hkey = nullptr;
    if (!OpenRunKeyWrite(hkey)) {
      return false;
    }

    LONG res =
        RegSetValueExA(hkey, id_.c_str(), 0, REG_SZ, reinterpret_cast<const BYTE*>(cmd.c_str()),
                       static_cast<DWORD>(cmd.size() + 1));
    RegCloseKey(hkey);
    return res == ERROR_SUCCESS;
  }

  bool Disable() {
    HKEY hkey = nullptr;
    // Use KEY_SET_VALUE to delete the value
    const char* kRunKey = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";
    LONG open_res = RegOpenKeyExA(HKEY_CURRENT_USER, kRunKey, 0, KEY_SET_VALUE, &hkey);
    if (open_res != ERROR_SUCCESS) {
      // Consider it disabled if the key doesn't exist
      return open_res == ERROR_FILE_NOT_FOUND;
    }

    LONG del_res = RegDeleteValueA(hkey, id_.c_str());
    RegCloseKey(hkey);
    return (del_res == ERROR_SUCCESS) || (del_res == ERROR_FILE_NOT_FOUND);
  }

  bool IsEnabled() const {
    HKEY hkey = nullptr;
    if (!OpenRunKeyRead(hkey)) {
      return false;
    }
    // Check if a value with name id_ exists
    LONG res = RegQueryValueExA(hkey, id_.c_str(), NULL, NULL, NULL, NULL);
    RegCloseKey(hkey);
    return res == ERROR_SUCCESS;
  }

 private:
  std::string id_;
  std::string display_name_;
  std::string program_path_;
  std::vector<std::string> arguments_;
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