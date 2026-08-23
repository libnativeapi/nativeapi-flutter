#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <memory>
#include <string>
#include "../../image.h"

namespace nativeapi {

class Image::Impl {
 public:
  Impl() : ui_image_(nil), size_({0, 0}), format_("Unknown") {}

  UIImage* ui_image_;
  Size size_;
  std::string format_;
};

Image::Image() : pimpl_(std::make_unique<Impl>()) {}
Image::~Image() {}

Image::Image(const Image& other) : pimpl_(std::make_unique<Impl>()) {
  if (other.pimpl_ && other.pimpl_->ui_image_) {
    pimpl_->ui_image_ = other.pimpl_->ui_image_;
    pimpl_->size_ = other.pimpl_->size_;
    pimpl_->format_ = other.pimpl_->format_;
  }
}

Image::Image(Image&& other) noexcept : pimpl_(std::move(other.pimpl_)) {}

std::shared_ptr<Image> Image::FromFile(const std::string& file_path) {
  auto image = std::shared_ptr<Image>(new Image());
  NSString* nsPath = [NSString stringWithUTF8String:file_path.c_str()];
  UIImage* uiImage = [UIImage imageWithContentsOfFile:nsPath];

  if (uiImage) {
    image->pimpl_->ui_image_ = uiImage;

    // Get actual image size
    CGSize size = uiImage.size;
    image->pimpl_->size_ = {static_cast<double>(size.width), static_cast<double>(size.height)};

    // Determine format from file extension
    NSString* extension = [[nsPath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"png"]) {
      image->pimpl_->format_ = "PNG";
    } else if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
      image->pimpl_->format_ = "JPEG";
    } else if ([extension isEqualToString:@"gif"]) {
      image->pimpl_->format_ = "GIF";
    } else {
      image->pimpl_->format_ = "Unknown";
    }
  } else {
    return nullptr;
  }

  return image;
}

std::shared_ptr<Image> Image::FromBase64(const std::string& base64_data) {
  auto image = std::shared_ptr<Image>(new Image());
  // Parse data URI if present
  std::string data = base64_data;
  size_t pos = data.find(",");
  if (pos != std::string::npos) {
    data = data.substr(pos + 1);
  }

  NSData* nsData =
      [[NSData alloc] initWithBase64EncodedString:[NSString stringWithUTF8String:data.c_str()]
                                          options:0];
  UIImage* uiImage = [UIImage imageWithData:nsData];

  if (uiImage) {
    image->pimpl_->ui_image_ = uiImage;

    // Get actual image size
    CGSize size = uiImage.size;
    image->pimpl_->size_ = {static_cast<double>(size.width), static_cast<double>(size.height)};

    // Default assumption for base64 images
    image->pimpl_->format_ = "PNG";
  } else {
    return nullptr;
  }

  return image;
}

Size Image::GetSize() const {
  return pimpl_->size_;
}

std::string Image::GetFormat() const {
  return pimpl_->format_;
}

std::string Image::ToBase64() const {
  if (!pimpl_->ui_image_) {
    return "";
  }

  NSData* pngData = UIImagePNGRepresentation(pimpl_->ui_image_);
  NSString* base64String = [pngData base64EncodedStringWithOptions:0];
  return std::string("data:image/png;base64,") + [base64String UTF8String];
}

bool Image::SaveToFile(const std::string& file_path) const {
  if (!pimpl_->ui_image_) {
    return false;
  }

  NSData* pngData = UIImagePNGRepresentation(pimpl_->ui_image_);
  NSString* nsPath = [NSString stringWithUTF8String:file_path.c_str()];
  return [pngData writeToFile:nsPath atomically:YES];
}

void* Image::GetNativeObjectInternal() const {
  return (__bridge void*)pimpl_->ui_image_;
}

}  // namespace nativeapi
