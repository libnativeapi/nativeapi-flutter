#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <vector>
#include "foundation/event.h"
#include "foundation/event_emitter.h"
#include "foundation/geometry.h"
#include "foundation/id_allocator.h"
#include "foundation/keyboard.h"
#include "foundation/native_object_provider.h"
#include "placement.h"
#include "positioning_strategy.h"

namespace nativeapi {

class Image;

typedef IdAllocator::IdType MenuId;
typedef IdAllocator::IdType MenuItemId;

/**
 * @brief Enumeration of different menu item types.
 *
 * Defines the various types of menu items that can be created,
 * each with different behavior and appearance characteristics.
 */
enum class MenuItemType {
  /**
   * Normal clickable menu item with text and optional icon.
   */
  Normal,

  /**
   * Checkable menu item that can be toggled on/off.
   */
  Checkbox,

  /**
   * Radio button menu item, part of a mutually exclusive group.
   */
  Radio,

  /**
   * Separator line between menu items.
   */
  Separator,

  /**
   * Submenu item that expands to show child items.
   */
  Submenu
};

/**
 * @brief State of a menu item (for checkboxes and radio buttons).
 *
 * Defines the possible states for checkable menu items.
 * Mixed state is typically used for checkboxes to indicate
 * a partially selected or indeterminate state.
 */
enum class MenuItemState {
  /**
   * Item is not checked/selected.
   */
  Unchecked,

  /**
   * Item is checked/selected.
   */
  Checked,

  /**
   * Item is in mixed/indeterminate state (checkboxes only).
   * Typically shown as a dash (-) or special symbol.
   */
  Mixed
};

// Forward declarations
class Menu;

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/**
 * @brief Base class for all menu-related events.
 *
 * This class provides common functionality for menu events.
 */
class MenuEvent : public Event {
 public:
  virtual ~MenuEvent() = default;

  std::string GetTypeName() const override { return "MenuEvent"; }
};

/**
 * @brief Menu opened event.
 *
 * This event is fired when a menu has been displayed.
 */
class MenuOpenedEvent : public MenuEvent {
 public:
  MenuOpenedEvent(MenuId menu_id) : menu_id_(menu_id) {}

  MenuId GetMenuId() const { return menu_id_; }

  std::string GetTypeName() const override { return "MenuOpenedEvent"; }

 private:
  MenuId menu_id_;
};

/**
 * @brief Menu closed event.
 *
 * This event is fired when a menu has been hidden or closed.
 */
class MenuClosedEvent : public MenuEvent {
 public:
  MenuClosedEvent(MenuId menu_id) : menu_id_(menu_id) {}

  MenuId GetMenuId() const { return menu_id_; }

  std::string GetTypeName() const override { return "MenuClosedEvent"; }

 private:
  MenuId menu_id_;
};

/**
 * @brief Menu item clicked event.
 *
 * This event is fired when a menu item is clicked or activated.
 * Contains information about which menu item was clicked.
 */
class MenuItemClickedEvent : public MenuEvent {
 public:
  MenuItemClickedEvent(MenuItemId item_id) : item_id_(item_id) {}

  MenuItemId GetItemId() const { return item_id_; }

  std::string GetTypeName() const override { return "MenuItemClickedEvent"; }

 private:
  MenuItemId item_id_;
};

/**
 * @brief Menu item submenu opened event.
 *
 * This event is fired when a menu item's submenu has been displayed.
 */
class MenuItemSubmenuOpenedEvent : public MenuEvent {
 public:
  MenuItemSubmenuOpenedEvent(MenuItemId item_id) : item_id_(item_id) {}

  MenuItemId GetItemId() const { return item_id_; }

  std::string GetTypeName() const override { return "MenuItemSubmenuOpenedEvent"; }

 private:
  MenuItemId item_id_;
};

/**
 * @brief Menu item submenu closed event.
 *
 * This event is fired when a menu item's submenu has been hidden or closed.
 */
class MenuItemSubmenuClosedEvent : public MenuEvent {
 public:
  MenuItemSubmenuClosedEvent(MenuItemId item_id) : item_id_(item_id) {}

  MenuItemId GetItemId() const { return item_id_; }

  std::string GetTypeName() const override { return "MenuItemSubmenuClosedEvent"; }

 private:
  MenuItemId item_id_;
};

/**
 * @brief MenuItem represents a single item in a menu.
 *
 * This class provides a cross-platform interface for creating and managing
 * menu items. Menu items can be simple clickable items, checkboxes, radio
 * buttons, separators, or submenu containers.
 *
 * The class supports:
 * - Different item types (normal, checkbox, radio, separator, submenu)
 * - Custom text, icons, and tooltips
 * - Keyboard shortcuts/accelerators
 * - Enable/disable state
 * - Event emission for user interaction
 * - Submenu nesting
 *
 * @note This class uses the PIMPL idiom to hide platform-specific
 * implementation details and ensure binary compatibility across different
 * platforms. It also inherits from EventEmitter to provide event-driven
 * interaction handling.
 *
 * @example
 * ```cpp
 * // Create a normal menu item
 * auto item = std::make_shared<MenuItem>("Open File", MenuItemType::Normal);
 * item->SetIcon("data:image/png;base64,...");
 * item->SetAccelerator(KeyboardAccelerator("O", ModifierKey::Ctrl));
 * item->AddListener<MenuItemClickedEvent>([](const MenuItemClickedEvent& event)
 * {
 *     // Handle menu item click
 *     std::cout << "Opening file..." << std::endl;
 * });
 *
 * // Create a checkbox item
 * auto checkbox = std::make_shared<MenuItem>("Show Toolbar", MenuItemType::Checkbox);
 * checkbox->SetState(MenuItemState::Checked);
 * checkbox->AddListener<MenuItemClickedEvent>([](const MenuItemClickedEvent&
 * event) { std::cout << "Toolbar clicked, handle state change manually" <<
 * std::endl;
 * });
 * ```
 */
class MenuItem : public EventEmitter<MenuEvent>, public NativeObjectProvider {
 public:
  /**
   * @brief Constructor to create a new menu item.
   *
   * Creates a menu item of the specified type with the given text.
   *
   * @param label The display text for the menu item
   * @param type The type of menu item to create
   *
   * @example
   * ```cpp
   * auto item = std::make_shared<MenuItem>("File", MenuItemType::Normal);
   * auto separator = std::make_shared<MenuItem>("", MenuItemType::Separator);
   * auto checkbox = std::make_shared<MenuItem>("Word Wrap", MenuItemType::Checkbox);
   * ```
   */
  MenuItem(const std::string& label = "", MenuItemType type = MenuItemType::Normal);

  /**
   * @brief Constructor that wraps an existing platform-specific menu item.
   *
   * This constructor is typically used internally by platform-specific
   * implementations to wrap existing menu items.
   *
   * @param native_item Pointer to the platform-specific menu item object
   */
  explicit MenuItem(void* native_item);

  /**
   * @brief Destructor for MenuItem.
   *
   * Cleans up the menu item and releases any associated platform-specific
   * resources. Also removes any event listeners.
   */
  virtual ~MenuItem();

  /**
   * @brief Get the unique identifier for this menu item.
   *
   * This ID is assigned when the item is created and can be used to
   * reference the item in event handlers and other operations.
   *
   * @return The unique identifier for this menu item
   */
  MenuItemId GetId() const;

  /**
   * @brief Get the type of this menu item.
   *
   * @return The MenuItemType of this item
   */
  MenuItemType GetType() const;

  /**
   * @brief Set the display label for the menu item.
   *
   * The label is what appears in the menu. On some platforms,
   * ampersand characters (&) can be used to indicate mnemonics
   * (keyboard navigation keys).
   *
   * @param label The label to display (optional)
   *
   * @example
   * ```cpp
   * item->SetLabel("&File");  // 'F' becomes the mnemonic on Windows/Linux
   * item->SetLabel("Open Recent");
   * item->SetLabel(std::nullopt);  // Clear the label
   * ```
   */
  void SetLabel(const std::optional<std::string>& label);

  /**
   * @brief Get the current display label of the menu item.
   *
   * @return The current label as an optional string
   */
  std::optional<std::string> GetLabel() const;

  /**
   * @brief Set the icon for the menu item using an Image object.
   *
   * This is the preferred method for setting the menu item icon as it
   * provides type safety and better control over image handling.
   *
   * @param image Shared pointer to an Image object, or nullptr to clear the icon
   *
   * @example
   * ```cpp
   * // Using file path
   * auto icon = Image::FromFile("/path/to/icon.png");
   * item->SetIcon(icon);
   *
   * // Using base64 data
   * auto icon = Image::FromBase64("data:image/png;base64,iVBORw0KGgo...");
   * item->SetIcon(icon);
   *
   * // Using system icon
   * auto icon = Image::FromSystemIcon("folder");
   * item->SetIcon(icon);
   *
   * // Clear icon
   * item->SetIcon(nullptr);
   * ```
   */
  void SetIcon(std::shared_ptr<Image> image);

  /**
   * @brief Get the current icon image of the menu item.
   *
   * @return A shared pointer to the current Image object, or nullptr if no icon is set
   */
  std::shared_ptr<Image> GetIcon() const;

  /**
   * @brief Set the tooltip text for the menu item.
   *
   * The tooltip may appear when the user hovers over the menu item,
   * depending on the platform and menu context.
   *
   * @param tooltip The tooltip text to display (optional)
   */
  void SetTooltip(const std::optional<std::string>& tooltip);

  /**
   * @brief Get the current tooltip text of the menu item.
   *
   * @return The current tooltip text as an optional string
   */
  std::optional<std::string> GetTooltip() const;

  /**
   * @brief Set the keyboard accelerator for the menu item.
   *
   * The accelerator allows users to trigger the menu item using
   * keyboard shortcuts. The accelerator is typically displayed
   * next to the menu item label.
   *
   * @param accelerator The keyboard accelerator to set, or std::nullopt to remove
   *
   * @example
   * ```cpp
   * // Set Ctrl+S as accelerator
   * item->SetAccelerator(KeyboardAccelerator("S", ModifierKey::Ctrl));
   *
   * // Set F1 as accelerator
   * item->SetAccelerator(KeyboardAccelerator("F1"));
   *
   * // Set Alt+F4 as accelerator
   * item->SetAccelerator(KeyboardAccelerator("F4", ModifierKey::Alt));
   *
   * // Remove accelerator
   * item->SetAccelerator(std::nullopt);
   * ```
   */
  void SetAccelerator(const std::optional<KeyboardAccelerator>& accelerator);

  /**
   * @brief Get the current keyboard accelerator of the menu item.
   *
   * @return The current KeyboardAccelerator, or an empty accelerator if none is
   * set
   */
  KeyboardAccelerator GetAccelerator() const;

  /**
   * @brief Enable or disable the menu item.
   *
   * Disabled menu items are typically grayed out and cannot be clicked.
   *
   * @param enabled true to enable the item, false to disable it
   */
  void SetEnabled(bool enabled);

  /**
   * @brief Check if the menu item is currently enabled.
   *
   * @return true if the item is enabled, false if disabled
   */
  bool IsEnabled() const;

  /**
   * @brief Set the state of a checkbox or radio menu item.
   *
   * This method allows you to set the checked state, including
   * you to set mixed/indeterminate state for checkboxes.
   * For radio items, only Unchecked and Checked states are valid.
   *
   * @param state The desired state (Unchecked, Checked, or Mixed)
   */
  void SetState(MenuItemState state);

  /**
   * @brief Get the current state of a checkbox or radio menu item.
   *
   * @return The current state (Unchecked, Checked, or Mixed)
   */
  MenuItemState GetState() const;

  /**
   * @brief Set the radio group ID for radio menu items.
   *
   * Radio items with the same group ID are mutually exclusive -
   * only one item in the group can be checked at a time.
   *
   * @param group_id The radio group identifier
   */
  void SetRadioGroup(int group_id);

  /**
   * @brief Get the radio group ID of this menu item.
   *
   * @return The radio group ID, or -1 if not a radio item or no group set
   */
  int GetRadioGroup() const;

  /**
   * @brief Set the submenu for this menu item.
   *
   * This converts the item into a submenu item that expands to show
   * the provided menu when hovered or clicked.
   *
   * @param submenu Shared pointer to the submenu to attach
   */
  void SetSubmenu(std::shared_ptr<Menu> submenu);

  /**
   * @brief Get the submenu attached to this menu item.
   *
   * @return Shared pointer to the submenu, or nullptr if no submenu is attached
   */
  std::shared_ptr<Menu> GetSubmenu() const;

 protected:
  /**
   * @brief Internal method to get the platform-specific native menu item object.
   *
   * This method must be implemented by platform-specific code to return
   * the underlying native menu item object.
   *
   * @return Pointer to the native menu item object
   */
  void* GetNativeObjectInternal() const override;

 private:
  friend class Menu;

  /**
   * @brief Private implementation class using the PIMPL idiom.
   */
  class Impl;

  /**
   * @brief Pointer to the private implementation instance.
   */
  std::unique_ptr<Impl> pimpl_;
};

/**
 * @brief Menu represents a collection of menu items.
 *
 * This class provides a cross-platform interface for creating and managing
 * menus. Menus can contain various types of items including normal items,
 * checkboxes, radio buttons, separators, and submenus.
 *
 * The class supports:
 * - Adding, removing, and organizing menu items
 * - Displaying as context menus or application menus
 * - Event emission for menu interactions
 * - Hierarchical submenu structures
 * - Dynamic menu modification
 *
 * @note This class uses the PIMPL idiom to hide platform-specific
 * implementation details and ensure binary compatibility across different
 * platforms. It also inherits from EventEmitter to provide event-driven
 * interaction handling.
 *
 * @example
 * ```cpp
 * // Create a file menu
 * auto file_menu = std::make_shared<Menu>();
 *
 * // Add items to the menu
 * auto new_item = std::make_shared<MenuItem>("New", MenuItemType::Normal);
 * new_item->SetAccelerator(KeyboardAccelerator("N", ModifierKey::Ctrl));
 * file_menu->AddItem(new_item);
 *
 * auto open_item = std::make_shared<MenuItem>("Open", MenuItemType::Normal);
 * open_item->SetAccelerator(KeyboardAccelerator("O",
 * ModifierKey::Ctrl)); file_menu->AddItem(open_item);
 *
 * file_menu->AddSeparator();
 *
 * auto exit_item = std::make_shared<MenuItem>("Exit", MenuItemType::Normal);
 * file_menu->AddItem(exit_item);
 *
 * // Listen to menu events
 * file_menu->AddListener<MenuOpenedEvent>([](const MenuOpenedEvent& event) {
 *     std::cout << "Menu opened" << std::endl;
 * });
 *
 * // Open as context menu
 * file_menu->Open(100, 100);
 * ```
 */
class Menu : public EventEmitter<MenuEvent>, public NativeObjectProvider {
 public:
  /**
   * @brief Constructor to create a new menu.
   *
   * Creates an empty menu that can be populated with menu items.
   */
  Menu();

  /**
   * @brief Constructor that wraps an existing platform-specific menu.
   *
   * This constructor is typically used internally by platform-specific
   * implementations to wrap existing menus.
   *
   * @param native_menu Pointer to the platform-specific menu object
   */
  explicit Menu(void* native_menu);

  /**
   * @brief Destructor for Menu.
   *
   * Cleans up the menu and all its items, releasing any associated
   * platform-specific resources.
   */
  virtual ~Menu();

  /**
   * @brief Get the unique identifier for this menu.
   *
   * This ID is assigned when the menu is created and can be used to
   * reference the menu in various operations.
   *
   * @return The unique identifier for this menu
   */
  MenuId GetId() const;

  /**
   * @brief Add a menu item to the end of the menu.
   *
   * The item is added to the bottom of the menu's item list.
   *
   * @param item Shared pointer to the menu item to add
   *
   * @example
   * ```cpp
   * auto item = std::make_shared<MenuItem>("Save");
   * menu->AddItem(item);
   * ```
   */
  void AddItem(std::shared_ptr<MenuItem> item);

  /**
   * @brief Insert a menu item at a specific position.
   *
   * Inserts the item at the specified index, shifting existing items
   * to make room. If the index is out of bounds, the item is added
   * to the end.
   *
   * @param index The position where to insert the item (0-based)
   * @param item Shared pointer to the menu item to insert
   */
  void InsertItem(size_t index, std::shared_ptr<MenuItem> item);

  /**
   * @brief Remove a menu item from the menu.
   *
   * Removes the specified item from the menu if it exists.
   *
   * @param item Shared pointer to the menu item to remove
   * @return true if the item was found and removed, false otherwise
   */
  bool RemoveItem(std::shared_ptr<MenuItem> item);

  /**
   * @brief Remove a menu item by its ID.
   *
   * Removes the menu item with the specified ID from the menu.
   *
   * @param item_id The ID of the menu item to remove
   * @return true if the item was found and removed, false otherwise
   */
  bool RemoveItemById(MenuItemId item_id);

  /**
   * @brief Remove a menu item at a specific position.
   *
   * Removes the menu item at the specified index.
   *
   * @param index The position of the item to remove (0-based)
   * @return true if the item was removed, false if index was out of bounds
   */
  bool RemoveItemAt(size_t index);

  /**
   * @brief Remove all menu items from the menu.
   *
   * Clears the entire menu, removing all items.
   */
  void Clear();

  /**
   * @brief Add a separator line to the menu.
   *
   * Separators are used to visually group related menu items.
   * This is a convenience method equivalent to adding a separator MenuItem.
   */
  void AddSeparator();

  /**
   * @brief Insert a separator at a specific position.
   *
   * @param index The position where to insert the separator (0-based)
   */
  void InsertSeparator(size_t index);

  /**
   * @brief Get the number of items in the menu.
   *
   * @return The total number of menu items (including separators)
   */
  size_t GetItemCount() const;

  /**
   * @brief Get a menu item by its position.
   *
   * Returns the menu item at the specified index.
   *
   * @param index The position of the item to retrieve (0-based)
   * @return Shared pointer to the menu item, or nullptr if index is out of
   * bounds
   */
  std::shared_ptr<MenuItem> GetItemAt(size_t index) const;

  /**
   * @brief Get a menu item by its ID.
   *
   * Searches for and returns the menu item with the specified ID.
   *
   * @param item_id The ID of the menu item to find
   * @return Shared pointer to the menu item, or nullptr if not found
   */
  std::shared_ptr<MenuItem> GetItemById(MenuItemId item_id) const;

  /**
   * @brief Get all menu items in the menu.
   *
   * Returns a vector containing all menu items in order.
   *
   * @return Vector of shared pointers to all menu items
   */
  std::vector<std::shared_ptr<MenuItem>> GetAllItems() const;

  /**
   * @brief Display the menu as a context menu using the specified positioning strategy.
   *
   * Shows the menu according to the provided positioning strategy and waits for
   * user interaction. The menu will close when the user clicks outside of it or
   * selects an item.
   *
   * @param strategy The positioning strategy determining where to display the menu
   * @param placement The placement option determining how the menu is positioned
   *                  relative to the reference point (default: BottomStart)
   * @return true if the menu was successfully opened, false otherwise
   *
   * @example
   * ```cpp
   * // Open context menu at cursor position, below the cursor
   * menu->Open(PositioningStrategy::CursorPosition(), Placement::BottomStart);
   *
   * // Open context menu at specific coordinates, above and centered
   * menu->Open(PositioningStrategy::Absolute({100, 200}), Placement::Top);
   *
   * // Open context menu relative to a button with offset, to the right
   * Rectangle buttonRect = button->GetBounds();
   * menu->Open(PositioningStrategy::Relative(buttonRect, {0, 10}), Placement::Right);
   *
   * // Use default placement (BottomStart)
   * menu->Open(PositioningStrategy::CursorPosition());
   * ```
   */
  bool Open(const PositioningStrategy& strategy, Placement placement = Placement::BottomStart);

  /**
   * @brief Programmatically close the menu if it's currently showing.
   *
   * @return true if the menu was successfully closed, false otherwise
   */
  bool Close();

 protected:
  /**
   * @brief Internal method to get the platform-specific native menu object.
   *
   * This method must be implemented by platform-specific code to return
   * the underlying native menu object.
   *
   * @return Pointer to the native menu object
   */
  void* GetNativeObjectInternal() const override;

 private:
  /**
   * @brief Private implementation class using the PIMPL idiom.
   */
  class Impl;

  /**
   * @brief Pointer to the private implementation instance.
   */
  std::unique_ptr<Impl> pimpl_;
};

}  // namespace nativeapi
