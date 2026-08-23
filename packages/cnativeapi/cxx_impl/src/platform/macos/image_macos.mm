#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#include <iomanip>
#include <memory>
#include <sstream>
#include <string>
#include "../../foundation/geometry.h"
#include "../../image.h"

namespace nativeapi {

// macOS-specific implementation of Image class
class Image::Impl {
 public:
  NSImage* ns_image_;
  std::string source_;
  Size size_;
  std::string format_;

  Impl() : ns_image_(nil), size_({0, 0}), format_("Unknown") {}

  ~Impl() {}

  Impl(const Impl& other)
      : ns_image_(nil), source_(other.source_), size_(other.size_), format_(other.format_) {
    if (other.ns_image_) {
      ns_image_ = [other.ns_image_ copy];
    }
  }

  Impl& operator=(const Impl& other) {
    if (this != &other) {
      ns_image_ = nil;
      source_ = other.source_;
      size_ = other.size_;
      format_ = other.format_;
      if (other.ns_image_) {
        ns_image_ = [other.ns_image_ copy];
      }
    }
    return *this;
  }
};

Image::Image() : pimpl_(std::make_unique<Impl>()) {}

Image::~Image() = default;

Image::Image(const Image& other) : pimpl_(std::make_unique<Impl>(*other.pimpl_)) {}

Image::Image(Image&& other) noexcept : pimpl_(std::move(other.pimpl_)) {}

std::shared_ptr<Image> Image::FromFile(const std::string& file_path) {
  auto image = std::shared_ptr<Image>(new Image());

  NSString* nsFilePath = [NSString stringWithUTF8String:file_path.c_str()];
  NSImage* nsImage = [[NSImage alloc] initWithContentsOfFile:nsFilePath];

  if (nsImage) {
    image->pimpl_->ns_image_ = nsImage;
    image->pimpl_->source_ = file_path;

    // Get actual image size
    NSSize nsSize = [nsImage size];
    image->pimpl_->size_ = {static_cast<double>(nsSize.width), static_cast<double>(nsSize.height)};

    // Determine format from file extension
    NSString* extension = [[nsFilePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"png"]) {
      image->pimpl_->format_ = "PNG";
    } else if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
      image->pimpl_->format_ = "JPEG";
    } else if ([extension isEqualToString:@"gif"]) {
      image->pimpl_->format_ = "GIF";
    } else if ([extension isEqualToString:@"tiff"] || [extension isEqualToString:@"tif"]) {
      image->pimpl_->format_ = "TIFF";
    } else if ([extension isEqualToString:@"bmp"]) {
      image->pimpl_->format_ = "BMP";
    } else if ([extension isEqualToString:@"ico"]) {
      image->pimpl_->format_ = "ICO";
    } else if ([extension isEqualToString:@"pdf"]) {
      image->pimpl_->format_ = "PDF";
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

  // Remove data URI prefix if present
  std::string cleanBase64 = base64_data;
  size_t commaPos = base64_data.find(',');
  if (commaPos != std::string::npos) {
    cleanBase64 = base64_data.substr(commaPos + 1);
  }

  // Decode base64
  NSString* base64String = [NSString stringWithUTF8String:cleanBase64.c_str()];
  NSData* imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];

  if (imageData) {
    NSImage* nsImage = [[NSImage alloc] initWithData:imageData];
    if (nsImage) {
      image->pimpl_->ns_image_ = nsImage;
      image->pimpl_->source_ = base64_data;

      // Get actual image size
      NSSize nsSize = [nsImage size];
      image->pimpl_->size_ = {static_cast<double>(nsSize.width),
                              static_cast<double>(nsSize.height)};

      // Default assumption for base64 images
      image->pimpl_->format_ = "PNG";
    } else {
      return nullptr;
    }
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
  if (!pimpl_->ns_image_) {
    return "";
  }

  // Convert NSImage to PNG data
  NSBitmapImageRep* bitmapRep =
      [[NSBitmapImageRep alloc] initWithData:[pimpl_->ns_image_ TIFFRepresentation]];
  if (!bitmapRep) {
    return "";
  }

  NSData* pngData = [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];

  if (!pngData) {
    return "";
  }

  // Convert to base64
  NSString* base64String = [pngData base64EncodedStringWithOptions:0];
  std::string result = "data:image/png;base64," + std::string([base64String UTF8String]);

  return result;
}

bool Image::SaveToFile(const std::string& file_path) const {
  if (!pimpl_->ns_image_) {
    return false;
  }

  NSString* nsFilePath = [NSString stringWithUTF8String:file_path.c_str()];
  NSString* extension = [[nsFilePath pathExtension] lowercaseString];

  NSBitmapImageFileType fileType;
  NSDictionary* properties = @{};

  if ([extension isEqualToString:@"png"]) {
    fileType = NSBitmapImageFileTypePNG;
  } else if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
    fileType = NSBitmapImageFileTypeJPEG;
    properties = @{NSImageCompressionFactor : @0.9};
  } else if ([extension isEqualToString:@"gif"]) {
    fileType = NSBitmapImageFileTypeGIF;
  } else if ([extension isEqualToString:@"tiff"] || [extension isEqualToString:@"tif"]) {
    fileType = NSBitmapImageFileTypeTIFF;
  } else if ([extension isEqualToString:@"bmp"]) {
    fileType = NSBitmapImageFileTypeBMP;
  } else {
    // Default to PNG
    fileType = NSBitmapImageFileTypePNG;
  }

  NSBitmapImageRep* bitmapRep =
      [[NSBitmapImageRep alloc] initWithData:[pimpl_->ns_image_ TIFFRepresentation]];
  if (!bitmapRep) {
    return false;
  }

  NSData* imageData = [bitmapRep representationUsingType:fileType properties:properties];

  if (!imageData) {
    return false;
  }

  BOOL success = [imageData writeToFile:nsFilePath atomically:YES];
  return success == YES;
}

void* Image::GetNativeObjectInternal() const {
  return (__bridge void*)pimpl_->ns_image_;
}

}  // namespace nativeapi
