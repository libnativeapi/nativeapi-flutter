#pragma once

#include <cstddef>
#include <functional>
#include <memory>
#include <optional>
#include <unordered_map>
#include <vector>

#include "foundation/event.h"
#include "foundation/event_emitter.h"
#include "foundation/geometry.h"
#include "window.h"

namespace nativeapi {

/**
 * @brief WindowManager is a singleton that manages all windows in the application
 *
 * The WindowManager provides a centralized interface for creating, managing, and
 * monitoring windows across the entire application. It follows the singleton pattern
 * to ensure there's only one instance managing all windows, and provides event
 * notifications for various window state changes.
 *
 * Key features:
 * - Singleton pattern ensures single point of window management
 * - Event-driven architecture for window state notifications
 * - Cross-platform window creation and management
 * - Thread-safe access to the singleton instance
 * - Automatic cleanup of resources on destruction
 *
 * @note This class is thread-safe for singleton access, but individual operations
 *       may require additional synchronization depending on the platform implementation.
 */
class WindowManager : public EventEmitter<WindowEvent> {
 public:
  /**
   * @brief Get the singleton instance of WindowManager
   *
   * This method provides access to the unique instance of WindowManager using
   * the Meyer's singleton pattern. The instance is created on first call and
   * remains alive for the duration of the application. This method is thread-safe
   * and guarantees that only one instance will be created even in multi-threaded
   * environments.
   *
   * @return Reference to the singleton WindowManager instance
   * @thread_safety This method is thread-safe
   *
   * @code
   * // Usage example:
   * auto& manager = WindowManager::GetInstance();
   * auto window = manager.Create(options);
   * @endcode
   */
  static WindowManager& GetInstance();

  /**
   * @brief Destructor
   *
   * Cleans up all resources, closes remaining windows, and stops event monitoring.
   * This is automatically called when the application terminates.
   */
  virtual ~WindowManager();

  /**
   * @brief Get a window by its unique ID
   *
   * Retrieves a window instance from the internal registry using its ID.
   * This method is useful for accessing windows when you have their ID
   * from events or other sources.
   *
   * @param id The unique identifier of the window to retrieve
   * @return Shared pointer to the Window instance, or nullptr if window not found
   *
   * @code
   * WindowId window_id = some_event.GetWindowId();
   * auto window = WindowManager::GetInstance().Get(window_id);
   * if (window) {
   *     window->Show();
   * }
   * @endcode
   */
  std::shared_ptr<Window> Get(WindowId id);

  /**
   * @brief Get all managed windows
   *
   * Returns a vector containing all currently managed window instances.
   * The returned vector is a snapshot of the current state and modifications
   * to it won't affect the internal window registry.
   *
   * @return Vector of shared pointers to all Window instances
   *
   * @code
   * auto all_windows = WindowManager::GetInstance().GetAll();
   * for (auto& window : all_windows) {
   *     window->Hide();  // Hide all windows
   * }
   * @endcode
   */
  std::vector<std::shared_ptr<Window>> GetAll();

  /**
   * @brief Get the currently active/focused window
   *
   * Returns the window that currently has keyboard focus and is active.
   * This is typically the window that the user is currently interacting with.
   *
   * @return Shared pointer to the current Window instance, or nullptr if no window is active
   *
   * @code
   * auto current = WindowManager::GetInstance().GetCurrent();
   * if (current) {
   *     std::cout << "Active window: " << current->GetTitle() << std::endl;
   * }
   * @endcode
   */
  std::shared_ptr<Window> GetCurrent();

  /**
   * Hooks invoked before native window show/hide operations (e.g., via swizzling).
   * These are declarations only; platform implementations can register and invoke them.
   */
  using WindowWillShowHook = std::function<void(WindowId)>;
  using WindowWillHideHook = std::function<void(WindowId)>;
  using WindowWillCloseHook = std::function<void(WindowId)>;

  // Set or clear single hooks (pass std::nullopt to clear)
  void SetWillShowHook(std::optional<WindowWillShowHook> hook);
  void SetWillHideHook(std::optional<WindowWillHideHook> hook);
  void SetWillCloseHook(std::optional<WindowWillCloseHook> hook);

  // Check if hooks are set
  bool HasWillShowHook() const;
  bool HasWillHideHook() const;
  bool HasWillCloseHook() const;

  // Called by platform layer BEFORE the actual show/hide/close happens
  void HandleWillShow(WindowId id);
  void HandleWillHide(WindowId id);
  void HandleWillClose(WindowId id);

  /**
   * Call the platform's original show/hide/close implementations for a window,
   * bypassing swizzled paths. Returns true if successfully invoked.
   * On unsupported platforms, these return false.
   */
  bool CallOriginalShow(WindowId id);
  bool CallOriginalHide(WindowId id);
  bool CallOriginalClose(WindowId id);

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

 private:
  /**
   * @brief Private constructor to enforce singleton pattern
   *
   * Initializes the WindowManager instance, sets up platform-specific
   * event monitoring, and prepares the internal data structures.
   * This constructor is private to prevent direct instantiation.
   */
  WindowManager();

  // Prevent copy construction and assignment to maintain singleton property
  WindowManager(const WindowManager&) = delete;
  WindowManager& operator=(const WindowManager&) = delete;
  WindowManager(WindowManager&&) = delete;
  WindowManager& operator=(WindowManager&&) = delete;

  /**
   * @brief Platform-specific implementation details
   *
   * Uses the PIMPL (Pointer to Implementation) idiom to hide platform-specific
   * details and reduce compilation dependencies.
   */
  class Impl;
  std::unique_ptr<Impl> pimpl_;

  // Window instances are tracked by WindowRegistry (see window_registry.h)

  /**
   * @brief Internal method to dispatch window events
   *
   * Processes window events received from the platform and dispatches them
   * to registered event listeners. This method is called by the platform-specific
   * event monitoring system.
   *
   * @param event The window event to dispatch
   */
  void DispatchWindowEvent(const WindowEvent& event);
};

}  // namespace nativeapi
