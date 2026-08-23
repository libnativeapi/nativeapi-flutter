#pragma once
#include <memory>
#include <string>
#include "foundation/event.h"
#include "foundation/geometry.h"
#include "foundation/id_allocator.h"
#include "foundation/native_object_provider.h"

namespace nativeapi {

/**
 * @typedef DisplayId
 * @brief Unique identifier for a display instance.
 *
 * Allocated from IdAllocator when the Display object is created. Stable for
 * as long as the display stays connected: DisplayManager hands out the same
 * Display instance (and therefore the same id) on every enumeration. A
 * display that is disconnected and reconnected gets a fresh instance with a
 * fresh id.
 */
typedef IdAllocator::IdType DisplayId;

/**
 * Display orientation enumeration
 */
enum class DisplayOrientation {
  kPortrait = 0,
  kLandscape = 90,
  kPortraitFlipped = 180,
  kLandscapeFlipped = 270
};

/**
 * Representation of a display/monitor.
 *
 * Display is an identity object: it stands for one
 * physical display, is managed through std::shared_ptr, and is identified by
 * an integer DisplayId. Instances are created and cached by DisplayManager —
 * asking the manager twice for the same physical display returns the same
 * Display object. Properties are read live from the underlying platform
 * display, so a held instance always reflects the current configuration.
 *
 * Display is not copyable. Share the std::shared_ptr instead.
 */
class Display : public NativeObjectProvider {
 public:
  /**
   * @brief Constructor that wraps an existing native display object.
   *
   * @param display Pointer to the platform-specific display object
   *                (NSScreen* on macOS, HMONITOR on Windows, GdkMonitor* on
   *                Linux). The native object stays owned by the platform.
   *
   * @note Prefer obtaining displays from DisplayManager, which deduplicates
   *       instances; construct one directly only to wrap a native object you
   *       already hold.
   */
  explicit Display(void* display);

  Display(const Display&) = delete;
  Display& operator=(const Display&) = delete;
  Display(Display&&) = delete;
  Display& operator=(Display&&) = delete;

  virtual ~Display();

  // Basic identification
  DisplayId GetId() const;
  std::string GetName() const;

  // Physical properties
  Point GetPosition() const;
  Size GetSize() const;
  Rectangle GetWorkArea() const;
  double GetScaleFactor() const;

  // Additional properties
  bool IsPrimary() const;
  DisplayOrientation GetOrientation() const;
  int GetRefreshRate() const;
  int GetBitDepth() const;

 protected:
  /**
   * @brief Internal method to get the platform-specific native display object.
   *
   * This method must be implemented by platform-specific code to return
   * the underlying native display object.
   *
   * @return Pointer to the native display object
   */
  void* GetNativeObjectInternal() const override;

 private:
  class Impl;
  std::unique_ptr<Impl> pimpl_;
};

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/**
 * Base class for all display-related events
 *
 * This class provides common functionality for display events,
 * including access to the display that triggered the event.
 */
class DisplayEvent : public Event {
 public:
  /**
   * Constructor for DisplayEvent
   * @param display The display associated with this event
   */
  explicit DisplayEvent(std::shared_ptr<Display> display) : display_(std::move(display)) {}

  /**
   * Virtual destructor
   */
  virtual ~DisplayEvent() = default;

  /**
   * Get the display associated with this event
   * @return Shared pointer to the display
   */
  std::shared_ptr<Display> GetDisplay() const { return display_; }

  /**
   * Get a string representation of the event type (for debugging)
   * Default implementation returns "DisplayEvent"
   */
  std::string GetTypeName() const override { return "DisplayEvent"; }

 private:
  std::shared_ptr<Display> display_;
};

/**
 * Event class for display addition
 *
 * This event is emitted when a new display is connected to the system.
 */
class DisplayAddedEvent : public DisplayEvent {
 public:
  explicit DisplayAddedEvent(std::shared_ptr<Display> display)
      : DisplayEvent(std::move(display)) {}

  /**
   * Get a string representation of the event type
   */
  std::string GetTypeName() const override { return "DisplayAddedEvent"; }
};

/**
 * Event class for display removal
 *
 * This event is emitted when a display is disconnected from the system.
 * The carried Display instance is the last reference to the now-disconnected
 * display; its id is no longer resolvable through DisplayManager.
 */
class DisplayRemovedEvent : public DisplayEvent {
 public:
  explicit DisplayRemovedEvent(std::shared_ptr<Display> display)
      : DisplayEvent(std::move(display)) {}

  /**
   * Get a string representation of the event type
   */
  std::string GetTypeName() const override { return "DisplayRemovedEvent"; }
};

/**
 * Event class for display configuration changes
 *
 * This event is emitted when a display's properties change (resolution,
 * orientation, etc.). Displays are identity objects whose properties are read
 * live, so the carried instance already reflects the new configuration.
 */
class DisplayChangedEvent : public DisplayEvent {
 public:
  explicit DisplayChangedEvent(std::shared_ptr<Display> display)
      : DisplayEvent(std::move(display)) {}

  /**
   * Get a string representation of the event type
   */
  std::string GetTypeName() const override { return "DisplayChangedEvent"; }
};

}  // namespace nativeapi
