#include <comdef.h>
#include <gdiplus.h>
#include <windows.h>
#include <memory>
#include <string>
#include <vector>
#include "../../foundation/geometry.h"
#include "../../image.h"

#pragma comment(lib, "gdiplus.lib")

namespace nativeapi {

// Forward declaration for Windows-specific helper function
HICON ImageToHICON(const Image* image, int width, int height);

// Helper function to convert std::string to std::wstring
static std::wstring StringToWString(const std::string& str) {
  if (str.empty())
    return std::wstring();
  int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
  std::wstring wstrTo(size_needed, 0);
  MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
  return wstrTo;
}

// Helper function to get image encoder CLSID
static int GetEncoderClsid(const WCHAR* format, CLSID* pClsid) {
  UINT num = 0;   // number of image encoders
  UINT size = 0;  // size of the image encoder array in bytes

  Gdiplus::GetImageEncodersSize(&num, &size);
  if (size == 0)
    return -1;

  Gdiplus::ImageCodecInfo* pImageCodecInfo = (Gdiplus::ImageCodecInfo*)(malloc(size));
  if (pImageCodecInfo == NULL)
    return -1;

  Gdiplus::GetImageEncoders(num, size, pImageCodecInfo);

  for (UINT j = 0; j < num; ++j) {
    if (wcscmp(pImageCodecInfo[j].MimeType, format) == 0) {
      *pClsid = pImageCodecInfo[j].Clsid;
      free(pImageCodecInfo);
      return j;
    }
  }

  free(pImageCodecInfo);
  return -1;
}

// Windows-specific implementation of Image class using GDI+
class Image::Impl {
 public:
  Gdiplus::Bitmap* bitmap_;
  std::string source_;
  Size size_;
  std::string format_;

  Impl() : bitmap_(nullptr), size_({0, 0}), format_("Unknown") {}

  ~Impl() {
    if (bitmap_) {
      delete bitmap_;
    }
  }

  Impl(const Impl& other)
      : bitmap_(nullptr), source_(other.source_), size_(other.size_), format_(other.format_) {
    if (other.bitmap_) {
      bitmap_ = other.bitmap_->Clone(0, 0, other.bitmap_->GetWidth(), other.bitmap_->GetHeight(),
                                     other.bitmap_->GetPixelFormat());
    }
  }

  Impl& operator=(const Impl& other) {
    if (this != &other) {
      if (bitmap_) {
        delete bitmap_;
      }
      bitmap_ = nullptr;
      source_ = other.source_;
      size_ = other.size_;
      format_ = other.format_;
      if (other.bitmap_) {
        bitmap_ = other.bitmap_->Clone(0, 0, other.bitmap_->GetWidth(), other.bitmap_->GetHeight(),
                                       other.bitmap_->GetPixelFormat());
      }
    }
    return *this;
  }
};

// Static GDI+ initialization
static bool g_gdiplus_initialized = false;
static ULONG_PTR g_gdiplus_token = 0;

static void EnsureGdiplusInitialized() {
  if (!g_gdiplus_initialized) {
    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    Gdiplus::GdiplusStartup(&g_gdiplus_token, &gdiplusStartupInput, NULL);
    g_gdiplus_initialized = true;
  }
}

Image::Image() : pimpl_(std::make_unique<Impl>()) {
  EnsureGdiplusInitialized();
}

Image::~Image() = default;

Image::Image(const Image& other) : pimpl_(std::make_unique<Impl>(*other.pimpl_)) {}

Image::Image(Image&& other) noexcept : pimpl_(std::move(other.pimpl_)) {}

std::shared_ptr<Image> Image::FromFile(const std::string& file_path) {
  EnsureGdiplusInitialized();
  auto image = std::shared_ptr<Image>(new Image());

  std::wstring wFilePath = StringToWString(file_path);
  Gdiplus::Bitmap* bitmap = Gdiplus::Bitmap::FromFile(wFilePath.c_str());

  if (bitmap && bitmap->GetLastStatus() == Gdiplus::Ok) {
    image->pimpl_->bitmap_ = bitmap;
    image->pimpl_->source_ = file_path;

    // Get actual image size
    UINT width = bitmap->GetWidth();
    UINT height = bitmap->GetHeight();
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
      } else {
        image->pimpl_->format_ = "Unknown";
      }
    }
  } else {
    if (bitmap) {
      delete bitmap;
    }
    return nullptr;
  }

  return image;
}

// Helper function to decode base64
static std::vector<unsigned char> DecodeBase64(const std::string& base64_data) {
  std::vector<unsigned char> result;

  // Calculate the expected output size
  DWORD dwOutLen = 0;
  if (!CryptStringToBinaryA(base64_data.c_str(), 0, CRYPT_STRING_BASE64, NULL, &dwOutLen, NULL,
                            NULL)) {
    return result;
  }

  result.resize(dwOutLen);
  if (!CryptStringToBinaryA(base64_data.c_str(), 0, CRYPT_STRING_BASE64, result.data(), &dwOutLen,
                            NULL, NULL)) {
    result.clear();
  }

  return result;
}

std::shared_ptr<Image> Image::FromBase64(const std::string& base64_data) {
  EnsureGdiplusInitialized();
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
    // Create IStream from memory
    HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, imageData.size());
    if (hMem) {
      void* pMem = GlobalLock(hMem);
      if (pMem) {
        memcpy(pMem, imageData.data(), imageData.size());
        GlobalUnlock(hMem);

        IStream* pStream = nullptr;
        if (CreateStreamOnHGlobal(hMem, TRUE, &pStream) == S_OK) {
          Gdiplus::Bitmap* bitmap = Gdiplus::Bitmap::FromStream(pStream);
          pStream->Release();

          if (bitmap && bitmap->GetLastStatus() == Gdiplus::Ok) {
            image->pimpl_->bitmap_ = bitmap;
            image->pimpl_->source_ = base64_data;

            // Get actual image size
            UINT width = bitmap->GetWidth();
            UINT height = bitmap->GetHeight();
            image->pimpl_->size_ = {static_cast<double>(width), static_cast<double>(height)};

            // Default assumption for base64 images
            image->pimpl_->format_ = "PNG";
          } else {
            if (bitmap) {
              delete bitmap;
            }
            return nullptr;
          }
        } else {
          GlobalFree(hMem);
          return nullptr;
        }
      } else {
        GlobalFree(hMem);
        return nullptr;
      }
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

// Helper function to encode to base64
static std::string EncodeBase64(const unsigned char* data, size_t length) {
  DWORD dwOutLen = 0;
  DWORD dwLength = static_cast<DWORD>(length);
  if (!CryptBinaryToStringA((BYTE*)data, dwLength, CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF, NULL,
                            &dwOutLen)) {
    return "";
  }

  std::string result(dwOutLen, '\0');
  if (!CryptBinaryToStringA((BYTE*)data, dwLength, CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF,
                            &result[0], &dwOutLen)) {
    return "";
  }

  // Remove trailing null characters
  result.resize(dwOutLen - 1);
  return result;
}

std::string Image::ToBase64() const {
  if (!pimpl_->bitmap_) {
    return "";
  }

  // Create IStream to save to memory
  IStream* pStream = nullptr;
  if (CreateStreamOnHGlobal(NULL, TRUE, &pStream) != S_OK) {
    return "";
  }

  // Get PNG encoder
  CLSID pngClsid;
  if (GetEncoderClsid(L"image/png", &pngClsid) < 0) {
    pStream->Release();
    return "";
  }

  // Save to stream
  Gdiplus::Status status = pimpl_->bitmap_->Save(pStream, &pngClsid, NULL);
  if (status != Gdiplus::Ok) {
    pStream->Release();
    return "";
  }

  // Get stream size
  STATSTG statstg;
  if (pStream->Stat(&statstg, STATFLAG_DEFAULT) != S_OK) {
    pStream->Release();
    return "";
  }

  // Read stream data
  LARGE_INTEGER li = {0};
  pStream->Seek(li, STREAM_SEEK_SET, NULL);

  std::vector<unsigned char> buffer(statstg.cbSize.LowPart);
  ULONG bytesRead = 0;
  pStream->Read(buffer.data(), statstg.cbSize.LowPart, &bytesRead);
  pStream->Release();

  if (bytesRead == 0) {
    return "";
  }

  // Convert to base64
  std::string base64String = EncodeBase64(buffer.data(), bytesRead);
  return "data:image/png;base64," + base64String;
}

bool Image::SaveToFile(const std::string& file_path) const {
  if (!pimpl_->bitmap_) {
    return false;
  }

  // Determine file type from extension
  size_t dotPos = file_path.find_last_of('.');
  std::wstring mimeType = L"image/png";  // default

  if (dotPos != std::string::npos) {
    std::string extension = file_path.substr(dotPos + 1);
    // Convert to lowercase
    for (auto& c : extension) {
      c = std::tolower(c);
    }

    if (extension == "jpg" || extension == "jpeg") {
      mimeType = L"image/jpeg";
    } else if (extension == "png") {
      mimeType = L"image/png";
    } else if (extension == "bmp") {
      mimeType = L"image/bmp";
    } else if (extension == "gif") {
      mimeType = L"image/gif";
    } else if (extension == "tiff" || extension == "tif") {
      mimeType = L"image/tiff";
    }
  }

  // Get encoder CLSID
  CLSID encoderClsid;
  if (GetEncoderClsid(mimeType.c_str(), &encoderClsid) < 0) {
    return false;
  }

  // Convert file path to wide string
  std::wstring wFilePath = StringToWString(file_path);

  // Set quality for JPEG
  Gdiplus::EncoderParameters encoderParams;
  ULONG quality = 90;

  if (mimeType == L"image/jpeg") {
    encoderParams.Count = 1;
    encoderParams.Parameter[0].Guid = Gdiplus::EncoderQuality;
    encoderParams.Parameter[0].Type = Gdiplus::EncoderParameterValueTypeLong;
    encoderParams.Parameter[0].NumberOfValues = 1;
    encoderParams.Parameter[0].Value = &quality;

    Gdiplus::Status status =
        pimpl_->bitmap_->Save(wFilePath.c_str(), &encoderClsid, &encoderParams);
    return status == Gdiplus::Ok;
  } else {
    Gdiplus::Status status = pimpl_->bitmap_->Save(wFilePath.c_str(), &encoderClsid, NULL);
    return status == Gdiplus::Ok;
  }
}

void* Image::GetNativeObjectInternal() const {
  return pimpl_->bitmap_;
}

// Windows-specific helper function to convert Image to HICON
// Uses only the public GetNativeObject() API to avoid private access
HICON ImageToHICON(const Image* image, int width, int height) {
  if (!image) {
    return nullptr;
  }

  // Retrieve native bitmap via public API
  void* native = image->GetNativeObject();
  Gdiplus::Bitmap* bitmap = static_cast<Gdiplus::Bitmap*>(native);
  if (!bitmap) {
    return nullptr;
  }

  // Scale bitmap if necessary
  Gdiplus::Bitmap* scaledBitmap = bitmap;
  bool needsScaling = (bitmap->GetWidth() != static_cast<UINT>(width) ||
                       bitmap->GetHeight() != static_cast<UINT>(height));

  if (needsScaling) {
    scaledBitmap = new Gdiplus::Bitmap(width, height, bitmap->GetPixelFormat());
    Gdiplus::Graphics graphics(scaledBitmap);
    graphics.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
    graphics.DrawImage(bitmap, 0, 0, width, height);
  }

  // Convert to HICON
  HICON hIcon = nullptr;
  scaledBitmap->GetHICON(&hIcon);

  // Clean up scaled bitmap if we created one
  if (needsScaling && scaledBitmap) {
    delete scaledBitmap;
  }

  return hIcon;
}

}  // namespace nativeapi
