#include <windows.h>
#include <cmath>
#include <cstring>
#include <functional>
#include <iostream>
#include <memory>
#include <optional>
#include <vector>
#include "../../foundation/id_allocator.h"
#include "../../image.h"
#include "../../menu.h"
#include "../../window.h"
#include "dpi_utils_windows.h"
#include "string_utils_windows.h"
#include "window_message_dispatcher.h"

namespace nativeapi {

HICON ImageToHICON(const Image* image, int width, int height);

// Helper function to convert KeyboardAccelerator to Windows accelerator
std::pair<UINT, UINT> ConvertAccelerator(const KeyboardAccelerator& accelerator) {
  UINT key = 0;
  UINT modifiers = 0;

  // Convert key
  if (!accelerator.key.empty()) {
    if (accelerator.key.length() == 1) {
      // Single character key
      char c = std::toupper(accelerator.key[0]);
      key = static_cast<UINT>(c);
    } else {
      // Special keys
      std::string key_str = accelerator.key;
      if (key_str == "F1")
        key = VK_F1;
      else if (key_str == "F2")
        key = VK_F2;
      else if (key_str == "F3")
        key = VK_F3;
      else if (key_str == "F4")
        key = VK_F4;
      else if (key_str == "F5")
        key = VK_F5;
      else if (key_str == "F6")
        key = VK_F6;
      else if (key_str == "F7")
        key = VK_F7;
      else if (key_str == "F8")
        key = VK_F8;
      else if (key_str == "F9")
        key = VK_F9;
      else if (key_str == "F10")
        key = VK_F10;
      else if (key_str == "F11")
        key = VK_F11;
      else if (key_str == "F12")
        key = VK_F12;
      else if (key_str == "Enter" || key_str == "Return")
        key = VK_RETURN;
      else if (key_str == "Tab")
        key = VK_TAB;
      else if (key_str == "Space")
        key = VK_SPACE;
      else if (key_str == "Escape")
        key = VK_ESCAPE;
      else if (key_str == "Delete" || key_str == "Backspace")
        key = VK_BACK;
      else if (key_str == "ArrowUp")
        key = VK_UP;
      else if (key_str == "ArrowDown")
        key = VK_DOWN;
      else if (key_str == "ArrowLeft")
        key = VK_LEFT;
      else if (key_str == "ArrowRight")
        key = VK_RIGHT;
    }
  }

  // Convert modifiers
  if ((accelerator.modifiers & ModifierKey::Ctrl) != ModifierKey::None) {
    modifiers |= FCONTROL;
  }
  if ((accelerator.modifiers & ModifierKey::Alt) != ModifierKey::None) {
    modifiers |= FALT;
  }
  if ((accelerator.modifiers & ModifierKey::Shift) != ModifierKey::None) {
    modifiers |= FSHIFT;
  }
  // Note: Windows doesn't have a direct equivalent for Meta key in accelerators

  return std::make_pair(key, modifiers);
}

// MenuItem::Impl implementation
class MenuItem::Impl {
 public:
  MenuItemId id_;
  HMENU parent_menu_;
  MenuItemType type_;
  std::optional<std::string> label_;
  std::shared_ptr<Image> image_;
  HICON menu_icon_;      // Stored icon for menu item with transparency support
  HBITMAP menu_bitmap_;  // Stored 32-bit ARGB bitmap with icon and transparent background
  std::optional<std::string> tooltip_;
  KeyboardAccelerator accelerator_;
  bool has_accelerator_;
  MenuItemState state_;
  bool enabled_;
  int radio_group_;
  std::shared_ptr<Menu> submenu_;
  int window_proc_handle_id_;
  std::function<void(MenuItemId)> clicked_callback_;
  size_t submenu_opened_listener_id_;
  size_t submenu_closed_listener_id_;

  Impl(MenuItemId id, HMENU parent_menu, MenuItemType type)
      : id_(id),
        parent_menu_(parent_menu),
        type_(type),
        menu_icon_(nullptr),
        menu_bitmap_(nullptr),
        accelerator_("", ModifierKey::None),
        has_accelerator_(false),
        state_(MenuItemState::Unchecked),
        enabled_(true),
        radio_group_(-1),
        window_proc_handle_id_(-1),
        submenu_opened_listener_id_(0),
        submenu_closed_listener_id_(0) {}

  ~Impl() {
    // Unregister window procedure handler
    if (window_proc_handle_id_ != -1) {
      WindowMessageDispatcher::GetInstance().UnregisterHandler(window_proc_handle_id_);
    }

    // Remove submenu listeners before cleaning up submenu reference
    if (submenu_ && submenu_opened_listener_id_ != 0) {
      submenu_->RemoveListener(submenu_opened_listener_id_);
      submenu_opened_listener_id_ = 0;
    }
    if (submenu_ && submenu_closed_listener_id_ != 0) {
      submenu_->RemoveListener(submenu_closed_listener_id_);
      submenu_closed_listener_id_ = 0;
    }

    // Clean up menu icon
    if (menu_icon_) {
      DestroyIcon(menu_icon_);
      menu_icon_ = nullptr;
    }

    // Clean up menu bitmap
    if (menu_bitmap_) {
      DeleteObject(menu_bitmap_);
      menu_bitmap_ = nullptr;
    }

    // Windows menu items are automatically cleaned up when the menu is
    // destroyed
  }

  // Handle window procedure delegate for menu item clicks
  std::optional<LRESULT> HandleWindowProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
    if (message == WM_COMMAND) {
      // For WM_COMMAND from menus, wparam contains the menu item ID
      // When using popup menus (TrackPopupMenu), the full 32-bit ID is
      // preserved in wparam, unlike menu bars which only use 16-bit IDs
      if (lparam == 0) {
        // Reconstruct the full 32-bit menu item ID from wparam
        MenuItemId menu_item_id = static_cast<MenuItemId>(wparam);

        // Check if this is our menu item
        if (menu_item_id == id_) {
          std::cout << "MenuItem: Item clicked, ID = " << menu_item_id << std::endl;
          // Call the clicked callback to emit the event
          if (clicked_callback_) {
            clicked_callback_(id_);
          }
          return 0;
        }
      }
    }
    return std::nullopt;  // Let other handlers process
  }
};

MenuItem::MenuItem(void* native_item)
    : pimpl_(std::make_unique<Impl>(IdAllocator::Allocate<MenuItem>(),
                                    nullptr,
                                    MenuItemType::Normal)) {
  // Set clicked callback to emit event
  pimpl_->clicked_callback_ = [this](MenuItemId id) { Emit<MenuItemClickedEvent>(id); };

  // Register window procedure handler for menu item clicks
  HWND host_window = WindowMessageDispatcher::GetInstance().GetHostWindow();
  if (host_window) {
    pimpl_->window_proc_handle_id_ = WindowMessageDispatcher::GetInstance().RegisterHandler(
        host_window, [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
          return pimpl_->HandleWindowProc(hwnd, message, wparam, lparam);
        });
  }
}

MenuItem::MenuItem(const std::string& label, MenuItemType type)
    : pimpl_(std::make_unique<Impl>(IdAllocator::Allocate<MenuItem>(), nullptr, type)) {
  pimpl_->label_ = label;

  // Set clicked callback to emit event
  pimpl_->clicked_callback_ = [this](MenuItemId id) { Emit<MenuItemClickedEvent>(id); };

  // Register window procedure handler for menu item clicks
  HWND host_window = WindowMessageDispatcher::GetInstance().GetHostWindow();
  if (host_window) {
    pimpl_->window_proc_handle_id_ = WindowMessageDispatcher::GetInstance().RegisterHandler(
        host_window, [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
          return pimpl_->HandleWindowProc(hwnd, message, wparam, lparam);
        });
  }
}

MenuItem::~MenuItem() {}

MenuItemId MenuItem::GetId() const {
  return pimpl_->id_;
}

MenuItemType MenuItem::GetType() const {
  return pimpl_->type_;
}

void MenuItem::SetLabel(const std::optional<std::string>& label) {
  pimpl_->label_ = label;
  if (pimpl_->parent_menu_) {
    MENUITEMINFOW mii = {};
    mii.cbSize = sizeof(MENUITEMINFOW);
    mii.fMask = MIIM_STRING;
    std::string label_str = label.has_value() ? *label : "";
    std::wstring w_label_str = StringToWString(label_str);
    mii.dwTypeData = const_cast<LPWSTR>(w_label_str.c_str());
    SetMenuItemInfoW(pimpl_->parent_menu_, pimpl_->id_, FALSE, &mii);
  }
}

std::optional<std::string> MenuItem::GetLabel() const {
  return pimpl_->label_;
}

void MenuItem::SetIcon(std::shared_ptr<Image> image) {
  // Clean up previous resources
  if (pimpl_->menu_icon_) {
    DestroyIcon(pimpl_->menu_icon_);
    pimpl_->menu_icon_ = nullptr;
  }
  if (pimpl_->menu_bitmap_) {
    DeleteObject(pimpl_->menu_bitmap_);
    pimpl_->menu_bitmap_ = nullptr;
  }

  pimpl_->image_ = image;

  if (image && pimpl_->parent_menu_) {
    // Use 32x32 for menu icons
    const int iconSize = 32;

    // Convert image to HICON first for proper transparency support
    HICON hIcon = ImageToHICON(image.get(), iconSize, iconSize);

    if (hIcon) {
      pimpl_->menu_icon_ = hIcon;

      // Create a 32-bit ARGB bitmap
      HDC hdc = GetDC(nullptr);

      // Create BITMAPINFO for 32-bit ARGB
      BITMAPINFO bmi = {};
      bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
      bmi.bmiHeader.biWidth = iconSize;
      bmi.bmiHeader.biHeight = -iconSize;  // Negative for top-down DIB
      bmi.bmiHeader.biPlanes = 1;
      bmi.bmiHeader.biBitCount = 32;
      bmi.bmiHeader.biCompression = BI_RGB;

      void* pBits = nullptr;
      HBITMAP hBmp = CreateDIBSection(hdc, &bmi, DIB_RGB_COLORS, &pBits, nullptr, 0);

      if (hBmp && pBits) {
        // Fill with fully transparent pixels (all-zero ARGB)
        // This ensures the icon blends seamlessly with the menu background.
        // On Windows Vista+, MIIM_BITMAP with a 32-bit ARGB DIB section
        // respects the alpha channel for proper transparency.
        DWORD* pixels = static_cast<DWORD*>(pBits);
        memset(pixels, 0, iconSize * iconSize * sizeof(DWORD));

        // Draw the icon on the bitmap
        HDC hdcMem = CreateCompatibleDC(hdc);
        HBITMAP hOldBmp = (HBITMAP)SelectObject(hdcMem, hBmp);

        // Draw icon with proper blending
        DrawIconEx(hdcMem, 0, 0, hIcon, iconSize, iconSize, 0, nullptr, DI_NORMAL);

        SelectObject(hdcMem, hOldBmp);
        DeleteDC(hdcMem);

        // Store the bitmap for cleanup
        pimpl_->menu_bitmap_ = hBmp;

        // Set the bitmap on the menu item
        MENUITEMINFOW mii = {};
        mii.cbSize = sizeof(MENUITEMINFOW);
        mii.fMask = MIIM_BITMAP;
        mii.hbmpItem = hBmp;
        SetMenuItemInfoW(pimpl_->parent_menu_, pimpl_->id_, FALSE, &mii);
      }

      ReleaseDC(nullptr, hdc);
    }
  }
}

std::shared_ptr<Image> MenuItem::GetIcon() const {
  return pimpl_->image_;
}

void MenuItem::SetTooltip(const std::optional<std::string>& tooltip) {
  pimpl_->tooltip_ = tooltip;
  // Windows doesn't have built-in tooltip support for menu items
  // This would require custom implementation
}

std::optional<std::string> MenuItem::GetTooltip() const {
  return pimpl_->tooltip_;
}

void MenuItem::SetAccelerator(const std::optional<KeyboardAccelerator>& accelerator) {
  if (accelerator.has_value()) {
    pimpl_->accelerator_ = *accelerator;
    pimpl_->has_accelerator_ = true;
  } else {
    pimpl_->accelerator_ = KeyboardAccelerator("", ModifierKey::None);
    pimpl_->has_accelerator_ = false;
  }
  // Windows accelerators would be handled through accelerator tables
  // This is a placeholder implementation
}

KeyboardAccelerator MenuItem::GetAccelerator() const {
  if (pimpl_->has_accelerator_) {
    return pimpl_->accelerator_;
  }
  return KeyboardAccelerator("", ModifierKey::None);
}

void MenuItem::SetEnabled(bool enabled) {
  pimpl_->enabled_ = enabled;
  if (pimpl_->parent_menu_) {
    EnableMenuItem(pimpl_->parent_menu_, pimpl_->id_, enabled ? MF_ENABLED : MF_GRAYED);
  }
}

bool MenuItem::IsEnabled() const {
  return pimpl_->enabled_;
}

void MenuItem::SetState(MenuItemState state) {
  if (pimpl_->type_ == MenuItemType::Checkbox || pimpl_->type_ == MenuItemType::Radio) {
    pimpl_->state_ = state;

    if (pimpl_->parent_menu_) {
      UINT check_state = MF_UNCHECKED;
      if (state == MenuItemState::Checked) {
        check_state = MF_CHECKED;
      }
      CheckMenuItem(pimpl_->parent_menu_, pimpl_->id_, check_state);
    }

    // Handle radio button group logic
    if (pimpl_->type_ == MenuItemType::Radio && state == MenuItemState::Checked &&
        pimpl_->radio_group_ >= 0) {
      // Note: Radio group logic would need to be implemented differently
      // without global registry. This could be done by maintaining group
      // information in the parent menu or through other means.
      // For now, this functionality is disabled.
    }
  }
}

MenuItemState MenuItem::GetState() const {
  return pimpl_->state_;
}

void MenuItem::SetRadioGroup(int group_id) {
  pimpl_->radio_group_ = group_id;
}

int MenuItem::GetRadioGroup() const {
  return pimpl_->radio_group_;
}

void MenuItem::SetSubmenu(std::shared_ptr<Menu> submenu) {
  // Remove previous submenu listeners if they exist
  if (pimpl_->submenu_ && pimpl_->submenu_opened_listener_id_ != 0) {
    pimpl_->submenu_->RemoveListener(pimpl_->submenu_opened_listener_id_);
    pimpl_->submenu_opened_listener_id_ = 0;
  }
  if (pimpl_->submenu_ && pimpl_->submenu_closed_listener_id_ != 0) {
    pimpl_->submenu_->RemoveListener(pimpl_->submenu_closed_listener_id_);
    pimpl_->submenu_closed_listener_id_ = 0;
  }

  pimpl_->submenu_ = submenu;

  // Update platform menu if parent_menu_ is set
  if (pimpl_->parent_menu_ && submenu) {
    MENUITEMINFOW mii = {};
    mii.cbSize = sizeof(MENUITEMINFOW);
    mii.fMask = MIIM_SUBMENU;
    mii.hSubMenu = static_cast<HMENU>(submenu->GetNativeObject());
    SetMenuItemInfoW(pimpl_->parent_menu_, pimpl_->id_, FALSE, &mii);
  }

  // Add event listeners to forward submenu events (independent of parent_menu_)
  if (submenu) {
    MenuItemId menu_item_id = pimpl_->id_;
    MenuItem* self = this;
    pimpl_->submenu_opened_listener_id_ =
        submenu->AddListener<MenuOpenedEvent>([self, menu_item_id](const MenuOpenedEvent& event) {
          self->Emit<MenuItemSubmenuOpenedEvent>(menu_item_id);
        });

    pimpl_->submenu_closed_listener_id_ =
        submenu->AddListener<MenuClosedEvent>([self, menu_item_id](const MenuClosedEvent& event) {
          self->Emit<MenuItemSubmenuClosedEvent>(menu_item_id);
        });
  }
}

std::shared_ptr<Menu> MenuItem::GetSubmenu() const {
  return pimpl_->submenu_;
}

void* MenuItem::GetNativeObjectInternal() const {
  return reinterpret_cast<void*>(static_cast<uintptr_t>(pimpl_->id_));
}

// Menu::Impl implementation
class Menu::Impl {
 public:
  MenuId id_;
  HMENU hmenu_;
  std::vector<std::shared_ptr<MenuItem>> items_;
  int window_proc_handle_id_;
  std::function<void(MenuId)> opened_callback_;
  std::function<void(MenuId)> closed_callback_;

  Impl(MenuId id, HMENU menu) : id_(id), hmenu_(menu), window_proc_handle_id_(-1) {}

  ~Impl() {
    // Unregister window procedure handler
    if (window_proc_handle_id_ != -1) {
      WindowMessageDispatcher::GetInstance().UnregisterHandler(window_proc_handle_id_);
    }

    if (hmenu_) {
      DestroyMenu(hmenu_);
    }
  }

  // Handle window procedure delegate for menu lifecycle events
  std::optional<LRESULT> HandleWindowProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
    // Handle menu lifecycle events only
    // Menu item clicks are now handled by individual MenuItem instances
    if (message == WM_INITMENUPOPUP) {
      // wParam contains the HMENU handle of the popup menu being opened
      HMENU popup_menu = reinterpret_cast<HMENU>(wparam);

      if (popup_menu == hmenu_) {
        // This is our menu being opened
        // Emit menu opened event via callback
        if (opened_callback_) {
          opened_callback_(id_);
        }
      } else {
        // Check if this is a submenu of one of our items
        for (const auto& item : items_) {
          auto submenu = item->GetSubmenu();
          if (submenu && submenu->GetNativeObject() == popup_menu) {
            // This is a submenu of one of our items being opened
            // The MenuItem will handle emitting MenuItemSubmenuOpenedEvent
            // through its event listeners
            break;
          }
        }
      }
    } else if (message == WM_UNINITMENUPOPUP) {
      // wParam contains the HMENU handle of the popup menu being closed
      HMENU popup_menu = reinterpret_cast<HMENU>(wparam);

      if (popup_menu == hmenu_) {
        // This is our menu being closed
        // Emit menu closed event via callback
        if (closed_callback_) {
          closed_callback_(id_);
        }
      } else {
        // Check if this is a submenu of one of our items
        for (const auto& item : items_) {
          auto submenu = item->GetSubmenu();
          if (submenu && submenu->GetNativeObject() == popup_menu) {
            // This is a submenu of one of our items being closed
            // The MenuItem will handle emitting MenuItemSubmenuClosedEvent
            // through its event listeners
            break;
          }
        }
      }
    }
    return std::nullopt;  // Let other handlers (including MenuItem handlers) process it
  }
};

Menu::Menu(void* native_menu)
    : pimpl_(
          std::make_unique<Impl>(IdAllocator::Allocate<Menu>(), static_cast<HMENU>(native_menu))) {
  // Set callbacks to emit events
  pimpl_->opened_callback_ = [this](MenuId id) { Emit<MenuOpenedEvent>(id); };
  pimpl_->closed_callback_ = [this](MenuId id) { Emit<MenuClosedEvent>(id); };

  // Register window procedure handler for menu commands and events
  HWND host_window = WindowMessageDispatcher::GetInstance().GetHostWindow();
  if (host_window) {
    pimpl_->window_proc_handle_id_ = WindowMessageDispatcher::GetInstance().RegisterHandler(
        host_window, [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
          return pimpl_->HandleWindowProc(hwnd, message, wparam, lparam);
        });
  }
}

Menu::Menu() : pimpl_(std::make_unique<Impl>(IdAllocator::Allocate<Menu>(), CreatePopupMenu())) {
  // Set callbacks to emit events
  pimpl_->opened_callback_ = [this](MenuId id) { Emit<MenuOpenedEvent>(id); };
  pimpl_->closed_callback_ = [this](MenuId id) { Emit<MenuClosedEvent>(id); };

  // Register window procedure handler for menu commands and events
  HWND host_window = WindowMessageDispatcher::GetInstance().GetHostWindow();
  if (host_window) {
    pimpl_->window_proc_handle_id_ = WindowMessageDispatcher::GetInstance().RegisterHandler(
        host_window, [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
          return pimpl_->HandleWindowProc(hwnd, message, wparam, lparam);
        });
  }
}

Menu::~Menu() {}

MenuId Menu::GetId() const {
  return pimpl_->id_;
}

void Menu::AddItem(std::shared_ptr<MenuItem> item) {
  if (!item)
    return;

  pimpl_->items_.push_back(item);

  UINT flags = MF_STRING;
  if (item->GetType() == MenuItemType::Separator) {
    flags = MF_SEPARATOR;
  } else if (item->GetType() == MenuItemType::Checkbox) {
    flags |= (item->GetState() == MenuItemState::Checked) ? MF_CHECKED
                                                           : MF_UNCHECKED;
  } else if (item->GetType() == MenuItemType::Radio) {
    flags |= (item->GetState() == MenuItemState::Checked) ? MF_CHECKED
                                                           : MF_UNCHECKED;
  }

  if (!item->IsEnabled()) {
    flags |= MF_GRAYED;
  }

  UINT_PTR menu_id = item->GetId();
  HMENU sub_menu = nullptr;
  if (item->GetSubmenu()) {
    sub_menu = static_cast<HMENU>(item->GetSubmenu()->GetNativeObject());
    flags |= MF_POPUP;
    menu_id = reinterpret_cast<UINT_PTR>(sub_menu);
  }

  auto label_opt = item->GetLabel();
  std::string label_str = label_opt.has_value() ? *label_opt : "";
  std::wstring w_label_str = StringToWString(label_str);
  AppendMenuW(pimpl_->hmenu_, flags, menu_id, w_label_str.c_str());

  // Update the item's impl with menu info
  item->pimpl_->parent_menu_ = pimpl_->hmenu_;
}

void Menu::InsertItem(size_t index, std::shared_ptr<MenuItem> item) {
  if (!item)
    return;

  if (index >= pimpl_->items_.size()) {
    AddItem(item);
    return;
  }

  pimpl_->items_.insert(pimpl_->items_.begin() + index, item);

  UINT flags = MF_STRING | MF_BYPOSITION;
  if (item->GetType() == MenuItemType::Separator) {
    flags = MF_SEPARATOR | MF_BYPOSITION;
  } else if (item->GetType() == MenuItemType::Checkbox) {
    flags |= (item->GetState() == MenuItemState::Checked) ? MF_CHECKED
                                                           : MF_UNCHECKED;
  } else if (item->GetType() == MenuItemType::Radio) {
    flags |= (item->GetState() == MenuItemState::Checked) ? MF_CHECKED
                                                           : MF_UNCHECKED;
  }

  if (!item->IsEnabled()) {
    flags |= MF_GRAYED;
  }

  UINT_PTR menu_id = item->GetId();
  if (item->GetSubmenu()) {
    auto sub_menu =
        static_cast<HMENU>(item->GetSubmenu()->GetNativeObject());
    flags |= MF_POPUP;
    menu_id = reinterpret_cast<UINT_PTR>(sub_menu);
  }

  auto label_opt = item->GetLabel();
  std::string label_str = label_opt.has_value() ? *label_opt : "";
  std::wstring w_label_str = StringToWString(label_str);
  InsertMenuW(pimpl_->hmenu_, static_cast<UINT>(index), flags, menu_id,
              w_label_str.c_str());

  item->pimpl_->parent_menu_ = pimpl_->hmenu_;
}

bool Menu::RemoveItem(std::shared_ptr<MenuItem> item) {
  if (!item)
    return false;

  auto it = std::find(pimpl_->items_.begin(), pimpl_->items_.end(), item);
  if (it != pimpl_->items_.end()) {
    RemoveMenu(pimpl_->hmenu_, item->GetId(), MF_BYCOMMAND);
    pimpl_->items_.erase(it);
    return true;
  }
  return false;
}

bool Menu::RemoveItemById(MenuItemId item_id) {
  for (auto it = pimpl_->items_.begin(); it != pimpl_->items_.end(); ++it) {
    if ((*it)->GetId() == item_id) {
      RemoveMenu(pimpl_->hmenu_, item_id, MF_BYCOMMAND);
      pimpl_->items_.erase(it);
      return true;
    }
  }
  return false;
}

bool Menu::RemoveItemAt(size_t index) {
  if (index >= pimpl_->items_.size())
    return false;

  RemoveMenu(pimpl_->hmenu_, static_cast<UINT>(index), MF_BYPOSITION);
  pimpl_->items_.erase(pimpl_->items_.begin() + index);
  return true;
}

void Menu::Clear() {
  while (GetMenuItemCount(pimpl_->hmenu_) > 0) {
    RemoveMenu(pimpl_->hmenu_, 0, MF_BYPOSITION);
  }
  pimpl_->items_.clear();
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
  if (index >= pimpl_->items_.size())
    return nullptr;
  return pimpl_->items_[index];
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
  POINT pt = {0, 0};

  // Determine position based on strategy type
  switch (strategy.GetType()) {
    case PositioningStrategy::Type::Absolute:
      pt.x = static_cast<int>(strategy.GetAbsolutePosition().x);
      pt.y = static_cast<int>(strategy.GetAbsolutePosition().y);
      break;

    case PositioningStrategy::Type::CursorPosition: {
      GetCursorPos(&pt);
      break;
    }

    case PositioningStrategy::Type::Relative: {
      Rectangle rect = strategy.GetRelativeRectangle();
      Point offset = strategy.GetRelativeOffset();
      if (strategy.GetRelativeWindow() != nullptr) {
        // rect and offset are in logical pixels (DIP) for Window-relative
        HWND rel_hwnd = static_cast<HWND>(strategy.GetRelativeWindow()->GetNativeObject());
        double scale = GetScaleFactorForWindow(rel_hwnd);
        if (scale <= 0.0)
          scale = 1.0;
        pt.x = static_cast<int>(std::lround((rect.x + offset.x) * scale));
        pt.y = static_cast<int>(std::lround((rect.y + offset.y) * scale));
      } else {
        // For plain rectangles, assume inputs already in screen pixels
        pt.x = static_cast<int>(rect.x + offset.x);
        pt.y = static_cast<int>(rect.y + offset.y);
      }
      break;
    }
  }

  // Get the host window for menus
  HWND host_window = WindowMessageDispatcher::GetInstance().GetHostWindow();
  if (!host_window) {
    return false;
  }

  // Set the host window as foreground to ensure menu can be displayed
  SetForegroundWindow(host_window);

  // Determine alignment flags based on placement (both axes)
  // Horizontal:  TPM_LEFTALIGN | TPM_CENTERALIGN | TPM_RIGHTALIGN
  // Vertical:    TPM_TOPALIGN  | TPM_VCENTERALIGN | TPM_BOTTOMALIGN
  UINT uFlags = 0;
  switch (placement) {
    case Placement::Top:
      uFlags = TPM_BOTTOMALIGN | TPM_CENTERALIGN;  // above anchor, horizontally centered
      break;
    case Placement::TopStart:
      uFlags = TPM_BOTTOMALIGN | TPM_LEFTALIGN;  // above anchor, align left
      break;
    case Placement::TopEnd:
      uFlags = TPM_BOTTOMALIGN | TPM_RIGHTALIGN;  // above anchor, align right
      break;
    case Placement::Right:
      uFlags = TPM_LEFTALIGN | TPM_VCENTERALIGN;  // right of anchor, vertically centered
      break;
    case Placement::RightStart:
      uFlags = TPM_LEFTALIGN | TPM_TOPALIGN;  // right of anchor, align top
      break;
    case Placement::RightEnd:
      uFlags = TPM_LEFTALIGN | TPM_BOTTOMALIGN;  // right of anchor, align bottom
      break;
    case Placement::Bottom:
      uFlags = TPM_TOPALIGN | TPM_CENTERALIGN;  // below anchor, horizontally centered
      break;
    case Placement::BottomStart:
      uFlags = TPM_TOPALIGN | TPM_LEFTALIGN;  // below anchor, align left
      break;
    case Placement::BottomEnd:
      uFlags = TPM_TOPALIGN | TPM_RIGHTALIGN;  // below anchor, align right
      break;
    case Placement::Left:
      uFlags = TPM_RIGHTALIGN | TPM_VCENTERALIGN;  // left of anchor, vertically centered
      break;
    case Placement::LeftStart:
      uFlags = TPM_RIGHTALIGN | TPM_TOPALIGN;  // left of anchor, align top
      break;
    case Placement::LeftEnd:
      uFlags = TPM_RIGHTALIGN | TPM_BOTTOMALIGN;  // left of anchor, align bottom
      break;
  }

  // Show the context menu using the host window
  // Note: TrackPopupMenu is a blocking call
  // - WM_INITMENUPOPUP is sent when the menu opens (triggers MenuOpenedEvent)
  // - WM_UNINITMENUPOPUP is sent when the menu closes (triggers
  // MenuClosedEvent)
  TrackPopupMenu(pimpl_->hmenu_, uFlags, pt.x, pt.y, 0, host_window, nullptr);

  return true;
}

bool Menu::Close() {
  // Send WM_CANCELMODE to close any open menus
  HWND host_window = WindowMessageDispatcher::GetInstance().GetHostWindow();
  if (host_window) {
    // This will close the menu and trigger WM_UNINITMENUPOPUP
    SendMessage(host_window, WM_CANCELMODE, 0, 0);
    return true;
  }
  return false;
}

void* Menu::GetNativeObjectInternal() const {
  return pimpl_->hmenu_;
}

}  // namespace nativeapi
