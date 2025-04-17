#ifndef NATIVE_API_DISPLAY_H_
#define NATIVE_API_DISPLAY_H_

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

struct NativeDisplayList {
  struct NativeDisplay* displays;
  long count;
};

#endif  // NATIVE_API_DISPLAY_H_