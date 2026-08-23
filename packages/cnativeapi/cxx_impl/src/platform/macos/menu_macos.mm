#include <iostream>
#include <optional>
#include <unordered_map>
#include <vector>
#include "../../foundation/id_allocator.h"
#include "../../image.h"
#include "../../menu.h"
#include "coordinate_utils_macos.h"

// Import Cocoa headers
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

// Note: This file assumes ARC (Automatic Reference Counting) is enabled
// for proper memory management of Objective-C objects.

// Static keys for associated objects
static const void* kMenuItemIdKey = &kMenuItemIdKey;
static const void* kMenuIdKey = &kMenuIdKey;

// Forward declarations - moved to global scope
typedef void (^MenuItemClickedBlock)(nativeapi::MenuItemId item_id);
typedef void (^MenuOpenedBlock)(nativeapi::MenuId menu_id);
typedef void (^MenuClosedBlock)(nativeapi::MenuId menu_id);

@interface NSMenuItemTarget : NSObject
@property(nonatomic, copy) MenuItemClickedBlock clickedBlock;
- (void)menuItemClicked:(id)sender;
@end

@interface NSMenuDelegateImpl : NSObject <NSMenuDelegate>
@property(nonatomic, copy) MenuOpenedBlock openedBlock;
@property(nonatomic, copy) MenuClosedBlock closedBlock;
@end

namespace nativeapi {

// Removed global registries; events are dispatched via direct back-pointers

// Helper function to convert KeyboardAccelerator to NSString and modifier mask
std::pair<NSString*, NSUInteger> ConvertAccelerator(const KeyboardAccelerator& accelerator) {
  NSString* key_equivalent = @"";
  NSUInteger modifier_mask = 0;

  // Convert key
  if (!accelerator.key.empty()) {
    if (accelerator.key.length() == 1) {
      // Single character key
      char c = std::tolower(accelerator.key[0]);
      key_equivalent = [NSString stringWithFormat:@"%c", c];
    } else {
      // Special keys
      std::string key = accelerator.key;
      if (key == "F1")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF1FunctionKey];
      else if (key == "F2")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF2FunctionKey];
      else if (key == "F3")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF3FunctionKey];
      else if (key == "F4")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF4FunctionKey];
      else if (key == "F5")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF5FunctionKey];
      else if (key == "F6")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF6FunctionKey];
      else if (key == "F7")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF7FunctionKey];
      else if (key == "F8")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF8FunctionKey];
      else if (key == "F9")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF9FunctionKey];
      else if (key == "F10")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF10FunctionKey];
      else if (key == "F11")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF11FunctionKey];
      else if (key == "F12")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSF12FunctionKey];
      else if (key == "Enter" || key == "Return")
        key_equivalent = @"\r";
      else if (key == "Tab")
        key_equivalent = @"\t";
      else if (key == "Space")
        key_equivalent = @" ";
      else if (key == "Escape")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)0x1B];
      else if (key == "Delete" || key == "Backspace")
        key_equivalent = @"\b";
      else if (key == "ArrowUp")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSUpArrowFunctionKey];
      else if (key == "ArrowDown")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSDownArrowFunctionKey];
      else if (key == "ArrowLeft")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSLeftArrowFunctionKey];
      else if (key == "ArrowRight")
        key_equivalent = [NSString stringWithFormat:@"%C", (unichar)NSRightArrowFunctionKey];
    }
  }

  // Convert modifiers
  if ((accelerator.modifiers & ModifierKey::Ctrl) != ModifierKey::None) {
    modifier_mask |= NSEventModifierFlagControl;
  }
  if ((accelerator.modifiers & ModifierKey::Alt) != ModifierKey::None) {
    modifier_mask |= NSEventModifierFlagOption;
  }
  if ((accelerator.modifiers & ModifierKey::Shift) != ModifierKey::None) {
    modifier_mask |= NSEventModifierFlagShift;
  }
  if ((accelerator.modifiers & ModifierKey::Meta) != ModifierKey::None) {
    modifier_mask |= NSEventModifierFlagCommand;
  }

  return std::make_pair(key_equivalent, modifier_mask);
}

}  // namespace nativeapi

// Implementation of NSMenuItemTarget - moved to global scope
@implementation NSMenuItemTarget
- (void)menuItemClicked:(id)sender {
  @try {
    NSMenuItem* menu_item = (NSMenuItem*)sender;
    if (!menu_item)
      return;

    // Ignore clicks on disabled items as an extra safety net.
    if (![menu_item isEnabled])
      return;

    // Call the block if it exists
    if (_clickedBlock) {
      // Get the MenuItemId from the menu item's associated object
      NSNumber* item_id_obj = objc_getAssociatedObject(menu_item, kMenuItemIdKey);
      if (item_id_obj) {
        nativeapi::MenuItemId item_id = static_cast<nativeapi::MenuItemId>([item_id_obj longValue]);
        _clickedBlock(item_id);
      }
    }
  } @catch (NSException* exception) {
    // Log the exception but don't crash
    NSLog(@"Exception in menuItemClicked: %@", [exception reason]);
  }
}

@end

// Implementation of NSMenuDelegateImpl - moved to global scope
@implementation NSMenuDelegateImpl
- (void)menuWillOpen:(NSMenu*)menu {
  @try {
    if (!menu)
      return;

    if (_openedBlock) {
      // Get the MenuId from the menu's associated object
      NSNumber* menu_id_obj = objc_getAssociatedObject(menu, kMenuIdKey);
      if (menu_id_obj) {
        nativeapi::MenuId menu_id = static_cast<nativeapi::MenuId>([menu_id_obj longValue]);
        _openedBlock(menu_id);
      }
    }
  } @catch (NSException* exception) {
    // Log the exception but don't crash
    NSLog(@"Exception in menuWillOpen: %@", [exception reason]);
  }
}

- (BOOL)menu:(NSMenu*)menu validateMenuItem:(NSMenuItem*)item {
  // Respect the programmatically set enabled state on NSMenuItem.
  // Without this override, NSMenu's default autoenablesItems (YES)
  // would re-enable all items whose target responds to the action,
  // overriding explicit setEnabled:NO calls.
  return [item isEnabled];
}

- (void)menuDidClose:(NSMenu*)menu {
  @try {
    if (!menu)
      return;

    if (_closedBlock) {
      // Get the MenuId from the menu's associated object
      NSNumber* menu_id_obj = objc_getAssociatedObject(menu, kMenuIdKey);
      if (menu_id_obj) {
        nativeapi::MenuId menu_id = static_cast<nativeapi::MenuId>([menu_id_obj longValue]);
        _closedBlock(menu_id);
      }
    }
  } @catch (NSException* exception) {
    // Log the exception but don't crash
    NSLog(@"Exception in menuDidClose: %@", [exception reason]);
  }
}
@end

namespace nativeapi {

// MenuItem::Impl implementation
class MenuItem::Impl {
 public:
  MenuItemId id_;
  NSMenuItem* ns_menu_item_;
  NSMenuItemTarget* ns_menu_item_target_;
  MenuItemType type_;
  std::optional<std::string> label_;
  std::shared_ptr<Image> image_;
  std::optional<std::string> tooltip_;
  KeyboardAccelerator accelerator_;
  bool has_accelerator_;
  MenuItemState state_;
  int radio_group_;
  std::shared_ptr<Menu> submenu_;
  size_t submenu_opened_listener_id_;
  size_t submenu_closed_listener_id_;

  Impl(MenuItemId id, NSMenuItem* menu_item, MenuItemType type)
      : id_(id),
        ns_menu_item_(menu_item),
        ns_menu_item_target_([[NSMenuItemTarget alloc] init]),
        type_(type),
        accelerator_("", ModifierKey::None),
        has_accelerator_(false),
        state_(MenuItemState::Unchecked),
        radio_group_(-1),
        submenu_opened_listener_id_(0),
        submenu_closed_listener_id_(0) {
    [ns_menu_item_ setTarget:ns_menu_item_target_];
    [ns_menu_item_ setAction:@selector(menuItemClicked:)];
  }

  ~Impl() {
    // First, remove submenu listeners before cleaning up submenu reference
    if (submenu_ && submenu_opened_listener_id_ != 0) {
      submenu_->RemoveListener(submenu_opened_listener_id_);
      submenu_opened_listener_id_ = 0;
    }
    if (submenu_ && submenu_closed_listener_id_ != 0) {
      submenu_->RemoveListener(submenu_closed_listener_id_);
      submenu_closed_listener_id_ = 0;
    }

    // Then clean up submenu reference
    if (submenu_) {
      submenu_.reset();
    }

    if (ns_menu_item_target_) {
      // Clean up blocks first
      ns_menu_item_target_.clickedBlock = nil;

      // Remove target and action to prevent callbacks after destruction
      [ns_menu_item_ setTarget:nil];
      [ns_menu_item_ setAction:nil];
      ns_menu_item_target_ = nil;
    }
  }
};

// MenuItem implementation
MenuItem::MenuItem(const std::string& label, MenuItemType type) {
  MenuItemId id = IdAllocator::Allocate<MenuItem>();
  NSMenuItem* ns_item = nullptr;

  switch (type) {
    case MenuItemType::Separator:
      ns_item = [NSMenuItem separatorItem];
      break;
    case MenuItemType::Normal:
    case MenuItemType::Checkbox:
    case MenuItemType::Radio:
    case MenuItemType::Submenu:
    default:
      ns_item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithUTF8String:label.c_str()]
                                           action:nil
                                    keyEquivalent:@""];
      break;
  }

  pimpl_ = std::make_unique<Impl>(id, ns_item, type);
  objc_setAssociatedObject(ns_item, kMenuItemIdKey, [NSNumber numberWithUnsignedInt:id],
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  pimpl_->label_ = label.empty() ? std::nullopt : std::optional<std::string>(label);

  // 设置默认的 Block 处理器，直接发送事件
  pimpl_->ns_menu_item_target_.clickedBlock = ^(MenuItemId item_id) {
    Emit<MenuItemClickedEvent>(item_id);
  };
}

MenuItem::MenuItem(void* native_item) {
  MenuItemId id = IdAllocator::Allocate<MenuItem>();
  NSMenuItem* ns_item = (__bridge NSMenuItem*)native_item;
  pimpl_ = std::make_unique<Impl>(id, (__bridge NSMenuItem*)native_item, MenuItemType::Normal);
  objc_setAssociatedObject(ns_item, kMenuItemIdKey, [NSNumber numberWithUnsignedInt:id],
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  // 设置默认的 Block 处理器，直接发送事件
  pimpl_->ns_menu_item_target_.clickedBlock = ^(MenuItemId item_id) {
    Emit<MenuItemClickedEvent>(item_id);
  };
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
  if (label.has_value()) {
    [pimpl_->ns_menu_item_ setTitle:[NSString stringWithUTF8String:label->c_str()]];
  } else {
    [pimpl_->ns_menu_item_ setTitle:@""];
  }
}

std::optional<std::string> MenuItem::GetLabel() const {
  return pimpl_->label_;
}

void MenuItem::SetIcon(std::shared_ptr<Image> image) {
  pimpl_->image_ = image;

  NSImage* ns_image = nil;

  if (image) {
    // Get NSImage directly from Image object using GetNativeObject
    ns_image = (__bridge NSImage*)image->GetNativeObject();
  }

  if (ns_image) {
    [ns_image setSize:NSMakeSize(16, 16)];  // Standard menu item icon size
    [ns_image setTemplate:YES];
    [pimpl_->ns_menu_item_ setImage:ns_image];
  } else {
    // Clear the image if no valid icon is provided
    [pimpl_->ns_menu_item_ setImage:nil];
  }
}

std::shared_ptr<Image> MenuItem::GetIcon() const {
  return pimpl_->image_;
}

void MenuItem::SetTooltip(const std::optional<std::string>& tooltip) {
  pimpl_->tooltip_ = tooltip;
  if (tooltip.has_value()) {
    [pimpl_->ns_menu_item_ setToolTip:[NSString stringWithUTF8String:tooltip->c_str()]];
  } else {
    [pimpl_->ns_menu_item_ setToolTip:nil];
  }
}

std::optional<std::string> MenuItem::GetTooltip() const {
  return pimpl_->tooltip_;
}

void MenuItem::SetAccelerator(const std::optional<KeyboardAccelerator>& accelerator) {
  if (accelerator.has_value()) {
    pimpl_->accelerator_ = *accelerator;
    pimpl_->has_accelerator_ = true;

    auto key_and_modifier = ConvertAccelerator(*accelerator);
    [pimpl_->ns_menu_item_ setKeyEquivalent:key_and_modifier.first];
    [pimpl_->ns_menu_item_ setKeyEquivalentModifierMask:key_and_modifier.second];
  } else {
    pimpl_->has_accelerator_ = false;
    pimpl_->accelerator_ = KeyboardAccelerator("", ModifierKey::None);
    [pimpl_->ns_menu_item_ setKeyEquivalent:@""];
    [pimpl_->ns_menu_item_ setKeyEquivalentModifierMask:0];
  }
}

KeyboardAccelerator MenuItem::GetAccelerator() const {
  if (pimpl_->has_accelerator_) {
    return pimpl_->accelerator_;
  }
  return KeyboardAccelerator("", ModifierKey::None);
}

void MenuItem::SetEnabled(bool enabled) {
  [pimpl_->ns_menu_item_ setEnabled:enabled];
}

bool MenuItem::IsEnabled() const {
  return [pimpl_->ns_menu_item_ isEnabled];
}

void MenuItem::SetState(MenuItemState state) {
  if (pimpl_->type_ == MenuItemType::Checkbox || pimpl_->type_ == MenuItemType::Radio) {
    // Radio buttons don't support Mixed state
    if (pimpl_->type_ == MenuItemType::Radio && state == MenuItemState::Mixed) {
      return;
    }

    pimpl_->state_ = state;

    // Set the appropriate NSControlStateValue
    NSControlStateValue ns_state;
    switch (state) {
      case MenuItemState::Unchecked:
        ns_state = NSControlStateValueOff;
        break;
      case MenuItemState::Checked:
        ns_state = NSControlStateValueOn;
        break;
      case MenuItemState::Mixed:
        ns_state = NSControlStateValueMixed;
        break;
    }
    [pimpl_->ns_menu_item_ setState:ns_state];

    // Handle radio button group logic - uncheck siblings in the same NSMenu
    if (pimpl_->type_ == MenuItemType::Radio && state == MenuItemState::Checked &&
        pimpl_->radio_group_ >= 0) {
      NSMenu* parent_menu = [pimpl_->ns_menu_item_ menu];
      if (parent_menu) {
        for (NSMenuItem* sibling in [parent_menu itemArray]) {
          if (sibling == pimpl_->ns_menu_item_)
            continue;
          NSObject* target_obj = [sibling target];
          if ([target_obj isKindOfClass:[NSMenuItemTarget class]]) {
            // Get the MenuItemId from the associated object
            NSNumber* sibling_id_obj = objc_getAssociatedObject(sibling, kMenuItemIdKey);
            if (sibling_id_obj) {
              // Find the corresponding MenuItem in the parent menu's items
              // This is a simplified approach - in practice, you might need to store
              // a reference to the parent menu or use a different strategy
              [sibling setState:NSControlStateValueOff];
            }
          }
        }
      }
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
  try {
    pimpl_->submenu_ = submenu;
    if (submenu) {
      NSMenu* ns_submenu = (__bridge NSMenu*)submenu->GetNativeObject();
      if (ns_submenu) {
        [pimpl_->ns_menu_item_ setSubmenu:ns_submenu];

        // Remove previous submenu listeners if they exist
        if (pimpl_->submenu_opened_listener_id_ != 0) {
          submenu->RemoveListener(pimpl_->submenu_opened_listener_id_);
          pimpl_->submenu_opened_listener_id_ = 0;
        }
        if (pimpl_->submenu_closed_listener_id_ != 0) {
          submenu->RemoveListener(pimpl_->submenu_closed_listener_id_);
          pimpl_->submenu_closed_listener_id_ = 0;
        }

        // Add event listeners to forward submenu events
        MenuItemId menu_item_id = pimpl_->id_;
        MenuItem* self = this;
        pimpl_->submenu_opened_listener_id_ = submenu->AddListener<MenuOpenedEvent>(
            [self, menu_item_id](const MenuOpenedEvent& event) {
              self->Emit<MenuItemSubmenuOpenedEvent>(menu_item_id);
            });

        pimpl_->submenu_closed_listener_id_ = submenu->AddListener<MenuClosedEvent>(
            [self, menu_item_id](const MenuClosedEvent& event) {
              self->Emit<MenuItemSubmenuClosedEvent>(menu_item_id);
            });
      }
    } else {
      // Remove listeners when submenu is cleared
      if (pimpl_->submenu_ && pimpl_->submenu_opened_listener_id_ != 0) {
        pimpl_->submenu_->RemoveListener(pimpl_->submenu_opened_listener_id_);
        pimpl_->submenu_opened_listener_id_ = 0;
      }
      if (pimpl_->submenu_ && pimpl_->submenu_closed_listener_id_ != 0) {
        pimpl_->submenu_->RemoveListener(pimpl_->submenu_closed_listener_id_);
        pimpl_->submenu_closed_listener_id_ = 0;
      }
      [pimpl_->ns_menu_item_ setSubmenu:nil];
    }
  } catch (...) {
    // Handle C++ exceptions
    NSLog(@"Exception in SetSubmenu");
  }
}

std::shared_ptr<Menu> MenuItem::GetSubmenu() const {
  return pimpl_->submenu_;
}

void* MenuItem::GetNativeObjectInternal() const {
  return (__bridge void*)pimpl_->ns_menu_item_;
}

// Menu::Impl implementation
class Menu::Impl {
 public:
  MenuId id_;
  NSMenu* ns_menu_;
  NSMenuDelegateImpl* delegate_;
  std::vector<std::shared_ptr<MenuItem>> items_;

  Impl(MenuId id, NSMenu* menu)
      : id_(id), ns_menu_(menu), delegate_([[NSMenuDelegateImpl alloc] init]) {
    [ns_menu_ setDelegate:delegate_];
    // Disable auto-enabling so explicit setEnabled: calls are respected.
    [ns_menu_ setAutoenablesItems:NO];
  }

  ~Impl() {
    // First, remove delegate to prevent callbacks during cleanup
    if (delegate_) {
      // Clean up blocks first
      delegate_.openedBlock = nil;
      delegate_.closedBlock = nil;

      [ns_menu_ setDelegate:nil];
      delegate_ = nil;
    }

    // Then clear all menu item references
    items_.clear();
  }
};

// Menu implementation
Menu::Menu() : Menu(nullptr) {}

Menu::Menu(void* native_menu) {
  MenuId id = IdAllocator::Allocate<Menu>();
  NSMenu* ns_menu = nullptr;

  if (native_menu == nullptr) {
    // Create new platform object
    ns_menu = [[NSMenu alloc] init];
  } else {
    // Wrap existing platform object
    ns_menu = (__bridge NSMenu*)native_menu;
  }

  // All initialization logic in one place
  pimpl_ = std::make_unique<Impl>(id, ns_menu);
  objc_setAssociatedObject(ns_menu, kMenuIdKey, [NSNumber numberWithUnsignedInt:id],
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  // 设置默认的 Block 处理器，直接发送事件
  pimpl_->delegate_.openedBlock = ^(MenuId menu_id) {
    Emit<MenuOpenedEvent>(menu_id);
  };

  pimpl_->delegate_.closedBlock = ^(MenuId menu_id) {
    Emit<MenuClosedEvent>(menu_id);
  };
}

Menu::~Menu() {}

MenuId Menu::GetId() const {
  return pimpl_->id_;
}

void Menu::AddItem(std::shared_ptr<MenuItem> item) {
  if (!item)
    return;

  pimpl_->items_.push_back(item);
  [pimpl_->ns_menu_ addItem:(__bridge NSMenuItem*)item->GetNativeObject()];
}

void Menu::InsertItem(size_t index, std::shared_ptr<MenuItem> item) {
  if (!item)
    return;

  if (index >= pimpl_->items_.size()) {
    AddItem(item);
    return;
  }

  pimpl_->items_.insert(pimpl_->items_.begin() + index, item);
  [pimpl_->ns_menu_ insertItem:(__bridge NSMenuItem*)item->GetNativeObject() atIndex:index];
}

bool Menu::RemoveItem(std::shared_ptr<MenuItem> item) {
  if (!item)
    return false;

  auto it = std::find(pimpl_->items_.begin(), pimpl_->items_.end(), item);
  if (it != pimpl_->items_.end()) {
    [pimpl_->ns_menu_ removeItem:(__bridge NSMenuItem*)item->GetNativeObject()];
    pimpl_->items_.erase(it);
    return true;
  }
  return false;
}

bool Menu::RemoveItemById(MenuItemId item_id) {
  for (auto it = pimpl_->items_.begin(); it != pimpl_->items_.end(); ++it) {
    if ((*it)->GetId() == item_id) {
      [pimpl_->ns_menu_ removeItem:(__bridge NSMenuItem*)(*it)->GetNativeObject()];
      pimpl_->items_.erase(it);
      return true;
    }
  }
  return false;
}

bool Menu::RemoveItemAt(size_t index) {
  if (index >= pimpl_->items_.size())
    return false;

  auto item = pimpl_->items_[index];
  [pimpl_->ns_menu_ removeItem:(__bridge NSMenuItem*)item->GetNativeObject()];
  pimpl_->items_.erase(pimpl_->items_.begin() + index);
  return true;
}

void Menu::Clear() {
  [pimpl_->ns_menu_ removeAllItems];
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
  double x = 0, y = 0;

  // Determine position based on strategy type
  switch (strategy.GetType()) {
    case PositioningStrategy::Type::Absolute:
      x = strategy.GetAbsolutePosition().x;
      y = strategy.GetAbsolutePosition().y;
      break;

    case PositioningStrategy::Type::CursorPosition: {
      NSPoint mouse_location = NSPointExt::topLeft([NSEvent mouseLocation]);
      x = mouse_location.x;
      y = mouse_location.y;
      break;
    }

    case PositioningStrategy::Type::Relative: {
      Rectangle rect = strategy.GetRelativeRectangle();
      Point offset = strategy.GetRelativeOffset();
      // Position at top-left corner of rectangle plus offset
      x = rect.x + offset.x;
      y = rect.y + offset.y;
      break;
    }
  }

  // Get menu size for placement adjustments
  NSSize menu_size = [pimpl_->ns_menu_ size];
  double menu_width = menu_size.width;
  double menu_height = menu_size.height;

  // Adjust position based on placement
  // Note: Coordinates are in top-left origin system (y grows downward)
  // popUpMenuPositioningItem places the menu's top-left corner at the specified location
  switch (placement) {
    case Placement::TopStart:  // Menu above reference point, left-aligned
      // Menu's bottom-left corner at reference point
      // No x adjustment needed (left-aligned)
      // Move up by menu height
      y -= menu_height;
      break;

    case Placement::Top:  // Menu above reference point, center-aligned
      // Menu's bottom-center at reference point
      x -= menu_width / 2.0;
      y -= menu_height;
      break;

    case Placement::TopEnd:  // Menu above reference point, right-aligned
      // Menu's bottom-right corner at reference point
      x -= menu_width;
      y -= menu_height;
      break;

    case Placement::RightStart:  // Menu to the right, top-aligned
      // Menu's top-left corner at reference point (no adjustment needed)
      break;

    case Placement::Right:  // Menu to the right, center-aligned
      // Menu's left-center at reference point
      y -= menu_height / 2.0;
      break;

    case Placement::RightEnd:  // Menu to the right, bottom-aligned
      // Menu's bottom-left corner at reference point
      y -= menu_height;
      break;

    case Placement::BottomStart:  // Menu below reference point, left-aligned
      // Menu's top-left corner at reference point (no adjustment needed)
      break;

    case Placement::Bottom:  // Menu below reference point, center-aligned
      // Menu's top-center at reference point
      x -= menu_width / 2.0;
      break;

    case Placement::BottomEnd:  // Menu below reference point, right-aligned
      // Menu's top-right corner at reference point
      x -= menu_width;
      break;

    case Placement::LeftStart:  // Menu to the left, top-aligned
      // Menu's top-right corner at reference point
      x -= menu_width;
      break;

    case Placement::Left:  // Menu to the left, center-aligned
      // Menu's right-center at reference point
      x -= menu_width;
      y -= menu_height / 2.0;
      break;

    case Placement::LeftEnd:  // Menu to the left, bottom-aligned
      // Menu's bottom-right corner at reference point
      x -= menu_width;
      y -= menu_height;
      break;
  }

  // Convert coordinates from top-left origin to macOS screen coordinates (bottom-left origin)
  // macOS screen coordinates: origin at bottom-left, y grows upward
  // Our coordinates: origin at top-left, y grows downward
  CGPoint top_left_point = CGPointMake(x, y);
  NSPoint point = NSPointExt::bottomLeft(top_left_point);

  // Use dispatch to ensure menu popup happens on the main run loop
  // Show the menu using screen coordinates (inView:nil)
  dispatch_async(dispatch_get_main_queue(), ^{
    @autoreleasepool {
      [pimpl_->ns_menu_ popUpMenuPositioningItem:nil atLocation:point inView:nil];
    }
  });

  return true;
}

bool Menu::Close() {
  [pimpl_->ns_menu_ cancelTracking];
  return true;
}

void* Menu::GetNativeObjectInternal() const {
  return (__bridge void*)pimpl_->ns_menu_;
}

}  // namespace nativeapi
