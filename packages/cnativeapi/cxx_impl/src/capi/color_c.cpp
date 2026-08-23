// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "color_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../foundation/color.h"

const native_color_t NATIVE_COLOR_TRANSPARENT = to_c_color(nativeapi::Color::Transparent);

const native_color_t NATIVE_COLOR_BLACK = to_c_color(nativeapi::Color::Black);

const native_color_t NATIVE_COLOR_WHITE = to_c_color(nativeapi::Color::White);

const native_color_t NATIVE_COLOR_RED = to_c_color(nativeapi::Color::Red);

const native_color_t NATIVE_COLOR_GREEN = to_c_color(nativeapi::Color::Green);

const native_color_t NATIVE_COLOR_BLUE = to_c_color(nativeapi::Color::Blue);

const native_color_t NATIVE_COLOR_YELLOW = to_c_color(nativeapi::Color::Yellow);

const native_color_t NATIVE_COLOR_CYAN = to_c_color(nativeapi::Color::Cyan);

const native_color_t NATIVE_COLOR_MAGENTA = to_c_color(nativeapi::Color::Magenta);

native_color_t native_color_from_rgba(unsigned char red, unsigned char green, unsigned char blue, unsigned char alpha) {
  try {
    const auto cpp_result = nativeapi::Color::FromRGBA(red, green, blue, alpha);
    return to_c_color(cpp_result);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_color_from_rgba");
    native_color_t result = {};
    return result;
  }
}

native_color_t native_color_from_hex(const char* hex) {
  try {
    const auto cpp_result = nativeapi::Color::FromHex(hex);
    return to_c_color(cpp_result);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_color_from_hex");
    native_color_t result = {};
    return result;
  }
}

unsigned int native_color_to_rgba(native_color_t color) {
  try {
    const auto self = to_cpp_color(color);
    return self.ToRGBA();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_color_to_rgba");
    return 0;
  }
}

unsigned int native_color_to_argb(native_color_t color) {
  try {
    const auto self = to_cpp_color(color);
    return self.ToARGB();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_color_to_argb");
    return 0;
  }
}

