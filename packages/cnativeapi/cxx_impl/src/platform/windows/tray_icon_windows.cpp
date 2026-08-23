// clang-format off
#include <windows.h>
#include <shellapi.h>
// clang-format on
#include <functional>
#include <iostream>
#include <memory>
#include <optional>
#include <string>

#include "../../foundation/geometry.h"
#include "../../foundation/id_allocator.h"
#include "../../image.h"
#include "../../menu.h"
#include "../../positioning_strategy.h"
#include "../../tray_icon.h"
#include "string_utils_windows.h"
#include "window_message_dispatcher.h"

namespace nativeapi {

// Forward declaration for Windows-specific helper function from
// image_windows.cpp
HICON ImageToHICON(const Image* image, int width, int height);

// Private implementation class
class TrayIcon::Impl {
 public:
  std::shared_ptr<Image> image_;

  // Callback function types
  using ClickedCallback = std::function<void(TrayIconId)>;
  using RightClickedCallback = std::function<void(TrayIconId)>;
  using DoubleClickedCallback = std::function<void(TrayIconId)>;

  Impl()
      : hwnd_(nullptr),
        icon_handle_(nullptr),
        window_proc_handle_id_(-1),
        event_monitoring_setup_(false),
        context_menu_trigger_(ContextMenuTrigger::None) {
    tray_icon_id_ = IdAllocator::Allocate<TrayIcon>();
  }

  Impl(HWND hwnd,
       ClickedCallback clicked_callback,
       RightClickedCallback right_clicked_callback,
       DoubleClickedCallback double_clicked_callback)
      : hwnd_(hwnd),
        icon_handle_(nullptr),
        window_proc_handle_id_(-1),
        clicked_callback_(std::move(clicked_callback)),
        right_clicked_callback_(std::move(right_clicked_callback)),
        double_clicked_callback_(std::move(double_clicked_callback)),
        event_monitoring_setup_(false),
        context_menu_trigger_(ContextMenuTrigger::None) {
    tray_icon_id_ = IdAllocator::Allocate<TrayIcon>();
    // Initialize NOTIFYICONDATA structure
    ZeroMemory(&nid_, sizeof(NOTIFYICONDATAW));
    nid_.cbSize = sizeof(NOTIFYICONDATAW);
    nid_.hWnd = hwnd_;
    nid_.uID = static_cast<UINT>(tray_icon_id_);  // Use tray_icon_id_ directly
    nid_.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
    nid_.uCallbackMessage = WM_USER + 1;  // Custom message for tray icon events

    // Event monitoring will be set up when first listener is added
    // via StartEventListening() override
  }

  ~Impl() {
    // Clean up event monitoring if it was set up
    if (event_monitoring_setup_) {
      CleanupEventMonitoring();
    }

    if (hwnd_) {
      Shell_NotifyIconW(NIM_DELETE, &nid_);
      // Note: We don't destroy the shared host window
    }
    if (icon_handle_) {
      DestroyIcon(icon_handle_);
    }
  }

  // Handle window procedure delegate
  std::optional<LRESULT> HandleWindowProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
    if (message == WM_USER + 1 && wparam == static_cast<WPARAM>(tray_icon_id_)) {
      if (lparam == WM_LBUTTONUP) {
        std::cout << "TrayIcon: Left button clicked, tray_icon_id = " << tray_icon_id_ << std::endl;
        // Call clicked callback
        if (clicked_callback_) {
          clicked_callback_(tray_icon_id_);
        }
      } else if (lparam == WM_RBUTTONUP) {
        std::cout << "TrayIcon: Right button clicked, tray_icon_id = " << tray_icon_id_
                  << std::endl;
        // Call right clicked callback
        if (right_clicked_callback_) {
          right_clicked_callback_(tray_icon_id_);
        }
      } else if (lparam == WM_LBUTTONDBLCLK) {
        std::cout << "TrayIcon: Left button double-clicked, tray_icon_id = " << tray_icon_id_
                  << std::endl;
        // Call double clicked callback
        if (double_clicked_callback_) {
          double_clicked_callback_(tray_icon_id_);
        }
      }
      return 0;
    }
    return std::nullopt;  // Let default window procedure handle it
  }

  void SetupEventMonitoring() {
    if (event_monitoring_setup_) {
      return;  // Already set up
    }

    if (!hwnd_) {
      return;
    }

    // Register window procedure handler
    window_proc_handle_id_ = WindowMessageDispatcher::GetInstance().RegisterHandler(
        hwnd_, [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
          return HandleWindowProc(hwnd, message, wparam, lparam);
        });

    event_monitoring_setup_ = true;
  }

  void CleanupEventMonitoring() {
    if (!event_monitoring_setup_) {
      return;  // Not set up
    }

    // Unregister window procedure handler
    if (window_proc_handle_id_ != -1) {
      WindowMessageDispatcher::GetInstance().UnregisterHandler(window_proc_handle_id_);
      window_proc_handle_id_ = -1;
    }

    event_monitoring_setup_ = false;
  }

  int window_proc_handle_id_;
  HWND hwnd_;
  NOTIFYICONDATAW nid_;
  std::shared_ptr<Menu> context_menu_;
  HICON icon_handle_;
  TrayIconId tray_icon_id_;
  bool event_monitoring_setup_;
  ContextMenuTrigger context_menu_trigger_;

  // Callback functions for event emission
  ClickedCallback clicked_callback_;
  RightClickedCallback right_clicked_callback_;
  DoubleClickedCallback double_clicked_callback_;
};

TrayIcon::TrayIcon() : TrayIcon(nullptr) {}

TrayIcon::TrayIcon(void* native_tray_icon) {
  HWND hwnd = nullptr;

  if (native_tray_icon == nullptr) {
    // Use the shared host window from WindowMessageDispatcher
    hwnd = WindowMessageDispatcher::GetInstance().GetHostWindow();
  } else {
    // Wrap existing native tray icon
    // In a real implementation, you'd extract HWND from the tray parameter
    // For now, this is mainly used by TrayManager for creating uninitialized
    // icons
  }

  // Initialize the Impl with the window handle
  // The tray_icon_id will be allocated inside Impl constructor
  if (hwnd) {
    // Create callback functions that emit events
    auto clicked_callback = [this](TrayIconId id) {
      this->Emit<TrayIconClickedEvent>(id);
      // Auto-trigger context menu if configured
      if (pimpl_ && pimpl_->context_menu_trigger_ == ContextMenuTrigger::Clicked) {
        this->OpenContextMenu();
      }
    };

    auto right_clicked_callback = [this](TrayIconId id) {
      this->Emit<TrayIconRightClickedEvent>(id);
      // Auto-trigger context menu if configured
      if (pimpl_ && pimpl_->context_menu_trigger_ == ContextMenuTrigger::RightClicked) {
        this->OpenContextMenu();
      }
    };

    auto double_clicked_callback = [this](TrayIconId id) {
      this->Emit<TrayIconDoubleClickedEvent>(id);
      // Auto-trigger context menu if configured
      if (pimpl_ && pimpl_->context_menu_trigger_ == ContextMenuTrigger::DoubleClicked) {
        this->OpenContextMenu();
      }
    };

    pimpl_ =
        std::make_unique<Impl>(hwnd, std::move(clicked_callback), std::move(right_clicked_callback),
                               std::move(double_clicked_callback));
  } else {
    // Failed to create window, create uninitialized Impl
    pimpl_ = std::make_unique<Impl>();
  }
}

TrayIcon::~TrayIcon() {}

void TrayIcon::StartEventListening() {
  // Called automatically when first listener is added
  // Set up platform event monitoring
  pimpl_->SetupEventMonitoring();
}

void TrayIcon::StopEventListening() {
  // Called automatically when last listener is removed
  // Clean up platform event monitoring
  pimpl_->CleanupEventMonitoring();
}

TrayIconId TrayIcon::GetId() {
  return pimpl_->tray_icon_id_;
}

void TrayIcon::SetIcon(std::shared_ptr<Image> image) {
  if (!pimpl_->hwnd_) {
    return;
  }

  // Store the image reference
  pimpl_->image_ = image;

  HICON hIcon = nullptr;

  if (image) {
    // Get system tray icon size (following Windows guidelines)
    int iconWidth = GetSystemMetrics(SM_CXSMICON);
    int iconHeight = GetSystemMetrics(SM_CYSMICON);

    // Use the helper function to convert Image to HICON
    // This handles file paths efficiently (like tray_manager_plugin.cpp)
    // and falls back to bitmap conversion when needed
    hIcon = ImageToHICON(image.get(), iconWidth, iconHeight);

    // Fallback to default icon if conversion failed
    if (!hIcon) {
      hIcon = LoadIcon(nullptr, IDI_APPLICATION);
    }
  } else {
    // Use default application icon when no image is provided
    hIcon = LoadIcon(nullptr, IDI_APPLICATION);
  }

  if (hIcon) {
    // Clean up previous icon
    if (pimpl_->icon_handle_) {
      DestroyIcon(pimpl_->icon_handle_);
    }

    pimpl_->icon_handle_ = hIcon;
    pimpl_->nid_.hIcon = hIcon;

    // Update the icon if it's currently visible
    if (IsVisible()) {
      Shell_NotifyIconW(NIM_MODIFY, &pimpl_->nid_);
    }
  }
}

std::shared_ptr<Image> TrayIcon::GetIcon() const {
  return pimpl_->image_;
}

void TrayIcon::SetTitle(std::optional<std::string> title) {
  (void)title;  // Unused on Windows
  // Windows tray icons don't support title
}

std::optional<std::string> TrayIcon::GetTitle() {
  // Windows tray icons don't support title
  return std::nullopt;
}

void TrayIcon::SetTooltip(std::optional<std::string> tooltip) {
  if (pimpl_->hwnd_) {
    std::string tooltip_str = tooltip.has_value() ? *tooltip : "";
    std::wstring wtooltip = StringToWString(tooltip_str);
    wcsncpy_s(pimpl_->nid_.szTip, _countof(pimpl_->nid_.szTip), wtooltip.c_str(), _TRUNCATE);

    // Update if icon is visible (check if hIcon is set as indicator)
    if (pimpl_->nid_.hIcon) {
      Shell_NotifyIconW(NIM_MODIFY, &pimpl_->nid_);
    }
  }
}

std::optional<std::string> TrayIcon::GetTooltip() {
  if (pimpl_->hwnd_ && pimpl_->nid_.szTip[0] != L'\0') {
    return WCharArrayToString(pimpl_->nid_.szTip);
  }
  return std::nullopt;
}

void TrayIcon::SetContextMenu(std::shared_ptr<Menu> menu) {
  pimpl_->context_menu_ = menu;
}

std::shared_ptr<Menu> TrayIcon::GetContextMenu() {
  return pimpl_->context_menu_;
}

Rectangle TrayIcon::GetBounds() {
  Rectangle bounds = {0, 0, 0, 0};

  if (pimpl_->hwnd_ && IsVisible()) {
    RECT rect;
    NOTIFYICONIDENTIFIER niid = {};
    niid.cbSize = sizeof(NOTIFYICONIDENTIFIER);
    niid.hWnd = pimpl_->hwnd_;
    niid.uID = static_cast<UINT>(pimpl_->tray_icon_id_);

    // Get the rectangle of the notification icon
    if (Shell_NotifyIconGetRect(&niid, &rect) == S_OK) {
      bounds.x = rect.left;
      bounds.y = rect.top;
      bounds.width = rect.right - rect.left;
      bounds.height = rect.bottom - rect.top;
    }
  }

  return bounds;
}

bool TrayIcon::SetVisible(bool visible) {
  if (!pimpl_->hwnd_) {
    return false;
  }

  bool currently_visible = IsVisible();

  if (visible && !currently_visible) {
    // Show the tray icon
    return Shell_NotifyIconW(NIM_ADD, &pimpl_->nid_) == TRUE;
  } else if (!visible && currently_visible) {
    // Hide the tray icon
    return Shell_NotifyIconW(NIM_DELETE, &pimpl_->nid_) == TRUE;
  } else {
    // Already in the desired state
    return true;
  }
}

bool TrayIcon::IsVisible() {
  if (!pimpl_->hwnd_) {
    return false;
  }

  // Check if the tray icon is visible by querying its bounds
  NOTIFYICONIDENTIFIER niid = {};
  niid.cbSize = sizeof(NOTIFYICONIDENTIFIER);
  niid.hWnd = pimpl_->hwnd_;
  niid.uID = static_cast<UINT>(pimpl_->tray_icon_id_);

  RECT rect;
  return Shell_NotifyIconGetRect(&niid, &rect) == S_OK;
}

bool TrayIcon::OpenContextMenu() {
  if (!pimpl_->context_menu_) {
    return false;
  }

  return pimpl_->context_menu_->Open(PositioningStrategy::CursorPosition());
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
  return reinterpret_cast<void*>(static_cast<uintptr_t>(pimpl_->tray_icon_id_));
}

}  // namespace nativeapi
