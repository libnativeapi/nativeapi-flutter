// Desktop integration regression for shadow-only layout changes on Wayland/X11.
// Uses GTK allocations and public nativeapi calls; sends no synthetic input.
#include <window.h>
#include <window_shadow.h>
#include <window_shape.h>
#include <gtk/gtk.h>
#include <iostream>
#include <memory>

static void Settle() {
  for (int i = 0; i < 20; ++i) {
    while (gtk_events_pending()) gtk_main_iteration();
    g_usleep(10000);
  }
}
int main(int argc, char** argv) {
  gtk_init(&argc, &argv);
  auto* widget = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(widget), "Shadow layout regression");
  auto* content = gtk_drawing_area_new();
  gtk_container_add(GTK_CONTAINER(widget), content);
  // Match Flutter's cold-start ordering: a realized CSD window whose header
  // is hidden and whose core gutter is configured before the first map.
  gtk_window_set_titlebar(GTK_WINDOW(widget), gtk_header_bar_new());
  gtk_window_set_default_size(GTK_WINDOW(widget), 320, 320);
  gtk_widget_realize(widget);
  nativeapi::Window window(widget);
  window.SetTitleBarStyle(nativeapi::TitleBarStyle::Hidden);
  window.SetBackgroundColor({0, 0, 0, 0});
  window.SetHasShadow(true);
  window.SetContentSize({320, 320});
  gtk_widget_show(content);
  gtk_widget_show(widget);
  Settle();
  GtkAllocation baseline{};
  gtk_widget_get_allocation(content, &baseline);
  int width = 0, height = 0;
  gtk_window_get_size(GTK_WINDOW(widget), &width, &height);
  int failures = 0;
  auto check = [&](bool ok, const char* name) {
    std::cout << (ok ? "PASS " : "FAIL ") << name << std::endl;
    if (!ok) ++failures;
  };
  check(baseline.width == 320 && baseline.height == 320, "initial content size excludes shadow gutter");
  auto unchanged = [&]() {
    GtkAllocation current{};
    gtk_widget_get_allocation(content, &current);
    int w = 0, h = 0;
    gtk_window_get_size(GTK_WINDOW(widget), &w, &h);
    return current.x == baseline.x && current.y == baseline.y &&
           current.width == baseline.width && current.height == baseline.height &&
           w == width && h == height;
  };
  bool stable = true;
  for (int i = 0; i < 40; ++i) {
    auto shadow = std::make_shared<nativeapi::WindowShadow>();
    shadow->SetBlurRadius(i % 2 ? 64 : 3);
    shadow->SetOffset({i % 2 ? -64.0 : 64.0, i % 3 ? 64.0 : -64.0});
    shadow->SetColor({100, 30, 200, static_cast<uint8_t>(50 + i * 4)});
    if (!window.SetCustomShadow(shadow)) stable = false;
    // Check both before GTK processes allocations and after its next frame.
    stable &= unchanged();
    while (gtk_events_pending()) gtk_main_iteration();
    stable &= unchanged();
  }
  Settle();
  check(stable && unchanged(), "blur/offset/color changes preserve surface and content geometry");
  window.SetHasShadow(false); Settle();
  check(unchanged(), "disable preserves content position");
  window.SetHasShadow(true); Settle();
  check(unchanged(), "enable preserves content position");
  window.SetCustomShadow(nullptr); Settle();
  check(unchanged(), "reset preserves content position");
  auto* overlay = gtk_bin_get_child(GTK_BIN(widget));
  check(GTK_IS_OVERLAY(overlay), "shadow has a layer above native content windows");
  if (GTK_IS_OVERLAY(overlay)) {
    GList* children = gtk_container_get_children(GTK_CONTAINER(overlay));
    auto* paint = GTK_WIDGET(g_list_last(children)->data);
    check(paint != content && gtk_overlay_get_overlay_pass_through(GTK_OVERLAY(overlay), paint),
          "shadow overlay does not intercept content input");
    auto triangle = std::make_shared<nativeapi::WindowShape>();
    triangle->AddPoint({160, 60});
    triangle->AddPoint({260, 260});
    triangle->AddPoint({60, 260});
    check(window.SetInputShape(triangle), "irregular contour accepted");
    Settle();
    auto alpha = [&](int x, int y) {
      auto* surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 320, 320);
      auto* cr = cairo_create(surface);
      gtk_widget_draw(paint, cr);
      cairo_surface_flush(surface);
      auto* row = reinterpret_cast<uint32_t*>(cairo_image_surface_get_data(surface) +
                                             y * cairo_image_surface_get_stride(surface));
      const auto result = row[x] >> 24;
      cairo_destroy(cr);
      cairo_surface_destroy(surface);
      return result;
    };
    check(alpha(160, 58) > 0, "contour shadow paints inside transparent content rectangle");
    check(alpha(160, 160) == 0, "shadow does not darken polygon interior");
    window.SetHasShadow(false); Settle();
    check(alpha(160, 58) == 0, "disabled overlay paints no shadow");
    g_list_free(children);
    window.SetInputShape(nullptr);
    window.SetTitleBarStyle(nativeapi::TitleBarStyle::Normal);
    Settle();
    check(gtk_bin_get_child(GTK_BIN(widget)) == content,
          "restoring decorations unwraps original content safely");
  }
  gtk_widget_destroy(widget);
  return failures ? 1 : 0;
}
