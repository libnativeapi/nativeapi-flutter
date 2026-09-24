// Desktop-only integration test: inspect the X server's actual bounding/input
// regions. No synthetic input. Built by build_window_shapes_linux.sh.
#include "window.h"
#include "window_shape.h"
#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/extensions/shape.h>
#include <cmath>
#include <iostream>

void settle() {
  for (int i = 0; i < 80; ++i) {
    while (gtk_events_pending()) gtk_main_iteration();
    g_usleep(10000);
  }
}

int main(int argc, char** argv) {
  gtk_init(&argc, &argv);
  int failures = 0, checks = 0;
  auto check = [&](bool ok, const char* label) {
    ++checks;
    if (!ok) ++failures;
    std::cout << (ok ? "PASS " : "FAIL ") << label << std::endl;
  };
  auto* widget = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(widget), "Native shape integration test");
  gtk_window_set_titlebar(GTK_WINDOW(widget), gtk_header_bar_new());
  nativeapi::Window window(widget);
  auto shape = std::make_shared<nativeapi::WindowShape>();
  shape->AddPoint({0, 0}); shape->AddPoint({320, 0}); shape->AddPoint({160, 320});
  check(nativeapi::Window::IsShapeSupported(), "X11 shape support");
  check(!window.SetShape(shape), "decorated window rejected");
  window.SetTitleBarStyle(nativeapi::TitleBarStyle::Hidden);
  window.SetContentSize({320, 320});
  gtk_widget_show_all(widget);
  settle();
  // show_all may reveal the header bar again: use the public API after mapping.
  window.SetTitleBarStyle(nativeapi::TitleBarStyle::Hidden);
  window.SetContentSize({320, 320});
  settle();
  auto* gdk = gtk_widget_get_window(widget);
  auto* display = GDK_DISPLAY_XDISPLAY(gdk_window_get_display(gdk));
  auto xid = GDK_WINDOW_XID(gdk);
  auto contains = [&](int kind, int x, int y) {
    int count = 0, ordering = 0;
    XRectangle* rects = XShapeGetRectangles(display, xid, kind, &count, &ordering);
    bool result = false;
    for (int i = 0; i < count; ++i)
      if (x >= rects[i].x && x < rects[i].x + rects[i].width &&
          y >= rects[i].y && y < rects[i].y + rects[i].height) result = true;
    XFree(rects);
    return result;
  };
  check(window.SetShape(shape) && window.IsShaped(), "apply triangle");
  settle();
  const auto content = window.GetContentBounds();
  int ox = 0, oy = 0;
  gdk_window_get_origin(gdk, &ox, &oy);
  int dx = content.x - ox, dy = content.y - oy;
  std::cout << "content offset " << dx << ',' << dy << std::endl;
  for (int kind : {ShapeBounding, ShapeInput}) {
    check(contains(kind, dx + 160, dy + 100), "triangle centre included");
    check(!contains(kind, dx + 10, dy + 300), "triangle lower corner excluded");
    check(contains(kind, dx + 10, dy + 5), "triangle top left included");
  }
  shape->Clear();
  check(window.IsShaped() && contains(ShapeBounding, dx + 160, dy + 100), "builder clear preserves applied shape");
  check(!window.SetShape(shape) && window.IsShaped(), "invalid replacement preserves shape");
  nativeapi::Window second(widget);
  check(second.GetTitleBarStyle() == nativeapi::TitleBarStyle::Hidden, "title bar style shared by wrappers");
  shape->AddPoint({0, 0}); shape->AddPoint({320, 0}); shape->AddPoint({160, 320});
  check(second.SetShape(shape), "apply shape through fresh wrapper");
  check(second.IsShaped(), "shape visible through second wrapper");
  check(second.SetShape(nullptr) && !window.IsShaped(), "clear via second wrapper");
  settle();
  check(contains(ShapeBounding, dx + 10, dy + 300) && contains(ShapeInput, dx + 10, dy + 300), "clear restores visual and input corners");
  for (int size : {320, 400}) {
    window.SetContentSize({double(size), double(size)});
    settle();
    for (bool star : {false, true}) {
      shape->Clear();
      int n = star ? 10 : 128;
      for (int i = 0; i < n; ++i) {
        double a = -M_PI/2 + 2*M_PI*i/n;
        double r = (size/2. - 4) * (star && i%2 ? .6 : 1.);
        shape->AddPoint({size/2. + r*cos(a), size/2. + r*sin(a)});
      }
      check(window.SetShape(shape), star ? "apply star" : "apply circle");
      settle();
      for (int kind : {ShapeBounding, ShapeInput}) {
        check(contains(kind, dx + size/2, dy + size/2) && !contains(kind, dx + 5, dy + 5), "centre included and corner excluded");
        check(contains(kind, dx + size/2, dy + int(size*.92)) != star, "circle/star lower contour distinguished");
      }
    }
  }
  shape->Clear();
  for (nativeapi::Point point : {nativeapi::Point{48, 32}, {352, 32}, {384, 64},
       {384, 288}, {352, 320}, {160, 320}, {64, 384}, {84, 320},
       {48, 320}, {16, 288}, {16, 64}}) shape->AddPoint(point);
  check(window.SetShape(shape), "apply bubble");
  settle();
  for (int kind : {ShapeBounding, ShapeInput}) {
    check(contains(kind, dx + 200, dy + 200), "bubble centre included");
    check(!contains(kind, dx + 5, dy + 5), "bubble corner excluded");
    check(contains(kind, dx + 80, dy + 360), "bubble tail included");
    check(!contains(kind, dx + 200, dy + 360), "beside bubble tail excluded");
  }
  check(window.SetShape(nullptr) && !window.IsShaped(), "final clear");
  gtk_widget_destroy(widget);
  std::cout << checks << " checks, " << failures << " failures" << std::endl;
  return failures ? 1 : 0;
}
