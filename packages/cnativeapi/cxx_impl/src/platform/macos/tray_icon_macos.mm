#include <optional>
#include "../../foundation/geometry.h"
#include "../../image.h"
#include "../../menu.h"
#include "../../positioning_strategy.h"
#include "../../tray_icon.h"
#include "coordinate_utils_macos.h"

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Note: This file assumes ARC (Automatic Reference Counting) is enabled
// for proper memory management of Objective-C objects.

// Forward declarations
typedef void (^TrayIconClickedBlock)(void);
typedef void (^TrayIconRightClickedBlock)(void);
typedef void (^TrayIconDoubleClickedBlock)(void);

// Key for associated object to store tray icon ID
static const void* kTrayIconIdKey = &kTrayIconIdKey;

@interface NSStatusBarButtonTarget : NSObject
@property(nonatomic, copy) TrayIconClickedBlock left_clicked_callback_;
@property(nonatomic, copy) TrayIconRightClickedBlock right_clicked_callback_;
@property(nonatomic, copy) TrayIconDoubleClickedBlock double_clicked_callback_;
- (void)handleStatusItemEvent:(id)sender;
@end

namespace nativeapi {

// Private implementation class
class TrayIcon::Impl {
 public:
  std::shared_ptr<Image> image_;

  Impl(NSStatusItem* status_item)
      : ns_status_item_(status_item),
        ns_status_bar_button_target_(nil),
        menu_closed_listener_id_(0),
        click_handler_setup_(false),
        context_menu_trigger_(ContextMenuTrigger::None) {
    if (status_item) {
      // Check if ID already exists in the associated object
      NSNumber* allocated_id = objc_getAssociatedObject(status_item, kTrayIconIdKey);
      if (allocated_id) {
        // Reuse allocated ID
        id_ = static_cast<TrayIconId>([allocated_id longValue]);
      } else {
        // Allocate new ID and store it
        id_ = IdAllocator::Allocate<TrayIcon>();
        objc_setAssociatedObject(status_item, kTrayIconIdKey, [NSNumber numberWithLong:id_],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      }
    }
  }

  ~Impl() {
    // Remove the menu closed listener before cleaning up
    if (context_menu_ && menu_closed_listener_id_ != 0) {
      context_menu_->RemoveListener(menu_closed_listener_id_);
      menu_closed_listener_id_ = 0;
    }

    // Clean up event handlers if they were set up
    if (click_handler_setup_) {
      CleanupEventHandlers();
    }

    // Then clean up the status item
    if (ns_status_item_) {
      // Clear menu reference
      ns_status_item_.menu = nil;

      // Clean up associated object
      objc_setAssociatedObject(ns_status_item_, kTrayIconIdKey, nil,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);

      [[NSStatusBar systemStatusBar] removeStatusItem:ns_status_item_];
      ns_status_item_ = nil;
    }

    // Finally, safely clean up context_menu_ after all UI references are cleared
    if (context_menu_) {
      context_menu_.reset();  // Explicitly reset shared_ptr
    }
  }

  void SetupEventHandlers() {
    if (click_handler_setup_) {
      return;  // Already set up
    }

    if (!ns_status_item_ || !ns_status_item_.button) {
      return;
    }

    // Create and set up button target
    ns_status_bar_button_target_ = [[NSStatusBarButtonTarget alloc] init];

    // Set up event handlers
    [ns_status_item_.button setTarget:ns_status_bar_button_target_];
    [ns_status_item_.button setAction:@selector(handleStatusItemEvent:)];

    // Enable right-click handling
    [ns_status_item_.button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];

    click_handler_setup_ = true;
  }

  void CleanupEventHandlers() {
    if (!click_handler_setup_) {
      return;  // Not set up
    }

    // Clean up blocks first
    if (ns_status_bar_button_target_) {
      ns_status_bar_button_target_.left_clicked_callback_ = nil;
      ns_status_bar_button_target_.right_clicked_callback_ = nil;
      ns_status_bar_button_target_.double_clicked_callback_ = nil;
      ns_status_bar_button_target_ = nil;
    }

    // Remove target and action to prevent callbacks after destruction
    if (ns_status_item_ && ns_status_item_.button) {
      [ns_status_item_.button setTarget:nil];
      [ns_status_item_.button setAction:nil];
    }

    click_handler_setup_ = false;
  }

  NSStatusItem* ns_status_item_;
  NSStatusBarButtonTarget* ns_status_bar_button_target_;

  TrayIconId id_;
  std::shared_ptr<Menu> context_menu_;
  size_t menu_closed_listener_id_;
  bool click_handler_setup_;
  ContextMenuTrigger context_menu_trigger_;
};

TrayIcon::TrayIcon() : TrayIcon(nullptr) {}

TrayIcon::TrayIcon(void* tray) {
  NSStatusItem* status_item = nullptr;

  if (tray == nullptr) {
    // Create platform-specific NSStatusItem
    NSStatusBar* status_bar = [NSStatusBar systemStatusBar];
    status_item = [status_bar statusItemWithLength:NSVariableStatusItemLength];
  } else {
    status_item = (__bridge NSStatusItem*)tray;
  }

  // Initialize the Impl with the status item
  pimpl_ = std::make_unique<Impl>(status_item);

  // Event handlers will be set up automatically when first listener is added
  // via StartEventListening() override
}

TrayIcon::~TrayIcon() = default;

void TrayIcon::StartEventListening() {
  // Called automatically when first listener is added
  // Set up platform event monitoring
  pimpl_->SetupEventHandlers();

  // Set up click handler blocks
  if (pimpl_->ns_status_bar_button_target_) {
    pimpl_->ns_status_bar_button_target_.left_clicked_callback_ = ^{
      Emit<TrayIconClickedEvent>(pimpl_->id_);
      // Auto-trigger context menu if configured
      if (pimpl_->context_menu_trigger_ == ContextMenuTrigger::Clicked) {
        OpenContextMenu();
      }
    };

    pimpl_->ns_status_bar_button_target_.right_clicked_callback_ = ^{
      Emit<TrayIconRightClickedEvent>(pimpl_->id_);
      // Auto-trigger context menu if configured
      if (pimpl_->context_menu_trigger_ == ContextMenuTrigger::RightClicked) {
        OpenContextMenu();
      }
    };

    pimpl_->ns_status_bar_button_target_.double_clicked_callback_ = ^{
      Emit<TrayIconDoubleClickedEvent>(pimpl_->id_);
      // Auto-trigger context menu if configured
      if (pimpl_->context_menu_trigger_ == ContextMenuTrigger::DoubleClicked) {
        OpenContextMenu();
      }
    };
  }
}

void TrayIcon::StopEventListening() {
  // Called automatically when last listener is removed
  // Clean up platform event monitoring
  pimpl_->CleanupEventHandlers();
}

TrayIconId TrayIcon::GetId() {
  return pimpl_->id_;
}

void TrayIcon::SetIcon(std::shared_ptr<Image> image) {
  if (!pimpl_->ns_status_item_ || !pimpl_->ns_status_item_.button) {
    return;
  }

  // Store the image reference
  pimpl_->image_ = image;

  NSImage* ns_image = nil;

  if (image) {
    // Get NSImage directly from Image object using GetNativeObject
    ns_image = (__bridge NSImage*)image->GetNativeObject();
  }

  if (ns_image) {
    // Set appropriate size for status bar
    [ns_image setSize:NSMakeSize(18, 18)];
    // Make it template image for proper appearance in dark mode
    [ns_image setTemplate:YES];

    // Set the image to the button
    [pimpl_->ns_status_item_.button setImage:ns_image];
  } else {
    // Clear the image if no valid icon is provided
    [pimpl_->ns_status_item_.button setImage:nil];
  }
}

std::shared_ptr<Image> TrayIcon::GetIcon() const {
  return pimpl_->image_;
}

void TrayIcon::SetTitle(std::optional<std::string> title) {
  if (pimpl_->ns_status_item_ && pimpl_->ns_status_item_.button) {
    if (title.has_value()) {
      NSString* title_string = [NSString stringWithUTF8String:title.value().c_str()];
      [pimpl_->ns_status_item_.button setTitle:title_string];
    } else {
      [pimpl_->ns_status_item_.button setTitle:@""];
    }
  }
}

std::optional<std::string> TrayIcon::GetTitle() {
  if (pimpl_->ns_status_item_ && pimpl_->ns_status_item_.button) {
    NSString* title_string = [pimpl_->ns_status_item_.button title];
    if (title_string && [title_string length] > 0) {
      return std::string([title_string UTF8String]);
    }
  }
  return std::nullopt;
}

void TrayIcon::SetTooltip(std::optional<std::string> tooltip) {
  if (pimpl_->ns_status_item_ && pimpl_->ns_status_item_.button) {
    if (tooltip.has_value()) {
      NSString* tooltip_string = [NSString stringWithUTF8String:tooltip.value().c_str()];
      [pimpl_->ns_status_item_.button setToolTip:tooltip_string];
    } else {
      [pimpl_->ns_status_item_.button setToolTip:nil];
    }
  }
}

std::optional<std::string> TrayIcon::GetTooltip() {
  if (pimpl_->ns_status_item_ && pimpl_->ns_status_item_.button) {
    NSString* tooltip_string = [pimpl_->ns_status_item_.button toolTip];
    if (tooltip_string && [tooltip_string length] > 0) {
      return std::string([tooltip_string UTF8String]);
    }
  }
  return std::nullopt;
}

void TrayIcon::SetContextMenu(std::shared_ptr<Menu> menu) {
  // Remove previous menu listener if it exists
  if (pimpl_->context_menu_ && pimpl_->menu_closed_listener_id_ != 0) {
    pimpl_->context_menu_->RemoveListener(pimpl_->menu_closed_listener_id_);
    pimpl_->menu_closed_listener_id_ = 0;
  }

  // Store the menu reference
  // Don't set the menu directly to the status item, as this would cause
  // macOS to take over click handling and prevent our custom click events
  // Instead, we'll show the menu manually in our click handler
  pimpl_->context_menu_ = menu;

  if (pimpl_->context_menu_) {
    auto pimpl_raw = pimpl_.get();
    pimpl_->menu_closed_listener_id_ = pimpl_->context_menu_->AddListener<MenuClosedEvent>(
        [pimpl_raw](const MenuClosedEvent& event) {
          if (pimpl_raw && pimpl_raw->ns_status_item_) {
            pimpl_raw->ns_status_item_.menu = nil;
          }
        });
  }
}

std::shared_ptr<Menu> TrayIcon::GetContextMenu() {
  return pimpl_->context_menu_;
}

Rectangle TrayIcon::GetBounds() {
  Rectangle bounds = {0, 0, 0, 0};

  if (pimpl_->ns_status_item_ && pimpl_->ns_status_item_.button && pimpl_->ns_status_item_.button.window) {
    NSStatusBarButton* button = pimpl_->ns_status_item_.button;
    NSRect window_rect = [button convertRect:button.bounds toView:nil];
    NSRect screen_rect = [button.window convertRectToScreen:window_rect];

    // Flip against the primary screen ([NSScreen screens][0]), matching every
    // other coordinate conversion in this library. Do NOT use mainScreen here:
    // it is the screen of the current key window, which makes the result depend
    // on where keyboard focus happens to be on multi-display setups.
    CGPoint top_left = NSRectExt::topLeft(screen_rect);

    bounds.x = top_left.x;
    bounds.y = top_left.y;
    bounds.width = screen_rect.size.width;
    bounds.height = screen_rect.size.height;
  }

  return bounds;
}

bool TrayIcon::SetVisible(bool visible) {
  if (!pimpl_->ns_status_item_) {
    return false;
  }

  [pimpl_->ns_status_item_ setVisible:visible ? YES : NO];
  return true;
}

bool TrayIcon::IsVisible() {
  if (pimpl_->ns_status_item_) {
    return [pimpl_->ns_status_item_ isVisible] == YES;
  }
  return false;
}

bool TrayIcon::OpenContextMenu() {
  if (!pimpl_->context_menu_ || !pimpl_->ns_status_item_ || !pimpl_->ns_status_item_.button) {
    return false;
  }

  // Use the Swift approach: set menu to status item and simulate click
  // Get the native NSMenu object from our Menu wrapper
  NSMenu* native_menu = (__bridge NSMenu*)pimpl_->context_menu_->GetNativeObject();
  if (!native_menu) {
    return false;
  }

  //  // Set our menu delegate to handle menu close events
  //  [nativeMenu setDelegate:pimpl_->menu_delegate_];

  // Set the menu to the status item (like Swift version)
  pimpl_->ns_status_item_.menu = native_menu;

  // Simulate a click to show the menu (like Swift version)
  [pimpl_->ns_status_item_.button performClick:nil];

  return true;
}

bool TrayIcon::CloseContextMenu() {
  if (!pimpl_->context_menu_) {
    return true;  // No menu to close, consider success
  }

  // Close the context menu
  return pimpl_->context_menu_->Close();
}

void TrayIcon::SetContextMenuTrigger(ContextMenuTrigger trigger) {
  pimpl_->context_menu_trigger_ = trigger;
}

ContextMenuTrigger TrayIcon::GetContextMenuTrigger() {
  return pimpl_->context_menu_trigger_;
}

void* TrayIcon::GetNativeObjectInternal() const {
  return (__bridge void*)pimpl_->ns_status_item_;
}

}  // namespace nativeapi

// Implementation of NSStatusBarButtonTarget
@implementation NSStatusBarButtonTarget

- (void)handleStatusItemEvent:(id)sender {
  NSEvent* event = [NSApp currentEvent];
  if (!event)
    return;

  // Check the type of click and call appropriate block
  if (event.type == NSEventTypeRightMouseUp ||
      (event.type == NSEventTypeLeftMouseUp &&
       (event.modifierFlags & NSEventModifierFlagControl))) {
    // Right click or Ctrl+Left click
    if (_right_clicked_callback_) {
      _right_clicked_callback_();
    }
  } else if (event.type == NSEventTypeLeftMouseUp) {
    // Check for double click
    if (event.clickCount == 2) {
      if (_double_clicked_callback_) {
        _double_clicked_callback_();
      }
    } else {
      if (_left_clicked_callback_) {
        _left_clicked_callback_();
      }
    }
  }
}

@end
