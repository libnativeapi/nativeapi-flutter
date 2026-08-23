#include <iomanip>
#include <iostream>
#include <sstream>
#include "nativeapi.h"

using nativeapi::Display;
using nativeapi::DisplayManager;
using nativeapi::DisplayOrientation;
using nativeapi::Point;
using nativeapi::Rectangle;
using nativeapi::Size;

// Helper function to convert orientation enum to string
std::string orientationToString(DisplayOrientation orientation) {
  switch (orientation) {
    case DisplayOrientation::kPortrait:
      return "Portrait (0°)";
    case DisplayOrientation::kLandscape:
      return "Landscape (90°)";
    case DisplayOrientation::kPortraitFlipped:
      return "Portrait Flipped (180°)";
    case DisplayOrientation::kLandscapeFlipped:
      return "Landscape Flipped (270°)";
    default:
      return "Unknown";
  }
}

int main() {
  try {
    std::cout << "=== Native API C++ Display Example ===" << std::endl << std::endl;

    DisplayManager& displayManager = DisplayManager::GetInstance();

    // Test getting all displays
    std::vector<std::shared_ptr<Display>> displays = displayManager.GetAll();

    if (!displays.empty()) {
      std::cout << "Found " << displays.size() << " display(s):" << std::endl << std::endl;

      for (size_t i = 0; i < displays.size(); i++) {
        const Display& display = *displays[i];

        std::cout << "Display " << (i + 1) << ":" << std::endl;

        // Name
        std::cout << "  Name: " << display.GetName() << std::endl;

        // ID
        std::cout << "  ID: " << display.GetId() << std::endl;

        // Position
        Point position = display.GetPosition();
        std::cout << "  Position: (" << (int)position.x << ", " << (int)position.y << ")"
                  << std::endl;

        // Size
        Size size = display.GetSize();
        std::cout << "  Size: " << (int)size.width << " x " << (int)size.height << std::endl;

        // Work Area
        Rectangle workArea = display.GetWorkArea();
        std::cout << "  Work Area: (" << (int)workArea.x << ", " << (int)workArea.y << ") "
                  << (int)workArea.width << " x " << (int)workArea.height << std::endl;

        // Scale Factor
        std::cout << "  Scale Factor: " << std::fixed << std::setprecision(2)
                  << display.GetScaleFactor() << std::endl;

        // Primary
        std::cout << "  Primary: " << (display.IsPrimary() ? "Yes" : "No") << std::endl;

        // Orientation
        std::cout << "  Orientation: " << orientationToString(display.GetOrientation())
                  << std::endl;

        // Refresh Rate
        std::cout << "  Refresh Rate: " << display.GetRefreshRate() << " Hz" << std::endl;

        // Bit Depth
        std::cout << "  Bit Depth: " << display.GetBitDepth() << " bits" << std::endl;

        std::cout << std::endl;
      }
    } else {
      std::cout << "No displays found or error occurred" << std::endl;
    }

    // Test getting primary display
    std::cout << "=== Primary Display ===" << std::endl;
    std::shared_ptr<Display> primary = displayManager.GetPrimary();
    if (primary) {
      std::cout << "Primary display: " << primary->GetName() << std::endl;

      Size size = primary->GetSize();
      std::cout << "Size: " << (int)size.width << " x " << (int)size.height << std::endl;
    } else {
      std::cout << "No primary display available" << std::endl;
    }

    // Test getting cursor position
    std::cout << std::endl << "=== Cursor Position ===" << std::endl;
    Point cursorPos = displayManager.GetCursorPosition();
    std::cout << "Cursor position: (" << (int)cursorPos.x << ", " << (int)cursorPos.y << ")"
              << std::endl;

  } catch (const std::exception& e) {
    std::cerr << "Error: " << e.what() << std::endl;
    return 1;
  } catch (...) {
    std::cerr << "Unknown error occurred" << std::endl;
    return 1;
  }

  return 0;
}
