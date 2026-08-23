#include <gtk/gtk.h>
#include <algorithm>
#include <cctype>
#include <iostream>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>
#include "../../foundation/id_allocator.h"
#include "../../image.h"
#include "../../menu.h"
#include "../../window.h"

namespace nativeapi {

// GTK signal handlers → Event emission
static void OnGtkMenuItemActivate(GtkMenuItem* /*item*/, gpointer user_data) {
  MenuItem* menu_item = static_cast<MenuItem*>(user_data);
  if (!menu_item) {
    return;
  }
  menu_item->Emit(MenuItemClickedEvent(menu_item->GetId()));
}

// For checkbox and radio items we listen to "toggled" to avoid recursive
// activate emissions when GTK internally updates group state. For radio items,
// we only emit when the item becomes active.
static void OnGtkCheckMenuItemToggled(GtkCheckMenuItem* item, gpointer user_data) {
  MenuItem* menu_item = static_cast<MenuItem*>(user_data);
  if (!menu_item) {
    return;
  }
  gboolean active = gtk_check_menu_item_get_active(item);
  if (menu_item->GetType() == MenuItemType::Radio) {
    if (active) {
      menu_item->Emit(MenuItemClickedEvent(menu_item->GetId()));
    }
  } else {
    // Checkbox: emit on any toggle
    menu_item->Emit(MenuItemClickedEvent(menu_item->GetId()));
  }
}

static void OnGtkMenuMap(GtkWidget* /*menu*/, gpointer user_data) {
  Menu* menu_obj = static_cast<Menu*>(user_data);
  if (!menu_obj) {
    return;
  }
  menu_obj->Emit(MenuOpenedEvent(menu_obj->GetId()));
}

static void OnGtkMenuUnmap(GtkWidget* /*menu*/, gpointer user_data) {
  Menu* menu_obj = static_cast<Menu*>(user_data);
  if (!menu_obj) {
    return;
  }
  menu_obj->Emit(MenuClosedEvent(menu_obj->GetId()));
}

static void OnGtkSubmenuMap(GtkWidget* /*submenu*/, gpointer user_data) {
  MenuItem* menu_item = static_cast<MenuItem*>(user_data);
  if (!menu_item) {
    return;
  }
  // Emit submenu opened on the item
  menu_item->Emit(MenuItemSubmenuOpenedEvent(menu_item->GetId()));
}

static void OnGtkSubmenuUnmap(GtkWidget* /*submenu*/, gpointer user_data) {
  MenuItem* menu_item = static_cast<MenuItem*>(user_data);
  if (!menu_item) {
    return;
  }
  // Emit submenu closed on the item
  menu_item->Emit(MenuItemSubmenuClosedEvent(menu_item->GetId()));
}

// Private implementation class for MenuItem
class MenuItem::Impl {
 public:
  Impl(MenuItemId id, GtkWidget* menu_item, MenuItemType type)
      : id_(id),
        gtk_menu_item_(menu_item),
        title_(""),
        tooltip_(""),
        type_(type),
        state_(MenuItemState::Unchecked),
        radio_group_(-1),
        accelerator_("", ModifierKey::None),
        activate_handler_id_(0),
        toggled_handler_id_(0) {}

  void ApplyRadioGroup() {
    if (!gtk_menu_item_ || type_ != MenuItemType::Radio || radio_group_ < 0) {
      return;
    }

    std::lock_guard<std::mutex> lock(s_group_map_mutex_);

    GSList* target_group = nullptr;
    auto it = s_group_map_.find(radio_group_);
    if (it != s_group_map_.end()) {
      target_group = it->second;
    } else {
      target_group = gtk_radio_menu_item_get_group(GTK_RADIO_MENU_ITEM(gtk_menu_item_));
      s_group_map_[radio_group_] = target_group;
    }

    gtk_radio_menu_item_set_group(GTK_RADIO_MENU_ITEM(gtk_menu_item_), target_group);

    // Update stored head pointer after potential re-linking
    s_group_map_[radio_group_] = gtk_radio_menu_item_get_group(GTK_RADIO_MENU_ITEM(gtk_menu_item_));
  }

  MenuItemId id_;
  GtkWidget* gtk_menu_item_;
  std::optional<std::string> title_;
  std::shared_ptr<Image> image_;
  std::optional<std::string> tooltip_;
  MenuItemType type_;
  MenuItemState state_;
  int radio_group_;
  KeyboardAccelerator accelerator_;
  std::shared_ptr<Menu> submenu_;

  // Signal handler IDs for cleanup
  gulong activate_handler_id_;
  gulong toggled_handler_id_;

  // Shared map from logical group id to GTK group list
  static std::unordered_map<int, GSList*> s_group_map_;
  static std::mutex s_group_map_mutex_;
};

// Static member definitions
std::unordered_map<int, GSList*> MenuItem::Impl::s_group_map_;
std::mutex MenuItem::Impl::s_group_map_mutex_;

MenuItem::MenuItem(const std::string& label, MenuItemType type) {
  MenuItemId id = IdAllocator::Allocate<MenuItem>();
  GtkWidget* gtk_item = nullptr;

  switch (type) {
    case MenuItemType::Separator:
      gtk_item = gtk_separator_menu_item_new();
      break;
    case MenuItemType::Checkbox:
      gtk_item = gtk_check_menu_item_new_with_label(label.c_str());
      break;
    case MenuItemType::Radio:
      gtk_item = gtk_radio_menu_item_new_with_label(nullptr, label.c_str());
      break;
    case MenuItemType::Normal:
    case MenuItemType::Submenu:
    default:
      gtk_item = gtk_menu_item_new_with_label(label.c_str());
      break;
  }

  pimpl_ = std::unique_ptr<Impl>(new Impl(id, gtk_item, type));

  if (!label.empty()) {
    pimpl_->title_ = label;
  } else {
    pimpl_->title_.reset();
  }

  // Connect signals for click/toggle events (except separators)
  if (gtk_item && type != MenuItemType::Separator) {
    if (type == MenuItemType::Checkbox || type == MenuItemType::Radio) {
      pimpl_->toggled_handler_id_ = g_signal_connect(G_OBJECT(gtk_item), "toggled",
                                                     G_CALLBACK(OnGtkCheckMenuItemToggled), this);
    } else {
      pimpl_->activate_handler_id_ =
          g_signal_connect(G_OBJECT(gtk_item), "activate", G_CALLBACK(OnGtkMenuItemActivate), this);
    }
  }
}

MenuItem::MenuItem(void* menu_item) {
  MenuItemId id = IdAllocator::Allocate<MenuItem>();
  pimpl_ = std::unique_ptr<Impl>(new Impl(id, (GtkWidget*)menu_item, MenuItemType::Normal));
  if (pimpl_->gtk_menu_item_ && pimpl_->type_ != MenuItemType::Separator) {
    const char* label = gtk_menu_item_get_label(GTK_MENU_ITEM(pimpl_->gtk_menu_item_));
    if (label && label[0] != '\0') {
      pimpl_->title_ = std::string(label);
    } else {
      pimpl_->title_.reset();
    }
  }

  if (pimpl_->gtk_menu_item_) {
    if (GTK_IS_CHECK_MENU_ITEM(pimpl_->gtk_menu_item_)) {
      pimpl_->toggled_handler_id_ = g_signal_connect(G_OBJECT(pimpl_->gtk_menu_item_), "toggled",
                                                     G_CALLBACK(OnGtkCheckMenuItemToggled), this);
    } else {
      pimpl_->activate_handler_id_ = g_signal_connect(G_OBJECT(pimpl_->gtk_menu_item_), "activate",
                                                      G_CALLBACK(OnGtkMenuItemActivate), this);
    }
  }
}

MenuItem::~MenuItem() {
  // Disconnect signal handlers before destruction to prevent accessing freed memory
  if (pimpl_->gtk_menu_item_) {
    // Disconnect submenu map/unmap handlers first if they exist
    if (pimpl_->submenu_ && pimpl_->submenu_->GetNativeObject()) {
      GtkWidget* submenu_widget = (GtkWidget*)pimpl_->submenu_->GetNativeObject();
      if (submenu_widget && GTK_IS_WIDGET(submenu_widget)) {
        g_signal_handlers_disconnect_by_func(G_OBJECT(submenu_widget), (gpointer)OnGtkSubmenuMap,
                                             this);
        g_signal_handlers_disconnect_by_func(G_OBJECT(submenu_widget), (gpointer)OnGtkSubmenuUnmap,
                                             this);
      }
    }

    // Disconnect item-specific signal handlers
    if (pimpl_->activate_handler_id_ > 0) {
      g_signal_handler_disconnect(G_OBJECT(pimpl_->gtk_menu_item_), pimpl_->activate_handler_id_);
      pimpl_->activate_handler_id_ = 0;
    }
    if (pimpl_->toggled_handler_id_ > 0) {
      g_signal_handler_disconnect(G_OBJECT(pimpl_->gtk_menu_item_), pimpl_->toggled_handler_id_);
      pimpl_->toggled_handler_id_ = 0;
    }

    // Note: We don't destroy the gtk_menu_item_ here because it's owned by the parent Menu
    // and will be destroyed when the Menu container is destroyed
  }
}

MenuItemId MenuItem::GetId() const {
  return pimpl_->id_;
}

MenuItemType MenuItem::GetType() const {
  return pimpl_->type_;
}

void MenuItem::SetLabel(const std::optional<std::string>& label) {
  pimpl_->title_ = label;
  if (pimpl_->gtk_menu_item_ && pimpl_->type_ != MenuItemType::Separator) {
    const char* labelStr = label.has_value() ? label->c_str() : "";

    // Check if we have a custom box layout (with icon)
    GtkWidget* child = gtk_bin_get_child(GTK_BIN(pimpl_->gtk_menu_item_));
    if (child && GTK_IS_BOX(child)) {
      // Custom layout with icon - find the label widget and update it
      GList* children = gtk_container_get_children(GTK_CONTAINER(child));
      for (GList* iter = children; iter != nullptr; iter = iter->next) {
        GtkWidget* widget = GTK_WIDGET(iter->data);
        if (GTK_IS_LABEL(widget)) {
          gtk_label_set_text(GTK_LABEL(widget), labelStr);
          break;
        }
      }
      g_list_free(children);
    } else {
      // Simple label-only layout
      gtk_menu_item_set_label(GTK_MENU_ITEM(pimpl_->gtk_menu_item_), labelStr);
    }
  }
}

std::optional<std::string> MenuItem::GetLabel() const {
  return pimpl_->title_;
}

void MenuItem::SetIcon(std::shared_ptr<Image> image) {
  pimpl_->image_ = image;

  if (!pimpl_->gtk_menu_item_ || pimpl_->type_ == MenuItemType::Separator) {
    return;
  }

  // Get current label text to preserve it - prefer stored title over GTK widget
  std::string current_label;
  if (pimpl_->title_.has_value()) {
    current_label = pimpl_->title_.value();
  } else {
    // Fallback to GTK widget if title not set
    const char* label_text = gtk_menu_item_get_label(GTK_MENU_ITEM(pimpl_->gtk_menu_item_));
    current_label = label_text ? label_text : "";
  }

  // Remove existing child widget
  GtkWidget* existing_child = gtk_bin_get_child(GTK_BIN(pimpl_->gtk_menu_item_));
  if (existing_child) {
    gtk_container_remove(GTK_CONTAINER(pimpl_->gtk_menu_item_), existing_child);
  }

  if (image && image->GetNativeObject()) {
    // Create a horizontal box to hold icon and label
    GtkWidget* box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);  // 6px spacing

    // Get the GdkPixbuf from the image
    GdkPixbuf* pixbuf = static_cast<GdkPixbuf*>(image->GetNativeObject());

    // Scale the icon to a reasonable menu size (16x16 is standard for menu items)
    const int icon_size = 16;
    GdkPixbuf* scaled_pixbuf = nullptr;

    int original_width = gdk_pixbuf_get_width(pixbuf);
    int original_height = gdk_pixbuf_get_height(pixbuf);

    if (original_width != icon_size || original_height != icon_size) {
      scaled_pixbuf = gdk_pixbuf_scale_simple(pixbuf, icon_size, icon_size, GDK_INTERP_BILINEAR);
    } else {
      scaled_pixbuf = gdk_pixbuf_copy(pixbuf);
    }

    // Create GtkImage from the pixbuf
    GtkWidget* gtk_image = gtk_image_new_from_pixbuf(scaled_pixbuf);
    g_object_unref(scaled_pixbuf);  // GtkImage takes its own reference

    // Create label widget
    GtkWidget* label = gtk_label_new(current_label.c_str());
    gtk_label_set_xalign(GTK_LABEL(label), 0.0);  // Left-align the label

    // Pack icon and label into box
    gtk_box_pack_start(GTK_BOX(box), gtk_image, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(box), label, TRUE, TRUE, 0);

    // Add box to menu item
    gtk_container_add(GTK_CONTAINER(pimpl_->gtk_menu_item_), box);
    gtk_widget_show_all(box);
  } else {
    // No icon - restore simple label display
    GtkWidget* label = gtk_label_new(current_label.c_str());
    gtk_label_set_xalign(GTK_LABEL(label), 0.0);
    gtk_container_add(GTK_CONTAINER(pimpl_->gtk_menu_item_), label);
    gtk_widget_show(label);
  }
}

std::shared_ptr<Image> MenuItem::GetIcon() const {
  return pimpl_->image_;
}

void MenuItem::SetTooltip(const std::optional<std::string>& tooltip) {
  pimpl_->tooltip_ = tooltip;
  if (pimpl_->gtk_menu_item_) {
    if (tooltip.has_value()) {
      gtk_widget_set_tooltip_text(pimpl_->gtk_menu_item_, tooltip->c_str());
    } else {
      gtk_widget_set_tooltip_text(pimpl_->gtk_menu_item_, nullptr);
    }
  }
}

std::optional<std::string> MenuItem::GetTooltip() const {
  return pimpl_->tooltip_;
}

void MenuItem::SetAccelerator(const std::optional<KeyboardAccelerator>& accelerator) {
  if (accelerator.has_value()) {
    pimpl_->accelerator_ = *accelerator;
  } else {
    pimpl_->accelerator_ = KeyboardAccelerator("", ModifierKey::None);
  }
  // TODO: Implement GTK accelerator setting
}

KeyboardAccelerator MenuItem::GetAccelerator() const {
  return pimpl_->accelerator_;
}

void MenuItem::SetEnabled(bool enabled) {
  if (pimpl_->gtk_menu_item_) {
    gtk_widget_set_sensitive(pimpl_->gtk_menu_item_, enabled ? TRUE : FALSE);
  }
}

bool MenuItem::IsEnabled() const {
  if (pimpl_->gtk_menu_item_) {
    return gtk_widget_get_sensitive(pimpl_->gtk_menu_item_) == TRUE;
  }
  return true;
}

void MenuItem::SetState(MenuItemState state) {
  pimpl_->state_ = state;
  if (pimpl_->gtk_menu_item_) {
    if (pimpl_->type_ == MenuItemType::Checkbox) {
      // Update checked state
      gboolean active = (state == MenuItemState::Checked) ? TRUE : FALSE;
      // Block the "toggled" signal to prevent recursive triggering when setting active
      g_signal_handlers_block_by_func(G_OBJECT(pimpl_->gtk_menu_item_),
                                      (gpointer)OnGtkCheckMenuItemToggled, this);
      gtk_check_menu_item_set_active(GTK_CHECK_MENU_ITEM(pimpl_->gtk_menu_item_), active);
      g_signal_handlers_unblock_by_func(G_OBJECT(pimpl_->gtk_menu_item_),
                                        (gpointer)OnGtkCheckMenuItemToggled, this);

      // Reflect tri-state (Mixed) visually using GTK's inconsistent state
      gtk_check_menu_item_set_inconsistent(GTK_CHECK_MENU_ITEM(pimpl_->gtk_menu_item_),
                                           (state == MenuItemState::Mixed) ? TRUE : FALSE);
    } else if (pimpl_->type_ == MenuItemType::Radio) {
      gboolean active = (state == MenuItemState::Checked) ? TRUE : FALSE;
      // Block the "toggled" signal to prevent recursive triggering
      g_signal_handlers_block_by_func(G_OBJECT(pimpl_->gtk_menu_item_),
                                      (gpointer)OnGtkCheckMenuItemToggled, this);
      gtk_check_menu_item_set_active(GTK_CHECK_MENU_ITEM(pimpl_->gtk_menu_item_), active);
      g_signal_handlers_unblock_by_func(G_OBJECT(pimpl_->gtk_menu_item_),
                                        (gpointer)OnGtkCheckMenuItemToggled, this);
    }
  }
}

MenuItemState MenuItem::GetState() const {
  // For checkbox and radio items, get the actual state from GTK widget
  if (pimpl_->gtk_menu_item_ &&
      (pimpl_->type_ == MenuItemType::Checkbox || pimpl_->type_ == MenuItemType::Radio)) {
    if (pimpl_->type_ == MenuItemType::Checkbox) {
      // If inconsistent is set, treat as Mixed regardless of active
      gboolean inconsistent =
          gtk_check_menu_item_get_inconsistent(GTK_CHECK_MENU_ITEM(pimpl_->gtk_menu_item_));
      if (inconsistent) {
        return MenuItemState::Mixed;
      }
    }

    gboolean active = gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(pimpl_->gtk_menu_item_));
    return active ? MenuItemState::Checked : MenuItemState::Unchecked;
  }
  return pimpl_->state_;
}

void MenuItem::SetRadioGroup(int group_id) {
  pimpl_->radio_group_ = group_id;
  pimpl_->ApplyRadioGroup();
}

int MenuItem::GetRadioGroup() const {
  return pimpl_->radio_group_;
}

void MenuItem::SetSubmenu(std::shared_ptr<Menu> submenu) {
  pimpl_->submenu_ = submenu;
  if (pimpl_->gtk_menu_item_ && submenu) {
    gtk_menu_item_set_submenu(GTK_MENU_ITEM(pimpl_->gtk_menu_item_),
                              (GtkWidget*)submenu->GetNativeObject());

    // Emit submenu open/close events on the parent item when submenu
    // maps/unmaps (actual visibility on screen)
    GtkWidget* submenu_widget = (GtkWidget*)submenu->GetNativeObject();
    if (submenu_widget) {
      g_signal_connect(G_OBJECT(submenu_widget), "map", G_CALLBACK(OnGtkSubmenuMap), this);
      g_signal_connect(G_OBJECT(submenu_widget), "unmap", G_CALLBACK(OnGtkSubmenuUnmap), this);
    }
  }
}

std::shared_ptr<Menu> MenuItem::GetSubmenu() const {
  return pimpl_->submenu_;
}

void* MenuItem::GetNativeObjectInternal() const {
  return (void*)pimpl_->gtk_menu_item_;
}

// Private implementation class for Menu
class Menu::Impl {
 public:
  Impl(MenuId id, GtkWidget* menu)
      : id_(id), gtk_menu_(menu), map_handler_id_(0), unmap_handler_id_(0) {}

  MenuId id_;
  GtkWidget* gtk_menu_;
  std::vector<std::shared_ptr<MenuItem>> items_;

  // Signal handler IDs for cleanup
  gulong map_handler_id_;
  gulong unmap_handler_id_;
};

Menu::Menu() {
  MenuId id = IdAllocator::Allocate<Menu>();
  pimpl_ = std::unique_ptr<Impl>(new Impl(id, gtk_menu_new()));
  // Connect menu map/unmap to emit open/close events when actually visible
  if (pimpl_->gtk_menu_) {
    pimpl_->map_handler_id_ =
        g_signal_connect(G_OBJECT(pimpl_->gtk_menu_), "map", G_CALLBACK(OnGtkMenuMap), this);
    pimpl_->unmap_handler_id_ =
        g_signal_connect(G_OBJECT(pimpl_->gtk_menu_), "unmap", G_CALLBACK(OnGtkMenuUnmap), this);
  }
}

Menu::Menu(void* menu) {
  MenuId id = IdAllocator::Allocate<Menu>();
  pimpl_ = std::unique_ptr<Impl>(new Impl(id, (GtkWidget*)menu));
  if (pimpl_->gtk_menu_) {
    pimpl_->map_handler_id_ =
        g_signal_connect(G_OBJECT(pimpl_->gtk_menu_), "map", G_CALLBACK(OnGtkMenuMap), this);
    pimpl_->unmap_handler_id_ =
        g_signal_connect(G_OBJECT(pimpl_->gtk_menu_), "unmap", G_CALLBACK(OnGtkMenuUnmap), this);
  }
}

Menu::~Menu() {
  // Disconnect signal handlers and properly clean up GTK widget
  if (pimpl_->gtk_menu_) {
    // Ensure menu is closed before destroying to prevent processing events on freed widget
    if (gtk_widget_get_visible(pimpl_->gtk_menu_)) {
      gtk_menu_popdown(GTK_MENU(pimpl_->gtk_menu_));
    }

    // Disconnect signal handlers before destroying to prevent accessing freed memory
    if (pimpl_->map_handler_id_ > 0) {
      g_signal_handler_disconnect(G_OBJECT(pimpl_->gtk_menu_), pimpl_->map_handler_id_);
      pimpl_->map_handler_id_ = 0;
    }
    if (pimpl_->unmap_handler_id_ > 0) {
      g_signal_handler_disconnect(G_OBJECT(pimpl_->gtk_menu_), pimpl_->unmap_handler_id_);
      pimpl_->unmap_handler_id_ = 0;
    }

    // Use gtk_widget_destroy() instead of g_object_unref() to properly clean up
    // the widget hierarchy and ensure all pending events are handled before destruction
    gtk_widget_destroy(pimpl_->gtk_menu_);
    pimpl_->gtk_menu_ = nullptr;
  }
}

MenuId Menu::GetId() const {
  return pimpl_->id_;
}

void Menu::AddItem(std::shared_ptr<MenuItem> item) {
  if (pimpl_->gtk_menu_ && item && item->GetNativeObject()) {
    pimpl_->items_.push_back(item);
    gtk_menu_shell_append(GTK_MENU_SHELL(pimpl_->gtk_menu_), (GtkWidget*)item->GetNativeObject());
  }
}

void Menu::InsertItem(size_t index, std::shared_ptr<MenuItem> item) {
  if (!item)
    return;

  if (index >= pimpl_->items_.size()) {
    AddItem(item);
    return;
  }

  pimpl_->items_.insert(pimpl_->items_.begin() + index, item);
  if (pimpl_->gtk_menu_ && item->GetNativeObject()) {
    gtk_menu_shell_insert(GTK_MENU_SHELL(pimpl_->gtk_menu_), (GtkWidget*)item->GetNativeObject(),
                          index);
  }
}

bool Menu::RemoveItem(std::shared_ptr<MenuItem> item) {
  if (pimpl_->gtk_menu_ && item && item->GetNativeObject()) {
    auto it = std::find(pimpl_->items_.begin(), pimpl_->items_.end(), item);
    if (it != pimpl_->items_.end()) {
      pimpl_->items_.erase(it);
      gtk_container_remove(GTK_CONTAINER(pimpl_->gtk_menu_), (GtkWidget*)item->GetNativeObject());
      return true;
    }
  }
  return false;
}

bool Menu::RemoveItemById(MenuItemId item_id) {
  for (auto& item : pimpl_->items_) {
    if (item->GetId() == item_id) {
      return RemoveItem(item);
    }
  }
  return false;
}

bool Menu::RemoveItemAt(size_t index) {
  if (index < pimpl_->items_.size()) {
    auto item = pimpl_->items_[index];
    return RemoveItem(item);
  }
  return false;
}

void Menu::Clear() {
  while (!pimpl_->items_.empty()) {
    RemoveItem(pimpl_->items_.back());
  }
}

void Menu::AddSeparator() {
  auto separator = std::make_shared<MenuItem>("", MenuItemType::Separator);
  AddItem(separator);
}

void Menu::InsertSeparator(size_t index) {
  auto separator = std::make_shared<MenuItem>("", MenuItemType::Separator);
  InsertItem(index, separator);
}

size_t Menu::GetItemCount() const {
  return pimpl_->items_.size();
}

std::shared_ptr<MenuItem> Menu::GetItemAt(size_t index) const {
  if (index < pimpl_->items_.size()) {
    return pimpl_->items_[index];
  }
  return nullptr;
}

std::shared_ptr<MenuItem> Menu::GetItemById(MenuItemId item_id) const {
  for (const auto& item : pimpl_->items_) {
    if (item->GetId() == item_id) {
      return item;
    }
  }
  return nullptr;
}

std::vector<std::shared_ptr<MenuItem>> Menu::GetAllItems() const {
  return pimpl_->items_;
}

bool Menu::Open(const PositioningStrategy& strategy, Placement placement) {
  // Ensure GTK operations run on the main thread (owner of default GMainContext)
  if (!g_main_context_is_owner(g_main_context_default())) {
    struct OpenInvokeData {
      Menu* self;
      PositioningStrategy strategy;
      Placement placement;
      bool result;
      GMutex mutex;
      GCond cond;
      bool done;
    } data{this, strategy, placement, false};

    g_mutex_init(&data.mutex);
    g_cond_init(&data.cond);
    data.done = false;

    g_mutex_lock(&data.mutex);
    g_main_context_invoke(
        nullptr,
        [](gpointer user_data) -> gboolean {
          OpenInvokeData* d = static_cast<OpenInvokeData*>(user_data);
          bool r = d->self->Open(d->strategy, d->placement);
          g_mutex_lock(&d->mutex);
          d->result = r;
          d->done = true;
          g_cond_signal(&d->cond);
          g_mutex_unlock(&d->mutex);
          return G_SOURCE_REMOVE;
        },
        &data);

    while (!data.done) {
      g_cond_wait(&data.cond, &data.mutex);
    }
    g_mutex_unlock(&data.mutex);
    g_cond_clear(&data.cond);
    g_mutex_clear(&data.mutex);
    return data.result;
  }

  if (!pimpl_->gtk_menu_) {
    return false;
  }

  gtk_widget_show_all(pimpl_->gtk_menu_);

  // Get GdkWindow from relative window if available, otherwise use root window
  GdkWindow* gdk_window = nullptr;
  const Window* relative_window = strategy.GetRelativeWindow();
  if (relative_window) {
    void* native_obj = relative_window->GetNativeObject();
    if (native_obj) {
      gdk_window = static_cast<GdkWindow*>(native_obj);
    }
  }
  if (!gdk_window) {
    gdk_window = gdk_get_default_root_window();
  }
  if (!gdk_window) {
    // No window available (e.g., Wayland without root window) → cannot show
    return false;
  }

  GdkRectangle rectangle;

  switch (strategy.GetType()) {
    case PositioningStrategy::Type::Absolute:
      // Linux does not support Absolute positioning strategy
      std::cerr << "Warning: Absolute positioning strategy is not supported on Linux" << std::endl;
      return false;

    case PositioningStrategy::Type::CursorPosition: {
      // Position relative to the window under the pointer to avoid coord space mismatches
      int x = 0, y = 0;
      GdkWindow* pointer_window = nullptr;
#if GTK_CHECK_VERSION(3, 20, 0)
      GdkDisplay* display = gdk_display_get_default();
      GdkSeat* seat = display ? gdk_display_get_default_seat(display) : nullptr;
      GdkDevice* pointer = seat ? gdk_seat_get_pointer(seat) : nullptr;
      if (pointer) {
        pointer_window = gdk_device_get_window_at_position(pointer, &x, &y);
      }
#else
      GdkDeviceManager* devman = gdk_display_get_device_manager(gdk_display_get_default());
      GdkDevice* pointer = gdk_device_manager_get_client_pointer(devman);
      if (pointer) {
        GdkScreen* screen = nullptr;
        gdk_device_get_position(pointer, &screen, &x, &y);  // screen coords
        pointer_window = gdk_get_default_root_window();
      }
#endif
      if (pointer_window) {
        gdk_window = pointer_window;  // ensure rect coords match this window
      } else if (!gdk_window) {
        gdk_window = gdk_get_default_root_window();
      }

      rectangle.x = x;
      rectangle.y = y;
      rectangle.width = 1;
      rectangle.height = 1;
      break;
    }

    case PositioningStrategy::Type::Relative: {
      // Relative positioning
      Rectangle rect = strategy.GetRelativeRectangle();
      Point offset = strategy.GetRelativeOffset();
      Point position = Point{rect.x + offset.x, rect.y + offset.y};

      // If we have a relative window, adjust for frame extents and title bar
      if (relative_window && relative_window->GetNativeObject()) {
        GdkRectangle frame_rectangle;
        gdk_window_get_frame_extents(gdk_window, &frame_rectangle);

        // Get GtkWindow for window position and title bar
        GtkWindow* gtk_window = nullptr;
        GList* toplevels = gtk_window_list_toplevels();
        for (GList* l = toplevels; l != nullptr; l = l->next) {
          GtkWindow* candidate = GTK_WINDOW(l->data);
          GdkWindow* candidate_gdk = gtk_widget_get_window(GTK_WIDGET(candidate));
          if (candidate_gdk == gdk_window) {
            gtk_window = candidate;
            break;
          }
        }
        g_list_free(toplevels);

        // Get window position using gtk_window_get_position (works better on Wayland)
        gint window_x = 0, window_y = 0;
        if (gtk_window) {
          gtk_window_get_position(gtk_window, &window_x, &window_y);
        } else {
          // Fallback to gdk_window_get_origin if gtk_window not found
          gdk_window_get_origin(gdk_window, &window_x, &window_y);
        }

        // Get title bar height from GtkWindow
        int title_bar_height = 0;
        if (gtk_window) {
          GtkWidget* titlebar = gtk_window_get_titlebar(gtk_window);
          if (titlebar) {
            title_bar_height = gtk_widget_get_allocated_height(titlebar);
          }
        }

        // Get device pixel ratio for DPI scaling
        double device_pixel_ratio = 1.0;
        GdkScreen* screen = gdk_window_get_screen(gdk_window);
        if (screen) {
          // Get scale factor (typically 1.0 for standard DPI, 2.0 for HiDPI)
          device_pixel_ratio = gdk_screen_get_resolution(screen) / 96.0;
          if (device_pixel_ratio <= 0.0) {
            device_pixel_ratio = 1.0;
          }
        }

        // Convert content-relative coordinates to window-relative coordinates
        // Apply DPI scaling, then adjust for window position and frame extents
        rectangle.x =
            static_cast<int>((position.x * device_pixel_ratio) + window_x - frame_rectangle.x);
        rectangle.y = static_cast<int>((position.y * device_pixel_ratio) + window_y -
                                       frame_rectangle.y + title_bar_height);
      } else {
        // Relative to rectangle (no window) - use root window coordinates
        rectangle.x = static_cast<int>(position.x);
        rectangle.y = static_cast<int>(position.y);
      }

      // Set rectangle dimensions
      rectangle.width = 1;
      rectangle.height = 1;
      break;
    }

    default:
      return false;
  }

  // Map placement to GDK gravity (menu anchor)
  GdkGravity menu_anchor = GDK_GRAVITY_NORTH_WEST;

  switch (placement) {
    case Placement::TopStart:
    case Placement::Top:
      menu_anchor = GDK_GRAVITY_SOUTH_WEST;
      break;
    case Placement::TopEnd:
      menu_anchor = GDK_GRAVITY_SOUTH_EAST;
      break;
    case Placement::BottomStart:
    case Placement::Bottom:
      menu_anchor = GDK_GRAVITY_NORTH_WEST;
      break;
    case Placement::BottomEnd:
      menu_anchor = GDK_GRAVITY_NORTH_EAST;
      break;
    case Placement::LeftStart:
    case Placement::Left:
      menu_anchor = GDK_GRAVITY_NORTH_EAST;
      break;
    case Placement::LeftEnd:
      menu_anchor = GDK_GRAVITY_SOUTH_EAST;
      break;
    case Placement::RightStart:
    case Placement::Right:
      menu_anchor = GDK_GRAVITY_NORTH_WEST;
      break;
    case Placement::RightEnd:
      menu_anchor = GDK_GRAVITY_SOUTH_WEST;
      break;
  }

  // Position menu using gtk_menu_popup_at_rect
  gtk_menu_popup_at_rect(GTK_MENU(pimpl_->gtk_menu_), gdk_window, &rectangle,
                         GDK_GRAVITY_NORTH_WEST, menu_anchor, nullptr);

  return true;
}

bool Menu::Close() {
  // Ensure GTK operations run on the main thread
  if (!g_main_context_is_owner(g_main_context_default())) {
    struct CloseInvokeData {
      Menu* self;
      bool result;
      GMutex mutex;
      GCond cond;
      bool done;
    } data{this, false};

    g_mutex_init(&data.mutex);
    g_cond_init(&data.cond);
    data.done = false;

    g_mutex_lock(&data.mutex);
    g_main_context_invoke(
        nullptr,
        [](gpointer user_data) -> gboolean {
          CloseInvokeData* d = static_cast<CloseInvokeData*>(user_data);
          bool r = d->self->Close();
          g_mutex_lock(&d->mutex);
          d->result = r;
          d->done = true;
          g_cond_signal(&d->cond);
          g_mutex_unlock(&d->mutex);
          return G_SOURCE_REMOVE;
        },
        &data);

    while (!data.done) {
      g_cond_wait(&data.cond, &data.mutex);
    }
    g_mutex_unlock(&data.mutex);
    g_cond_clear(&data.cond);
    g_mutex_clear(&data.mutex);
    return data.result;
  }

  if (pimpl_->gtk_menu_) {
    gtk_menu_popdown(GTK_MENU(pimpl_->gtk_menu_));
    return true;
  }
  return false;
}

void* Menu::GetNativeObjectInternal() const {
  return (void*)pimpl_->gtk_menu_;
}

}  // namespace nativeapi
