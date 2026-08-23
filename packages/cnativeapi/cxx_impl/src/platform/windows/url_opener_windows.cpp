#include <windows.h>
#include <shellapi.h>

#include <sstream>

#include "../../url_opener.h"

namespace nativeapi {
namespace {

class WindowsUrlOpenerImpl final : public UrlOpener::Impl {
 public:
  bool IsSupported() const override { return true; }

  UrlOpenResult Open(const std::string& url) const override {
    HINSTANCE launch_result =
        ShellExecuteA(nullptr, "open", url.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
    const auto code = reinterpret_cast<intptr_t>(launch_result);
    if (code <= 32) {
      std::ostringstream oss;
      oss << "ShellExecute failed with code " << code << ".";
      UrlOpenResult result;
      result.success = false;
      result.error_code = UrlOpenErrorCode::kInvocationFailed;
      result.error_message = oss.str();
      return result;
    }

    UrlOpenResult result;
    result.success = true;
    result.error_code = UrlOpenErrorCode::kNone;
    return result;
  }
};

}  // namespace

UrlOpener::UrlOpener() : pimpl_(std::make_unique<WindowsUrlOpenerImpl>()) {}

UrlOpener::~UrlOpener() = default;

}  // namespace nativeapi
