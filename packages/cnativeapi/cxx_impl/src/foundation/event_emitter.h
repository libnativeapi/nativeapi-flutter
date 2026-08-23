#pragma once

#include <algorithm>
#include <atomic>
#include <functional>
#include <memory>
#include <mutex>
#include <type_traits>
#include <typeindex>
#include <unordered_map>
#include <utility>
#include <vector>

#include "dispatcher.h"
#include "event.h"

namespace nativeapi {

/**
 * Base class that provides event emission capabilities with type constraints.
 * Classes that inherit from EventEmitter must specify the base event type they work with,
 * and then only emit events of that type or its subclasses. This provides compile-time
 * type safety and makes the API more explicit about what events a class can produce.
 *
 * Template Parameters:
 *   BaseEventType - The base event type this emitter can handle. All emitted events
 *                   must be of this type or inherit from it.
 *
 * Threading and re-entrancy guarantees:
 *   - Listener callbacks are ALWAYS invoked without holding any internal lock.
 *     A callback may freely call AddListener(), RemoveListener(), or Emit() on the
 *     same emitter without deadlocking.
 *   - Emit() is synchronous: listeners run on the thread that called it. Platform
 *     code is expected to call it from the main thread.
 *   - EmitAsync() defers to the platform main/UI thread (see dispatcher.h). It is
 *     the right choice whenever the event originates on a background thread, or
 *     whenever the caller holds a lock it does not want user code running under.
 *   - Removing a listener from inside its own callback is safe. The listener object
 *     stays alive for the duration of the callback, and no further events are
 *     delivered to it once removed.
 *   - StartEventListening() / StopEventListening() are invoked without holding the
 *     listener lock, so platform implementations may call back into the emitter.
 *   - Listeners are invoked in registration order, regardless of event type.
 *
 * Dispatch semantics:
 *   An emitted event is delivered to every listener whose registered type is the
 *   event's dynamic type or one of its base types (up to BaseEventType). The
 *   resolution of "which listeners match this event type" is cached per dynamic
 *   event type, so steady-state dispatch is a single hash lookup rather than a
 *   scan over every registered listener.
 *
 * Example usage:
 *
 * // Define your event hierarchy
 * class MyEvent : public Event {
 * public:
 *   std::string data;
 *   MyEvent(std::string d) : data(std::move(d)) {}
 *   std::string GetTypeName() const override { return "MyEvent"; }
 * };
 *
 * class MySpecificEvent : public MyEvent {
 * public:
 *   int value;
 *   MySpecificEvent(std::string d, int v) : MyEvent(std::move(d)), value(v) {}
 *   std::string GetTypeName() const override { return "MySpecificEvent"; }
 * };
 *
 * // Create a class that only emits MyEvent and its subclasses
 * class MyClass : public EventEmitter<MyEvent> {
 * public:
 *   ~MyClass() override { ShutdownEmitter(); }  // see ShutdownEmitter() docs
 *
 *   void DoSomething() {
 *     // Emit a MyEvent - OK
 *     Emit<MyEvent>("some data");
 *
 *     // Emit a MySpecificEvent (subclass of MyEvent) - OK
 *     EmitAsync<MySpecificEvent>("data", 42);
 *
 *     // Emit<SomeOtherEvent>() - Compile error! Not a subclass of MyEvent
 *   }
 * };
 *
 * MyClass obj;
 * // Listen for base event type
 * obj.AddListener<MyEvent>([](const MyEvent& event) {
 *   std::cout << "MyEvent: " << event.data << std::endl;
 * });
 *
 * // Listen for specific event type
 * obj.AddListener<MySpecificEvent>([](const MySpecificEvent& event) {
 *   std::cout << "MySpecificEvent: " << event.data << ", " << event.value << std::endl;
 * });
 */
template <typename BaseEventType>
class EventEmitter {
  // Ensure BaseEventType is derived from Event
  static_assert(std::is_base_of<Event, BaseEventType>::value,
                "BaseEventType must be derived from Event");

 private:
  /**
   * Type-erased listener record.
   *
   * Entries are held by shared_ptr so that a dispatch snapshot keeps the record
   * alive even if the listener is removed concurrently (or by its own callback).
   * `removed` is the tombstone: once set, no further callbacks are delivered,
   * even from a snapshot that was taken before the removal.
   */
  struct ListenerEntry {
    ListenerEntry(std::type_index type, size_t identifier)
        : event_type(type), id(identifier), removed(false) {}
    virtual ~ListenerEntry() = default;

    /** Whether this listener accepts an event with the given dynamic type. */
    virtual bool Matches(const BaseEventType& event) const = 0;

    /** Deliver the event. Only called when Matches() returned true. */
    virtual void Invoke(const BaseEventType& event) = 0;

    std::type_index event_type;
    size_t id;
    std::atomic<bool> removed;
  };

  using ListenerEntryPtr = std::shared_ptr<ListenerEntry>;

 public:
  // Initializer order follows member declaration order.
  EventEmitter()
      : listening_active_(false),
        dispatch_guard_(std::make_shared<DispatchGuard>()),
        next_listener_id_(1) {}

  /**
   * Destructor.
   *
   * Calls ShutdownEmitter(). Note that by the time a base-class destructor runs,
   * the derived object has already been destroyed — so derived classes that emit
   * events from other threads should call ShutdownEmitter() at the top of their
   * own destructor. See ShutdownEmitter().
   */
  virtual ~EventEmitter() { ShutdownEmitter(); }

  /**
   * Add a typed event listener for a specific event type.
   * The event type must be BaseEventType or a subclass of it.
   *
   * @param listener Pointer to the event listener (must remain valid until removed)
   * @return A unique listener ID that can be used to remove the listener
   */
  template <typename EventType>
  size_t AddListener(EventListener<EventType>* listener) {
    static_assert(std::is_base_of<BaseEventType, EventType>::value,
                  "EventType must be derived from the EventEmitter's BaseEventType");

    struct TypedListenerWrapper : public ListenerEntry {
      EventListener<EventType>* listener_;

      TypedListenerWrapper(EventListener<EventType>* listener, size_t id)
          : ListenerEntry(std::type_index(typeid(EventType)), id), listener_(listener) {}

      bool Matches(const BaseEventType& event) const override {
        return dynamic_cast<const EventType*>(&event) != nullptr;
      }

      void Invoke(const BaseEventType& event) override {
        if (auto* typed_event = dynamic_cast<const EventType*>(&event)) {
          listener_->OnEvent(*typed_event);
        }
      }
    };

    const size_t listener_id = next_listener_id_.fetch_add(1);
    return AddListenerEntry(std::make_shared<TypedListenerWrapper>(listener, listener_id));
  }

  /**
   * Add a callback function as a listener for a specific event type.
   * The event type must be BaseEventType or a subclass of it.
   *
   * @param callback Function to call when the event occurs
   * @return A unique listener ID that can be used to remove the listener
   */
  template <typename EventType>
  size_t AddListener(std::function<void(const EventType&)> callback) {
    static_assert(std::is_base_of<BaseEventType, EventType>::value,
                  "EventType must be derived from the EventEmitter's BaseEventType");

    struct CallbackListenerWrapper : public ListenerEntry {
      std::function<void(const EventType&)> callback_;

      CallbackListenerWrapper(std::function<void(const EventType&)> callback, size_t id)
          : ListenerEntry(std::type_index(typeid(EventType)), id),
            callback_(std::move(callback)) {}

      bool Matches(const BaseEventType& event) const override {
        return dynamic_cast<const EventType*>(&event) != nullptr;
      }

      void Invoke(const BaseEventType& event) override {
        if (auto* typed_event = dynamic_cast<const EventType*>(&event)) {
          if (callback_) {
            callback_(*typed_event);
          }
        }
      }
    };

    const size_t listener_id = next_listener_id_.fetch_add(1);
    return AddListenerEntry(
        std::make_shared<CallbackListenerWrapper>(std::move(callback), listener_id));
  }

  /**
   * Remove a listener by its ID.
   *
   * Safe to call from inside a listener callback, including for the listener
   * currently being invoked.
   *
   * @param listener_id The ID returned by AddListener
   * @return true if the listener was found and removed, false otherwise
   */
  bool RemoveListener(size_t listener_id) {
    bool removed = false;
    bool became_empty = false;

    {
      std::lock_guard<std::mutex> lock(listeners_mutex_);

      auto it = std::find_if(
          listeners_.begin(), listeners_.end(),
          [listener_id](const ListenerEntryPtr& entry) { return entry->id == listener_id; });

      if (it != listeners_.end()) {
        // Tombstone first: a dispatch snapshot taken before this point must not
        // deliver any further events to this listener.
        (*it)->removed.store(true);
        listeners_.erase(it);
        dispatch_cache_.clear();
        removed = true;
        became_empty = listeners_.empty();
      }
    }

    if (became_empty) {
      UpdateListeningState(false);
    }

    return removed;
  }

  /**
   * Remove all listeners for a specific event type.
   * The event type must be BaseEventType or a subclass of it.
   */
  template <typename EventType>
  void RemoveAllListeners() {
    static_assert(std::is_base_of<BaseEventType, EventType>::value,
                  "EventType must be derived from the EventEmitter's BaseEventType");
    RemoveAllListeners(std::type_index(typeid(EventType)));
  }

  /**
   * Remove all listeners for all event types.
   */
  void RemoveAllListeners() {
    bool had_listeners = false;

    {
      std::lock_guard<std::mutex> lock(listeners_mutex_);

      had_listeners = !listeners_.empty();
      for (const auto& entry : listeners_) {
        entry->removed.store(true);
      }
      listeners_.clear();
      dispatch_cache_.clear();
    }

    if (had_listeners) {
      UpdateListeningState(false);
    }
  }

  /**
   * Get the number of listeners registered for a specific event type.
   * The event type must be BaseEventType or a subclass of it.
   */
  template <typename EventType>
  size_t GetListenerCount() const {
    static_assert(std::is_base_of<BaseEventType, EventType>::value,
                  "EventType must be derived from the EventEmitter's BaseEventType");
    return GetListenerCount(std::type_index(typeid(EventType)));
  }

  /**
   * Get the total number of registered listeners.
   */
  size_t GetTotalListenerCount() const {
    std::lock_guard<std::mutex> lock(listeners_mutex_);
    return listeners_.size();
  }

  /**
   * Check if there are any listeners for a specific event type.
   */
  template <typename EventType>
  bool HasListeners() const {
    return GetListenerCount<EventType>() > 0;
  }

  /**
   * Emit an event synchronously to all registered listeners.
   * This is a public method for internal use by platform implementations.
   * The event must be of BaseEventType or a subclass.
   *
   * Listener callbacks are invoked without holding any internal lock.
   *
   * @param event The event to emit
   */
  void Emit(const BaseEventType& event) {
    std::vector<ListenerEntryPtr> snapshot;

    {
      std::lock_guard<std::mutex> lock(listeners_mutex_);
      snapshot = ResolveListenersLocked(event);
    }

    // Dispatch outside the lock so callbacks may re-enter the emitter.
    for (const auto& entry : snapshot) {
      if (entry->removed.load()) {
        continue;  // Removed after the snapshot was taken (possibly by an earlier callback).
      }
      entry->Invoke(event);
    }
  }

 protected:
  /**
   * Called when the first listener is added.
   * Subclasses can override this to start platform-specific event monitoring.
   *
   * This is called WITHOUT holding any internal lock, so implementations may
   * safely call back into the emitter.
   */
  virtual void StartEventListening() {}

  /**
   * Called when the last listener is removed.
   * Subclasses can override this to stop platform-specific event monitoring.
   *
   * This is called WITHOUT holding any internal lock, so implementations may
   * safely call back into the emitter.
   */
  virtual void StopEventListening() {}

  /**
   * Detach from pending async dispatch and drop all listeners.
   *
   * Derived classes that emit events asynchronously should call this at the TOP
   * of their own destructor. By the time ~EventEmitter() runs, the derived
   * portion of the object is already destroyed, so a queued EmitAsync() landing
   * on the main thread would otherwise dispatch into a half-destroyed object.
   *
   * Blocks until any dispatch already inside the guard has finished, then marks
   * the emitter dead so later arrivals become no-ops.
   *
   * Idempotent — safe to call multiple times.
   */
  void ShutdownEmitter() {
    {
      std::lock_guard<std::recursive_mutex> lock(dispatch_guard_->mutex);
      dispatch_guard_->alive = false;
    }
    RemoveAllListeners();
  }

  /**
   * Emit an event synchronously using perfect forwarding.
   * This creates the event object and emits it immediately.
   * The event type must be BaseEventType or a subclass of it.
   */
  template <typename EventType, typename... Args>
  void Emit(Args&&... args) {
    static_assert(std::is_base_of<BaseEventType, EventType>::value,
                  "EventType must be derived from the EventEmitter's BaseEventType");

    EventType event(std::forward<Args>(args)...);
    Emit(event);
  }

  /**
   * Emit an event asynchronously, on the platform's main/UI thread.
   *
   * Delivery is always deferred, even when called from the main thread. That
   * matters for the library's own callers: ShortcutManager emits while holding
   * its internal mutex, and deferring is what keeps user callbacks from running
   * underneath a lock they know nothing about.
   *
   * The event must be of BaseEventType or a subclass.
   *
   * @param event The event to emit (will be moved)
   */
  void EmitAsync(std::unique_ptr<BaseEventType> event) {
    if (!event) {
      return;
    }

    std::shared_ptr<BaseEventType> shared_event(std::move(event));
    auto guard = dispatch_guard_;
    EventEmitter* self = this;

    const bool queued = RunOnMainThread([guard, self, shared_event]() {
      std::lock_guard<std::recursive_mutex> lock(guard->mutex);
      if (!guard->alive) {
        return;  // Emitter was destroyed after this work was queued.
      }
      self->Emit(*shared_event);
    });

    if (!queued) {
      // No main-thread dispatch on this platform (currently Android/OpenHarmony).
      //
      // Deliver inline rather than dropping the event: losing notifications
      // silently is a worse failure than delivering them on the calling thread,
      // and the calling thread is what these platforms did before anyway.
      //
      // Caveat: this reintroduces "callback runs under the emitter's caller's
      // lock" on those platforms. IsMainThreadDispatchSupported() reports the
      // situation; wiring the remaining loopers is tracked as TODO in the
      // respective dispatcher_*.cpp.
      Emit(*shared_event);
    }
  }

  /**
   * Emit an event asynchronously using perfect forwarding.
   * The event type must be BaseEventType or a subclass of it.
   */
  template <typename EventType, typename... Args>
  void EmitAsync(Args&&... args) {
    static_assert(std::is_base_of<BaseEventType, EventType>::value,
                  "EventType must be derived from the EventEmitter's BaseEventType");

    auto event = std::make_unique<EventType>(std::forward<Args>(args)...);
    EmitAsync(std::move(event));
  }

 private:
  size_t AddListenerEntry(ListenerEntryPtr entry) {
    const size_t listener_id = entry->id;
    bool was_empty = false;

    {
      std::lock_guard<std::mutex> lock(listeners_mutex_);
      was_empty = listeners_.empty();
      listeners_.push_back(std::move(entry));
      dispatch_cache_.clear();
    }

    if (was_empty) {
      UpdateListeningState(true);
    }

    return listener_id;
  }

  void RemoveAllListeners(std::type_index event_type) {
    bool became_empty = false;
    bool removed_any = false;

    {
      std::lock_guard<std::mutex> lock(listeners_mutex_);

      const size_t before = listeners_.size();
      auto new_end = std::remove_if(listeners_.begin(), listeners_.end(),
                                    [event_type](const ListenerEntryPtr& entry) {
                                      if (entry->event_type == event_type) {
                                        entry->removed.store(true);
                                        return true;
                                      }
                                      return false;
                                    });
      listeners_.erase(new_end, listeners_.end());

      removed_any = listeners_.size() != before;
      if (removed_any) {
        dispatch_cache_.clear();
      }
      became_empty = removed_any && listeners_.empty();
    }

    if (became_empty) {
      UpdateListeningState(false);
    }
  }

  size_t GetListenerCount(std::type_index event_type) const {
    std::lock_guard<std::mutex> lock(listeners_mutex_);
    return static_cast<size_t>(
        std::count_if(listeners_.begin(), listeners_.end(),
                      [event_type](const ListenerEntryPtr& entry) {
                        return entry->event_type == event_type;
                      }));
  }

  /**
   * Serializes StartEventListening() / StopEventListening() transitions.
   *
   * Must be called WITHOUT holding listeners_mutex_. The dedicated mutex keeps
   * the start/stop pair ordered even when concurrent add/remove operations race.
   *
   * The mutex is recursive on purpose: a platform hook is allowed to add or
   * remove listeners from inside StartEventListening()/StopEventListening(),
   * which re-enters this function on the same thread. A plain mutex would
   * deadlock there, which is exactly the class of bug this rewrite removes.
   */
  void UpdateListeningState(bool should_listen) {
    std::lock_guard<std::recursive_mutex> lock(listening_mutex_);

    if (should_listen == listening_active_) {
      return;
    }
    listening_active_ = should_listen;

    if (should_listen) {
      StartEventListening();
    } else {
      StopEventListening();
    }
  }

  /**
   * Resolve the listeners that should receive this event.
   *
   * Caller must hold listeners_mutex_. The per-dynamic-type resolution is cached,
   * so the dynamic_cast scan over all listeners only happens on a cache miss.
   */
  std::vector<ListenerEntryPtr> ResolveListenersLocked(const BaseEventType& event) {
    const std::type_index dynamic_type(typeid(event));

    auto cached = dispatch_cache_.find(dynamic_type);
    if (cached != dispatch_cache_.end()) {
      return cached->second;
    }

    std::vector<ListenerEntryPtr> matched;
    for (const auto& entry : listeners_) {
      if (entry->Matches(event)) {
        matched.push_back(entry);
      }
    }

    dispatch_cache_.emplace(dynamic_type, matched);
    return matched;
  }

  /**
   * Keeps queued async dispatch from touching a destroyed emitter.
   *
   * Held by shared_ptr so a posted lambda can outlive the emitter and still have
   * something valid to inspect. Recursive because a listener callback is allowed
   * to destroy the emitter, which re-enters this mutex on the same thread.
   */
  struct DispatchGuard {
    std::recursive_mutex mutex;
    bool alive = true;
  };

  // Listener registry. Insertion-ordered so dispatch order is deterministic.
  mutable std::mutex listeners_mutex_;
  std::vector<ListenerEntryPtr> listeners_;

  // Cache: dynamic event type -> listeners that accept it.
  // Invalidated wholesale whenever the listener set changes.
  std::unordered_map<std::type_index, std::vector<ListenerEntryPtr>> dispatch_cache_;

  // Serializes StartEventListening()/StopEventListening() transitions.
  // Recursive: platform hooks may add/remove listeners re-entrantly.
  std::recursive_mutex listening_mutex_;
  bool listening_active_;

  // Shared with in-flight async dispatch; see DispatchGuard.
  std::shared_ptr<DispatchGuard> dispatch_guard_;

  // Listener ID generation
  std::atomic<size_t> next_listener_id_;
};

}  // namespace nativeapi
