// Native GTK renderer regression, no Flutter and no synthetic input.
// Compile with core/src/window_shape.cpp and core/src/window_shadow.cpp, -Icore/src and pkg-config gtk+-3.0.
// Run under a real GTK backend (Wayland, X11 or Quartz); captures go to /tmp.
#include "platform/linux/window_shadow_linux.h"
#include "window_shape.h"
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <gtk/gtk.h>
#include <memory>
// This renderer-only test does not exercise Window input-region
// synchronization.
namespace nativeapi {
static void RefreshShadowInput(GtkWidget *) {}
} // namespace nativeapi
static void drain() {
  for (int i = 0; i < 40; i++) {
    while (gtk_events_pending())
      gtk_main_iteration();
    g_usleep(10000);
  }
}
static int capture(GtkWidget *window, const char *name) {
  int w = gtk_widget_get_allocated_width(window),
      h = gtk_widget_get_allocated_height(window);
  auto *image = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, h);
  auto *cr = cairo_create(image);
  gtk_widget_draw(window, cr);
  cairo_destroy(cr);
  cairo_surface_flush(image);
  auto *pixels =
      reinterpret_cast<uint32_t *>(cairo_image_surface_get_data(image));
  int soft = 0;
  for (int i = 0; i < w * h; i++)
    if ((pixels[i] >> 24) > 2 && (pixels[i] >> 24) < 150)
      soft++;
  cairo_surface_write_to_png(image, name);
  cairo_surface_destroy(image);
  printf("%s %dx%d soft=%d\n", name, w, h, soft);
  return soft;
}
int main(int argc, char **argv) {
  gtk_init(&argc, &argv);
  auto *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
  gtk_widget_set_app_paintable(window, TRUE);
  gtk_widget_set_visual(
      window, gdk_screen_get_rgba_visual(gtk_widget_get_screen(window)));
  auto *provider = gtk_css_provider_new();
  gtk_css_provider_load_from_data(provider,
                                  "window {background:transparent;} window "
                                  "decoration {box-shadow:none;border:none;}",
                                  -1, nullptr);
  gtk_style_context_add_provider_for_screen(gtk_widget_get_screen(window),
                                            GTK_STYLE_PROVIDER(provider), 800);
  auto *child = gtk_drawing_area_new();
  gtk_container_add(GTK_CONTAINER(window), child);
  gtk_window_set_default_size(GTK_WINDOW(window), 320, 320);
  gtk_widget_show_all(window);
  drain();
  auto *shadow = nativeapi::linux_shadow::Ensure(window);
  drain();
  if (gtk_widget_get_allocated_width(child) != 320 ||
      gtk_widget_get_allocated_height(child) != 320)
    return 2;
  auto polygon = std::make_shared<nativeapi::WindowShape>();
  polygon->AddPoint({160, 4});
  polygon->AddPoint({310, 310});
  polygon->AddPoint({10, 310});
  nativeapi::linux_shadow::SetPolygon(window, polygon);
  drain();
  int soft = capture(window, "/tmp/shadow-native-linux.png");
  auto custom = std::make_shared<nativeapi::WindowShadow>();
  custom->SetColor(nativeapi::Color{200, 20, 40, 110});
  custom->SetBlurRadius(30);
  custom->SetOffset({-12, 9});
  nativeapi::linux_shadow::Configure(window, custom);
  drain();
  if (gtk_widget_get_allocated_width(child) != 320 ||
      gtk_widget_get_allocated_height(child) != 320)
    return 4;
  if (capture(window, "/tmp/shadow-native-linux-custom.png") < 1000)
    return 5;
  nativeapi::linux_shadow::Configure(window, nullptr);
  drain();
  if (gtk_widget_get_allocated_width(child) != 320)
    return 6;
  shadow->enabled = false;
  gtk_widget_queue_draw(window);
  drain();
  int disabled = capture(window, "/tmp/shadow-native-linux-off.png");
  gtk_widget_destroy(window);
  drain();
  if (soft < 1000 || disabled != 0)
    return 3;
  puts("PASS native GTK contour shadow and toggle; content remains 320x320");
}
