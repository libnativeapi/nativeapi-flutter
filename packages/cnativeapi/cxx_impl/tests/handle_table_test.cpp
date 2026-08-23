// Tests for the generational handle table.
//
// Maps to DESIGN_REVIEW.md P0-3 / P0-4 and docs/handle-ownership.md. The
// behaviours asserted here are exactly the ones raw-pointer handles could not
// provide: stale handles failing safely instead of dereferencing freed memory,
// double-release being a no-op, and handle confusion being rejected rather than
// reinterpreted.

#include <atomic>
#include <cstdlib>
#include <functional>
#include <iostream>
#include <memory>
#include <set>
#include <string>
#include <thread>
#include <vector>

#include "../src/foundation/handle_table.h"

// ---------------------------------------------------------------------------
// Test-local types
//
// Registered in the high end of the tag range so they cannot collide with the
// real registry in id_allocator.h, which is append-only for shipping types.
// ---------------------------------------------------------------------------
namespace nativeapi {

struct FakeWidget {
  explicit FakeWidget(int v) : value(v) {}
  int value;
};

struct FakeGadget {
  explicit FakeGadget(int v) : value(v) {}
  int value;
};

/// Calls back into the table from its destructor.
struct SelfReleasingThing {
  std::function<void()> on_destroy;
  ~SelfReleasingThing() {
    if (on_destroy) {
      on_destroy();
    }
  }
};

template <>
struct IdTypeTag<FakeWidget> {
  static constexpr uint32_t value = 200;
};
template <>
struct IdTypeTag<FakeGadget> {
  static constexpr uint32_t value = 201;
};
template <>
struct IdTypeTag<SelfReleasingThing> {
  static constexpr uint32_t value = 202;
};

}  // namespace nativeapi

namespace {

using namespace nativeapi;

int g_failures = 0;

void Check(bool condition, const std::string& what) {
  if (!condition) {
    std::cerr << "FAIL: " << what << std::endl;
    ++g_failures;
  } else {
    std::cout << "  ok: " << what << std::endl;
  }
}

HandleTable& Table() {
  return HandleTable::GetInstance();
}

// ---------------------------------------------------------------------------
// Basics
// ---------------------------------------------------------------------------

void TestInsertResolveRoundTrip() {
  std::cout << "[basic] insert/resolve round-trip" << std::endl;

  const auto handle = Table().Insert(std::make_shared<FakeWidget>(42));
  Check(handle != kInvalidHandle, "insert returns a usable handle");

  auto resolved = Table().Resolve<FakeWidget>(handle);
  Check(resolved != nullptr, "handle resolves");
  Check(resolved && resolved->value == 42, "resolved object carries the right state");
  Check(Table().Contains(handle), "Contains agrees");

  Table().Release(handle);
}

void TestNullAndInvalid() {
  std::cout << "[basic] null and invalid inputs" << std::endl;

  Check(Table().Insert(std::shared_ptr<FakeWidget>()) == kInvalidHandle,
        "inserting null yields kInvalidHandle");
  Check(Table().Resolve<FakeWidget>(kInvalidHandle) == nullptr, "kInvalidHandle never resolves");
  Check(!Table().Release(kInvalidHandle), "releasing kInvalidHandle is a no-op");
  Check(!Table().Contains(kInvalidHandle), "kInvalidHandle is not contained");

  // A handle whose slot index is far beyond the table.
  const HandleValue bogus = HandleTable::Encode(1, 0xFFFFFF);
  Check(Table().Resolve<FakeWidget>(bogus) == nullptr, "out-of-range slot fails safely");
  Check(!Table().Release(bogus), "releasing an out-of-range slot is a no-op");
}

// ---------------------------------------------------------------------------
// The failure modes raw pointers could not survive
// ---------------------------------------------------------------------------

void TestReleaseInvalidatesHandle() {
  std::cout << "[safety] release invalidates the handle" << std::endl;

  const auto handle = Table().Insert(std::make_shared<FakeWidget>(1));
  Check(Table().Release(handle), "first release succeeds");

  Check(Table().Resolve<FakeWidget>(handle) == nullptr, "released handle no longer resolves");
  Check(!Table().Contains(handle), "released handle is not contained");
}

void TestDoubleReleaseIsSafe() {
  std::cout << "[safety] double release" << std::endl;

  const auto handle = Table().Insert(std::make_shared<FakeWidget>(1));

  Check(Table().Release(handle), "first release succeeds");
  Check(!Table().Release(handle), "second release reports failure instead of double-freeing");
  Check(!Table().Release(handle), "third release likewise");
}

// The critical one for GC languages: a finalizer running late must not be able
// to reach a new object that happens to have landed in the recycled slot.
void TestStaleHandleAfterSlotReuse() {
  std::cout << "[safety] stale handle after slot reuse" << std::endl;

  const auto first = Table().Insert(std::make_shared<FakeWidget>(111));
  const uint32_t slot = HandleTable::SlotOf(first);
  Table().Release(first);

  // Force reuse of the same slot.
  const auto second = Table().Insert(std::make_shared<FakeWidget>(222));
  Check(HandleTable::SlotOf(second) == slot, "slot was recycled (precondition)");
  Check(HandleTable::GenerationOf(second) != HandleTable::GenerationOf(first),
        "generation advanced on reuse");

  Check(Table().Resolve<FakeWidget>(first) == nullptr,
        "the OLD handle does not resolve to the NEW occupant");

  auto live = Table().Resolve<FakeWidget>(second);
  Check(live && live->value == 222, "the new handle resolves correctly");

  Check(!Table().Release(first), "releasing the stale handle does not evict the new occupant");
  Check(Table().Contains(second), "new occupant survives the stale release");

  Table().Release(second);
}

void TestTypeConfusionRejected() {
  std::cout << "[safety] handle confusion" << std::endl;

  const auto widget = Table().Insert(std::make_shared<FakeWidget>(7));

  Check(Table().Resolve<FakeGadget>(widget) == nullptr,
        "resolving a widget handle as a gadget returns null");
  Check(Table().Resolve<FakeWidget>(widget) != nullptr, "correct type still resolves");
  Check(Table().GetTypeTag(widget) == IdTypeTag<FakeWidget>::value, "type tag is readable");

  Table().Release(widget);
}

// Resolve() hands out a strong reference; releasing the handle must not pull the
// object out from under a caller that is still using it.
void TestResolvedReferenceOutlivesRelease() {
  std::cout << "[safety] resolved reference outlives release" << std::endl;

  auto handle = Table().Insert(std::make_shared<FakeWidget>(99));
  auto strong = Table().Resolve<FakeWidget>(handle);

  Table().Release(handle);

  Check(strong != nullptr, "previously resolved reference is still held");
  Check(strong->value == 99, "and the object is still readable after release");
  Check(strong.use_count() == 1, "caller now holds the only reference");
}

// Release() must drop the last reference outside its own lock, or a destructor
// touching the table deadlocks.
void TestDestructorMayReenterTable() {
  std::cout << "[safety] destructor re-enters the table" << std::endl;

  const auto inner = Table().Insert(std::make_shared<FakeWidget>(5));

  auto thing = std::make_shared<SelfReleasingThing>();
  thing->on_destroy = [inner] { HandleTable::GetInstance().Release(inner); };
  const auto outer = Table().Insert(thing);
  thing.reset();

  // Before deferring destruction past the lock, this call deadlocked.
  Check(Table().Release(outer), "releasing an object whose destructor re-enters succeeds");
  Check(!Table().Contains(inner), "the nested release took effect");
}

// ---------------------------------------------------------------------------
// Bookkeeping
// ---------------------------------------------------------------------------

void TestSlotReuseKeepsTableCompact() {
  std::cout << "[bookkeeping] slot reuse" << std::endl;

  const size_t baseline = Table().LiveCount();

  std::vector<HandleValue> handles;
  for (int i = 0; i < 100; ++i) {
    handles.push_back(Table().Insert(std::make_shared<FakeWidget>(i)));
  }
  Check(Table().LiveCount() == baseline + 100, "LiveCount tracks insertions");

  for (const auto handle : handles) {
    Table().Release(handle);
  }
  Check(Table().LiveCount() == baseline, "LiveCount returns to baseline after releases");

  std::set<uint32_t> reused_slots;
  std::vector<HandleValue> again;
  for (int i = 0; i < 100; ++i) {
    const auto handle = Table().Insert(std::make_shared<FakeWidget>(i));
    again.push_back(handle);
    reused_slots.insert(HandleTable::SlotOf(handle));
  }
  Check(reused_slots.size() == 100, "reinsertion reuses freed slots rather than growing");

  for (const auto handle : again) {
    Table().Release(handle);
  }
}

void TestHandlesAreDistinct() {
  std::cout << "[bookkeeping] handle uniqueness" << std::endl;

  std::set<HandleValue> seen;
  std::vector<HandleValue> handles;
  for (int i = 0; i < 500; ++i) {
    const auto handle = Table().Insert(std::make_shared<FakeWidget>(i));
    handles.push_back(handle);
    seen.insert(handle);
  }

  Check(seen.size() == 500, "concurrently live handles are all distinct");

  for (const auto handle : handles) {
    Table().Release(handle);
  }
}

// ---------------------------------------------------------------------------
// Concurrency
// ---------------------------------------------------------------------------

void TestConcurrentInsertResolveRelease() {
  std::cout << "[concurrency] parallel insert/resolve/release" << std::endl;

  constexpr int kThreads = 8;
  constexpr int kPerThread = 400;

  const size_t baseline = Table().LiveCount();
  std::atomic<int> resolve_failures{0};
  std::atomic<int> stale_resolves{0};

  std::vector<std::thread> threads;
  for (int t = 0; t < kThreads; ++t) {
    threads.emplace_back([&] {
      for (int i = 0; i < kPerThread; ++i) {
        const auto handle = Table().Insert(std::make_shared<FakeWidget>(i));

        auto resolved = Table().Resolve<FakeWidget>(handle);
        if (!resolved || resolved->value != i) {
          ++resolve_failures;
        }

        Table().Release(handle);

        // Must never resolve after our own release, no matter what other
        // threads are doing to that slot.
        if (Table().Resolve<FakeWidget>(handle) != nullptr) {
          ++stale_resolves;
        }
      }
    });
  }
  for (auto& thread : threads) {
    thread.join();
  }

  Check(resolve_failures.load() == 0, "every handle resolved to its own object");
  Check(stale_resolves.load() == 0, "no handle resolved after being released");
  Check(Table().LiveCount() == baseline, "no handles leaked under concurrency");
}

int RunTests() {
  TestInsertResolveRoundTrip();
  TestNullAndInvalid();
  TestReleaseInvalidatesHandle();
  TestDoubleReleaseIsSafe();
  TestStaleHandleAfterSlotReuse();
  TestTypeConfusionRejected();
  TestResolvedReferenceOutlivesRelease();
  TestDestructorMayReenterTable();
  TestSlotReuseKeepsTableCompact();
  TestHandlesAreDistinct();
  TestConcurrentInsertResolveRelease();

  if (g_failures != 0) {
    std::cerr << g_failures << " check(s) failed." << std::endl;
    return 1;
  }
  std::cout << "All handle_table checks passed." << std::endl;
  return 0;
}

}  // namespace

int main() {
  return RunTests();
}
