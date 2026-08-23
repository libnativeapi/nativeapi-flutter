#pragma once

#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>

#include "tray_icon.h"

namespace nativeapi {

/**
 * @brief TrayManager is a singleton class that provides system tray functionality.
 *
 * This class provides centralized access to system tray capabilities and
 * manages existing tray icons. It ensures that there's only one instance of
 * the tray manager throughout the application lifetime and provides thread-safe
 * operations for accessing tray icons.
 *
 * @note This class is implemented as a singleton to ensure consistent
 * access to system tray resources across the entire application.
 * @note TrayIcon instances should be created directly using std::make_shared<TrayIcon>()
 * rather than through this manager.
 */
class TrayManager {
 public:
  /**
   * @brief Get the singleton instance of TrayManager.
   *
   * This method provides access to the unique instance of TrayManager.
   * The instance is created on first call and remains alive for the
   * duration of the application.
   *
   * @return Reference to the singleton TrayManager instance
   * @thread_safety This method is thread-safe
   */
  static TrayManager& GetInstance();

  /**
   * @brief Destructor for TrayManager.
   *
   * Cleans up all managed tray icons and releases system resources.
   */
  virtual ~TrayManager();

  /**
   * @brief Check if the system tray is supported on the current platform.
   *
   * Some platforms or desktop environments may not support system tray
   * functionality. This method allows checking for availability before
   * attempting to create tray icons.
   *
   * @return true if system tray is supported, false otherwise
   */
  bool IsSupported();

  /**
   * @brief Get a tray icon by its unique ID.
   *
   * Retrieves a previously created tray icon using its assigned ID.
   *
   * @param id The unique identifier of the tray icon
   * @return Shared pointer to the TrayIcon if found, nullptr otherwise
   * @thread_safety This method is thread-safe
   */
  std::shared_ptr<TrayIcon> Get(TrayIconId id);

  /**
   * @brief Get all managed tray icons.
   *
   * Returns a vector containing all currently active tray icons
   * managed by this TrayManager instance.
   *
   * @return Vector of shared pointers to all active TrayIcon instances
   * @thread_safety This method is thread-safe
   */
  std::vector<std::shared_ptr<TrayIcon>> GetAll();

  // Prevent copy construction and assignment to maintain singleton property
  TrayManager(const TrayManager&) = delete;
  TrayManager& operator=(const TrayManager&) = delete;
  TrayManager(TrayManager&&) = delete;
  TrayManager& operator=(TrayManager&&) = delete;

 private:
  /**
   * @brief Private constructor to enforce singleton pattern.
   *
   * Initializes the TrayManager instance and sets up initial state.
   */
  TrayManager();

  /**
   * @brief Private implementation class using the PIMPL idiom.
   */
  class Impl;

  /**
   * @brief Pointer to the private implementation instance.
   */
  std::unique_ptr<Impl> pimpl_;

  /**
   * @brief Container for storing active tray icon instances.
   *
   * Maps tray icon IDs to their corresponding TrayIcon instances
   * for efficient lookup and management.
   */
  std::unordered_map<TrayIconId, std::shared_ptr<TrayIcon>> trays_;

  /**
   * @brief ID generator for creating unique tray icon identifiers.
   *
   * Maintains the next available ID to assign to newly created tray icons.
   * This ensures each tray icon has a unique identifier.
   */
  TrayIconId next_tray_id_;

  /**
   * @brief Mutex for thread-safe operations.
   *
   * Protects access to internal data structures to ensure thread safety
   * when multiple threads access the TrayManager simultaneously.
   */
  mutable std::mutex mutex_;
};

}  // namespace nativeapi
