#include "keyboard.h"
#include <sstream>

namespace nativeapi {

std::string KeyboardAccelerator::ToString() const {
  if (key.empty()) {
    return "";
  }

  std::ostringstream oss;

  // Add modifiers in a consistent order
  if ((modifiers & ModifierKey::Ctrl) != ModifierKey::None) {
    oss << "Ctrl+";
  }
  if ((modifiers & ModifierKey::Alt) != ModifierKey::None) {
    oss << "Alt+";
  }
  if ((modifiers & ModifierKey::Shift) != ModifierKey::None) {
    oss << "Shift+";
  }
  if ((modifiers & ModifierKey::Meta) != ModifierKey::None) {
#ifdef __APPLE__
    oss << "Cmd+";
#elif defined(_WIN32)
    oss << "Win+";
#else
    oss << "Super+";
#endif
  }

  // Add the main key
  oss << key;

  return oss.str();
}

}  // namespace nativeapi
