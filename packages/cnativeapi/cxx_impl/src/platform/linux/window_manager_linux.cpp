#include <cstring>
#include <iostream>
#include <mutex>
#include <set>
#include <string>
#include <unordered_map>

#include "../../window.h"
#include "../../window_manager.h"
#include "../../window_registry.h"

// Import GTK headers
#include <gdk/gdk.h>
#include <gtk/gtk.h>

namespace nativeapi {

// Key to store/retrieve WindowId on GObjects (must match window_linux.cpp)
static const char* kWindowIdKey = "NativeAPIWindowId";

// Shared static variables for window ID mapping
static std::unordered_map<GdkWindow*, WindowId> g_window_id_map;
static std::mutex g_map_mutex;

// Track widgets that have been hooked to avoid duplicate connections
static std::set<GtkWidget*> g_hooked_widgets;
static std::mutex g_hook_mutex;

// Flag to indicate if global swizzling has been installed
static bool g_swizzle_installed = false;

// Helper function to manage mapping between GdkWindow pointers and WindowIds
static WindowId GetOrCreateWindowId(GdkWindow* gdk_window) {
  if (!gdk_window) {
    return IdAllocator::kInvalidId;
  }

  // First, try to read ID attached to the GObject
  gpointer data = g_object_get_data(G_OBJECT(gdk_window), kWindowIdKey);
  if (data) {
    WindowId id = static_cast<WindowId>(reinterpret_cast<uintptr_t>(data));
    // Cache it in the map for faster lookup next time
    std::lock_guard<std::mutex> lock(g_map_mutex);
    g_window_id_map[gdk_window] = id;
    return id;
  }

  // Fallback to cached map
  {
    std::lock_guard<std::mutex> lock(g_map_mutex);
    auto it = g_window_id_map.find(gdk_window);
    if (it != g_window_id_map.end()) {
      return it->second;
    }
  }

  // Allocate new ID and attach to the GObject for consistency
  WindowId new_id = IdAllocator::Allocate<Window>();
  if (new_id != IdAllocator::kInvalidId) {
    g_object_set_data(G_OBJECT(gdk_window), kWindowIdKey,
                      reinterpret_cast<gpointer>(static_cast<uintptr_t>(new_id)));
    std::lock_guard<std::mutex> lock(g_map_mutex);
    g_window_id_map[gdk_window] = new_id;
  }
  return new_id;
}

// Helper function to find GdkWindow by WindowId
static GdkWindow* FindGdkWindowById(WindowId id) {
  std::lock_guard<std::mutex> lock(g_map_mutex);
  for (const auto& pair : g_window_id_map) {
    if (pair.second == id) {
      return pair.first;
    }
  }
  return nullptr;
}

// Forward declarations for swizzling functions
static void InstallShowHideHooks(GtkWidget* widget);
static void InstallGlobalSwizzling();

// Signal emission hook for show signal
static gboolean on_show_emission_hook(GSignalInvocationHint* ihint,
                                      guint n_param_values,
                                      const GValue* param_values,
                                      gpointer data) {
  (void)ihint;
  (void)n_param_values;
  (void)data;

  GtkWidget* widget = GTK_WIDGET(g_value_get_object(&param_values[0]));
  if (widget && GTK_IS_WINDOW(widget)) {
    GdkWindow* gdk_window = gtk_widget_get_window(widget);
    if (gdk_window) {
      WindowId id = GetOrCreateWindowId(gdk_window);
      WindowManager::GetInstance().HandleWillShow(id);
    }
  }

  return TRUE;  // Continue emission
}

// Signal emission hook for hide signal
static gboolean on_hide_emission_hook(GSignalInvocationHint* ihint,
                                      guint n_param_values,
                                      const GValue* param_values,
                                      gpointer data) {
  (void)ihint;
  (void)n_param_values;
  (void)data;

  GtkWidget* widget = GTK_WIDGET(g_value_get_object(&param_values[0]));
  if (widget && GTK_IS_WINDOW(widget)) {
    GdkWindow* gdk_window = gtk_widget_get_window(widget);
    if (gdk_window) {
      WindowId id = GetOrCreateWindowId(gdk_window);
      WindowManager::GetInstance().HandleWillHide(id);
    }
  }

  return TRUE;  // Continue emission
}

// Signal emission hook for delete-event signal
static gboolean on_delete_event_emission_hook(GSignalInvocationHint* ihint,
                                              guint n_param_values,
                                              const GValue* param_values,
                                              gpointer data) {
  (void)ihint;
  (void)n_param_values;
  (void)data;

  GtkWidget* widget = GTK_WIDGET(g_value_get_object(&param_values[0]));
  if (widget && GTK_IS_WINDOW(widget)) {
    GdkWindow* gdk_window = gtk_widget_get_window(widget);
    if (gdk_window) {
      WindowId id = GetOrCreateWindowId(gdk_window);
      WindowManager::GetInstance().HandleWillClose(id);
    }
  }

  return TRUE;  // Continue emission
}

// GTK signal callbacks to invoke hooks (used as fallback)
static gboolean OnGtkMapEvent(GtkWidget* widget, GdkEvent* event, gpointer user_data) {
  (void)event;
  (void)user_data;

  if (GTK_IS_WINDOW(widget)) {
    auto& manager = WindowManager::GetInstance();
    GdkWindow* gdk_window = gtk_widget_get_window(widget);
    if (gdk_window) {
      WindowId id = GetOrCreateWindowId(gdk_window);
      manager.HandleWillShow(id);
    }
  }
  // Return FALSE to propagate event further
  return FALSE;
}

static gboolean OnGtkUnmapEvent(GtkWidget* widget, GdkEvent* event, gpointer user_data) {
  (void)event;
  (void)user_data;

  if (GTK_IS_WINDOW(widget)) {
    auto& manager = WindowManager::GetInstance();
    GdkWindow* gdk_window = gtk_widget_get_window(widget);
    if (gdk_window) {
      WindowId id = GetOrCreateWindowId(gdk_window);
      manager.HandleWillHide(id);
    }
  }
  // Return FALSE to propagate event further
  return FALSE;
}

// Install hooks for a specific widget
static void InstallShowHideHooks(GtkWidget* widget) {
  if (!widget || !GTK_IS_WINDOW(widget)) {
    return;
  }

  std::lock_guard<std::mutex> lock(g_hook_mutex);

  // Check if already hooked
  if (g_hooked_widgets.find(widget) != g_hooked_widgets.end()) {
    return;
  }

  // Connect map/unmap events as fallback
  g_signal_connect(G_OBJECT(widget), "map-event", G_CALLBACK(OnGtkMapEvent), nullptr);
  g_signal_connect(G_OBJECT(widget), "unmap-event", G_CALLBACK(OnGtkUnmapEvent), nullptr);

  g_hooked_widgets.insert(widget);
}

// Install global swizzling using signal emission hooks
static void InstallGlobalSwizzling() {
  if (g_swizzle_installed) {
    return;
  }

  // Get the show, hide, and delete-event signal IDs for GtkWidget
  guint show_signal_id = g_signal_lookup("show", GTK_TYPE_WIDGET);
  guint hide_signal_id = g_signal_lookup("hide", GTK_TYPE_WIDGET);
  guint delete_event_signal_id = g_signal_lookup("delete-event", GTK_TYPE_WIDGET);

  if (show_signal_id != 0) {
    // Add emission hook for show signal
    g_signal_add_emission_hook(show_signal_id, 0, on_show_emission_hook, nullptr, nullptr);
  }

  if (hide_signal_id != 0) {
    // Add emission hook for hide signal
    g_signal_add_emission_hook(hide_signal_id, 0, on_hide_emission_hook, nullptr, nullptr);
  }

  if (delete_event_signal_id != 0) {
    // Add emission hook for delete-event signal
    g_signal_add_emission_hook(delete_event_signal_id, 0, on_delete_event_emission_hook, nullptr, nullptr);
  }

  g_swizzle_installed = true;
}

// Private implementation for Linux
class WindowManager::Impl {
 public:
  Impl(WindowManager* manager) : manager_(manager) {}
  ~Impl() {}

  void StartEventListening() {
    // Install global swizzling for show/hide interception
    InstallGlobalSwizzling();

    // Monitor all existing windows
    GdkDisplay* display = gdk_display_get_default();
    if (display) {
      GList* toplevels = gtk_window_list_toplevels();
      for (GList* l = toplevels; l != nullptr; l = l->next) {
        GtkWindow* gtk_window = GTK_WINDOW(l->data);
        InstallShowHideHooks(GTK_WIDGET(gtk_window));
      }
      g_list_free(toplevels);
    }
  }

  void StopEventListening() {
    // Clear hooked widgets set
    std::lock_guard<std::mutex> lock(g_hook_mutex);
    g_hooked_widgets.clear();
  }

 private:
  WindowManager* manager_;
  // Optional pre-show/hide/close hooks
  std::optional<WindowManager::WindowWillShowHook> will_show_hook_;
  std::optional<WindowManager::WindowWillHideHook> will_hide_hook_;
  std::optional<WindowManager::WindowWillCloseHook> will_close_hook_;

  friend class WindowManager;
};

WindowManager::WindowManager() : pimpl_(std::make_unique<Impl>(this)) {
  // Try to initialize GTK if not already initialized
  // In headless environments, this may fail, which is acceptable
  if (!gdk_display_get_default()) {
    // Temporarily redirect stderr to suppress GTK warnings in headless
    // environments
    FILE* original_stderr = stderr;
    freopen("/dev/null", "w", stderr);

    gboolean gtk_result = gtk_init_check(nullptr, nullptr);

    // Restore stderr
    fflush(stderr);
    freopen("/dev/tty", "w", stderr);
    stderr = original_stderr;

    // gtk_init_check returns FALSE if initialization failed (e.g., no display)
    // This is acceptable for headless environments
  }

  StartEventListening();
}

WindowManager::~WindowManager() {
  StopEventListening();
}

std::shared_ptr<Window> WindowManager::Get(WindowId id) {
  auto cached = WindowRegistry::GetInstance().Get(id);
  if (cached) {
    return cached;
  }

  // Try to find the window by ID in the current display
  GdkDisplay* display = gdk_display_get_default();
  if (!display) {
    return nullptr;
  }

  // Get all toplevel windows
  GList* toplevels = gtk_window_list_toplevels();
  for (GList* l = toplevels; l != nullptr; l = l->next) {
    GtkWindow* gtk_window = GTK_WINDOW(l->data);
    GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(gtk_window));

    if (gdk_window && GetOrCreateWindowId(gdk_window) == id) {
      auto window = std::make_shared<Window>((void*)gdk_window);
      WindowRegistry::GetInstance().Add(id, window);
      g_list_free(toplevels);
      return window;
    }
  }
  g_list_free(toplevels);
  return nullptr;
}

std::vector<std::shared_ptr<Window>> WindowManager::GetAll() {
  std::vector<std::shared_ptr<Window>> windows;

  GdkDisplay* display = gdk_display_get_default();
  if (!display) {
    return windows;
  }

  // Get all toplevel windows
  GList* toplevels = gtk_window_list_toplevels();
  for (GList* l = toplevels; l != nullptr; l = l->next) {
    GtkWindow* gtk_window = GTK_WINDOW(l->data);
    GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(gtk_window));

    if (gdk_window) {
      WindowId window_id = GetOrCreateWindowId(gdk_window);
      if (!WindowRegistry::GetInstance().Get(window_id)) {
        auto window = std::make_shared<Window>((void*)gdk_window);
        WindowRegistry::GetInstance().Add(window_id, window);
      }
    }
  }
  g_list_free(toplevels);

  // Return all cached windows
  return WindowRegistry::GetInstance().GetAll();
}

std::shared_ptr<Window> WindowManager::GetCurrent() {
  GdkDisplay* display = gdk_display_get_default();
  if (!display) {
    return nullptr;
  }

  // Try to get the focused window
  GdkSeat* seat = gdk_display_get_default_seat(display);
  if (seat) {
    GdkDevice* keyboard = gdk_seat_get_keyboard(seat);
    if (keyboard) {
      GdkWindow* focused_window = gdk_device_get_window_at_position(keyboard, nullptr, nullptr);
      if (focused_window) {
        WindowId window_id = GetOrCreateWindowId(focused_window);
        return Get(window_id);
      }
    }
  }

  // Fallback: get the first visible window
  GList* toplevels = gtk_window_list_toplevels();
  for (GList* l = toplevels; l != nullptr; l = l->next) {
    GtkWindow* gtk_window = GTK_WINDOW(l->data);
    if (gtk_widget_get_visible(GTK_WIDGET(gtk_window))) {
      GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(gtk_window));
      if (gdk_window) {
        WindowId window_id = GetOrCreateWindowId(gdk_window);
        g_list_free(toplevels);
        return Get(window_id);
      }
    }
  }
  g_list_free(toplevels);

  return nullptr;
}

void WindowManager::SetWillShowHook(std::optional<WindowWillShowHook> hook) {
  pimpl_->will_show_hook_ = std::move(hook);
  if (pimpl_->will_show_hook_) {
    // Ensure global swizzling is installed when hook is set
    InstallGlobalSwizzling();
  }
}

void WindowManager::SetWillHideHook(std::optional<WindowWillHideHook> hook) {
  pimpl_->will_hide_hook_ = std::move(hook);
  if (pimpl_->will_hide_hook_) {
    // Ensure global swizzling is installed when hook is set
    InstallGlobalSwizzling();
  }
}

void WindowManager::SetWillCloseHook(std::optional<WindowWillCloseHook> hook) {
  pimpl_->will_close_hook_ = std::move(hook);
  if (pimpl_->will_close_hook_) {
    // Ensure global swizzling is installed when hook is set
    InstallGlobalSwizzling();
  }
}

bool WindowManager::HasWillShowHook() const {
  return pimpl_->will_show_hook_.has_value();
}

bool WindowManager::HasWillHideHook() const {
  return pimpl_->will_hide_hook_.has_value();
}

bool WindowManager::HasWillCloseHook() const {
  return pimpl_->will_close_hook_.has_value();
}

void WindowManager::HandleWillShow(WindowId id) {
  if (pimpl_->will_show_hook_) {
    (*pimpl_->will_show_hook_)(id);
  }
}

void WindowManager::HandleWillHide(WindowId id) {
  if (pimpl_->will_hide_hook_) {
    (*pimpl_->will_hide_hook_)(id);
  }
}

void WindowManager::HandleWillClose(WindowId id) {
  if (pimpl_->will_close_hook_) {
    (*pimpl_->will_close_hook_)(id);
  }
}

bool WindowManager::CallOriginalShow(WindowId id) {
  GdkWindow* gdk_window = FindGdkWindowById(id);
  if (!gdk_window) {
    return false;
  }

  // Call the original GDK show function directly
  gdk_window_show(gdk_window);
  return true;
}

bool WindowManager::CallOriginalHide(WindowId id) {
  GdkWindow* gdk_window = FindGdkWindowById(id);
  if (!gdk_window) {
    return false;
  }

  // Call the original GDK hide function directly
  gdk_window_hide(gdk_window);
  return true;
}

bool WindowManager::CallOriginalClose(WindowId id) {
  GdkWindow* gdk_window = FindGdkWindowById(id);
  if (!gdk_window) {
    return false;
  }

  // On Linux, destroy the underlying GtkWidget to close the window
  GtkWidget* widget = gtk_widget_get_toplevel(GTK_WIDGET(gdk_window));
  if (widget && GTK_IS_WINDOW(widget)) {
    gtk_widget_destroy(widget);
    return true;
  }
  return false;
}

void WindowManager::StartEventListening() {
  pimpl_->StartEventListening();
}

void WindowManager::StopEventListening() {
  pimpl_->StopEventListening();
}

void WindowManager::DispatchWindowEvent(const WindowEvent& event) {
  Emit(event);
}

}  // namespace nativeapi
