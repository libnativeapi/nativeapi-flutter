#include "dialog.h"

namespace nativeapi {

Dialog::~Dialog() = default;

bool Dialog::Open() {
  return false;  // Base class implementation - should be overridden
}

bool Dialog::Close() {
  return false;  // Base class implementation - should be overridden
}

}  // namespace nativeapi
