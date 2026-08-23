#pragma once

namespace nativeapi {

/**
 * @class AccessibilityManager
 * @brief A singleton class that manages system accessibility features
 *
 * The AccessibilityManager provides a centralized interface for managing
 * accessibility functionality across the system. It follows the singleton
 * pattern to ensure only one instance exists throughout the application
 * lifecycle, providing consistent state management for accessibility features.
 *
 * Key responsibilities:
 * - Enable/disable system accessibility features
 * - Query accessibility state
 * - Provide thread-safe access to accessibility functionality
 *
 * Usage example:
 * @code
 * AccessibilityManager& manager = AccessibilityManager::GetInstance();
 * manager.Enable();
 * bool enabled = manager.IsEnabled();
 * @endcode
 */
class AccessibilityManager {
 public:
  /**
   * @brief Gets the singleton instance of AccessibilityManager
   * @return Reference to the singleton instance
   *
   * This method provides thread-safe access to the singleton instance.
   * The instance is created on first access and remains alive for the
   * duration of the application.
   */
  static AccessibilityManager& GetInstance();

  /**
   * @brief Virtual destructor
   *
   * Ensures proper cleanup of resources when the manager is destroyed.
   * Note: In singleton pattern, this is typically called only at application
   * shutdown.
   */
  virtual ~AccessibilityManager();

  /**
   * @brief Enables system accessibility features
   *
   * Activates accessibility functionality across the system. This method
   * should be called to make accessibility features available to users.
   * The operation is idempotent - calling it multiple times has the same
   * effect as calling it once.
   *
   * @note This operation may require system permissions depending on the
   *       platform implementation.
   */
  void Enable();

  /**
   * @brief Checks if accessibility features are currently enabled
   * @return true if accessibility is enabled, false otherwise
   *
   * This method provides a quick way to query the current state of
   * accessibility features without modifying the system state.
   */
  bool IsEnabled();

  // Delete copy constructor and assignment operator to prevent copies
  AccessibilityManager(const AccessibilityManager&) = delete;
  AccessibilityManager& operator=(const AccessibilityManager&) = delete;

 private:
  /**
   * @brief Private constructor for singleton pattern
   *
   * Initializes the AccessibilityManager instance. This constructor is
   * private to prevent direct instantiation - use GetInstance() instead.
   */
  AccessibilityManager();

  /**
   * @brief Internal flag tracking accessibility state
   *
   * Maintains the current enabled/disabled state of accessibility features.
   * This member is used internally by Enable() and IsEnabled() methods.
   */
  bool enabled_;
};

}  // namespace nativeapi