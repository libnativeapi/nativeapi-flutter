#pragma once

#include <memory>
#include <string>

namespace nativeapi {

enum class UrlOpenErrorCode {
  kNone = 0,
  kInvalidUrlEmpty,
  kInvalidUrlMissingScheme,
  kInvalidUrlUnsupportedScheme,
  kUnsupportedPlatform,
  kInvocationFailed,
};

struct UrlOpenResult {
  bool success = false;
  UrlOpenErrorCode error_code = UrlOpenErrorCode::kNone;
  std::string error_message;
};

class UrlOpener {
 public:
  static UrlOpener& GetInstance();

  bool IsSupported() const;
  bool CanOpen(const std::string& url) const;
  UrlOpenResult Open(const std::string& url) const;

  UrlOpener(const UrlOpener&) = delete;
  UrlOpener& operator=(const UrlOpener&) = delete;
  UrlOpener(UrlOpener&&) = delete;
  UrlOpener& operator=(UrlOpener&&) = delete;

  class Impl {
   public:
    virtual ~Impl() = default;

    virtual bool IsSupported() const = 0;
    virtual bool CanOpen(const std::string& url) const;
    virtual UrlOpenResult Open(const std::string& url) const = 0;
  };

 private:
  UrlOpener();
  ~UrlOpener();

  std::unique_ptr<Impl> pimpl_;
};

}  // namespace nativeapi
