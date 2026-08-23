#include <limits.h>
#include <pwd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <algorithm>
#include <cerrno>
#include <cstring>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include "../../launch_at_login.h"

namespace nativeapi {

namespace {

// Get HOME directory path
static std::string GetHomeDir() {
  const char* home = std::getenv("HOME");
  if (home && *home) {
    return std::string(home);
  }
  struct passwd* pw = getpwuid(getuid());
  if (pw && pw->pw_dir) {
    return std::string(pw->pw_dir);
  }
  return std::string();
}

// Return XDG config directory: $XDG_CONFIG_HOME or $HOME/.config
static std::string GetXdgConfigHome() {
  const char* xdg = std::getenv("XDG_CONFIG_HOME");
  if (xdg && *xdg) {
    return std::string(xdg);
  }
  std::string home = GetHomeDir();
  if (!home.empty()) {
    return home + "/.config";
  }
  return std::string();
}

// Ensure that a directory exists; create intermediate parents as needed (0755)
static bool EnsureDirExists(const std::string& path) {
  if (path.empty())
    return false;

  // Walk through path components creating directories if needed
  std::string current;
  current.reserve(path.size());
  for (size_t i = 0; i < path.size(); ++i) {
    char c = path[i];
    current.push_back(c);
    if (c == '/' && !current.empty()) {
      if (current.size() > 1) {  // skip root "/"
        if (mkdir(current.c_str(), 0755) != 0 && errno != EEXIST) {
          // Ignore errors if directory already exists
          struct stat st{};
          if (stat(current.c_str(), &st) != 0 || !S_ISDIR(st.st_mode)) {
            return false;
          }
        }
      }
    }
  }
  // Final component (if not ending with '/')
  struct stat st{};
  if (stat(path.c_str(), &st) == 0) {
    if (S_ISDIR(st.st_mode))
      return true;
  }
  if (mkdir(path.c_str(), 0755) != 0 && errno != EEXIST) {
    // If not EEXIST, it's a failure
    if (stat(path.c_str(), &st) != 0 || !S_ISDIR(st.st_mode)) {
      return false;
    }
  }
  return true;
}

// Get autostart dir: <XDG_CONFIG_HOME>/autostart
static std::string GetAutostartDir() {
  std::string base = GetXdgConfigHome();
  if (base.empty())
    return std::string();
  return base + "/autostart";
}

// Sanitize identifier for file name usage: replace '/' and whitespace with '_'
static std::string SanitizeIdForFileName(const std::string& id) {
  std::string s = id;
  std::replace(s.begin(), s.end(), '/', '_');
  for (char& ch : s) {
    if (std::isspace(static_cast<unsigned char>(ch)))
      ch = '_';
  }
  return s;
}

// Compute desktop file path: <autostart>/<sanitized-id>.desktop
static std::string GetDesktopFilePath(const std::string& id) {
  std::string dir = GetAutostartDir();
  if (dir.empty())
    return std::string();
  return dir + "/" + SanitizeIdForFileName(id) + ".desktop";
}

// Readlink for /proc/self/exe to get absolute program path
static std::string DetectDefaultProgramPath() {
  char buf[PATH_MAX] = {0};
  ssize_t len = readlink("/proc/self/exe", buf, sizeof(buf) - 1);
  if (len > 0) {
    buf[len] = '\0';
    return std::string(buf);
  }
  return std::string();
}

// Extract program name (basename) from a path
static std::string Basename(const std::string& path) {
  if (path.empty())
    return std::string();
  size_t pos = path.find_last_of('/');
  if (pos == std::string::npos)
    return path;
  if (pos + 1 >= path.size())
    return path;  // trailing slash
  return path.substr(pos + 1);
}

// Detect a default identifier: "com.nativeapi.launch_at_login.<program-name>"
static std::string DetectDefaultId() {
  std::string prog = DetectDefaultProgramPath();
  std::string name = Basename(prog);
  if (name.empty())
    name = "app";
  return "com.nativeapi.launch_at_login." + name;
}

// Detect default display name: program name
static std::string DetectDefaultDisplayName() {
  std::string prog = DetectDefaultProgramPath();
  std::string name = Basename(prog);
  if (name.empty())
    name = "Application";
  return name;
}

// Determine if an argument requires quoting
static bool NeedsQuoting(const std::string& s) {
  for (char c : s) {
    if (std::isspace(static_cast<unsigned char>(c)) || c == '"' || c == '\'' || c == '\\' ||
        c == '$' || c == '`' || c == '(' || c == ')' || c == '|' || c == '&' || c == ';' ||
        c == '<' || c == '>' || c == '*' || c == '?' || c == '[' || c == ']' || c == '{' ||
        c == '}' || c == '~' || c == '!' || c == '#') {
      return true;
    }
  }
  return false;
}

// Quote an argument for Exec= line using double quotes; escape inner " and \ with backslashes.
static std::string QuoteArg(const std::string& s) {
  if (!NeedsQuoting(s))
    return s;
  std::string out;
  out.reserve(s.size() + 2);
  out.push_back('"');
  for (char c : s) {
    if (c == '"' || c == '\\') {
      out.push_back('\\');
    }
    out.push_back(c);
  }
  out.push_back('"');
  return out;
}

// Join program and arguments into an Exec= line per XDG spec (simple quoting)
static std::string BuildExecLine(const std::string& program, const std::vector<std::string>& args) {
  std::ostringstream oss;
  oss << QuoteArg(program);
  for (const auto& a : args) {
    oss << ' ' << QuoteArg(a);
  }
  return oss.str();
}

// Check if a file exists
static bool FileExists(const std::string& path) {
  struct stat st{};
  return stat(path.c_str(), &st) == 0 && S_ISREG(st.st_mode);
}

// Write content to file atomically-ish: write to temp, then rename
static bool WriteFileAtomic(const std::string& path, const std::string& content, mode_t mode) {
  std::string tmp = path + ".tmp";
  {
    std::ofstream ofs(tmp, std::ios::out | std::ios::trunc);
    if (!ofs.is_open())
      return false;
    ofs << content;
    if (!ofs.good()) {
      ofs.close();
      unlink(tmp.c_str());
      return false;
    }
  }
  // Set permissions
  chmod(tmp.c_str(), mode);
  // Rename into place
  if (rename(tmp.c_str(), path.c_str()) != 0) {
    unlink(tmp.c_str());
    return false;
  }
  return true;
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
    const std::string dir = GetAutostartDir();
    if (dir.empty())
      return false;
    if (!EnsureDirExists(dir))
      return false;

    if (program_path_.empty()) {
      program_path_ = DetectDefaultProgramPath();
      if (program_path_.empty())
        return false;
    }

    // Build .desktop content
    std::ostringstream content;
    content << "[Desktop Entry]\n";
    content << "Type=Application\n";
    content << "Name=" << display_name_ << "\n";
    // Optional comment
    content << "Comment=LaunchAtLogin entry for " << display_name_ << "\n";
    content << "Exec=" << BuildExecLine(program_path_, arguments_) << "\n";
    content << "X-GNOME-Autostart-enabled=true\n";
    content << "Hidden=false\n";
    // Try to be friendly with common desktops
    content << "X-KDE-autostart-after=panel\n";

    const std::string path = GetDesktopFilePath(id_);
    if (path.empty())
      return false;

    // Write file with 0644
    if (!WriteFileAtomic(path, content.str(), 0644)) {
      return false;
    }

    return true;
  }

  bool Disable() {
    const std::string path = GetDesktopFilePath(id_);
    if (path.empty())
      return false;
    if (FileExists(path)) {
      if (unlink(path.c_str()) != 0) {
        return false;
      }
    }
    return true;
  }

  bool IsEnabled() const {
    const std::string path = GetDesktopFilePath(id_);
    return FileExists(path);
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