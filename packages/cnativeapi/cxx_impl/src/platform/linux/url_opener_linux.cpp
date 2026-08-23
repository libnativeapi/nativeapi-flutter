#include <gio/gio.h>

#include <string>

#include "../../url_opener.h"

namespace nativeapi {
namespace {

class LinuxUrlOpenerImpl final : public UrlOpener::Impl {
 public:
  bool IsSupported() const override { return true; }

  UrlOpenResult Open(const std::string& url) const override {
    GError* error = nullptr;
    const gboolean ok = g_app_info_launch_default_for_uri(url.c_str(), nullptr, &error);
    if (!ok) {
      std::string message = "Failed to launch URL via desktop defaults.";
      if (error && error->message) {
        message = error->message;
      }
      if (error) {
        g_error_free(error);
      }
      UrlOpenResult result;
      result.success = false;
      result.error_code = UrlOpenErrorCode::kInvocationFailed;
      result.error_message = message;
      return result;
    }

    UrlOpenResult result;
    result.success = true;
    result.error_code = UrlOpenErrorCode::kNone;
    return result;
  }
};

}  // namespace

UrlOpener::UrlOpener() : pimpl_(std::make_unique<LinuxUrlOpenerImpl>()) {}

UrlOpener::~UrlOpener() = default;

}  // namespace nativeapi
