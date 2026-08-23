#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

#include "../../url_opener.h"

namespace nativeapi {
namespace {

class MacosUrlOpenerImpl final : public UrlOpener::Impl {
 public:
  bool IsSupported() const override { return true; }

  UrlOpenResult Open(const std::string& url) const override {
    @autoreleasepool {
      NSString* ns_url = [NSString stringWithUTF8String:url.c_str()];
      if (!ns_url) {
        UrlOpenResult result;
        result.success = false;
        result.error_code = UrlOpenErrorCode::kInvocationFailed;
        result.error_message = "Failed to build NSURL from UTF-8 input.";
        return result;
      }

      NSURL* target = [NSURL URLWithString:ns_url];
      if (!target) {
        UrlOpenResult result;
        result.success = false;
        result.error_code = UrlOpenErrorCode::kInvocationFailed;
        result.error_message = "Failed to parse URL.";
        return result;
      }

      const BOOL opened = [[NSWorkspace sharedWorkspace] openURL:target];
      if (!opened) {
        UrlOpenResult result;
        result.success = false;
        result.error_code = UrlOpenErrorCode::kInvocationFailed;
        result.error_message = "NSWorkspace could not open the URL.";
        return result;
      }

      UrlOpenResult result;
      result.success = true;
      result.error_code = UrlOpenErrorCode::kNone;
      return result;
    }
  }
};

}  // namespace

UrlOpener::UrlOpener() : pimpl_(std::make_unique<MacosUrlOpenerImpl>()) {}

UrlOpener::~UrlOpener() = default;

}  // namespace nativeapi
