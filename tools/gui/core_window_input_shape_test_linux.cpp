// Desktop integration fixture for X11 and Wayland; no input is injected.
#include "window.h"
#include "window_shape.h"
#include <gtk/gtk.h>
#include <iostream>

static void Settle() {
  for (int i = 0; i < 80; ++i) {
    while (gtk_events_pending()) gtk_main_iteration();
    g_usleep(10000);
  }
}

int main(int argc, char** argv) {
  gtk_init(&argc, &argv);
  int failures = 0;
  auto check = [&](bool ok, const char* text) {
    std::cout << (ok ? "PASS " : "FAIL ") << text << std::endl;
    if (!ok) ++failures;
  };
  GtkWidget* widget = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(widget), "Input region integration test");
  gtk_window_set_titlebar(GTK_WINDOW(widget), gtk_header_bar_new());
  GtkWidget* content = gtk_drawing_area_new();
  gtk_container_add(GTK_CONTAINER(widget), content);
  nativeapi::Window window(widget);
  auto shape = std::make_shared<nativeapi::WindowShape>();
  shape->AddPoint({0, 0}); shape->AddPoint({320, 0}); shape->AddPoint({160, 320});
  check(nativeapi::Window::IsInputShapeSupported(), "input shaping supported");
  check(!window.SetInputShape(shape), "decorated window rejected");
  window.SetContentSize({320, 320});
  gtk_widget_show_all(widget);
  window.SetTitleBarStyle(nativeapi::TitleBarStyle::Hidden);
  Settle();
  check(window.SetInputShape(shape), "triangle applied");
  Settle();
  auto region = [&](const char* label) {
    gint x = 0, y = 0;
    gtk_widget_translate_coordinates(content, widget, 0, 0, &x, &y);
    std::cout << "CHECK_REGION " << label << ' ' << x << ' ' << y << std::endl;
  };
  region("triangle");
  check(window.IsInputShaped() && !window.IsShaped(), "input shape leaves visual region unchanged");
  nativeapi::Window other(widget);
  check(other.IsInputShaped(), "state shared by wrappers");
  shape->Clear();
  check(!other.SetInputShape(shape) && window.IsInputShaped(), "invalid replacement preserves region");
  // Force GTK to recalculate its CSD input region, without changing content geometry.
  gtk_widget_queue_resize(widget);
  Settle();
  region("triangle");
  check(other.SetInputShape(nullptr) && !window.IsInputShaped(), "clear through another wrapper");
  Settle();
  region("rectangle");
  window.SetHasShadow(false);
  window.SetContentSize({400, 400});
  Settle();
  shape->AddPoint({0, 0}); shape->AddPoint({400, 0}); shape->AddPoint({200, 400});
  check(other.SetInputShape(shape), "reapply resized polygon without shadow");
  Settle();
  region("large");
  shape->Clear();
  check(window.IsInputShaped(), "builder clear leaves applied region alive");
  check(other.SetInputShape(nullptr), "final clear");
  gtk_widget_destroy(widget);
  std::cout << failures << " failures" << std::endl;
  return failures ? 1 : 0;
}
