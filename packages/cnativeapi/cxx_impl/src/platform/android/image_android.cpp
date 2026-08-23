#include <android/log.h>
#include "../../image.h"

#define LOG_TAG "NativeApi"
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

namespace nativeapi {

class Image::Impl {
 public:
  Impl() {}
};

Image::Image() : pimpl_(std::make_unique<Impl>()) {}
Image::~Image() {}
Image::Image(const Image& other) : pimpl_(std::make_unique<Impl>()) {}
Image::Image(Image&& other) noexcept : pimpl_(std::move(other.pimpl_)) {}

std::shared_ptr<Image> Image::FromFile(const std::string& file_path) {
  ALOGW("Image::FromFile not implemented on Android");
  return nullptr;
}

std::shared_ptr<Image> Image::FromBase64(const std::string& base64_data) {
  ALOGW("Image::FromBase64 not implemented on Android");
  return nullptr;
}

Size Image::GetSize() const {
  return Size{0, 0};
}

std::string Image::GetFormat() const {
  return "";
}

std::string Image::ToBase64() const {
  ALOGW("Image::ToBase64 not implemented on Android");
  return "";
}

bool Image::SaveToFile(const std::string& file_path) const {
  ALOGW("Image::SaveToFile not implemented on Android");
  return false;
}

void* Image::GetNativeObjectInternal() const {
  return nullptr;
}

}  // namespace nativeapi
