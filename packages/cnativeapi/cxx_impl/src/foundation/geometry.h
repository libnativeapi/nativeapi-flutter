#pragma once

namespace nativeapi {

/**
 * Point is a 2D point in the coordinate system.
 */
struct Point {
  double x;
  double y;
};

/**
 * Size is a 2D size in the coordinate system.
 */
struct Size {
  double width;
  double height;
};

/**
 * Rectangle is a 2D rectangle in the coordinate system.
 */
struct Rectangle {
  double x;
  double y;
  double width;
  double height;
};

}  // namespace nativeapi