#import <Foundation/Foundation.h>
#include "../../preferences.h"

namespace nativeapi {

class Preferences::Impl {
 public:
  explicit Impl(const std::string& scope) : scope_(scope) {
    // Create suite name for NSUserDefaults
    NSString* suite_name =
        [NSString stringWithFormat:@"com.nativeapi.preferences.%s", scope.c_str()];
    user_defaults_ = [[NSUserDefaults alloc] initWithSuiteName:suite_name];

    if (!user_defaults_) {
      // Fallback to standard user defaults
      user_defaults_ = [NSUserDefaults standardUserDefaults];
    }
  }

  ~Impl() { user_defaults_ = nil; }

  bool Set(const std::string& key, const std::string& value) {
    @autoreleasepool {
      NSString* ns_key = [NSString stringWithUTF8String:key.c_str()];
      NSString* ns_value = [NSString stringWithUTF8String:value.c_str()];

      [user_defaults_ setObject:ns_value forKey:ns_key];
      return [user_defaults_ synchronize];
    }
  }

  std::string Get(const std::string& key, const std::string& default_value) const {
    @autoreleasepool {
      NSString* ns_key = [NSString stringWithUTF8String:key.c_str()];
      NSString* ns_value = [user_defaults_ stringForKey:ns_key];

      if (ns_value) {
        return std::string([ns_value UTF8String]);
      }

      return default_value;
    }
  }

  bool Remove(const std::string& key) {
    @autoreleasepool {
      NSString* ns_key = [NSString stringWithUTF8String:key.c_str()];

      if ([user_defaults_ objectForKey:ns_key]) {
        [user_defaults_ removeObjectForKey:ns_key];
        return [user_defaults_ synchronize];
      }

      return false;
    }
  }

  bool Clear() {
    @autoreleasepool {
      NSDictionary* dict = [user_defaults_ dictionaryRepresentation];

      for (NSString* key in dict) {
        [user_defaults_ removeObjectForKey:key];
      }

      return [user_defaults_ synchronize];
    }
  }

  bool Contains(const std::string& key) const {
    @autoreleasepool {
      NSString* ns_key = [NSString stringWithUTF8String:key.c_str()];
      return [user_defaults_ objectForKey:ns_key] != nil;
    }
  }

  std::vector<std::string> GetKeys() const {
    @autoreleasepool {
      std::vector<std::string> keys;
      NSDictionary* dict = [user_defaults_ dictionaryRepresentation];

      for (NSString* key in dict) {
        keys.push_back(std::string([key UTF8String]));
      }

      return keys;
    }
  }

  size_t GetSize() const {
    @autoreleasepool {
      NSDictionary* dict = [user_defaults_ dictionaryRepresentation];
      return [dict count];
    }
  }

  std::map<std::string, std::string> GetAll() const {
    @autoreleasepool {
      std::map<std::string, std::string> result;
      NSDictionary* dict = [user_defaults_ dictionaryRepresentation];

      for (NSString* key in dict) {
        id value = [dict objectForKey:key];

        // Only include string values
        if ([value isKindOfClass:[NSString class]]) {
          NSString* string_value = (NSString*)value;
          result[std::string([key UTF8String])] = std::string([string_value UTF8String]);
        }
      }

      return result;
    }
  }

  const std::string& GetScope() const { return scope_; }

 private:
  std::string scope_;
  NSUserDefaults* user_defaults_;
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
