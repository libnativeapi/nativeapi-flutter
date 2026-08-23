// Linux tray icon implemented via the StatusNotifierItem D-Bus specification.
// https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/
//
// Uses GDBus (part of GLib/GIO, already a transitive dependency of GTK) so that
// no GPL-licensed libayatana-appindicator dependency is required.

#include <gio/gio.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <glib.h>
#include <gtk/gtk.h>
#include <sys/types.h>
#include <unistd.h>
#include <atomic>
#include <cstdint>
#include <iostream>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

#include "../../foundation/id_allocator.h"
#include "../../image.h"
#include "../../menu.h"
#include "../../tray_icon.h"

namespace nativeapi {

// ── D-Bus introspection XML for org.kde.StatusNotifierItem ───────────────────

static const char kSniIntrospectionXml[] =
    "<node>"
    "  <interface name='org.kde.StatusNotifierItem'>"
    "    <property name='Category'           type='s'        access='read'/>"
    "    <property name='Id'                 type='s'        access='read'/>"
    "    <property name='Title'              type='s'        access='read'/>"
    "    <property name='Status'             type='s'        access='read'/>"
    "    <property name='WindowId'           type='u'        access='read'/>"
    "    <property name='IconName'           type='s'        access='read'/>"
    "    <property name='IconPixmap'         type='a(iiay)'  access='read'/>"
    "    <property name='OverlayIconName'    type='s'        access='read'/>"
    "    <property name='OverlayIconPixmap'  type='a(iiay)'  access='read'/>"
    "    <property name='AttentionIconName'  type='s'        access='read'/>"
    "    <property name='AttentionIconPixmap' type='a(iiay)' access='read'/>"
    "    <property name='AttentionMovieName' type='s'        access='read'/>"
    "    <property name='ToolTip'            type='(sa(iiay)ss)' access='read'/>"
    "    <property name='ItemIsMenu'         type='b'        access='read'/>"
    "    <property name='Menu'               type='o'        access='read'/>"
    "    <method name='ContextMenu'>"
    "      <arg type='i' direction='in' name='x'/>"
    "      <arg type='i' direction='in' name='y'/>"
    "    </method>"
    "    <method name='Activate'>"
    "      <arg type='i' direction='in' name='x'/>"
    "      <arg type='i' direction='in' name='y'/>"
    "    </method>"
    "    <method name='SecondaryActivate'>"
    "      <arg type='i' direction='in' name='x'/>"
    "      <arg type='i' direction='in' name='y'/>"
    "    </method>"
    "    <method name='Scroll'>"
    "      <arg type='i' direction='in' name='delta'/>"
    "      <arg type='s' direction='in' name='orientation'/>"
    "    </method>"
    "    <signal name='NewTitle'/>"
    "    <signal name='NewIcon'/>"
    "    <signal name='NewAttentionIcon'/>"
    "    <signal name='NewOverlayIcon'/>"
    "    <signal name='NewToolTip'/>"
    "    <signal name='NewStatus'>"
    "      <arg type='s' name='status'/>"
    "    </signal>"
    "  </interface>"
    "</node>";

static const char kDbusMenuIntrospectionXml[] =
    "<node>"
    "  <interface name='com.canonical.dbusmenu'>"
    "    <property name='Version' type='u' access='read'/>"
    "    <property name='TextDirection' type='s' access='read'/>"
    "    <property name='Status' type='s' access='read'/>"
    "    <property name='IconThemePath' type='as' access='read'/>"
    "    <method name='GetLayout'>"
    "      <arg type='i' name='parentId' direction='in'/>"
    "      <arg type='i' name='recursionDepth' direction='in'/>"
    "      <arg type='as' name='propertyNames' direction='in'/>"
    "      <arg type='u' name='revision' direction='out'/>"
    "      <arg type='(ia{sv}av)' name='layout' direction='out'/>"
    "    </method>"
    "    <method name='GetGroupProperties'>"
    "      <arg type='ai' name='ids' direction='in'/>"
    "      <arg type='as' name='propertyNames' direction='in'/>"
    "      <arg type='a(ia{sv})' name='properties' direction='out'/>"
    "    </method>"
    "    <method name='GetProperty'>"
    "      <arg type='i' name='id' direction='in'/>"
    "      <arg type='s' name='name' direction='in'/>"
    "      <arg type='v' name='value' direction='out'/>"
    "    </method>"
    "    <method name='Event'>"
    "      <arg type='i' name='id' direction='in'/>"
    "      <arg type='s' name='eventId' direction='in'/>"
    "      <arg type='v' name='data' direction='in'/>"
    "      <arg type='u' name='timestamp' direction='in'/>"
    "    </method>"
    "    <method name='EventGroup'>"
    "      <arg type='a(isvu)' name='events' direction='in'/>"
    "      <arg type='ai' name='idErrors' direction='out'/>"
    "    </method>"
    "    <method name='AboutToShow'>"
    "      <arg type='i' name='id' direction='in'/>"
    "      <arg type='b' name='needUpdate' direction='out'/>"
    "    </method>"
    "    <method name='AboutToShowGroup'>"
    "      <arg type='ai' name='ids' direction='in'/>"
    "      <arg type='ai' name='updatesNeeded' direction='out'/>"
    "      <arg type='ai' name='idErrors' direction='out'/>"
    "    </method>"
    "    <signal name='ItemsPropertiesUpdated'>"
    "      <arg type='a(ia{sv})' name='updatedProps'/>"
    "      <arg type='a(ias)' name='removedProps'/>"
    "    </signal>"
    "    <signal name='LayoutUpdated'>"
    "      <arg type='u' name='revision'/>"
    "      <arg type='i' name='parent'/>"
    "    </signal>"
    "    <signal name='ItemActivationRequested'>"
    "      <arg type='i' name='id'/>"
    "      <arg type='u' name='timestamp'/>"
    "    </signal>"
    "  </interface>"
    "</node>";

// ── Icon pixel-data conversion ───────────────────────────────────────────────

// Returns a GVariant of type a(iiay) containing one entry for the supplied
// pixbuf (or an empty array when pixbuf is nullptr).  Each pixel is encoded as
// four bytes in network byte order: Alpha, Red, Green, Blue (ARGB32).
static GVariant* PixbufToSniIconPixmaps(GdkPixbuf* pixbuf) {
  GVariantBuilder array_builder;
  g_variant_builder_init(&array_builder, G_VARIANT_TYPE("a(iiay)"));

  if (pixbuf) {
    const int width = gdk_pixbuf_get_width(pixbuf);
    const int height = gdk_pixbuf_get_height(pixbuf);
    const int rowstride = gdk_pixbuf_get_rowstride(pixbuf);
    const int n_channels = gdk_pixbuf_get_n_channels(pixbuf);
    const gboolean has_alpha = gdk_pixbuf_get_has_alpha(pixbuf);
    const guchar* pixels = gdk_pixbuf_get_pixels(pixbuf);

    std::vector<uint8_t> argb;
    argb.reserve(static_cast<size_t>(width * height * 4));

    for (int row = 0; row < height; ++row) {
      const guchar* p = pixels + row * rowstride;
      for (int col = 0; col < width; ++col) {
        const uint8_t r = p[0];
        const uint8_t g = p[1];
        const uint8_t b = p[2];
        const uint8_t a = has_alpha ? p[3] : 255u;
        argb.push_back(a);
        argb.push_back(r);
        argb.push_back(g);
        argb.push_back(b);
        p += n_channels;
      }
    }

    GVariantBuilder entry_builder;
    g_variant_builder_init(&entry_builder, G_VARIANT_TYPE("(iiay)"));
    g_variant_builder_add(&entry_builder, "i", width);
    g_variant_builder_add(&entry_builder, "i", height);
    g_variant_builder_add_value(
        &entry_builder,
        g_variant_new_fixed_array(G_VARIANT_TYPE_BYTE, argb.data(), argb.size(), sizeof(uint8_t)));
    g_variant_builder_add_value(&array_builder, g_variant_builder_end(&entry_builder));
  }

  return g_variant_builder_end(&array_builder);
}

// ── Private implementation ───────────────────────────────────────────────────

class TrayIcon::Impl {
 public:
  TrayIcon* owner_;
  TrayIconId id_;

  std::shared_ptr<Image> image_;
  std::optional<std::string> title_;
  std::optional<std::string> tooltip_;
  std::shared_ptr<Menu> context_menu_;
  bool visible_;
  ContextMenuTrigger context_menu_trigger_;

  // D-Bus state
  GDBusConnection* connection_;
  guint registration_id_;
  guint menu_registration_id_;
  guint name_owner_id_;
  std::string service_name_;
  std::unordered_map<int, GtkWidget*> dbusmenu_items_;
  unsigned int menu_revision_;

  explicit Impl(TrayIcon* owner)
      : owner_(owner),
        image_(nullptr),
        title_(std::nullopt),
        tooltip_(std::nullopt),
        context_menu_(nullptr),
        visible_(false),
        context_menu_trigger_(ContextMenuTrigger::None),
        connection_(nullptr),
        registration_id_(0),
        menu_registration_id_(0),
        name_owner_id_(0),
        menu_revision_(1) {
    id_ = IdAllocator::Allocate<TrayIcon>();
  }

  ~Impl() { Cleanup(); }

  // Connect to the session bus, register the SNI object, and request a
  // well-known service name.  Returns false on error (icon will be invisible).
  bool Init() {
    GError* error = nullptr;
    connection_ = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
    if (!connection_) {
      if (error) {
        std::cerr << "[nativeapi] SNI: D-Bus session connection failed: " << error->message
                  << std::endl;
        g_error_free(error);
      }
      return false;
    }

    static std::atomic<int> next_sni_index{1};
    service_name_ = "org.kde.StatusNotifierItem-" +
                    std::to_string(static_cast<long>(getpid())) + "-" +
                    std::to_string(next_sni_index++);

    GDBusNodeInfo* node_info = g_dbus_node_info_new_for_xml(kSniIntrospectionXml, &error);
    if (!node_info) {
      if (error) {
        std::cerr << "[nativeapi] SNI: Bad introspection XML: " << error->message << std::endl;
        g_error_free(error);
      }
      return false;
    }

    GDBusInterfaceInfo* iface_info =
        g_dbus_node_info_lookup_interface(node_info, "org.kde.StatusNotifierItem");

    static const GDBusInterfaceVTable vtable = {
        &Impl::OnMethodCall,
        &Impl::OnGetProperty,
        nullptr  // no writable properties
    };

    registration_id_ = g_dbus_connection_register_object(connection_, "/StatusNotifierItem",
                                                          iface_info, &vtable,
                                                          this,     // user_data
                                                          nullptr,  // user_data_free_func
                                                          &error);
    g_dbus_node_info_unref(node_info);

    if (registration_id_ == 0) {
      if (error) {
        std::cerr << "[nativeapi] SNI: Object registration failed: " << error->message
                  << std::endl;
        g_error_free(error);
      }
      return false;
    }

    GDBusNodeInfo* menu_node_info =
        g_dbus_node_info_new_for_xml(kDbusMenuIntrospectionXml, &error);
    if (!menu_node_info) {
      if (error) {
        std::cerr << "[nativeapi] SNI: Bad dbusmenu introspection XML: " << error->message
                  << std::endl;
        g_error_free(error);
      }
      return false;
    }

    GDBusInterfaceInfo* menu_iface_info =
        g_dbus_node_info_lookup_interface(menu_node_info, "com.canonical.dbusmenu");

    static const GDBusInterfaceVTable menu_vtable = {
        &Impl::OnMenuMethodCall,
        &Impl::OnMenuGetProperty,
        nullptr  // no writable properties
    };

    menu_registration_id_ = g_dbus_connection_register_object(
        connection_, "/StatusNotifierItem/Menu", menu_iface_info, &menu_vtable, this, nullptr,
        &error);
    g_dbus_node_info_unref(menu_node_info);

    if (menu_registration_id_ == 0) {
      if (error) {
        std::cerr << "[nativeapi] SNI: dbusmenu object registration failed: " << error->message
                  << std::endl;
        g_error_free(error);
      }
      return false;
    }

    name_owner_id_ = g_bus_own_name_on_connection(connection_, service_name_.c_str(),
                                                   G_BUS_NAME_OWNER_FLAGS_NONE, &Impl::OnNameAcquired,
                                                   &Impl::OnNameLost, this, nullptr);
    return true;
  }

  void Cleanup() {
    // Nullify the back-pointer first so any in-flight GLib callbacks that
    // haven't been dispatched yet will see a null owner and skip event emission.
    owner_ = nullptr;

    if (name_owner_id_ != 0) {
      g_bus_unown_name(name_owner_id_);
      name_owner_id_ = 0;
    }
    if (connection_ && registration_id_ != 0) {
      g_dbus_connection_unregister_object(connection_, registration_id_);
      registration_id_ = 0;
    }
    if (connection_ && menu_registration_id_ != 0) {
      g_dbus_connection_unregister_object(connection_, menu_registration_id_);
      menu_registration_id_ = 0;
    }
    if (connection_) {
      g_object_unref(connection_);
      connection_ = nullptr;
    }
  }

  void EmitSignal(const char* signal_name, GVariant* params = nullptr) {
    if (!connection_ || registration_id_ == 0) return;
    GError* error = nullptr;
    g_dbus_connection_emit_signal(connection_, nullptr, "/StatusNotifierItem",
                                   "org.kde.StatusNotifierItem", signal_name, params, &error);
    if (error) g_error_free(error);
  }

  bool ShouldExposeMenu() const {
    return context_menu_ != nullptr && context_menu_trigger_ == ContextMenuTrigger::Clicked;
  }

  void EmitMenuPropertiesChanged() {
    if (!connection_ || registration_id_ == 0) return;

    const bool expose_menu = ShouldExposeMenu();

    GVariantBuilder changed;
    GVariantBuilder invalidated;
    g_variant_builder_init(&changed, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_init(&invalidated, G_VARIANT_TYPE("as"));
    g_variant_builder_add(&changed, "{sv}", "ItemIsMenu", g_variant_new_boolean(expose_menu));
    g_variant_builder_add(&changed, "{sv}", "Menu",
                          g_variant_new_object_path(expose_menu ? "/StatusNotifierItem/Menu"
                                                                : "/"));

    GError* error = nullptr;
    g_dbus_connection_emit_signal(
        connection_, nullptr, "/StatusNotifierItem", "org.freedesktop.DBus.Properties",
        "PropertiesChanged",
        g_variant_new("(s@a{sv}@as)", "org.kde.StatusNotifierItem",
                      g_variant_builder_end(&changed), g_variant_builder_end(&invalidated)),
        &error);
    if (error) g_error_free(error);
  }

  // ── D-Bus name callbacks ──────────────────────────────────────────────────

  static void OnNameAcquired(GDBusConnection* conn, const gchar* name, gpointer user_data) {
    Impl* self = static_cast<Impl*>(user_data);
    if (self) self->RegisterWithWatcher(conn, name);
  }

  static void OnNameLost(GDBusConnection*, const gchar* name, gpointer) {
    std::cerr << "[nativeapi] SNI: lost D-Bus name " << (name ? name : "(null)") << std::endl;
  }

  // Try both KDE and Canonical watcher service names.
  void RegisterWithWatcher(GDBusConnection* conn, const gchar* service_name) {
    static const char* const kWatchers[] = {
        "org.kde.StatusNotifierWatcher",
        "com.canonical.StatusNotifierWatcher",
        nullptr,
    };
    for (int i = 0; kWatchers[i]; ++i) {
      GError* error = nullptr;
      GVariant* reply = g_dbus_connection_call_sync(
          conn, kWatchers[i], "/StatusNotifierWatcher", kWatchers[i],
          "RegisterStatusNotifierItem", g_variant_new("(s)", service_name), nullptr,
          G_DBUS_CALL_FLAGS_NONE, 2000, nullptr, &error);
      if (reply) {
        g_variant_unref(reply);
        return;
      }
      if (error) g_error_free(error);
    }
    std::cerr << "[nativeapi] SNI: no StatusNotifierWatcher found; tray icon may not appear"
              << std::endl;
  }

  // ── D-Bus method-call handler ─────────────────────────────────────────────

  static void OnMethodCall(GDBusConnection*, const gchar*, const gchar*, const gchar*,
                           const gchar* method_name, GVariant*,
                           GDBusMethodInvocation* invocation, gpointer user_data) {
    if (!user_data) {
      g_dbus_method_invocation_return_error(invocation, G_DBUS_ERROR, G_DBUS_ERROR_FAILED,
                                             "Internal error");
      return;
    }

    if (g_strcmp0(method_name, "Activate") == 0 ||
        g_strcmp0(method_name, "SecondaryActivate") == 0 ||
        g_strcmp0(method_name, "ContextMenu") == 0 ||
        g_strcmp0(method_name, "Scroll") == 0) {
      g_dbus_method_invocation_return_value(invocation, nullptr);
    } else {
      g_dbus_method_invocation_return_error(invocation, G_DBUS_ERROR,
                                             G_DBUS_ERROR_UNKNOWN_METHOD,
                                             "Unknown method: %s", method_name);
    }
  }

  // ── D-Bus property getter ─────────────────────────────────────────────────

  static GVariant* OnGetProperty(GDBusConnection*, const gchar*, const gchar*, const gchar*,
                                  const gchar* property_name, GError** error,
                                  gpointer user_data) {
    Impl* self = static_cast<Impl*>(user_data);
    if (!self) return nullptr;

    if (g_strcmp0(property_name, "Category") == 0)
      return g_variant_new_string("ApplicationStatus");

    if (g_strcmp0(property_name, "Id") == 0)
      return g_variant_new_string("nativeapi-tray");

    if (g_strcmp0(property_name, "Title") == 0)
      return g_variant_new_string(self->title_.value_or("").c_str());

    if (g_strcmp0(property_name, "Status") == 0)
      return g_variant_new_string(self->visible_ ? "Active" : "Passive");

    if (g_strcmp0(property_name, "WindowId") == 0)
      return g_variant_new_uint32(0);

    if (g_strcmp0(property_name, "IconName") == 0)
      return g_variant_new_string("");  // we use IconPixmap instead

    if (g_strcmp0(property_name, "IconPixmap") == 0) {
      // image_linux.cpp's GetNativeObjectInternal() returns GdkPixbuf* on Linux.
      GdkPixbuf* pb =
          self->image_ ? static_cast<GdkPixbuf*>(self->image_->GetNativeObject()) : nullptr;
      return PixbufToSniIconPixmaps(pb);
    }

    if (g_strcmp0(property_name, "OverlayIconName") == 0) return g_variant_new_string("");
    if (g_strcmp0(property_name, "OverlayIconPixmap") == 0) return PixbufToSniIconPixmaps(nullptr);
    if (g_strcmp0(property_name, "AttentionIconName") == 0) return g_variant_new_string("");
    if (g_strcmp0(property_name, "AttentionIconPixmap") == 0)
      return PixbufToSniIconPixmaps(nullptr);
    if (g_strcmp0(property_name, "AttentionMovieName") == 0) return g_variant_new_string("");

    if (g_strcmp0(property_name, "ToolTip") == 0) {
      // (sa(iiay)ss): iconName, iconPixmap[], title, description
      const std::string& tip = self->tooltip_.value_or(self->title_.value_or(""));
      return g_variant_new("(s@a(iiay)ss)", "", PixbufToSniIconPixmaps(nullptr),
                           self->title_.value_or("").c_str(), tip.c_str());
    }

    if (g_strcmp0(property_name, "ItemIsMenu") == 0)
      return g_variant_new_boolean(self->ShouldExposeMenu());
    if (g_strcmp0(property_name, "Menu") == 0) {
      const bool expose_menu = self->ShouldExposeMenu();
      return g_variant_new_object_path(expose_menu ? "/StatusNotifierItem/Menu" : "/");
    }

    if (error) {
      *error = g_error_new(G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_PROPERTY,
                           "Unknown property: %s", property_name);
    }
    return nullptr;
  }

  static std::string GtkMenuItemLabel(GtkWidget* item) {
    if (!item || !GTK_IS_MENU_ITEM(item) || GTK_IS_SEPARATOR_MENU_ITEM(item)) {
      return "";
    }

    const char* label = gtk_menu_item_get_label(GTK_MENU_ITEM(item));
    if (label && label[0] != '\0') {
      return label;
    }

    GtkWidget* child = gtk_bin_get_child(GTK_BIN(item));
    if (!child) {
      return "";
    }

    if (GTK_IS_LABEL(child)) {
      label = gtk_label_get_text(GTK_LABEL(child));
      return label ? label : "";
    }

    if (GTK_IS_CONTAINER(child)) {
      GList* children = gtk_container_get_children(GTK_CONTAINER(child));
      for (GList* iter = children; iter; iter = iter->next) {
        GtkWidget* widget = GTK_WIDGET(iter->data);
        if (GTK_IS_LABEL(widget)) {
          label = gtk_label_get_text(GTK_LABEL(widget));
          std::string result = label ? label : "";
          g_list_free(children);
          return result;
        }
      }
      g_list_free(children);
    }

    return "";
  }

  int RegisterDbusMenuItem(GtkWidget* item) {
    int id = static_cast<int>(reinterpret_cast<uintptr_t>(item) & 0x7fffffff);
    if (id == 0) {
      id = 1;
    }
    dbusmenu_items_[id] = item;
    return id;
  }

  void AppendMenuItemProperties(GVariantBuilder* props, GtkWidget* item) {
    const bool is_separator = item && GTK_IS_SEPARATOR_MENU_ITEM(item);
    const bool enabled = item ? gtk_widget_get_sensitive(item) == TRUE : true;
    const bool visible = true;

    g_variant_builder_add(props, "{sv}", "enabled", g_variant_new_boolean(enabled));
    g_variant_builder_add(props, "{sv}", "visible", g_variant_new_boolean(visible));

    if (is_separator) {
      g_variant_builder_add(props, "{sv}", "type", g_variant_new_string("separator"));
      return;
    }

    std::string label = GtkMenuItemLabel(item);
    if (!label.empty()) {
      g_variant_builder_add(props, "{sv}", "label", g_variant_new_string(label.c_str()));
    }

    if (item && GTK_IS_CHECK_MENU_ITEM(item)) {
      const bool is_radio = GTK_IS_RADIO_MENU_ITEM(item);
      g_variant_builder_add(props, "{sv}", "toggle-type",
                            g_variant_new_string(is_radio ? "radio" : "checkmark"));
      g_variant_builder_add(
          props, "{sv}", "toggle-state",
          g_variant_new_int32(gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(item)) ? 1 : 0));
    }

    if (item && GTK_IS_MENU_ITEM(item) && gtk_menu_item_get_submenu(GTK_MENU_ITEM(item))) {
      g_variant_builder_add(props, "{sv}", "children-display", g_variant_new_string("submenu"));
    }
  }

  GVariant* BuildDbusMenuLayout(GtkWidget* menu, int item_id = 0) {
    GVariantBuilder props;
    GVariantBuilder children;
    g_variant_builder_init(&props, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_init(&children, G_VARIANT_TYPE("av"));

    if (item_id != 0 && menu && GTK_IS_MENU_ITEM(menu)) {
      AppendMenuItemProperties(&props, menu);
      GtkWidget* submenu = gtk_menu_item_get_submenu(GTK_MENU_ITEM(menu));
      if (submenu && GTK_IS_MENU_SHELL(submenu)) {
        GList* items = gtk_container_get_children(GTK_CONTAINER(submenu));
        for (GList* iter = items; iter; iter = iter->next) {
          GtkWidget* child = GTK_WIDGET(iter->data);
          int child_id = RegisterDbusMenuItem(child);
          g_variant_builder_add(&children, "v", BuildDbusMenuLayout(child, child_id));
        }
        g_list_free(items);
      }
    } else if (menu && GTK_IS_MENU_SHELL(menu)) {
      dbusmenu_items_.clear();
      GList* items = gtk_container_get_children(GTK_CONTAINER(menu));
      for (GList* iter = items; iter; iter = iter->next) {
        GtkWidget* child = GTK_WIDGET(iter->data);
        int child_id = RegisterDbusMenuItem(child);
        g_variant_builder_add(&children, "v", BuildDbusMenuLayout(child, child_id));
      }
      g_list_free(items);
    }

    return g_variant_new("(i@a{sv}@av)", item_id, g_variant_builder_end(&props),
                         g_variant_builder_end(&children));
  }

  GVariant* BuildDbusMenuProperties(int id) {
    GVariantBuilder props;
    g_variant_builder_init(&props, G_VARIANT_TYPE("a{sv}"));
    auto it = dbusmenu_items_.find(id);
    if (it != dbusmenu_items_.end()) {
      AppendMenuItemProperties(&props, it->second);
    }
    return g_variant_new("(i@a{sv})", id, g_variant_builder_end(&props));
  }

  void ActivateDbusMenuItem(int id) {
    auto it = dbusmenu_items_.find(id);
    if (it == dbusmenu_items_.end() || !it->second || !GTK_IS_MENU_ITEM(it->second)) {
      return;
    }
    gtk_menu_item_activate(GTK_MENU_ITEM(it->second));
  }

  static void OnMenuMethodCall(GDBusConnection*, const gchar*, const gchar*, const gchar*,
                               const gchar* method_name, GVariant* parameters,
                               GDBusMethodInvocation* invocation, gpointer user_data) {
    Impl* self = static_cast<Impl*>(user_data);
    if (!self) {
      g_dbus_method_invocation_return_error(invocation, G_DBUS_ERROR, G_DBUS_ERROR_FAILED,
                                             "Internal error");
      return;
    }

    if (g_strcmp0(method_name, "GetLayout") == 0) {
      gint parent_id = 0;
      if (parameters) {
        gint recursion_depth = -1;
        GVariantIter* property_names = nullptr;
        g_variant_get(parameters, "(iias)", &parent_id, &recursion_depth, &property_names);
        if (property_names) {
          g_variant_iter_free(property_names);
        }
      }

      GtkWidget* menu = self->context_menu_
                            ? static_cast<GtkWidget*>(self->context_menu_->GetNativeObject())
                            : nullptr;
      if (parent_id != 0) {
        auto it = self->dbusmenu_items_.find(parent_id);
        menu = it != self->dbusmenu_items_.end() ? it->second : nullptr;
      }
      g_dbus_method_invocation_return_value(
          invocation,
          g_variant_new("(u@(ia{sv}av))", self->menu_revision_,
                        self->BuildDbusMenuLayout(menu, parent_id)));
      return;
    }

    if (g_strcmp0(method_name, "GetGroupProperties") == 0) {
      GVariantIter* ids = nullptr;
      GVariantIter* property_names = nullptr;
      if (parameters) {
        g_variant_get(parameters, "(aias)", &ids, &property_names);
      }

      GVariantBuilder result;
      g_variant_builder_init(&result, G_VARIANT_TYPE("a(ia{sv})"));
      if (ids) {
        gint item_id = 0;
        while (g_variant_iter_loop(ids, "i", &item_id)) {
          g_variant_builder_add_value(&result, self->BuildDbusMenuProperties(item_id));
        }
        g_variant_iter_free(ids);
      }
      if (property_names) {
        g_variant_iter_free(property_names);
      }
      g_dbus_method_invocation_return_value(invocation,
                                             g_variant_new("(@a(ia{sv}))",
                                                           g_variant_builder_end(&result)));
      return;
    }

    if (g_strcmp0(method_name, "GetProperty") == 0) {
      gint item_id = 0;
      const gchar* name = nullptr;
      if (parameters) {
        g_variant_get(parameters, "(i&s)", &item_id, &name);
      }

      GVariantBuilder props;
      g_variant_builder_init(&props, G_VARIANT_TYPE("a{sv}"));
      auto it = self->dbusmenu_items_.find(item_id);
      if (it != self->dbusmenu_items_.end()) {
        self->AppendMenuItemProperties(&props, it->second);
      }
      GVariant* props_variant = g_variant_builder_end(&props);
      GVariant* value = g_variant_lookup_value(props_variant, name ? name : "", nullptr);
      g_variant_unref(props_variant);
      g_dbus_method_invocation_return_value(
          invocation,
          g_variant_new("(@v)", value ? g_variant_new_variant(value)
                                      : g_variant_new_variant(g_variant_new_string(""))));
      if (value) {
        g_variant_unref(value);
      }
      return;
    }

    if (g_strcmp0(method_name, "Event") == 0) {
      gint item_id = 0;
      const gchar* event_id = nullptr;
      GVariant* data = nullptr;
      guint timestamp = 0;
      if (parameters) {
        g_variant_get(parameters, "(i&svu)", &item_id, &event_id, &data, &timestamp);
        if (data) {
          g_variant_unref(data);
        }
      }
      if (event_id && (g_strcmp0(event_id, "clicked") == 0 ||
                       g_strcmp0(event_id, "activated") == 0)) {
        self->ActivateDbusMenuItem(item_id);
      }
      g_dbus_method_invocation_return_value(invocation, nullptr);
      return;
    }

    if (g_strcmp0(method_name, "EventGroup") == 0) {
      GVariantIter* events = nullptr;
      if (parameters) {
        g_variant_get(parameters, "(a(isvu))", &events);
      }
      if (events) {
        gint item_id = 0;
        const gchar* event_id = nullptr;
        GVariant* data = nullptr;
        guint timestamp = 0;
        while (g_variant_iter_loop(events, "(i&svu)", &item_id, &event_id, &data, &timestamp)) {
          if (event_id && (g_strcmp0(event_id, "clicked") == 0 ||
                           g_strcmp0(event_id, "activated") == 0)) {
            self->ActivateDbusMenuItem(item_id);
          }
        }
        g_variant_iter_free(events);
      }

      GVariantBuilder errors;
      g_variant_builder_init(&errors, G_VARIANT_TYPE("ai"));
      g_dbus_method_invocation_return_value(invocation,
                                             g_variant_new("(@ai)",
                                                           g_variant_builder_end(&errors)));
      return;
    }

    if (g_strcmp0(method_name, "AboutToShow") == 0) {
      g_dbus_method_invocation_return_value(invocation, g_variant_new("(b)", FALSE));
      return;
    }

    if (g_strcmp0(method_name, "AboutToShowGroup") == 0) {
      GVariantBuilder updates;
      GVariantBuilder errors;
      g_variant_builder_init(&updates, G_VARIANT_TYPE("ai"));
      g_variant_builder_init(&errors, G_VARIANT_TYPE("ai"));
      g_dbus_method_invocation_return_value(
          invocation, g_variant_new("(@ai@ai)", g_variant_builder_end(&updates),
                                    g_variant_builder_end(&errors)));
      return;
    }

    g_dbus_method_invocation_return_error(invocation, G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_METHOD,
                                           "Unknown dbusmenu method: %s", method_name);
  }

  static GVariant* OnMenuGetProperty(GDBusConnection*, const gchar*, const gchar*, const gchar*,
                                     const gchar* property_name, GError** error,
                                     gpointer user_data) {
    if (g_strcmp0(property_name, "Version") == 0) return g_variant_new_uint32(3);
    if (g_strcmp0(property_name, "TextDirection") == 0) return g_variant_new_string("ltr");
    if (g_strcmp0(property_name, "Status") == 0) return g_variant_new_string("normal");
    if (g_strcmp0(property_name, "IconThemePath") == 0) {
      GVariantBuilder paths;
      g_variant_builder_init(&paths, G_VARIANT_TYPE("as"));
      return g_variant_builder_end(&paths);
    }

    if (error) {
      *error = g_error_new(G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_PROPERTY,
                           "Unknown dbusmenu property: %s", property_name);
    }
    return nullptr;
  }
};

// ── TrayIcon public interface ─────────────────────────────────────────────────

TrayIcon::TrayIcon() : pimpl_(std::make_unique<Impl>(this)) {
  if (pimpl_->Init()) {
    pimpl_->visible_ = true;
  } else {
    std::cerr << "[nativeapi] TrayIcon: D-Bus initialisation failed; icon will not appear"
              << std::endl;
  }
}

TrayIcon::TrayIcon(void* /*tray*/) : pimpl_(std::make_unique<Impl>(this)) {
  // For API compatibility; create a fresh SNI tray icon ignoring the raw pointer.
  if (pimpl_->Init()) {
    pimpl_->visible_ = true;
  } else {
    std::cerr << "[nativeapi] TrayIcon: D-Bus initialisation failed; icon will not appear"
              << std::endl;
  }
}

TrayIcon::~TrayIcon() {
  // Impl::~Impl calls Cleanup(), which unregisters the D-Bus object and
  // releases the connection before pimpl_ is destroyed.
}

TrayIconId TrayIcon::GetId() {
  return pimpl_->id_;
}

void TrayIcon::SetIcon(std::shared_ptr<Image> image) {
  pimpl_->image_ = image;
  pimpl_->EmitSignal("NewIcon");
}

std::shared_ptr<Image> TrayIcon::GetIcon() const {
  return pimpl_->image_;
}

void TrayIcon::SetTitle(std::optional<std::string> title) {
  pimpl_->title_ = title;
  pimpl_->EmitSignal("NewTitle");
}

std::optional<std::string> TrayIcon::GetTitle() {
  return pimpl_->title_;
}

void TrayIcon::SetTooltip(std::optional<std::string> tooltip) {
  pimpl_->tooltip_ = tooltip;
  pimpl_->EmitSignal("NewToolTip");
}

std::optional<std::string> TrayIcon::GetTooltip() {
  return pimpl_->tooltip_;
}

void TrayIcon::SetContextMenu(std::shared_ptr<Menu> menu) {
  pimpl_->context_menu_ = menu;
  ++pimpl_->menu_revision_;
  pimpl_->EmitSignal("NewStatus",
                     g_variant_new("(s)", pimpl_->visible_ ? "Active" : "Passive"));
  pimpl_->EmitMenuPropertiesChanged();
  if (pimpl_->connection_ && pimpl_->menu_registration_id_ != 0) {
    g_dbus_connection_emit_signal(pimpl_->connection_, nullptr, "/StatusNotifierItem/Menu",
                                  "com.canonical.dbusmenu", "LayoutUpdated",
                                  g_variant_new("(ui)", pimpl_->menu_revision_, 0), nullptr);
  }
}

std::shared_ptr<Menu> TrayIcon::GetContextMenu() {
  return pimpl_->context_menu_;
}

Rectangle TrayIcon::GetBounds() {
  // The SNI specification does not expose icon geometry; return empty bounds.
  return {0, 0, 0, 0};
}

bool TrayIcon::SetVisible(bool visible) {
  pimpl_->visible_ = visible;
  const char* status = visible ? "Active" : "Passive";
  pimpl_->EmitSignal("NewStatus", g_variant_new("(s)", status));
  return true;
}

bool TrayIcon::IsVisible() {
  return pimpl_->visible_;
}

bool TrayIcon::OpenContextMenu() {
  return false;
}

bool TrayIcon::CloseContextMenu() {
  return true;
}

void TrayIcon::SetContextMenuTrigger(ContextMenuTrigger trigger) {
  pimpl_->context_menu_trigger_ = trigger;
  pimpl_->EmitSignal("NewStatus",
                     g_variant_new("(s)", pimpl_->visible_ ? "Active" : "Passive"));
  pimpl_->EmitMenuPropertiesChanged();
}

ContextMenuTrigger TrayIcon::GetContextMenuTrigger() {
  return pimpl_->context_menu_trigger_;
}

void* TrayIcon::GetNativeObjectInternal() const {
  return static_cast<void*>(pimpl_->connection_);
}

void TrayIcon::StartEventListening() {
  // GDBus dispatches D-Bus method calls via the GLib main loop automatically.
}

void TrayIcon::StopEventListening() {
  // Nothing to tear down; GDBus uses the GLib main loop.
}

}  // namespace nativeapi
