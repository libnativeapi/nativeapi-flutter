#pragma once

namespace nativeapi {

/**
 * @struct Color
 * @brief Represents an RGBA color.
 *
 * This structure defines a color using red, green, blue, and alpha (transparency)
 * components. Each component is represented as an unsigned byte (0-255).
 *
 * @note Alpha value: 0 = fully transparent, 255 = fully opaque
 */
struct Color {
  unsigned char r;  ///< Red component (0-255)
  unsigned char g;  ///< Green component (0-255)
  unsigned char b;  ///< Blue component (0-255)
  unsigned char a;  ///< Alpha component (0-255)

  /**
   * @brief Creates a Color from RGBA values.
   *
   * @param red Red component (0-255)
   * @param green Green component (0-255)
   * @param blue Blue component (0-255)
   * @param alpha Alpha component (0-255), defaults to 255 (fully opaque)
   * @return Color instance with specified values
   *
   * @example
   * // Create an opaque red color
   * auto red = Color::FromRGBA(255, 0, 0);
   *
   * // Create a semi-transparent blue color
   * auto blue = Color::FromRGBA(0, 0, 255, 128);
   */
  static Color FromRGBA(unsigned char red, unsigned char green,
                        unsigned char blue, unsigned char alpha = 255) {
    return Color{red, green, blue, alpha};
  }

  /**
   * @brief Creates a Color from a hexadecimal string.
   *
   * Supports multiple hex color formats:
   * - "#RGB" - 3-digit hex (e.g., "#F00" = red)
   * - "#RGBA" - 4-digit hex with alpha
   * - "#RRGGBB" - 6-digit hex (e.g., "#FF0000" = red)
   * - "#RRGGBBAA" - 8-digit hex with alpha
   *
   * @param hex Hexadecimal color string (with or without '#' prefix)
   * @return Color instance parsed from the hex string
   *
   * @example
   * // Create a red color
   * auto red = Color::FromHex("#FF0000");
   *
   * // Create a semi-transparent blue color
   * auto blue = Color::FromHex("#0000FF80");
   *
   * // Short format
   * auto green = Color::FromHex("#0F0");
   */
  static Color FromHex(const char* hex);

  /**
   * @brief Converts the color to a 32-bit integer (RGBA format).
   *
   * @return 32-bit unsigned integer in RGBA format (0xRRGGBBAA)
   */
  unsigned int ToRGBA() const {
    return (static_cast<unsigned int>(r) << 24) |
           (static_cast<unsigned int>(g) << 16) |
           (static_cast<unsigned int>(b) << 8) |
           static_cast<unsigned int>(a);
  }

  /**
   * @brief Converts the color to a 32-bit integer (ARGB format).
   *
   * @return 32-bit unsigned integer in ARGB format (0xAARRGGBB)
   */
  unsigned int ToARGB() const {
    return (static_cast<unsigned int>(a) << 24) |
           (static_cast<unsigned int>(r) << 16) |
           (static_cast<unsigned int>(g) << 8) |
           static_cast<unsigned int>(b);
  }

  // Common color constants
  static const Color Transparent;
  static const Color Black;
  static const Color White;
  static const Color Red;
  static const Color Green;
  static const Color Blue;
  static const Color Yellow;
  static const Color Cyan;
  static const Color Magenta;
};

}  // namespace nativeapi