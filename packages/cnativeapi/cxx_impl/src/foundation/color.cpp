#include "color.h"
#include <cstring>
#include <stdexcept>

namespace nativeapi {

// Parse a single hex digit (0-9, A-F, a-f) to a value 0-15
static unsigned char ParseHexDigit(char c) {
  if (c >= '0' && c <= '9')
    return c - '0';
  if (c >= 'A' && c <= 'F')
    return c - 'A' + 10;
  if (c >= 'a' && c <= 'f')
    return c - 'a' + 10;
  throw std::invalid_argument("Invalid hex digit");
}

// Parse two hex digits to a byte value 0-255
static unsigned char ParseHexByte(const char* hex) {
  return (ParseHexDigit(hex[0]) << 4) | ParseHexDigit(hex[1]);
}

Color Color::FromHex(const char* hex) {
  if (!hex) {
    throw std::invalid_argument("Hex string cannot be null");
  }

  // Skip leading '#' if present
  if (hex[0] == '#') {
    hex++;
  }

  size_t len = std::strlen(hex);

  // Parse based on format
  if (len == 3) {
    // #RGB format - expand each digit to two digits
    unsigned char r = ParseHexDigit(hex[0]);
    unsigned char g = ParseHexDigit(hex[1]);
    unsigned char b = ParseHexDigit(hex[2]);
    // Expand: F -> FF (15 -> 255)
    r = (r << 4) | r;
    g = (g << 4) | g;
    b = (b << 4) | b;
    return Color{r, g, b, 255};
  } else if (len == 4) {
    // #RGBA format - expand each digit to two digits
    unsigned char r = ParseHexDigit(hex[0]);
    unsigned char g = ParseHexDigit(hex[1]);
    unsigned char b = ParseHexDigit(hex[2]);
    unsigned char a = ParseHexDigit(hex[3]);
    r = (r << 4) | r;
    g = (g << 4) | g;
    b = (b << 4) | b;
    a = (a << 4) | a;
    return Color{r, g, b, a};
  } else if (len == 6) {
    // #RRGGBB format
    unsigned char r = ParseHexByte(hex);
    unsigned char g = ParseHexByte(hex + 2);
    unsigned char b = ParseHexByte(hex + 4);
    return Color{r, g, b, 255};
  } else if (len == 8) {
    // #RRGGBBAA format
    unsigned char r = ParseHexByte(hex);
    unsigned char g = ParseHexByte(hex + 2);
    unsigned char b = ParseHexByte(hex + 4);
    unsigned char a = ParseHexByte(hex + 6);
    return Color{r, g, b, a};
  } else {
    throw std::invalid_argument("Invalid hex color format. Expected #RGB, #RGBA, #RRGGBB, or #RRGGBBAA");
  }
}

// Color constants
const Color Color::Transparent = {0, 0, 0, 0};
const Color Color::Black = {0, 0, 0, 255};
const Color Color::White = {255, 255, 255, 255};
const Color Color::Red = {255, 0, 0, 255};
const Color Color::Green = {0, 255, 0, 255};
const Color Color::Blue = {0, 0, 255, 255};
const Color Color::Yellow = {255, 255, 0, 255};
const Color Color::Cyan = {0, 255, 255, 255};
const Color Color::Magenta = {255, 0, 255, 255};

}  // namespace nativeapi