#include "url_opener.h"

#include <algorithm>
#include <cctype>

namespace nativeapi {
namespace {

std::string Trim(const std::string& value) {
  size_t start = 0;
  while (start < value.size() && std::isspace(static_cast<unsigned char>(value[start]))) {
    ++start;
  }

  size_t end = value.size();
  while (end > start && std::isspace(static_cast<unsigned char>(value[end - 1]))) {
    --end;
  }

  return value.substr(start, end - start);
}

std::string ToLower(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
    return static_cast<char>(std::tolower(c));
  });
  return value;
}

UrlOpenResult ValidateUrl(const std::string& raw_url) {
  const std::string url = Trim(raw_url);
  if (url.empty()) {
    UrlOpenResult result;
    result.success = false;
    result.error_code = UrlOpenErrorCode::kInvalidUrlEmpty;
    result.error_message = "URL is empty.";
    return result;
  }

  const size_t scheme_separator = url.find(':');
  if (scheme_separator == std::string::npos || scheme_separator == 0) {
    UrlOpenResult result;
    result.success = false;
    result.error_code = UrlOpenErrorCode::kInvalidUrlMissingScheme;
    result.error_message = "URL must include an explicit scheme (http or https).";
    return result;
  }

  const std::string scheme = ToLower(url.substr(0, scheme_separator));
  if (scheme != "http" && scheme != "https") {
    UrlOpenResult result;
    result.success = false;
    result.error_code = UrlOpenErrorCode::kInvalidUrlUnsupportedScheme;
    result.error_message = "Only http and https URLs are supported.";
    return result;
  }

  UrlOpenResult ok;
  ok.success = true;
  ok.error_code = UrlOpenErrorCode::kNone;
  return ok;
}

}  // namespace

// ---------------------------------------------------------------------------
// UrlOpener::Impl
// ---------------------------------------------------------------------------

bool UrlOpener::Impl::CanOpen(const std::string& url) const {
  (void)url;
  return true;
}

// ---------------------------------------------------------------------------
// UrlOpener
// ---------------------------------------------------------------------------

UrlOpener& UrlOpener::GetInstance() {
  static UrlOpener instance;
  return instance;
}

bool UrlOpener::CanOpen(const std::string& url) const {
  if (!ValidateUrl(url).success) {
    return false;
  }
  return pimpl_->CanOpen(url);
}

UrlOpenResult UrlOpener::Open(const std::string& url) const {
  UrlOpenResult result = ValidateUrl(url);
  if (!result.success) {
    return result;
  }
  return pimpl_->Open(url);
}

bool UrlOpener::IsSupported() const {
  return pimpl_->IsSupported();
}

}  // namespace nativeapi
