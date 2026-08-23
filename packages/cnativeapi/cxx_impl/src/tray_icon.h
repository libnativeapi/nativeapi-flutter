#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <string>
#include "foundation/event.h"
#include "foundation/event_emitter.h"
#include "foundation/geometry.h"
#include "foundation/id_allocator.h"
#include "menu.h"

namespace nativeapi {

class Image;

typedef IdAllocator::IdType TrayIconId;

/**
 * @brief Defines how the context menu is triggered for a tray icon.
 *
 * This enum specifies which mouse interactions should display the tray icon's
 * context menu. The values align with tray icon event types for consistency.
 */
enum class ContextMenuTrigger {
  /**
   * @brief Context menu is not automatically triggered by mouse events.
   *
   * The application must call OpenContextMenu() explicitly to display the menu.
   * Use this when you want full control over when the menu appears.
   */
  None,

  /**
   * @brief Context menu is triggered on TrayIconClickedEvent.
   *
   * Automatically opens the context menu when the tray icon is left-clicked.
   * This is common on some Linux desktop environments.
   */
  Clicked,

  /**
   * @brief Context menu is triggered on TrayIconRightClickedEvent.
   *
   * Automatically opens the context menu when the tray icon is right-clicked.
   * This follows the convention on Windows and most desktop environments.
   */
  RightClicked,

  /**
   * @brief Context menu is triggered on TrayIconDoubleClickedEvent.
   *
   * Automatically opens the context menu when the tray icon is double-clicked.
   * Less common but useful for applications that use single-click for another action.
   */
  DoubleClicked
};

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/**
 * @brief Base class for all tray icon-related events.
 *
 * This class provides common functionality for tray icon events.
 */
class TrayIconEvent : public Event {
 public:
  virtual ~TrayIconEvent() = default;

  std::string GetTypeName() const override { return "TrayIconEvent"; }
};

/**
 * @brief Tray icon clicked event.
 *
 * This event is fired when a tray icon is clicked (left-clicked).
 */
class TrayIconClickedEvent : public TrayIconEvent {
 public:
  TrayIconClickedEvent(TrayIconId tray_icon_id) : tray_icon_id_(tray_icon_id) {}

  TrayIconId GetTrayIconId() const { return tray_icon_id_; }

  std::string GetTypeName() const override { return "TrayIconClickedEvent"; }

 private:
  TrayIconId tray_icon_id_;
};

/**
 * @brief Tray icon right-clicked event.
 *
 * This event is fired when a tray icon is right-clicked.
 */
class TrayIconRightClickedEvent : public TrayIconEvent {
 public:
  TrayIconRightClickedEvent(TrayIconId tray_icon_id) : tray_icon_id_(tray_icon_id) {}

  TrayIconId GetTrayIconId() const { return tray_icon_id_; }

  std::string GetTypeName() const override { return "TrayIconRightClickedEvent"; }

 private:
  TrayIconId tray_icon_id_;
};

/**
 * @brief Tray icon double-clicked event.
 *
 * This event is fired when a tray icon is double-clicked.
 */
class TrayIconDoubleClickedEvent : public TrayIconEvent {
 public:
  TrayIconDoubleClickedEvent(TrayIconId tray_icon_id) : tray_icon_id_(tray_icon_id) {}

  TrayIconId GetTrayIconId() const { return tray_icon_id_; }

  std::string GetTypeName() const override { return "TrayIconDoubleClickedEvent"; }

 private:
  TrayIconId tray_icon_id_;
};

/**
 * @brief TrayIcon represents a system tray icon (notification area icon).
 *
 * This class provides a cross-platform interface for creating and managing
 * system tray icons. System tray icons appear in the notification area of
 * the desktop and provide quick access to application functionality through
 * context menus and click events.
 *
 * The class supports:
 * - Setting custom icons (including base64-encoded images)
 * - Displaying text titles and tooltips
 * - Context menus for user interaction
 * - Event emission for mouse clicks (TrayIconClickedEvent,
 * TrayIconRightClickedEvent, TrayIconDoubleClickedEvent)
 * - Visibility control
 *
 * @note This class uses the PIMPL idiom to hide platform-specific
 * implementation details and ensure binary compatibility across different
 * platforms.
 *
 * @example
 * ```cpp
 * // Create a tray icon
 * auto tray_icon = std::make_shared<TrayIcon>();
 * tray_icon->SetIcon("path/to/icon.png");
 * tray_icon->SetTooltip("My Application");
 *
 * // Set up event listeners
 * tray_icon->AddListener<TrayIconClickedEvent>([](const TrayIconClickedEvent&
 * event) {
 *     // Handle left click - show/hide main window
 *     main_window->IsVisible() ? main_window->Hide() : main_window->Show();
 * });
 *
 * tray_icon->AddListener<TrayIconRightClickedEvent>([](const
 * TrayIconRightClickedEvent& event) {
 *     // Handle right click - open context menu
 *     tray_icon->OpenContextMenu();
 * });
 *
 * // Set up a context menu
 * Menu menu;
 * auto item = menu.CreateItem("Exit");
 * menu.AddItem(item);
 * tray_icon->SetContextMenu(menu);
 *
 * // Show the tray icon
 * tray_icon->SetVisible(true);
 * ```
 */
class TrayIcon : public EventEmitter<TrayIconEvent>, public NativeObjectProvider {
 public:
  /**
   * @brief Default constructor for TrayIcon.
   *
   * Creates a new tray icon instance with platform-specific initialization.
   * The icon will not be visible until SetVisible(true) is called.
   * This constructor handles all platform-specific setup internally.
   */
  TrayIcon();

  /**
   * @brief Constructor that wraps an existing platform-specific tray icon.
   *
   * This constructor is typically used internally by the TrayManager
   * to wrap existing system tray icons.
   *
   * @param tray Pointer to the platform-specific tray icon object
   */
  TrayIcon(void* tray);

  /**
   * @brief Destructor for TrayIcon.
   *
   * Cleans up the tray icon and removes it from the system tray if visible.
   * Also releases any associated platform-specific resources.
   */
  virtual ~TrayIcon();

  /**
   * @brief Get the unique identifier for this tray icon.
   *
   * @return The unique identifier for this tray icon
   */
  TrayIconId GetId();

  /**
   * @brief Set the icon image for the tray icon using an Image object.
   *
   * This is the preferred method for setting the tray icon image as it
   * provides type safety and better control over image handling.
   *
   * @param image Shared pointer to an Image object, or nullptr to clear the icon
   *
   * @example
   * ```cpp
   * // Using file path
   * auto icon = Image::FromFile("/path/to/icon.png");
   * trayIcon->SetIcon(icon);
   *
   * // Using base64 data
   * auto icon = Image::FromBase64("data:image/png;base64,iVBORw0KGgo...");
   * trayIcon->SetIcon(icon);
   *
   * // Using raw RGBA data
   * std::vector<uint8_t> pixels = {...};
   * auto icon = Image::FromRawData(pixels.data(), 32, 32, ImagePixelFormat::RGBA32);
   * trayIcon->SetIcon(icon);
   *
   * // Clear icon
   * trayIcon->SetIcon(nullptr);
   * ```
   */
  void SetIcon(std::shared_ptr<Image> image);

  /**
   * @brief Get the current icon image of the tray icon.
   *
   * @return A shared pointer to the current Image object, or nullptr if no icon is set
   */
  std::shared_ptr<Image> GetIcon() const;

  /**
   * @brief Set the title text for the tray icon.
   *
   * On platforms that support it (primarily macOS), the title text
   * is displayed next to the icon in the status bar. On other platforms,
   * this may be used internally for identification purposes.
   *
   * @param title The title text to display, or std::nullopt to clear the title
   *
   * @note On Windows and most Linux desktop environments, tray icons
   *       do not display title text directly.
   */
  void SetTitle(std::optional<std::string> title);

  /**
   * @brief Get the current title text of the tray icon.
   *
   * @return The current title text as an optional string, or std::nullopt if no title is set
   */
  std::optional<std::string> GetTitle();

  /**
   * @brief Set the tooltip text for the tray icon.
   *
   * The tooltip appears when the user hovers the mouse over the tray icon.
   * This is supported on all platforms and is useful for providing
   * additional context about the application's current state.
   *
   * @param tooltip The tooltip text to display on hover, or std::nullopt to clear the tooltip
   *
   * @example
   * ```cpp
   * tray_icon->SetTooltip("MyApp - Status: Connected");
   * tray_icon->SetTooltip(std::nullopt); // Clear tooltip
   * ```
   */
  void SetTooltip(std::optional<std::string> tooltip);

  /**
   * @brief Get the current tooltip text of the tray icon.
   *
   * @return The current tooltip text as an optional string, or std::nullopt if no tooltip is set
   */
  std::optional<std::string> GetTooltip();

  /**
   * @brief Set the context menu for the tray icon.
   *
   * The context menu is displayed when the user right-clicks (or equivalent
   * platform-specific action) on the tray icon. The menu provides the primary
   * interface for user interaction with the application.
   *
   * @param menu The Menu object containing the context menu items
   *
   * @note The Menu object is copied internally, so the original menu
   *       object's lifetime doesn't need to extend beyond this call.
   *
   * @example
   * ```cpp
   * Menu context_menu;
   * context_menu.AddItem(context_menu.CreateItem("Show Window"));
   * context_menu.AddSeparator();
   * context_menu.AddItem(context_menu.CreateItem("Exit"));
   * tray_icon->SetContextMenu(context_menu);
   * ```
   */
  void SetContextMenu(std::shared_ptr<Menu> menu);

  /**
   * @brief Get the current context menu of the tray icon.
   *
   * @return A copy of the current context Menu object
   */
  std::shared_ptr<Menu> GetContextMenu();

  /**
   * @brief Set the context menu trigger behavior.
   *
   * Determines which mouse interactions will automatically display the
   * context menu. By default, the trigger is set to None, requiring
   * explicit control via OpenContextMenu() or by setting a trigger mode.
   *
   * @param trigger The desired trigger behavior
   *
   * @note When set to ContextMenuTrigger::None (default), the context menu
   *       will only appear when OpenContextMenu() is called explicitly, giving
   *       you full control over menu display through event listeners.
   *
   * @example
   * ```cpp
   * // Right click shows menu (common on Windows/Linux)
   * tray_icon->SetContextMenuTrigger(ContextMenuTrigger::RightClicked);
   *
   * // Left click shows menu (common on some Linux environments and macOS)
   * tray_icon->SetContextMenuTrigger(ContextMenuTrigger::Clicked);
   *
   * // Double click shows menu
   * tray_icon->SetContextMenuTrigger(ContextMenuTrigger::DoubleClicked);
   *
   * // Manual control (default) - handle events yourself
   * tray_icon->SetContextMenuTrigger(ContextMenuTrigger::None);
   * tray_icon->AddListener<TrayIconRightClickedEvent>([&](const auto& e) {
   *   // Custom logic before showing menu
   *   tray_icon->OpenContextMenu();
   * });
   * ```
   */
  void SetContextMenuTrigger(ContextMenuTrigger trigger);

  /**
   * @brief Get the current context menu trigger behavior.
   *
   * @return The current ContextMenuTrigger setting
   */
  ContextMenuTrigger GetContextMenuTrigger();

  /**
   * @brief Get the screen coordinates and dimensions of the tray icon.
   *
   * Returns the bounding rectangle of the tray icon in screen coordinates.
   * This can be useful for positioning popup windows or dialogs relative
   * to the tray icon.
   *
   * @return Rectangle containing the screen position and size of the tray icon
   *
   * @note The accuracy of this information varies by platform:
   *       - macOS: Precise bounds of the status item
   *       - Windows: Approximate location of the notification area
   *       - Linux: Depends on the desktop environment and system tray
   * implementation
   */
  Rectangle GetBounds();

  /**
   * @brief Set the visibility of the tray icon in the system tray.
   *
   * Controls whether the tray icon is visible in the system notification area.
   * This method replaces the previous Show() and Hide() methods for a more
   * unified interface.
   *
   * @param visible true to make the icon visible, false to hide it
   * @return true if the visibility was successfully changed, false otherwise
   *
   * @note On some platforms, showing a tray icon may fail if the
   *       system tray is not available or if there are too many icons.
   *
   * @example
   * ```cpp
   * // Show the tray icon
   * tray_icon->SetVisible(true);
   *
   * // Hide the tray icon
   * tray_icon->SetVisible(false);
   * ```
   */
  bool SetVisible(bool visible);

  /**
   * @brief Check if the tray icon is currently visible.
   *
   * @return true if the icon is visible in the system tray, false otherwise
   */
  bool IsVisible();

  /**
   * @brief Display the context menu at the tray icon's location.
   *
   * Opens the context menu at a default position near the tray icon.
   * This is a convenience method that automatically determines an appropriate
   * position based on the tray icon's current location.
   *
   * @return true if the menu was successfully opened, false otherwise
   *
   * @note The exact positioning behavior may vary by platform:
   *       - macOS: Menu appears below the status item
   *       - Windows: Menu appears near the notification area
   *       - Linux: Menu appears at cursor position or near tray area
   *
   * @example
   * ```cpp
   * // Open context menu at default location
   * tray_icon->OpenContextMenu();
   * ```
   */
  bool OpenContextMenu();

  /**
   * @brief Close the currently displayed context menu.
   *
   * Closes the tray icon's context menu if it is currently visible.
   * This allows for programmatic dismissal of the menu.
   *
   * @return true if the menu was successfully closed or wasn't visible, false
   * on error
   *
   * @note This method is useful for keyboard shortcuts or programmatic control
   *       that needs to dismiss the context menu without user interaction.
   *
   * @example
   * ```cpp
   * // Close the context menu programmatically
   * tray_icon->CloseContextMenu();
   * ```
   */
  bool CloseContextMenu();

 protected:
  /**
   * @brief Called when the first listener is added.
   *
   * Subclasses can override this to start platform-specific event monitoring.
   * This is called automatically by the EventEmitter when transitioning from
   * 0 to 1+ listeners.
   */
  void StartEventListening() override;

  /**
   * @brief Called when the last listener is removed.
   *
   * Subclasses can override this to stop platform-specific event monitoring.
   * This is called automatically by the EventEmitter when transitioning from
   * 1+ to 0 listeners.
   */
  void StopEventListening() override;

  /**
   * @brief Internal method to get the platform-specific native tray icon object.
   *
   * This method must be implemented by platform-specific code to return
   * the underlying native tray icon object.
   *
   * @return Pointer to the native menu item object
   */
  void* GetNativeObjectInternal() const override;

 private:
  /**
   * @brief Private implementation class using the PIMPL idiom.
   *
   * This forward declaration hides the platform-specific implementation
   * details from the public interface, allowing for better binary
   * compatibility and cleaner separation of concerns.
   */
  class Impl;

  /**
   * @brief Pointer to the private implementation instance.
   *
   * This pointer manages the platform-specific implementation of
   * the tray icon functionality.
   */
  std::unique_ptr<Impl> pimpl_;
};

}  // namespace nativeapi
