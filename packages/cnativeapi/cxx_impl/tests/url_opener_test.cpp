#include <cstdlib>
#include <iostream>

#include "../src/url_opener.h"

namespace {

int RunTests() {
  using namespace nativeapi;

  UrlOpener& opener = UrlOpener::GetInstance();

  // --- CanOpen validation tests ---

  {
    if (opener.CanOpen("")) {
      std::cerr << "Expected CanOpen to return false for empty URL." << std::endl;
      return 1;
    }
  }

  {
    if (opener.CanOpen("example.com")) {
      std::cerr << "Expected CanOpen to return false for missing scheme." << std::endl;
      return 1;
    }
  }

  {
    if (opener.CanOpen("mailto:test@example.com")) {
      std::cerr << "Expected CanOpen to return false for unsupported scheme." << std::endl;
      return 1;
    }
  }

  {
    if (!opener.CanOpen("https://example.com")) {
      std::cerr << "Expected CanOpen to return true for a valid https URL." << std::endl;
      return 1;
    }
  }

  {
    if (!opener.CanOpen("http://example.com")) {
      std::cerr << "Expected CanOpen to return true for a valid http URL." << std::endl;
      return 1;
    }
  }

  // --- Open validation error tests ---

  {
    UrlOpenResult result = opener.Open("");
    if (result.success || result.error_code != UrlOpenErrorCode::kInvalidUrlEmpty) {
      std::cerr << "Expected Open('') to fail with kInvalidUrlEmpty." << std::endl;
      return 1;
    }
  }

  {
    UrlOpenResult result = opener.Open("example.com");
    if (result.success || result.error_code != UrlOpenErrorCode::kInvalidUrlMissingScheme) {
      std::cerr << "Expected Open('example.com') to fail with kInvalidUrlMissingScheme."
                << std::endl;
      return 1;
    }
  }

  {
    UrlOpenResult result = opener.Open("mailto:test@example.com");
    if (result.success || result.error_code != UrlOpenErrorCode::kInvalidUrlUnsupportedScheme) {
      std::cerr << "Expected Open('mailto:...') to fail with kInvalidUrlUnsupportedScheme."
                << std::endl;
      return 1;
    }
  }

  return 0;
}

}  // namespace

int main() {
  return RunTests();
}
