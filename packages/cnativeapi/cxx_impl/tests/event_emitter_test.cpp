// Regression tests for EventEmitter locking and dispatch behaviour.
//
// Every case here maps to a defect described in DESIGN_REVIEW.md:
//   P0-1  EmitAsync self-deadlock (recursive lock on queue_mutex_)
//   P0-2  Emit invoking listener callbacks while holding listeners_mutex_
//
// A deadlock must surface as a test FAILURE, not as a hung CI job, so the whole
// run is guarded by a watchdog thread that aborts the process on timeout.

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdlib>
#include <iostream>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "../src/foundation/dispatcher.h"
#include "../src/foundation/event_emitter.h"

namespace {

using namespace nativeapi;

// ---------------------------------------------------------------------------
// Fake main thread
// ---------------------------------------------------------------------------

// A test binary has no run loop, so the platform dispatcher would queue work
// that never runs. Route dispatch into a queue this file drains explicitly, and
// let the test decide which thread counts as "main".
class FakeMainThread {
 public:
  FakeMainThread() : main_thread_id_(std::this_thread::get_id()) {
    SetMainThreadDispatcher(
        [this](std::function<void()> fn) {
          std::lock_guard<std::mutex> lock(mutex_);
          queue_.push_back(std::move(fn));
          return true;
        },
        [this] { return std::this_thread::get_id() == main_thread_id_; });
  }

  ~FakeMainThread() { SetMainThreadDispatcher(nullptr, nullptr); }

  /** Runs everything queued so far. Returns how many items ran. */
  size_t Drain() {
    std::vector<std::function<void()>> batch;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      batch.swap(queue_);
    }
    for (auto& fn : batch) {
      fn();
    }
    return batch.size();
  }

  size_t PendingCount() {
    std::lock_guard<std::mutex> lock(mutex_);
    return queue_.size();
  }

 private:
  std::mutex mutex_;
  std::vector<std::function<void()>> queue_;
  std::thread::id main_thread_id_;
};

FakeMainThread* g_main_thread = nullptr;

// ---------------------------------------------------------------------------
// Test scaffolding
// ---------------------------------------------------------------------------

int g_failures = 0;

void Check(bool condition, const std::string& what) {
  if (!condition) {
    std::cerr << "FAIL: " << what << std::endl;
    ++g_failures;
  } else {
    std::cout << "  ok: " << what << std::endl;
  }
}

// Aborts the process if the suite does not finish in time. Without this, a
// regression of the locking bugs would hang the test binary forever.
class Watchdog {
 public:
  explicit Watchdog(std::chrono::seconds timeout) : done_(false) {
    thread_ = std::thread([this, timeout] {
      std::unique_lock<std::mutex> lock(mutex_);
      if (!cv_.wait_for(lock, timeout, [this] { return done_; })) {
        std::cerr << "FAIL: watchdog timeout — the emitter deadlocked." << std::endl;
        std::cerr.flush();
        std::_Exit(1);
      }
    });
  }

  ~Watchdog() {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      done_ = true;
    }
    cv_.notify_all();
    thread_.join();
  }

 private:
  std::mutex mutex_;
  std::condition_variable cv_;
  bool done_;
  std::thread thread_;
};

// ---------------------------------------------------------------------------
// Event hierarchy under test
// ---------------------------------------------------------------------------

class TestEvent : public Event {
 public:
  explicit TestEvent(int v) : value(v) {}
  std::string GetTypeName() const override { return "TestEvent"; }
  int value;
};

class DerivedEvent : public TestEvent {
 public:
  explicit DerivedEvent(int v) : TestEvent(v) {}
  std::string GetTypeName() const override { return "DerivedEvent"; }
};

class OtherEvent : public TestEvent {
 public:
  explicit OtherEvent(int v) : TestEvent(v) {}
  std::string GetTypeName() const override { return "OtherEvent"; }
};

// Exposes the protected emit surface for testing.
class TestEmitter : public EventEmitter<TestEvent> {
 public:
  ~TestEmitter() override { ShutdownEmitter(); }

  using EventEmitter<TestEvent>::Emit;

  template <typename E, typename... Args>
  void EmitAsyncPublic(Args&&... args) {
    EmitAsync<E>(std::forward<Args>(args)...);
  }

  int start_calls = 0;
  int stop_calls = 0;

 protected:
  void StartEventListening() override { ++start_calls; }
  void StopEventListening() override { ++stop_calls; }
};

// ---------------------------------------------------------------------------
// P0-1: EmitAsync must not deadlock on its first call
// ---------------------------------------------------------------------------

void TestEmitAsyncDoesNotDeadlock() {
  std::cout << "[P0-1] EmitAsync first call" << std::endl;

  TestEmitter emitter;
  int received = 0;

  emitter.AddListener<TestEvent>([&](const TestEvent& e) { received = e.value; });

  // Before the fix this call never returned: EmitAsync held queue_mutex_ and
  // then called StartAsyncProcessing(), which locked queue_mutex_ again.
  emitter.EmitAsyncPublic<TestEvent>(42);

  Check(received == 0, "EmitAsync defers rather than delivering inline");
  g_main_thread->Drain();

  Check(received == 42, "async event reaches the listener on the main thread");
}

// Mirrors ShortcutManager::Register(): EmitAsync is called while the caller
// still holds its own lock (shortcut_manager.cpp:29 -> :34/:42/:56/:66).
// Deferring is what keeps the listener from running under that lock.
void TestEmitAsyncUnderCallerLock() {
  std::cout << "[P0-1] EmitAsync while caller holds its own lock" << std::endl;

  TestEmitter emitter;
  std::mutex caller_mutex;
  bool ran_under_caller_lock = false;
  int received = 0;

  emitter.AddListener<TestEvent>([&](const TestEvent& e) {
    received = e.value;
    // If the callback runs while the emitting scope still holds caller_mutex_,
    // try_lock fails — that is the hazard this design avoids.
    if (caller_mutex.try_lock()) {
      caller_mutex.unlock();
    } else {
      ran_under_caller_lock = true;
    }
  });

  {
    std::unique_lock<std::mutex> lock(caller_mutex);
    emitter.EmitAsyncPublic<TestEvent>(7);
  }
  g_main_thread->Drain();

  Check(received == 7, "cross-lock EmitAsync completes");
  Check(!ran_under_caller_lock, "listener does not run under the emitter's caller lock");
}

// EmitAsync from a background thread must land on the main thread.
void TestEmitAsyncFromBackgroundThread() {
  std::cout << "[P0-5] EmitAsync from a background thread" << std::endl;

  TestEmitter emitter;
  std::atomic<bool> delivered_on_main{false};
  std::atomic<int> received{0};

  emitter.AddListener<TestEvent>([&](const TestEvent& e) {
    received.store(e.value);
    delivered_on_main.store(IsMainThread());
  });

  std::thread worker([&] { emitter.EmitAsyncPublic<TestEvent>(99); });
  worker.join();

  Check(received.load() == 0, "not delivered on the emitting background thread");
  g_main_thread->Drain();

  Check(received.load() == 99, "event delivered after draining the main thread queue");
  Check(delivered_on_main.load(), "listener ran on the main thread, not the worker");
}

// A queued event whose emitter dies before the main thread drains must not
// dispatch into freed memory.
void TestAsyncAfterEmitterDestroyed() {
  std::cout << "[P0-5] emitter destroyed before queued event runs" << std::endl;

  std::atomic<int> calls{0};
  {
    TestEmitter emitter;
    emitter.AddListener<TestEvent>([&](const TestEvent&) { ++calls; });
    emitter.EmitAsyncPublic<TestEvent>(1);
    Check(g_main_thread->PendingCount() == 1, "event is queued while emitter is alive");
  }  // ~TestEmitter -> ShutdownEmitter()

  g_main_thread->Drain();
  Check(calls.load() == 0, "queued event is dropped once the emitter is gone");
}

// ---------------------------------------------------------------------------
// P0-2: callbacks must run without the listener lock held
// ---------------------------------------------------------------------------

void TestRemoveSelfFromCallback() {
  std::cout << "[P0-2] listener removes itself from its own callback" << std::endl;

  TestEmitter emitter;
  std::atomic<int> calls{0};
  size_t id = 0;

  id = emitter.AddListener<TestEvent>([&](const TestEvent&) {
    ++calls;
    // Before the fix this deadlocked: RemoveListener wants listeners_mutex_,
    // which Emit was still holding.
    emitter.RemoveListener(id);
  });

  emitter.Emit(TestEvent(1));
  emitter.Emit(TestEvent(2));

  Check(calls.load() == 1, "one-shot listener fires exactly once");
  Check(emitter.GetTotalListenerCount() == 0, "listener is gone after self-removal");
}

void TestAddListenerFromCallback() {
  std::cout << "[P0-2] listener adds another listener from its callback" << std::endl;

  TestEmitter emitter;
  std::atomic<int> outer{0};
  std::atomic<int> inner{0};

  emitter.AddListener<TestEvent>([&](const TestEvent&) {
    ++outer;
    if (outer.load() == 1) {
      emitter.AddListener<TestEvent>([&](const TestEvent&) { ++inner; });
    }
  });

  emitter.Emit(TestEvent(1));
  Check(outer.load() == 1, "first emit reaches the original listener");
  Check(inner.load() == 0, "listener added during dispatch does not fire for that same event");

  emitter.Emit(TestEvent(2));
  Check(inner.load() == 1, "newly added listener fires on the next event");
}

void TestReentrantEmitFromCallback() {
  std::cout << "[P0-2] re-entrant Emit from inside a callback" << std::endl;

  TestEmitter emitter;
  std::atomic<int> depth{0};
  std::atomic<int> max_depth{0};

  emitter.AddListener<TestEvent>([&](const TestEvent& e) {
    const int d = ++depth;
    if (d > max_depth.load()) {
      max_depth.store(d);
    }
    if (e.value > 0) {
      emitter.Emit(TestEvent(e.value - 1));
    }
    --depth;
  });

  emitter.Emit(TestEvent(3));

  Check(max_depth.load() == 4, "nested Emit recursion completes without deadlock");
}

void TestRemoveOtherListenerDuringDispatch() {
  std::cout << "[P0-2] listener removes a not-yet-invoked listener" << std::endl;

  TestEmitter emitter;
  std::atomic<int> second_calls{0};
  size_t second_id = 0;

  emitter.AddListener<TestEvent>([&](const TestEvent&) { emitter.RemoveListener(second_id); });
  second_id = emitter.AddListener<TestEvent>([&](const TestEvent&) { ++second_calls; });

  emitter.Emit(TestEvent(1));

  // The tombstone must suppress delivery even though the snapshot was taken
  // before the removal happened.
  Check(second_calls.load() == 0, "removed-mid-dispatch listener does not fire");
}

// ---------------------------------------------------------------------------
// Dispatch semantics
// ---------------------------------------------------------------------------

void TestBaseAndDerivedDispatch() {
  std::cout << "[dispatch] base/derived routing" << std::endl;

  TestEmitter emitter;
  std::atomic<int> base_calls{0};
  std::atomic<int> derived_calls{0};
  std::atomic<int> other_calls{0};

  emitter.AddListener<TestEvent>([&](const TestEvent&) { ++base_calls; });
  emitter.AddListener<DerivedEvent>([&](const DerivedEvent&) { ++derived_calls; });
  emitter.AddListener<OtherEvent>([&](const OtherEvent&) { ++other_calls; });

  emitter.Emit(DerivedEvent(1));

  Check(base_calls.load() == 1, "base listener receives derived event");
  Check(derived_calls.load() == 1, "derived listener receives derived event");
  Check(other_calls.load() == 0, "sibling listener does not receive derived event");

  emitter.Emit(TestEvent(2));

  Check(base_calls.load() == 2, "base listener receives base event");
  Check(derived_calls.load() == 1, "derived listener does not receive base event");
}

void TestDispatchOrder() {
  std::cout << "[dispatch] registration order" << std::endl;

  TestEmitter emitter;
  std::vector<int> order;

  emitter.AddListener<TestEvent>([&](const TestEvent&) { order.push_back(1); });
  emitter.AddListener<DerivedEvent>([&](const DerivedEvent&) { order.push_back(2); });
  emitter.AddListener<TestEvent>([&](const TestEvent&) { order.push_back(3); });

  emitter.Emit(DerivedEvent(0));

  const bool ok = order.size() == 3 && order[0] == 1 && order[1] == 2 && order[2] == 3;
  Check(ok, "listeners fire in registration order across types");
}

void TestDispatchCacheInvalidation() {
  std::cout << "[dispatch] cache invalidation" << std::endl;

  TestEmitter emitter;
  std::atomic<int> calls{0};

  emitter.Emit(TestEvent(1));  // Populate the cache with an empty result.

  emitter.AddListener<TestEvent>([&](const TestEvent&) { ++calls; });
  emitter.Emit(TestEvent(2));
  Check(calls.load() == 1, "cache invalidated after AddListener");

  emitter.RemoveAllListeners();
  emitter.Emit(TestEvent(3));
  Check(calls.load() == 1, "cache invalidated after RemoveAllListeners");
}

// ---------------------------------------------------------------------------
// Start/StopEventListening lifecycle
// ---------------------------------------------------------------------------

void TestListeningLifecycle() {
  std::cout << "[lifecycle] Start/StopEventListening transitions" << std::endl;

  TestEmitter emitter;

  const size_t a = emitter.AddListener<TestEvent>([](const TestEvent&) {});
  Check(emitter.start_calls == 1, "StartEventListening on 0->1");

  const size_t b = emitter.AddListener<TestEvent>([](const TestEvent&) {});
  Check(emitter.start_calls == 1, "no extra StartEventListening on 1->2");

  emitter.RemoveListener(a);
  Check(emitter.stop_calls == 0, "no StopEventListening while listeners remain");

  emitter.RemoveListener(b);
  Check(emitter.stop_calls == 1, "StopEventListening on 1->0");
}

// A platform hook that calls back into the emitter must not deadlock. Before the
// fix these hooks ran while listeners_mutex_ was held.
class ReentrantHookEmitter : public EventEmitter<TestEvent> {
 public:
  ~ReentrantHookEmitter() override { ShutdownEmitter(); }
  using EventEmitter<TestEvent>::Emit;
  std::atomic<int> hook_observed_count{0};

 protected:
  void StartEventListening() override {
    // Re-enters the emitter from inside the hook.
    hook_observed_count.store(static_cast<int>(GetTotalListenerCount()));
  }
};

void TestHookMayReenter() {
  std::cout << "[lifecycle] platform hook re-enters the emitter" << std::endl;

  ReentrantHookEmitter emitter;
  emitter.AddListener<TestEvent>([](const TestEvent&) {});

  Check(emitter.hook_observed_count.load() == 1,
        "StartEventListening can query the emitter without deadlocking");
}

// ---------------------------------------------------------------------------
// Concurrency
// ---------------------------------------------------------------------------

void TestConcurrentAddRemoveEmit() {
  std::cout << "[concurrency] parallel add/remove/emit" << std::endl;

  TestEmitter emitter;
  std::atomic<bool> stop{false};
  std::atomic<long> deliveries{0};

  std::thread emitter_thread([&] {
    while (!stop.load()) {
      emitter.Emit(TestEvent(1));
    }
  });

  std::vector<std::thread> churn;
  for (int t = 0; t < 4; ++t) {
    churn.emplace_back([&] {
      for (int i = 0; i < 200; ++i) {
        const size_t id = emitter.AddListener<TestEvent>([&](const TestEvent&) { ++deliveries; });
        std::this_thread::yield();
        emitter.RemoveListener(id);
      }
    });
  }

  for (auto& t : churn) {
    t.join();
  }
  stop.store(true);
  emitter_thread.join();

  Check(true, "no deadlock or crash under concurrent churn");
  Check(emitter.GetTotalListenerCount() == 0, "all listeners removed after churn");
}

int RunTests() {
  TestEmitAsyncDoesNotDeadlock();
  TestEmitAsyncUnderCallerLock();
  TestEmitAsyncFromBackgroundThread();
  TestAsyncAfterEmitterDestroyed();
  TestRemoveSelfFromCallback();
  TestAddListenerFromCallback();
  TestReentrantEmitFromCallback();
  TestRemoveOtherListenerDuringDispatch();
  TestBaseAndDerivedDispatch();
  TestDispatchOrder();
  TestDispatchCacheInvalidation();
  TestListeningLifecycle();
  TestHookMayReenter();
  TestConcurrentAddRemoveEmit();

  if (g_failures != 0) {
    std::cerr << g_failures << " check(s) failed." << std::endl;
    return 1;
  }
  std::cout << "All event_emitter checks passed." << std::endl;
  return 0;
}

}  // namespace

int main() {
  Watchdog watchdog(std::chrono::seconds(60));

  FakeMainThread main_thread;
  g_main_thread = &main_thread;

  const int result = RunTests();

  g_main_thread = nullptr;
  return result;
}
