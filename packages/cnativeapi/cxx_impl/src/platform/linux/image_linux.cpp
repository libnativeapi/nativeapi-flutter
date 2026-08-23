#include <gdk-pixbuf/gdk-pixbuf.h>
#include <glib.h>
#include <gtk/gtk.h>
#include <cstring>
#include <memory>
#include <string>
#include <vector>
#include "../../foundation/geometry.h"
#include "../../image.h"

namespace nativeapi {

// Linux-specific implementation of Image class using GdkPixbuf
class Image::Impl {
 public:
  GdkPixbuf* pixbuf_;
  std::string source_;
  Size size_;
  std::string format_;

  Impl() : pixbuf_(nullptr), size_({0, 0}), format_("Unknown") {}

  ~Impl() {
    if (pixbuf_) {
      g_object_unref(pixbuf_);
    }
  }

  Impl(const Impl& other)
      : pixbuf_(nullptr), source_(other.source_), size_(other.size_), format_(other.format_) {
    if (other.pixbuf_) {
      pixbuf_ = gdk_pixbuf_copy(other.pixbuf_);
    }
  }

  Impl& operator=(const Impl& other) {
    if (this != &other) {
      if (pixbuf_) {
        g_object_unref(pixbuf_);
      }
      pixbuf_ = nullptr;
      source_ = other.source_;
      size_ = other.size_;
      format_ = other.format_;
      if (other.pixbuf_) {
        pixbuf_ = gdk_pixbuf_copy(other.pixbuf_);
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

  GError* error = nullptr;
  GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(file_path.c_str(), &error);

  if (pixbuf) {
    image->pimpl_->pixbuf_ = pixbuf;
    image->pimpl_->source_ = file_path;

    // Get actual image size
    int width = gdk_pixbuf_get_width(pixbuf);
    int height = gdk_pixbuf_get_height(pixbuf);
    image->pimpl_->size_ = {static_cast<double>(width), static_cast<double>(height)};

    // Determine format from file extension
    size_t dotPos = file_path.find_last_of('.');
    if (dotPos != std::string::npos) {
      std::string extension = file_path.substr(dotPos + 1);
      // Convert to lowercase
      for (auto& c : extension) {
        c = std::tolower(c);
      }

      if (extension == "png") {
        image->pimpl_->format_ = "PNG";
      } else if (extension == "jpg" || extension == "jpeg") {
        image->pimpl_->format_ = "JPEG";
      } else if (extension == "gif") {
        image->pimpl_->format_ = "GIF";
      } else if (extension == "bmp") {
        image->pimpl_->format_ = "BMP";
      } else if (extension == "tiff" || extension == "tif") {
        image->pimpl_->format_ = "TIFF";
      } else if (extension == "ico") {
        image->pimpl_->format_ = "ICO";
      } else if (extension == "svg") {
        image->pimpl_->format_ = "SVG";
      } else if (extension == "xpm") {
        image->pimpl_->format_ = "XPM";
      } else {
        image->pimpl_->format_ = "Unknown";
      }
    }
  } else {
    if (error) {
      g_error_free(error);
    }
    return nullptr;
  }

  return image;
}

// Helper function to decode base64
static std::vector<unsigned char> DecodeBase64(const std::string& base64_data) {
  std::vector<unsigned char> result;

  gsize out_len = 0;
  guchar* decoded = g_base64_decode(base64_data.c_str(), &out_len);

  if (decoded && out_len > 0) {
    result.assign(decoded, decoded + out_len);
    g_free(decoded);
  }

  return result;
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
  std::vector<unsigned char> imageData = DecodeBase64(cleanBase64);

  if (!imageData.empty()) {
    GError* error = nullptr;
    GInputStream* stream =
        g_memory_input_stream_new_from_data(imageData.data(), imageData.size(), nullptr);

    GdkPixbuf* pixbuf = gdk_pixbuf_new_from_stream(stream, nullptr, &error);
    g_object_unref(stream);

    if (pixbuf) {
      image->pimpl_->pixbuf_ = pixbuf;
      image->pimpl_->source_ = base64_data;

      // Get actual image size
      int width = gdk_pixbuf_get_width(pixbuf);
      int height = gdk_pixbuf_get_height(pixbuf);
      image->pimpl_->size_ = {static_cast<double>(width), static_cast<double>(height)};

      // Default assumption for base64 images
      image->pimpl_->format_ = "PNG";
    } else {
      if (error) {
        g_error_free(error);
      }
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

// Helper function to encode to base64
static std::string EncodeBase64(const unsigned char* data, size_t length) {
  gchar* encoded = g_base64_encode(data, length);
  std::string result(encoded);
  g_free(encoded);
  return result;
}

std::string Image::ToBase64() const {
  if (!pimpl_->pixbuf_) {
    return "";
  }

  gchar* buffer = nullptr;
  gsize buffer_size = 0;
  GError* error = nullptr;

  // Save pixbuf to PNG in memory
  gboolean success =
      gdk_pixbuf_save_to_buffer(pimpl_->pixbuf_, &buffer, &buffer_size, "png", &error, nullptr);

  if (!success || !buffer) {
    if (error) {
      g_error_free(error);
    }
    if (buffer) {
      g_free(buffer);
    }
    return "";
  }

  // Convert to base64
  std::string base64String = EncodeBase64(reinterpret_cast<unsigned char*>(buffer), buffer_size);
  g_free(buffer);

  return "data:image/png;base64," + base64String;
}

bool Image::SaveToFile(const std::string& file_path) const {
  if (!pimpl_->pixbuf_) {
    return false;
  }

  // Determine file type from extension
  size_t dotPos = file_path.find_last_of('.');
  std::string type = "png";  // default

  if (dotPos != std::string::npos) {
    std::string extension = file_path.substr(dotPos + 1);
    // Convert to lowercase
    for (auto& c : extension) {
      c = std::tolower(c);
    }

    if (extension == "jpg" || extension == "jpeg") {
      type = "jpeg";
    } else if (extension == "png") {
      type = "png";
    } else if (extension == "bmp") {
      type = "bmp";
    } else if (extension == "ico") {
      type = "ico";
    } else if (extension == "tiff" || extension == "tif") {
      type = "tiff";
    }
  }

  GError* error = nullptr;
  gboolean success = FALSE;

  if (type == "jpeg") {
    // For JPEG, specify quality
    success = gdk_pixbuf_save(pimpl_->pixbuf_, file_path.c_str(), type.c_str(), &error, "quality",
                              "90", nullptr);
  } else {
    success = gdk_pixbuf_save(pimpl_->pixbuf_, file_path.c_str(), type.c_str(), &error, nullptr);
  }

  if (error) {
    g_error_free(error);
  }

  return success == TRUE;
}

void* Image::GetNativeObjectInternal() const {
  return pimpl_->pixbuf_;
}

}  // namespace nativeapi
