#include "../../url_opener.h"

namespace nativeapi {
namespace {

class OhosUrlOpenerImpl final : public UrlOpener::Impl {
 public:
  bool IsSupported() const override { return false; }

  UrlOpenResult Open(const std::string& url) const override {
    (void)url;
    UrlOpenResult result;
    result.success = false;
    result.error_code = UrlOpenErrorCode::kUnsupportedPlatform;
    result.error_message = "URL opening is not implemented on OHOS in this native layer.";
    return result;
  }
};

}  // namespace

UrlOpener::UrlOpener() : pimpl_(std::make_unique<OhosUrlOpenerImpl>()) {}

UrlOpener::~UrlOpener() = default;

}  // namespace nativeapi
