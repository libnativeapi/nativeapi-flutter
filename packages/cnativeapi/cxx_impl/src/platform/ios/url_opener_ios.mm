#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include <dispatch/dispatch.h>

#include "../../url_opener.h"

namespace nativeapi {
namespace {

UrlOpenResult LaunchUrlOnMainThread(const std::string& url) {
  @autoreleasepool {
    UIApplication* app = [UIApplication sharedApplication];
    if (!app) {
      UrlOpenResult result;
      result.success = false;
      result.error_code = UrlOpenErrorCode::kInvocationFailed;
      result.error_message = "UIApplication is unavailable.";
      return result;
    }

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

    if (![app canOpenURL:target]) {
      UrlOpenResult result;
      result.success = false;
      result.error_code = UrlOpenErrorCode::kInvocationFailed;
      result.error_message = "No handler available for URL.";
      return result;
    }

    if (@available(iOS 10.0, *)) {
      __block BOOL open_result = NO;
      dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
      [app openURL:target
          options:@{}
completionHandler:^(BOOL success) {
  open_result = success;
  dispatch_semaphore_signal(semaphore);
}];

      const long wait_result =
          dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
      if (wait_result != 0) {
        UrlOpenResult result;
        result.success = false;
        result.error_code = UrlOpenErrorCode::kInvocationFailed;
        result.error_message = "Timed out waiting for openURL completion.";
        return result;
      }
      if (!open_result) {
        UrlOpenResult result;
        result.success = false;
        result.error_code = UrlOpenErrorCode::kInvocationFailed;
        result.error_message = "UIApplication failed to open URL.";
        return result;
      }
      UrlOpenResult result;
      result.success = true;
      result.error_code = UrlOpenErrorCode::kNone;
      return result;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    const BOOL opened = [app openURL:target];
#pragma clang diagnostic pop
    if (!opened) {
      UrlOpenResult result;
      result.success = false;
      result.error_code = UrlOpenErrorCode::kInvocationFailed;
      result.error_message = "UIApplication failed to open URL.";
      return result;
    }
    UrlOpenResult result;
    result.success = true;
    result.error_code = UrlOpenErrorCode::kNone;
    return result;
  }
}

UrlOpenResult LaunchUrl(const std::string& url) {
  if ([NSThread isMainThread]) {
    return LaunchUrlOnMainThread(url);
  }

  __block UrlOpenResult outcome;
  dispatch_sync(dispatch_get_main_queue(), ^{
    outcome = LaunchUrlOnMainThread(url);
  });
  return outcome;
}

class IosUrlOpenerImpl final : public UrlOpener::Impl {
 public:
  bool IsSupported() const override { return true; }

  bool CanOpen(const std::string& url) const override {
    @autoreleasepool {
      NSString* ns_url = [NSString stringWithUTF8String:url.c_str()];
      if (!ns_url) return false;

      NSURL* target = [NSURL URLWithString:ns_url];
      if (!target) return false;

      UIApplication* app = [UIApplication sharedApplication];
      if (!app) return false;

      return [app canOpenURL:target];
    }
  }

  UrlOpenResult Open(const std::string& url) const override {
    return LaunchUrl(url);
  }
};

}  // namespace

UrlOpener::UrlOpener() : pimpl_(std::make_unique<IosUrlOpenerImpl>()) {}

UrlOpener::~UrlOpener() = default;

}  // namespace nativeapi
