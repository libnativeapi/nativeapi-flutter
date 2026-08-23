#pragma once

#include <memory>
#include <optional>
#include <string>
#include <vector>
#include "foundation/geometry.h"
#include "foundation/native_object_provider.h"

namespace nativeapi {

/**
 * @brief Image class for cross-platform image handling.
 *
 * This class provides a unified interface for working with images across
 * different platforms. It supports multiple initialization methods including
 * file paths, base64-encoded data, and system icons.
 *
 * The Image class is designed to be used with UI components like TrayIcon
 * and MenuItem that require icon images.
 *
 * Features:
 * - Load images from file paths
 * - Load images from base64-encoded strings
 * - Automatic format detection and conversion
 * - Memory-efficient internal representation
 *
 * @note This class uses the PIMPL idiom to hide platform-specific
 * implementation details and ensure binary compatibility.
 *
 * @note All Image instances must be created using static factory methods
 * (FromFile, FromBase64). Empty/null images are represented
 * using std::shared_ptr<Image>{nullptr}.
 *
 * @note Assignment operations are not supported to avoid resource management
 * issues with platform-specific native objects. Use shared_ptr assignment
 * instead: `auto newImage = oldImage;`
 *
 * @example
 * ```cpp
 * // Create image from file path
 * auto image1 = Image::FromFile("/path/to/icon.png");
 *
 * // Create image from base64 string
 * auto image2 = Image::FromBase64("data:image/png;base64,iVBORw0KGgo...");
 *
 * // Use with TrayIcon
 * trayIcon->SetIcon(image1);
 *
 * // Use with MenuItem
 * menuItem->SetIcon(image2);
 *
 * // Empty/null image representation
 * std::shared_ptr<Image> emptyImage = nullptr;
 *
 * // Assignment using shared_ptr (recommended)
 * auto newImage = image1;  // Creates a new shared_ptr pointing to same object
 *
 * // Get image dimensions
 * auto size = image1->GetSize();
 * if (size.width > 0 && size.height > 0) {
 *     std::cout << "Image size: " << size.width << "x" << size.height <<
 * std::endl;
 * }
 *
 * // Get image format for debugging
 * std::string format = image1->GetFormat();
 * std::cout << "Image format: " << format << std::endl;
 * ```
 */
class Image : public NativeObjectProvider {
 public:
  /**
   * @brief Destructor.
   *
   * Cleans up the image and releases any associated platform-specific
   * resources.
   */
  ~Image();

  /**
   * @brief Copy constructor.
   *
   * Creates a copy of the image. The underlying image data may be shared
   * between instances depending on the platform implementation.
   *
   * @param other The image to copy from
   */
  Image(const Image& other);

  /**
   * @brief Move constructor.
   *
   * Transfers ownership of the image data from another instance.
   *
   * @param other The image to move from
   */
  Image(Image&& other) noexcept;

  /**
   * @brief Create an image from a file path.
   *
   * Loads an image from the specified file path on disk. The image format
   * is automatically detected based on the file contents.
   *
   * @param file_path Path to the image file
   * @return A shared pointer to the created Image, or nullptr if loading failed
   *
   * @note Supported formats depend on the platform:
   *       - macOS: PNG, JPEG, GIF, TIFF, BMP, ICO, PDF
   *       - Windows: PNG, JPEG, BMP, GIF, TIFF, ICO
   *       - Linux: PNG, JPEG, BMP, GIF, SVG, XPM (depends on system libraries)
   *
   * @example
   * ```cpp
   * auto image = Image::FromFile("/path/to/icon.png");
   * if (image && image->IsValid()) {
   *     trayIcon->SetIcon(image);
   * }
   * ```
   */
  static std::shared_ptr<Image> FromFile(const std::string& file_path);

  /**
   * @brief Create an image from base64-encoded data.
   *
   * Decodes and loads an image from a base64-encoded string. The string
   * can optionally include a data URI prefix (e.g., "data:image/png;base64,").
   *
   * @param base64_data Base64-encoded image data, with or without data URI
   * prefix
   * @return A shared pointer to the created Image, or nullptr if decoding
   * failed
   *
   * @note The image format is automatically detected from the decoded data.
   *
   * @example
   * ```cpp
   * // With data URI prefix
   * auto image1 = Image::FromBase64("data:image/png;base64,iVBORw0KGgo...");
   *
   * // Without data URI prefix
   * auto image2 = Image::FromBase64("iVBORw0KGgo...");
   * ```
   */
  static std::shared_ptr<Image> FromBase64(const std::string& base64_data);

  /**
   * @brief Get the size of the image in pixels.
   *
   * @return The image size with width and height as double values,
   *         or Size(0,0) if the image is invalid
   */
  Size GetSize() const;

  /**
   * @brief Get the image format string for debugging purposes.
   *
   * @return The image format (e.g., "PNG", "JPEG", "GIF"), or empty string if
   * unknown
   */
  std::string GetFormat() const;

  /**
   * @brief Convert the image to base64-encoded PNG data.
   *
   * Encodes the image as PNG and returns it as a base64 string with
   * the data URI prefix.
   *
   * @return Base64-encoded PNG data with data URI prefix, or empty string on
   * error
   *
   * @example
   * ```cpp
   * auto image = Image::FromFile("/path/to/icon.png");
   * std::string base64 = image->ToBase64();
   * // Result: "data:image/png;base64,iVBORw0KGgo..."
   * ```
   */
  std::string ToBase64() const;

  /**
   * @brief Save the image to a file.
   *
   * Saves the image to the specified file path. The format is determined
   * by the file extension.
   *
   * @param file_path Path where the image should be saved
   * @return true if saved successfully, false otherwise
   *
   * @note Supported output formats depend on the platform but typically
   *       include PNG, JPEG, BMP, and TIFF.
   *
   * @example
   * ```cpp
   * auto image = Image::FromBase64("data:image/png;base64,iVBORw0KGgo...");
   * image->SaveToFile("/path/to/output.png");
   * ```
   */
  bool SaveToFile(const std::string& file_path) const;

 protected:
  /**
   * @brief Internal method to get the platform-specific native image object.
   *
   * This method must be implemented by platform-specific code to return
   * the underlying native image object.
   *
   * @return Pointer to the native image object
   */
  void* GetNativeObjectInternal() const override;

 private:
  /**
   * @brief Private default constructor for use by factory methods.
   *
   * This constructor is private to prevent direct instantiation of Image objects.
   * Use the static factory methods (FromFile, FromBase64, FromSystemIcon) instead.
   */
  Image();

  /**
   * @brief Private implementation class using the PIMPL idiom.
   *
   * This forward declaration hides the platform-specific implementation
   * details from the public interface.
   */
  class Impl;

  /**
   * @brief Pointer to the private implementation instance.
   */
  std::unique_ptr<Impl> pimpl_;
};

}  // namespace nativeapi
