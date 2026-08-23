#pragma once

#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "foundation/event_emitter.h"
#include "foundation/id_allocator.h"
#include "shortcut.h"

namespace nativeapi {

typedef IdAllocator::IdType ShortcutId;

/**
 * @brief ShortcutManager is a singleton class that manages global keyboard shortcuts.
 *
 * The ShortcutManager provides centralized access to system-wide keyboard shortcut
 * registration and handling. It follows the singleton pattern to ensure there's only
 * one instance managing all shortcuts throughout the application lifetime.
 *
 * Key features:
 * - Singleton pattern ensures centralized shortcut management
 * - Event-driven architecture for shortcut activation notifications
 * - Cross-platform shortcut registration and monitoring
 * - Thread-safe access to the singleton instance
 * - Automatic cleanup of resources on destruction
 * - Support for both global and application-local shortcuts
 *
 * @note This class is thread-safe for singleton access and shortcut operations.
 * @note Shortcut instances should be created and managed through this manager.
 */
class ShortcutManager : public EventEmitter<ShortcutEvent> {
 public:
  /**
   * @brief Get the singleton instance of ShortcutManager.
   *
   * This method provides access to the unique instance of ShortcutManager using
   * the Meyer's singleton pattern. The instance is created on first call and
   * remains alive for the duration of the application. This method is thread-safe
   * and guarantees that only one instance will be created even in multi-threaded
   * environments.
   *
   * @return Reference to the singleton ShortcutManager instance
   * @thread_safety This method is thread-safe
   *
   * @code
   * // Usage example:
   * auto& manager = ShortcutManager::GetInstance();
   * auto shortcut = manager.Register("Ctrl+Shift+A", callback);
   * @endcode
   */
  static ShortcutManager& GetInstance();

  /**
   * @brief Destructor for ShortcutManager.
   *
   * Cleans up all managed shortcuts, unregisters them from the system,
   * and releases system resources. This is automatically called when
   * the application terminates.
   */
  virtual ~ShortcutManager();

  /**
   * @brief Check if global shortcuts are supported on the current platform.
   *
   * Some platforms or configurations may not support global keyboard shortcuts
   * due to security restrictions or desktop environment limitations. This method
   * allows checking for availability before attempting to register shortcuts.
   *
   * @return true if global shortcuts are supported, false otherwise
   */
  bool IsSupported();

  /**
   * @brief Register a new global keyboard shortcut.
   *
   * Creates and registers a new keyboard shortcut that can be triggered
   * system-wide, regardless of which application has focus. The shortcut
   * will trigger the provided callback when activated.
   *
   * @param accelerator The keyboard shortcut string (e.g., "Ctrl+Shift+A", "Cmd+Space")
   * @param callback Function to call when the shortcut is activated
   * @return Shared pointer to the created Shortcut instance, nullptr if registration failed
   * @thread_safety This method is thread-safe
   *
   * @note Accelerator format follows Electron-style conventions:
   *       - Modifiers: Ctrl, Alt, Shift, Cmd (macOS), Super (Linux), Meta
   *       - Keys: A-Z, 0-9, F1-F12, Space, Tab, Enter, Escape, etc.
   *       - Examples: "Ctrl+C", "Cmd+Shift+4", "Alt+F4", "Ctrl+Alt+Delete"
   *
   * @example
   * ```cpp
   * auto shortcut = manager.Register("Ctrl+Shift+Q", []() {
   *     std::cout << "Quick action triggered!" << std::endl;
   * });
   *
   * if (!shortcut) {
   *     std::cerr << "Failed to register shortcut" << std::endl;
   * }
   * ```
   */
  std::shared_ptr<Shortcut> Register(const std::string& accelerator,
                                     std::function<void()> callback);

  /**
   * @brief Register a new keyboard shortcut with detailed options.
   *
   * Creates and registers a keyboard shortcut with additional configuration
   * options such as scope (global vs application-local) and description.
   *
   * @param options ShortcutOptions struct containing shortcut configuration
   * @return Shared pointer to the created Shortcut instance, nullptr if registration failed
   * @thread_safety This method is thread-safe
   *
   * @example
   * ```cpp
   * ShortcutOptions options;
   * options.accelerator = "Ctrl+Alt+T";
   * options.callback = []() { OpenTerminal(); };
   * options.description = "Open terminal";
   * options.scope = ShortcutScope::Global;
   *
   * auto shortcut = manager.Register(options);
   * ```
   */
  std::shared_ptr<Shortcut> Register(const ShortcutOptions& options);

  /**
   * @brief Unregister a keyboard shortcut by its ID.
   *
   * Removes a previously registered shortcut from the system and
   * stops monitoring for its activation.
   *
   * @param id The unique identifier of the shortcut to unregister
   * @return true if the shortcut was successfully unregistered, false otherwise
   * @thread_safety This method is thread-safe
   *
   * @example
   * ```cpp
   * ShortcutId id = shortcut->GetId();
   * bool success = manager.Unregister(id);
   * ```
   */
  bool Unregister(ShortcutId id);

  /**
   * @brief Unregister a keyboard shortcut by its accelerator string.
   *
   * Removes a previously registered shortcut from the system using
   * its accelerator string identifier.
   *
   * @param accelerator The keyboard shortcut string to unregister
   * @return true if the shortcut was successfully unregistered, false otherwise
   * @thread_safety This method is thread-safe
   *
   * @example
   * ```cpp
   * bool success = manager.Unregister("Ctrl+Shift+Q");
   * ```
   */
  bool Unregister(const std::string& accelerator);

  /**
   * @brief Unregister all keyboard shortcuts.
   *
   * Removes all currently registered shortcuts from the system.
   * This is useful for cleanup or when switching shortcut profiles.
   *
   * @return Number of shortcuts that were unregistered
   * @thread_safety This method is thread-safe
   *
   * @example
   * ```cpp
   * int count = manager.UnregisterAll();
   * std::cout << "Unregistered " << count << " shortcuts" << std::endl;
   * ```
   */
  int UnregisterAll();

  /**
   * @brief Get a shortcut by its unique ID.
   *
   * Retrieves a previously registered shortcut using its assigned ID.
   *
   * @param id The unique identifier of the shortcut
   * @return Shared pointer to the Shortcut if found, nullptr otherwise
   * @thread_safety This method is thread-safe
   *
   * @example
   * ```cpp
   * auto shortcut = manager.Get(shortcut_id);
   * if (shortcut) {
   *     std::cout << "Found shortcut: " << shortcut->GetAccelerator() << std::endl;
   * }
   * ```
   */
  std::shared_ptr<Shortcut> Get(ShortcutId id);

  /**
   * @brief Get a shortcut by its accelerator string.
   *
   * Retrieves a previously registered shortcut using its accelerator string.
   *
   * @param accelerator The keyboard shortcut string to find
   * @return Shared pointer to the Shortcut if found, nullptr otherwise
   * @thread_safety This method is thread-safe
   *
   * @example
   * ```cpp
   * auto shortcut = manager.Get("Ctrl+Shift+Q");
   * if (shortcut) {
   *     shortcut->SetEnabled(false);
   * }
   * ```
   */
  std::shared_ptr<Shortcut> Get(const std::string& accelerator);

  /**
   * @brief Get all managed shortcuts.
   *
   * Returns a vector containing all currently registered shortcut instances.
   * The returned vector is a snapshot of the current state and modifications
   * to it won't affect the internal shortcut registry.
   *
   * @return Vector of shared pointers to all Shortcut instances
   * @thread_safety This method is thread-safe
   *
   * @example
   * ```cpp
   * auto all_shortcuts = manager.GetAll();
   * for (auto& shortcut : all_shortcuts) {
   *     std::cout << shortcut->GetAccelerator() << std::endl;
   * }
   * ```
   */
  std::vector<std::shared_ptr<Shortcut>> GetAll();

  /**
   * @brief Get shortcuts filtered by scope.
   *
   * Returns shortcuts that match the specified scope (global or application-local).
   *
   * @param scope The shortcut scope to filter by
   * @return Vector of shared pointers to matching Shortcut instances
   * @thread_safety This method is thread-safe
   *
   * @example
   * ```cpp
   * auto global_shortcuts = manager.GetByScope(ShortcutScope::Global);
   * auto app_shortcuts = manager.GetByScope(ShortcutScope::Application);
   * ```
   */
  std::vector<std::shared_ptr<Shortcut>> GetByScope(ShortcutScope scope);

  /**
   * @brief Check if a specific accelerator is available for registration.
   *
   * Determines whether a keyboard shortcut string is available for use,
   * i.e., not already registered by this application or conflicting with
   * system shortcuts.
   *
   * @param accelerator The keyboard shortcut string to check
   * @return true if the accelerator is available, false if already in use
   * @thread_safety This method is thread-safe
   *
   * @example
   * ```cpp
   * if (manager.IsAvailable("Ctrl+Shift+N")) {
   *     auto shortcut = manager.Register("Ctrl+Shift+N", callback);
   * } else {
   *     std::cout << "Shortcut already in use" << std::endl;
   * }
   * ```
   */
  bool IsAvailable(const std::string& accelerator);

  /**
   * @brief Validate an accelerator string format.
   *
   * Checks if the provided accelerator string follows the correct format
   * and contains valid key combinations. This is useful for validating
   * user input before attempting registration.
   *
   * @param accelerator The keyboard shortcut string to validate
   * @return true if the format is valid, false otherwise
   *
   * @example
   * ```cpp
   * if (manager.IsValidAccelerator("Ctrl+Shift+Q")) {
   *     // Valid format, safe to register
   * } else {
   *     std::cout << "Invalid shortcut format" << std::endl;
   * }
   * ```
   */
  bool IsValidAccelerator(const std::string& accelerator);

  /**
   * @brief Enable or disable shortcut processing.
   *
   * Allows temporarily disabling all shortcut processing without unregistering
   * shortcuts. When disabled, shortcuts will remain registered but won't trigger
   * their callbacks. This is useful for modal dialogs or when the application
   * needs to temporarily suppress shortcut handling.
   *
   * @param enabled true to enable shortcut processing, false to disable
   * @thread_safety This method is thread-safe
   *
   * @example
   * ```cpp
   * // Disable shortcuts during modal dialog
   * manager.SetEnabled(false);
   * ShowModalDialog();
   * manager.SetEnabled(true);  // Re-enable after dialog closes
   * ```
   */
  void SetEnabled(bool enabled);

  /**
   * @brief Check if shortcut processing is enabled.
   *
   * @return true if shortcut processing is enabled, false otherwise
   * @thread_safety This method is thread-safe
   */
  bool IsEnabled() const;

  /**
   * @brief Emit a shortcut activated event (internal use).
   *
   * Platform implementations should call this when a registered shortcut fires.
   */
  void EmitShortcutActivated(ShortcutId id, const std::string& accelerator);

  // Prevent copy construction and assignment to maintain singleton property
  ShortcutManager(const ShortcutManager&) = delete;
  ShortcutManager& operator=(const ShortcutManager&) = delete;
  ShortcutManager(ShortcutManager&&) = delete;
  ShortcutManager& operator=(ShortcutManager&&) = delete;

  /**
   * @brief Private implementation class using the PIMPL idiom.
   */
  class Impl {
   public:
    virtual ~Impl() = default;
    virtual bool IsSupported() = 0;
    virtual bool RegisterShortcut(const std::shared_ptr<Shortcut>& shortcut) = 0;
    virtual bool UnregisterShortcut(const std::shared_ptr<Shortcut>& shortcut) = 0;
    virtual void SetupEventMonitoring() = 0;
    virtual void CleanupEventMonitoring() = 0;
  };

 protected:
  /**
   * @brief Called when the first listener is added.
   *
   * Starts platform-specific shortcut monitoring. This is called automatically
   * by the EventEmitter when transitioning from 0 to 1+ listeners.
   */
  void StartEventListening() override;

  /**
   * @brief Called when the last listener is removed.
   *
   * Stops platform-specific shortcut monitoring. This is called automatically
   * by the EventEmitter when transitioning from 1+ to 0 listeners.
   */
  void StopEventListening() override;

 private:
  /**
   * @brief Private constructor to enforce singleton pattern.
   *
   * Initializes the ShortcutManager instance and sets up initial state.
   */
  ShortcutManager();

  /**
   * @brief Pointer to the private implementation instance.
   */
  std::unique_ptr<Impl> pimpl_;

  /**
   * @brief Container for storing active shortcut instances by ID.
   *
   * Maps shortcut IDs to their corresponding Shortcut instances
   * for efficient lookup and management.
   */
  std::unordered_map<ShortcutId, std::shared_ptr<Shortcut>> shortcuts_by_id_;

  /**
   * @brief Container for storing active shortcut instances by accelerator.
   *
   * Maps accelerator strings to their corresponding Shortcut instances
   * for efficient lookup by keyboard combination.
   */
  std::unordered_map<std::string, std::shared_ptr<Shortcut>> shortcuts_by_accelerator_;

  /**
   * @brief ID generator for creating unique shortcut identifiers.
   *
   * Maintains the next available ID to assign to newly created shortcuts.
   * This ensures each shortcut has a unique identifier.
   */
  ShortcutId next_shortcut_id_;

  /**
   * @brief Flag indicating whether shortcut processing is enabled.
   */
  bool enabled_;

  /**
   * @brief Mutex for thread-safe operations.
   *
   * Protects access to internal data structures to ensure thread safety
   * when multiple threads access the ShortcutManager simultaneously.
   */
  mutable std::mutex mutex_;

  /**
   * @brief Availability check for callers that already hold mutex_.
   *
   * The public IsAvailable() acquires mutex_, so calling it from an already-
   * locked section self-deadlocks (mutex_ is not recursive). Register() needs
   * the check and the subsequent insert to be one atomic step, so it must not
   * drop the lock in between — it uses this helper instead.
   *
   * @param accelerator The accelerator string to check.
   * @return true if no shortcut is currently registered for this accelerator.
   */
  bool IsAvailableUnlocked(const std::string& accelerator) const;
};

}  // namespace nativeapi
