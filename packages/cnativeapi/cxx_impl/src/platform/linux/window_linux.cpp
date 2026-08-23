#include <iostream>
#include <mutex>
#include <unordered_map>
#include "../../foundation/id_allocator.h"
#include "../../window.h"
#include "../../window_manager.h"
#include "../../window_registry.h"

// Import GTK headers
#include <gdk/gdk.h>
#include <gtk/gtk.h>

namespace nativeapi {

// Key to store/retrieve WindowId on GObjects
static const char* kWindowIdKey = "NativeAPIWindowId";

// Helper function to find header bar in widget hierarchy
static GtkWidget* FindHeaderBar(GtkWidget* widget) {
  if (!widget)
    return nullptr;

  // Check if this widget is a header bar
  if (GTK_IS_HEADER_BAR(widget))
    return widget;

  // If it's a container, search children
  if (GTK_IS_CONTAINER(widget)) {
    GList* children = gtk_container_get_children(GTK_CONTAINER(widget));
    for (GList* l = children; l != nullptr; l = l->next) {
      GtkWidget* child = GTK_WIDGET(l->data);
      GtkWidget* result = FindHeaderBar(child);
      if (result) {
        g_list_free(children);
        return result;
      }
    }
    g_list_free(children);
  }

  return nullptr;
}

// Private implementation class
class Window::Impl {
 public:
  Impl(GtkWidget* widget, GdkWindow* gdk_window)
      : widget_(widget),
        gdk_window_(gdk_window),
        title_bar_style_(TitleBarStyle::Normal),
        visual_effect_(VisualEffect::None),
        background_color_(Color::White) {}
  GtkWidget* widget_;
  GdkWindow* gdk_window_;
  TitleBarStyle title_bar_style_;
  VisualEffect visual_effect_;
  Color background_color_;
};

Window::Window() {
  // Check if GTK is available
  GdkDisplay* display = gdk_display_get_default();
  if (!display) {
    std::cerr << "No display available for window creation" << std::endl;
    pimpl_ = std::make_unique<Impl>(nullptr, nullptr);
    return;
  }

  // Create a new GTK toplevel window
  GtkWidget* widget = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  if (!widget) {
    std::cerr << "Failed to create GTK window" << std::endl;
    pimpl_ = std::make_unique<Impl>(nullptr, nullptr);
    return;
  }

  // Realize to ensure GdkWindow exists
  if (!gtk_widget_get_realized(widget)) {
    gtk_widget_realize(widget);
  }

  // Obtain GdkWindow
  GdkWindow* gdk_window = gtk_widget_get_window(widget);
  if (!gdk_window) {
    std::cerr << "Failed to get GdkWindow from GTK widget" << std::endl;
    gtk_widget_destroy(widget);
    pimpl_ = std::make_unique<Impl>(nullptr, nullptr);
    return;
  }

  // Allocate and attach a stable WindowId to the native objects
  WindowId id = IdAllocator::Allocate<Window>();
  if (id != IdAllocator::kInvalidId) {
    g_object_set_data(G_OBJECT(widget), kWindowIdKey,
                      reinterpret_cast<gpointer>(static_cast<uintptr_t>(id)));
    g_object_set_data(G_OBJECT(gdk_window), kWindowIdKey,
                      reinterpret_cast<gpointer>(static_cast<uintptr_t>(id)));
  }

  // Only create the instance, don't show the window
  pimpl_ = std::make_unique<Impl>(widget, gdk_window);
}

Window::Window(void* native_window) {
  // Wrap existing GdkWindow or GtkWidget
  GtkWidget* widget = nullptr;
  GdkWindow* gdk_window = nullptr;

  // Heuristic: if this looks like a GtkWidget*, use it; otherwise treat as GdkWindow*
  // In our codebase, native Linux window handles should be GtkWidget* (GtkWindow)
  widget = static_cast<GtkWidget*>(native_window);
  if (widget && GTK_IS_WIDGET(widget)) {
    if (!gtk_widget_get_realized(widget)) {
      gtk_widget_realize(widget);
    }
    gdk_window = gtk_widget_get_window(widget);
  } else {
    // Fallback: assume GdkWindow*
    gdk_window = static_cast<GdkWindow*>(native_window);
  }

  pimpl_ = std::make_unique<Impl>(widget, gdk_window);
}

Window::~Window() {}

WindowId Window::GetId() const {
  // Prefer reading ID stored on the native objects
  if (pimpl_->gdk_window_) {
    gpointer data = g_object_get_data(G_OBJECT(pimpl_->gdk_window_), kWindowIdKey);
    if (data) {
      return static_cast<WindowId>(reinterpret_cast<uintptr_t>(data));
    }
  }
  if (pimpl_->widget_) {
    gpointer data = g_object_get_data(G_OBJECT(pimpl_->widget_), kWindowIdKey);
    if (data) {
      return static_cast<WindowId>(reinterpret_cast<uintptr_t>(data));
    }
  }
  return IdAllocator::kInvalidId;
}

void Window::Focus() {
  if (pimpl_->widget_) {
    gtk_window_present(GTK_WINDOW(pimpl_->widget_));
  } else if (pimpl_->gdk_window_) {
    gdk_window_focus(pimpl_->gdk_window_, GDK_CURRENT_TIME);
  }
}

void Window::Blur() {
  if (pimpl_->gdk_window_) {
    gdk_window_lower(pimpl_->gdk_window_);
  }
}

bool Window::IsFocused() const {
  if (!pimpl_->gdk_window_)
    return false;
  // Check if this window is the focus window of its display
  GdkDisplay* display = gdk_window_get_display(pimpl_->gdk_window_);
  GdkSeat* seat = gdk_display_get_default_seat(display);
  if (seat) {
    GdkDevice* keyboard = gdk_seat_get_keyboard(seat);
    if (keyboard) {
      GdkWindow* focus_window = gdk_device_get_window_at_position(keyboard, nullptr, nullptr);
      return focus_window == pimpl_->gdk_window_;
    }
  }
  return false;
}

void Window::Show() {
  if (pimpl_->widget_) {
    gtk_widget_show(pimpl_->widget_);
  } else if (pimpl_->gdk_window_) {
    gdk_window_show(pimpl_->gdk_window_);
  }
}

void Window::ShowInactive() {
  if (pimpl_->widget_) {
    gtk_widget_show(pimpl_->widget_);
  } else if (pimpl_->gdk_window_) {
    gdk_window_show_unraised(pimpl_->gdk_window_);
  }
}

void Window::Hide() {
  if (pimpl_->widget_) {
    gtk_widget_hide(pimpl_->widget_);
  } else if (pimpl_->gdk_window_) {
    gdk_window_hide(pimpl_->gdk_window_);
  }
}

bool Window::IsVisible() const {
  if (pimpl_->widget_) {
    return gtk_widget_get_visible(pimpl_->widget_);
  }
  if (pimpl_->gdk_window_) {
    return gdk_window_is_visible(pimpl_->gdk_window_);
  }
  return false;
}

void Window::Maximize() {
  if (pimpl_->gdk_window_) {
    gdk_window_maximize(pimpl_->gdk_window_);
  }
}

void Window::Unmaximize() {
  if (pimpl_->gdk_window_) {
    gdk_window_unmaximize(pimpl_->gdk_window_);
  }
}

bool Window::IsMaximized() const {
  if (!pimpl_->gdk_window_)
    return false;
  GdkWindowState state = gdk_window_get_state(pimpl_->gdk_window_);
  return state & GDK_WINDOW_STATE_MAXIMIZED;
}

void Window::Minimize() {
  if (pimpl_->gdk_window_) {
    gdk_window_iconify(pimpl_->gdk_window_);
  }
}

void Window::Restore() {
  if (pimpl_->gdk_window_) {
    gdk_window_deiconify(pimpl_->gdk_window_);
  }
}

bool Window::IsMinimized() const {
  if (!pimpl_->gdk_window_)
    return false;
  GdkWindowState state = gdk_window_get_state(pimpl_->gdk_window_);
  return state & GDK_WINDOW_STATE_ICONIFIED;
}

void Window::SetFullScreen(bool is_full_screen) {
  if (!pimpl_->gdk_window_)
    return;
  if (is_full_screen) {
    gdk_window_fullscreen(pimpl_->gdk_window_);
  } else {
    gdk_window_unfullscreen(pimpl_->gdk_window_);
  }
}

bool Window::IsFullScreen() const {
  if (!pimpl_->gdk_window_)
    return false;
  GdkWindowState state = gdk_window_get_state(pimpl_->gdk_window_);
  return state & GDK_WINDOW_STATE_FULLSCREEN;
}

void Window::SetBounds(Rectangle bounds) {
  if (pimpl_->gdk_window_) {
    gdk_window_move_resize(pimpl_->gdk_window_, (gint)bounds.x, (gint)bounds.y, (gint)bounds.width,
                           (gint)bounds.height);
  }
}

Rectangle Window::GetBounds() const {
  Rectangle bounds = {0, 0, 0, 0};
  if (pimpl_->gdk_window_) {
    gint x, y, width, height;
    gdk_window_get_geometry(pimpl_->gdk_window_, &x, &y, &width, &height);
    bounds.x = x;
    bounds.y = y;
    bounds.width = width;
    bounds.height = height;
  }
  return bounds;
}

void Window::SetSize(Size size, bool animate) {
  if (pimpl_->gdk_window_) {
    gdk_window_resize(pimpl_->gdk_window_, (gint)size.width, (gint)size.height);
  }
}

Size Window::GetSize() const {
  Size size = {0, 0};
  if (pimpl_->gdk_window_) {
    gint width, height;
    gdk_window_get_geometry(pimpl_->gdk_window_, nullptr, nullptr, &width, &height);
    size.width = width;
    size.height = height;
  }
  return size;
}

void Window::SetContentSize(Size size) {
  // For GDK windows, content size is the same as window size
  SetSize(size, false);
}

Size Window::GetContentSize() const {
  // For GDK windows, content size is the same as window size
  return GetSize();
}

void Window::SetContentBounds(Rectangle bounds) {
  // For GDK windows, content bounds is the same as window bounds
  SetBounds(bounds);
}

Rectangle Window::GetContentBounds() const {
  // For GDK windows, content bounds is the same as window bounds
  return GetBounds();
}

void Window::SetMinimumSize(Size size) {
  // GTK minimum size constraints would need to be set on the widget level
  // For now, we'll provide a basic implementation that doesn't enforce
  // constraints
}

Size Window::GetMinimumSize() const {
  return Size{0, 0};
}

void Window::SetMaximumSize(Size size) {
  // GTK maximum size constraints would need to be set on the widget level
  // For now, we'll provide a basic implementation that doesn't enforce
  // constraints
}

Size Window::GetMaximumSize() const {
  return Size{-1, -1};  // -1 indicates no maximum
}

void Window::SetResizable(bool is_resizable) {
  // This would typically be set at window creation time in GTK
  // For now, provide stub implementation
}

bool Window::IsResizable() const {
  return true;  // Default assumption
}

void Window::SetMovable(bool is_movable) {
  // Window movability is typically a window manager property
  // Provide stub implementation
}

bool Window::IsMovable() const {
  return true;  // Default assumption
}

void Window::SetMinimizable(bool is_minimizable) {
  // This would typically be set via window hints
  // Provide stub implementation
}

bool Window::IsMinimizable() const {
  return true;  // Default assumption
}

void Window::SetMaximizable(bool is_maximizable) {
  // This would typically be set via window hints
  // Provide stub implementation
}

bool Window::IsMaximizable() const {
  return true;  // Default assumption
}

void Window::SetFullScreenable(bool is_full_screenable) {
  // Provide stub implementation
}

bool Window::IsFullScreenable() const {
  return true;  // Default assumption
}

void Window::SetClosable(bool is_closable) {
  // This would typically be set via window hints
  // Provide stub implementation
}

bool Window::IsClosable() const {
  return true;  // Default assumption
}

void Window::SetWindowControlButtonsVisible(bool is_visible) {
  // TODO: Implement for Linux
  // This would involve manipulating GTK window decorations
}

bool Window::IsWindowControlButtonsVisible() const {
  // TODO: Implement for Linux
  return true;  // Default to visible
}

void Window::SetAlwaysOnTop(bool is_always_on_top) {
  if (pimpl_->gdk_window_) {
    gdk_window_set_keep_above(pimpl_->gdk_window_, is_always_on_top);
  }
}

bool Window::IsAlwaysOnTop() const {
  if (!pimpl_->gdk_window_)
    return false;
  GdkWindowState state = gdk_window_get_state(pimpl_->gdk_window_);
  return state & GDK_WINDOW_STATE_ABOVE;
}

void Window::SetPosition(Point point) {
  if (pimpl_->gdk_window_) {
    gdk_window_move(pimpl_->gdk_window_, (gint)point.x, (gint)point.y);
  }
}

Point Window::GetPosition() const {
  Point point = {0, 0};
  if (pimpl_->gdk_window_) {
    gint x, y;
    gdk_window_get_position(pimpl_->gdk_window_, &x, &y);
    point.x = x;
    point.y = y;
  }
  return point;
}

void Window::Center() {
  if (!pimpl_->gdk_window_)
    return;

  // Get the window size
  gint window_width, window_height;
  gdk_window_get_geometry(pimpl_->gdk_window_, nullptr, nullptr, &window_width, &window_height);

  // Get the screen size
  GdkDisplay* display = gdk_window_get_display(pimpl_->gdk_window_);
  GdkMonitor* monitor = gdk_display_get_primary_monitor(display);
  if (!monitor) {
    // Fallback to first monitor if no primary monitor is found
    monitor = gdk_display_get_monitor(display, 0);
  }

  if (monitor) {
    GdkRectangle geometry;
    gdk_monitor_get_geometry(monitor, &geometry);

    // Calculate center position
    gint center_x = geometry.x + (geometry.width - window_width) / 2;
    gint center_y = geometry.y + (geometry.height - window_height) / 2;

    // Move the window to center
    gdk_window_move(pimpl_->gdk_window_, center_x, center_y);
  }
}

void Window::SetTitle(std::string title) {
  // Prefer setting title via GtkWindow if available
  if (pimpl_->widget_ && GTK_IS_WINDOW(pimpl_->widget_)) {
    gtk_window_set_title(GTK_WINDOW(pimpl_->widget_), title.c_str());
    return;
  }

  // If only GdkWindow is available, try to get associated GtkWindow
  if (pimpl_->gdk_window_) {
    gpointer user_data = nullptr;
    gdk_window_get_user_data(pimpl_->gdk_window_, &user_data);
    if (user_data && GTK_IS_WINDOW(user_data)) {
      gtk_window_set_title(GTK_WINDOW(user_data), title.c_str());
      return;
    }

    // Fallback: set title via GDK for toplevel windows
    gdk_window_set_title(pimpl_->gdk_window_, title.c_str());
  }
}

std::string Window::GetTitle() const {
  // Prefer reading title via GtkWindow if available
  if (pimpl_->widget_ && GTK_IS_WINDOW(pimpl_->widget_)) {
    const gchar* t = gtk_window_get_title(GTK_WINDOW(pimpl_->widget_));
    return t ? std::string(t) : std::string();
  }

  // If only GdkWindow is available, try to get associated GtkWindow
  if (pimpl_->gdk_window_) {
    gpointer user_data = nullptr;
    gdk_window_get_user_data(pimpl_->gdk_window_, &user_data);
    if (user_data && GTK_IS_WINDOW(user_data)) {
      const gchar* t = gtk_window_get_title(GTK_WINDOW(user_data));
      return t ? std::string(t) : std::string();
    }
  }

  // No reliable way to get title directly from GdkWindow
  return std::string();
}

void Window::SetTitleBarStyle(TitleBarStyle style) {
  pimpl_->title_bar_style_ = style;

  if (!pimpl_->widget_ || !GTK_IS_WINDOW(pimpl_->widget_))
    return;

  GtkWindow* gtk_window = GTK_WINDOW(pimpl_->widget_);
  bool show_decorations = (style == TitleBarStyle::Normal);

  // Try to find and toggle header bar visibility
  GtkWidget* header_bar = FindHeaderBar(pimpl_->widget_);
  if (header_bar) {
    gtk_widget_set_visible(header_bar, show_decorations);
  } else {
    // If no header bar found, toggle window decorations
    const gchar* title = gtk_window_get_title(gtk_window);
    if (title != nullptr) {
      gtk_window_set_decorated(gtk_window, show_decorations);
    }
  }

  // When restoring to normal, ensure decorations are shown
  if (show_decorations) {
    gtk_window_set_decorated(gtk_window, TRUE);
  }
}

TitleBarStyle Window::GetTitleBarStyle() const {
  return pimpl_->title_bar_style_;
}

void Window::SetHasShadow(bool has_shadow) {
  // Window shadows are typically managed by the window manager
  // Provide stub implementation
}

bool Window::HasShadow() const {
  return true;  // Default assumption
}

void Window::SetOpacity(float opacity) {
  if (pimpl_->gdk_window_) {
    gdk_window_set_opacity(pimpl_->gdk_window_, opacity);
  }
}

float Window::GetOpacity() const {
  // GDK doesn't provide a direct way to get opacity
  return 1.0f;  // Default assumption
}

void Window::SetVisualEffect(VisualEffect effect) {
  pimpl_->visual_effect_ = effect;
  // TODO: Implement background blur for Linux (GTK/GDK)
  // This typically requires compositor support or specific GTK CSS
}

VisualEffect Window::GetVisualEffect() const {
  return pimpl_->visual_effect_;
}

void Window::SetBackgroundColor(const Color& color) {
  if (!pimpl_->widget_)
    return;

  // Store the color
  pimpl_->background_color_ = color;

  // Create CSS provider for background color
  GtkCssProvider* provider = gtk_css_provider_new();
  
  // Format CSS string with RGBA color
  gchar* css = g_strdup_printf(
    "window { background-color: rgba(%d, %d, %d, %.2f); }",
    color.r, color.g, color.b, color.a / 255.0);
  
  gtk_css_provider_load_from_data(provider, css, -1, nullptr);
  g_free(css);
  
  // Apply CSS to the widget
  GtkStyleContext* context = gtk_widget_get_style_context(pimpl_->widget_);
  gtk_style_context_add_provider(context,
                                 GTK_STYLE_PROVIDER(provider),
                                 GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  
  g_object_unref(provider);
}

Color Window::GetBackgroundColor() const {
  if (!pimpl_->widget_)
    return Color::White;
  
  // Return the stored background color
  // Since we set it via CSS, we track it ourselves to avoid using deprecated APIs
  return pimpl_->background_color_;
}

void Window::SetVisibleOnAllWorkspaces(bool is_visible_on_all_workspaces) {
  if (pimpl_->gdk_window_) {
    gdk_window_stick(pimpl_->gdk_window_);
  }
}

bool Window::IsVisibleOnAllWorkspaces() const {
  if (!pimpl_->gdk_window_)
    return false;
  GdkWindowState state = gdk_window_get_state(pimpl_->gdk_window_);
  return state & GDK_WINDOW_STATE_STICKY;
}

void Window::SetIgnoreMouseEvents(bool is_ignore_mouse_events) {
  // This would involve setting input shapes or event masks
  // Provide stub implementation
}

bool Window::IsIgnoreMouseEvents() const {
  return false;  // Default assumption
}

void Window::SetFocusable(bool is_focusable) {
  // This would typically be set via window hints
  // Provide stub implementation
}

bool Window::IsFocusable() const {
  return true;  // Default assumption
}

void Window::StartDragging() {
  // Window dragging would typically involve listening to mouse events
  // Provide stub implementation
}

void Window::StartResizing() {
  // Window resizing would typically involve listening to mouse events at edges
  // Provide stub implementation
}

void* Window::GetNativeObjectInternal() const {
  // Return the GtkWidget* (GtkWindow) as the native handle on Linux
  return pimpl_ ? static_cast<void*>(pimpl_->widget_ ? pimpl_->widget_ : nullptr) : nullptr;
}

}  // namespace nativeapi
