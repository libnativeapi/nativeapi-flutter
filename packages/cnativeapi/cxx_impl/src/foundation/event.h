#pragma once

#include <chrono>
#include <functional>
#include <memory>
#include <string>

namespace nativeapi {

/**
 * Base class for all events in the generic event system.
 * Events should inherit from this class and provide their own data.
 */
class Event {
 public:
  Event() : timestamp_(std::chrono::steady_clock::now()) {}
  virtual ~Event() = default;

  // Get the time when this event was created
  std::chrono::steady_clock::time_point GetTimestamp() const { return timestamp_; }

  // Get a string representation of the event type (for debugging)
  virtual std::string GetTypeName() const = 0;

 private:
  std::chrono::steady_clock::time_point timestamp_;
};

/**
 * Generic event listener interface providing type-safe event handling.
 *
 * This interface supports both generic and specific event handling:
 * - Use EventListener<Event> to handle all event types (requires manual type checking)
 * - Use EventListener<SpecificEventType> for compile-time type safety with specific events
 *
 * Example:
 * ```cpp
 * class MyListener : public EventListener<MyCustomEvent> {
 * public:
 *   void OnEvent(const MyCustomEvent& event) override {
 *     // Handle the event with full type safety
 *   }
 * };
 * ```
 */
template <typename T>
class EventListener {
 public:
  virtual ~EventListener() = default;

  /**
   * Handles an incoming event of type T.
   *
   * The event parameter is guaranteed to be of type T or a subtype.
   * Implementation should process the event according to the listener's logic.
   */
  virtual void OnEvent(const T& event) = 0;
};

/**
 * A callback-based event listener that wraps function callbacks into the EventListener interface.
 *
 * This implementation allows using function references, lambda functions, or any callable
 * as event handlers without requiring a full class implementation. It's particularly useful
 * for simple event handling scenarios or when you want to use inline functions.
 *
 * Example usage:
 * ```cpp
 * // Using a lambda function
 * auto listener = std::make_unique<CallbackEventListener<MyEvent>>(
 *     [](const MyEvent& event) { std::cout << "Received: " << event << std::endl; });
 *
 * // Using a function reference
 * void handleMyEvent(const MyEvent& event) { // handle event }
 * auto listener = std::make_unique<CallbackEventListener<MyEvent>>(handleMyEvent);
 * ```
 */
template <typename T>
class CallbackEventListener : public EventListener<T> {
 public:
  using CallbackType = std::function<void(const T&)>;

  /**
   * Creates a new callback-based event listener with the specified callback function.
   *
   * The callback must accept a single parameter of type T and return void.
   */
  explicit CallbackEventListener(CallbackType callback) : callback_(std::move(callback)) {}

  void OnEvent(const T& event) override {
    if (callback_) {
      callback_(event);
    }
  }

 private:
  CallbackType callback_;
};

}  // namespace nativeapi