
// Representation of a display
struct NativeDisplay {
  char* id;
  char* name;
  double width;
  double height;
  double visiblePositionX;
  double visiblePositionY;
  double visibleSizeWidth;
  double visibleSizeHeight;
  double scaleFactor;
};

// Representation of a list of displays
struct NativeDisplayList {
  struct NativeDisplay* displays;
  int count;
};

struct NativePoint {
  double x;
  double y;
};
