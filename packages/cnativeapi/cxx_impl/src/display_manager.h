#pragma once

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "display.h"
#include "foundation/event.h"
#include "foundation/event_emitter.h"
#include "foundation/geometry.h"

namespace nativeapi {

/**
 * DisplayManager is a singleton that manages all displays on the system.
 *
 * This class provides functionality to:
 * - Query all connected displays
 * - Get primary display information
 * - Monitor display changes (addition/removal)
 * - Get cursor position across displays
 *
 * Display is an identity object: the manager keeps
 * one live Display instance per connected physical display and returns the
 * same std::shared_ptr on every query, so a display's DisplayId stays stable
 * for as long as it remains connected.
 *
 * Thread Safety: This class is not thread-safe. External synchronization
 * is required if accessed from multiple threads.
 *
 * Example usage:
 * @code
 * DisplayManager& manager = DisplayManager::GetInstance();
 * std::vector<std::shared_ptr<Display>> displays = manager.GetAll();
 * std::shared_ptr<Display> primary = manager.GetPrimary();
 * @endcode
 */
class DisplayManager : public EventEmitter<DisplayEvent> {
 public:
  /**
   * Get the singleton instance of DisplayManager
   * @return Reference to the singleton DisplayManager instance
   */
  static DisplayManager& GetInstance();

  /**
   * @brief Destructor for DisplayManager.
   *
   * Cleans up all resources, stops event monitoring.
   * This is automatically called when the application terminates.
   */
  virtual ~DisplayManager();

  /**
   * Get all connected displays
   *
   * @return Vector of shared pointers to all connected displays. The vector
   * may be empty if no displays are detected. Repeated calls return the same
   * Display instances for displays that stayed connected.
   */
  std::vector<std::shared_ptr<Display>> GetAll();

  /**
   * Get the primary display
   *
   * The primary display is typically the main screen where the desktop
   * environment displays its primary interface elements.
   *
   * @return Shared pointer to the primary display, or nullptr if no display
   * is available.
   */
  std::shared_ptr<Display> GetPrimary();

  /**
   * Get the current cursor position in screen coordinates
   *
   * The coordinates are relative to the top-left corner of the primary display,
   * with positive X extending right and positive Y extending down.
   *
   * @return Point containing the current cursor coordinates (x, y)
   * @note The position is captured at the time of the function call
   */
  Point GetCursorPosition();

  // Prevent copy construction and assignment to maintain singleton property
  DisplayManager(const DisplayManager&) = delete;
  DisplayManager& operator=(const DisplayManager&) = delete;
  DisplayManager(DisplayManager&&) = delete;
  DisplayManager& operator=(DisplayManager&&) = delete;

 private:
  /**
   * @brief Private constructor to enforce singleton pattern.
   *
   * Initializes the DisplayManager instance and sets up platform display
   * change monitoring.
   */
  DisplayManager();

  /**
   * One display as reported by the platform enumeration.
   */
  struct NativeDisplayInfo {
    /**
     * Platform-stable identity key (e.g. CGDirectDisplayID on macOS, device
     * name on Windows). Used to recognize an already-known display across
     * enumerations; never exposed publicly.
     */
    std::string key;

    /** Platform display object, consumable by Display's constructor. */
    void* native;

    /** Whether the platform reports this display as primary. */
    bool is_primary;
  };

  /**
   * Enumerate the platform's current displays. Implemented per platform;
   * everything else (instance caching, diffing, events) is shared code.
   */
  std::vector<NativeDisplayInfo> EnumerateNativeDisplays();

  /**
   * Reconcile the instance cache against a platform enumeration.
   *
   * Known displays keep their existing instance; new ones get a fresh
   * Display; missing ones are dropped from the cache. When @p added /
   * @p removed are non-null they receive the corresponding instances.
   *
   * @return The current displays in enumeration order.
   */
  std::vector<std::shared_ptr<Display>> Reconcile(
      const std::vector<NativeDisplayInfo>& natives,
      std::vector<std::shared_ptr<Display>>* added,
      std::vector<std::shared_ptr<Display>>* removed);

  /**
   * Re-enumerate and emit DisplayAddedEvent / DisplayRemovedEvent for the
   * differences. Called by the platform display-change observers.
   */
  void HandleDisplaysChanged();

  /**
   * Live Display instances keyed by platform identity key, so repeated
   * enumeration returns the same objects (stable DisplayId).
   */
  std::unordered_map<std::string, std::shared_ptr<Display>> displays_;
};

}  // namespace nativeapi
