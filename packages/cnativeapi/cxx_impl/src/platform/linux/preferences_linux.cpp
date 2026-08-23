#include <pwd.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fstream>
#include <sstream>
#include "../../preferences.h"

namespace nativeapi {

class Preferences::Impl {
 public:
  explicit Impl(const std::string& scope) : scope_(scope) {
    // Use XDG Base Directory Specification
    const char* xdg_config_home = getenv("XDG_CONFIG_HOME");
    std::string config_dir;

    if (xdg_config_home) {
      config_dir = std::string(xdg_config_home);
    } else {
      const char* home = getenv("HOME");
      if (!home) {
        struct passwd* pw = getpwuid(getuid());
        home = pw->pw_dir;
      }
      config_dir = std::string(home) + "/.config";
    }

    config_dir += "/nativeapi";

    // Create directory if it doesn't exist
    mkdir(config_dir.c_str(), 0755);

    config_file_ = config_dir + "/preferences_" + scope + ".conf";

    // Load existing preferences
    LoadFromFile();
  }

  ~Impl() { SaveToFile(); }

  bool Set(const std::string& key, const std::string& value) {
    data_[key] = value;
    return SaveToFile();
  }

  std::string Get(const std::string& key, const std::string& default_value) const {
    auto it = data_.find(key);
    return (it != data_.end()) ? it->second : default_value;
  }

  bool Remove(const std::string& key) {
    auto it = data_.find(key);
    if (it != data_.end()) {
      data_.erase(it);
      return SaveToFile();
    }
    return false;
  }

  bool Clear() {
    data_.clear();
    return SaveToFile();
  }

  bool Contains(const std::string& key) const { return data_.find(key) != data_.end(); }

  std::vector<std::string> GetKeys() const {
    std::vector<std::string> keys;
    keys.reserve(data_.size());

    for (const auto& pair : data_) {
      keys.push_back(pair.first);
    }

    return keys;
  }

  size_t GetSize() const { return data_.size(); }

  std::map<std::string, std::string> GetAll() const { return data_; }

  const std::string& GetScope() const { return scope_; }

 private:
  bool LoadFromFile() {
    std::ifstream file(config_file_);
    if (!file.is_open()) {
      return false;
    }

    std::string line;
    while (std::getline(file, line)) {
      // Skip empty lines and comments
      if (line.empty() || line[0] == '#') {
        continue;
      }

      // Parse key=value
      size_t pos = line.find('=');
      if (pos != std::string::npos) {
        std::string key = line.substr(0, pos);
        std::string value = line.substr(pos + 1);

        // Unescape newlines
        size_t escape_pos = 0;
        while ((escape_pos = value.find("\\n", escape_pos)) != std::string::npos) {
          value.replace(escape_pos, 2, "\n");
          escape_pos += 1;
        }

        data_[key] = value;
      }
    }

    file.close();
    return true;
  }

  bool SaveToFile() const {
    std::ofstream file(config_file_);
    if (!file.is_open()) {
      return false;
    }

    file << "# NativeAPI Preferences - " << scope_ << std::endl;

    for (const auto& pair : data_) {
      std::string value = pair.second;

      // Escape newlines
      size_t pos = 0;
      while ((pos = value.find('\n', pos)) != std::string::npos) {
        value.replace(pos, 1, "\\n");
        pos += 2;
      }

      file << pair.first << "=" << value << std::endl;
    }

    file.close();
    return true;
  }

  std::string scope_;
  std::string config_file_;
  mutable std::map<std::string, std::string> data_;
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
