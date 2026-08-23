#ifdef __OHOS__
#include <hilog/log.h>
#endif
#include <memory>
#include <string>
#include <utility>
#include "../../image.h"

#ifdef __OHOS__
#define LOG_CORE 0xD001700
// Note: LOG_TAG is defined in hilog/log.h as NULL,
// redefine to avoid warnings if needed
#undef LOG_TAG
#define LOG_TAG "NativeApi"
#endif

namespace nativeapi {

class Image::Impl {
 public:
  Impl() = default;

  void* native_image_ = nullptr;
  std::string source_;
  Size size_ = {0, 0};
  std::string format_ = "Unknown";
};

Image::Image() : pimpl_(std::make_unique<Impl>()) {}

Image::~Image() = default;

Image::Image(const Image& other) : pimpl_(std::make_unique<Impl>(*other.pimpl_)) {}

Image::Image(Image&& other) noexcept : pimpl_(std::move(other.pimpl_)) {}

std::shared_ptr<Image> Image::FromFile(const std::string& file_path) {
  // Return nullptr - not implemented on OpenHarmony yet
  return nullptr;
}

std::shared_ptr<Image> Image::FromBase64(const std::string& base64_data) {
  // Return nullptr - not implemented on OpenHarmony yet
  return nullptr;
}

Size Image::GetSize() const {
  return pimpl_->size_;
}

std::string Image::GetFormat() const {
  return pimpl_->format_;
}

std::string Image::ToBase64() const {
  // Return empty string - not implemented on OpenHarmony yet
  return "";
}

bool Image::SaveToFile(const std::string& file_path) const {
  // Return false - not implemented on OpenHarmony yet
  return false;
}

void* Image::GetNativeObjectInternal() const {
  return pimpl_->native_image_;
}

}  // namespace nativeapi
