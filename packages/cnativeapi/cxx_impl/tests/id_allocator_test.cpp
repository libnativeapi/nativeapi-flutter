// Tests for IdAllocator's ID encoding and type tagging.
//
// Maps to DESIGN_REVIEW.md P1-5: type tags used to be handed out by a runtime
// counter on a first-call-wins basis, so a given C++ type could receive a
// different tag depending on call order or from one run to the next. That made
// the type bits useless for the handle validation they are meant to support.

#include <atomic>
#include <cstdlib>
#include <iostream>
#include <set>
#include <string>
#include <thread>
#include <vector>

// Only id_allocator.h is needed: Window/Menu/MenuItem/TrayIcon/Display/Shortcut
// are used purely as template arguments, and the tag registry already
// forward-declares them.
#include "../src/foundation/id_allocator.h"

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

// ---------------------------------------------------------------------------
// Type tags
// ---------------------------------------------------------------------------

void TestTypeTagsAreCompileTimeConstants() {
  std::cout << "[tags] tags are compile-time constants" << std::endl;

  // If these were still runtime-assigned, they could not appear in a constant
  // expression at all — this block failing to compile IS the regression test.
  static_assert(IdTypeTag<Window>::value == 1, "Window tag changed");
  static_assert(IdTypeTag<Menu>::value == 2, "Menu tag changed");
  static_assert(IdTypeTag<MenuItem>::value == 3, "MenuItem tag changed");
  static_assert(IdTypeTag<TrayIcon>::value == 4, "TrayIcon tag changed");

  Check(true, "type tags usable in constant expressions");
}

void TestTypeTagsAreDistinct() {
  std::cout << "[tags] tags are distinct" << std::endl;

  const std::set<uint32_t> tags = {IdTypeTag<Window>::value, IdTypeTag<Menu>::value,
                                   IdTypeTag<MenuItem>::value, IdTypeTag<TrayIcon>::value,
                                   IdTypeTag<Display>::value, IdTypeTag<Shortcut>::value};

  Check(tags.size() == 6, "all six registered types have distinct tags");
  Check(tags.find(IdAllocator::kInvalidId) == tags.end(), "no type reuses the invalid-ID value");
}

// The property the old implementation could not provide: the tag encoded into
// an ID depends only on the type, never on which type allocated first.
void TestEncodedTypeIsIndependentOfAllocationOrder() {
  std::cout << "[tags] encoded type is independent of allocation order" << std::endl;

  const auto tray_first = IdAllocator::Allocate<TrayIcon>();
  const auto window_second = IdAllocator::Allocate<Window>();

  Check(IdAllocator::GetType(tray_first) == IdTypeTag<TrayIcon>::value,
        "TrayIcon ID carries the TrayIcon tag even when allocated first");
  Check(IdAllocator::GetType(window_second) == IdTypeTag<Window>::value,
        "Window ID carries the Window tag even when allocated second");
}

// ---------------------------------------------------------------------------
// ID encoding
// ---------------------------------------------------------------------------

void TestIdEncoding() {
  std::cout << "[encoding] type/sequence round-trip" << std::endl;

  const auto id = IdAllocator::Allocate<Menu>();
  const auto decomposed = IdAllocator::Decompose(id);

  Check(IdAllocator::IsValid(id), "allocated ID is valid");
  Check(decomposed.first == IdTypeTag<Menu>::value, "Decompose returns the right type");
  Check(decomposed.second == IdAllocator::GetSequence(id), "Decompose agrees with GetSequence");
  Check(IdAllocator::GetSequence(id) != 0, "sequence is never 0");
  Check(!IdAllocator::IsValid(IdAllocator::kInvalidId), "kInvalidId is not valid");
}

void TestIdsAreUniquePerType() {
  std::cout << "[encoding] uniqueness within a type" << std::endl;

  std::set<IdAllocator::IdType> ids;
  for (int i = 0; i < 1000; ++i) {
    ids.insert(IdAllocator::Allocate<Window>());
  }

  Check(ids.size() == 1000, "1000 allocations produce 1000 distinct IDs");
}

void TestIdsDoNotCollideAcrossTypes() {
  std::cout << "[encoding] no collisions across types" << std::endl;

  std::set<IdAllocator::IdType> ids;
  bool collision = false;
  for (int i = 0; i < 200; ++i) {
    if (!ids.insert(IdAllocator::Allocate<Window>()).second)
      collision = true;
    if (!ids.insert(IdAllocator::Allocate<Menu>()).second)
      collision = true;
    if (!ids.insert(IdAllocator::Allocate<MenuItem>()).second)
      collision = true;
  }

  Check(!collision, "interleaved allocation across three types never collides");
}

void TestIsValidTypeRange() {
  std::cout << "[encoding] type range" << std::endl;

  Check(!IdAllocator::IsValidType(0), "0 is not a valid type");
  Check(IdAllocator::IsValidType(1), "1 is a valid type");
  Check(IdAllocator::IsValidType(255), "255 is a valid type — the old cap of 10 is gone");
  Check(!IdAllocator::IsValidType(256), "256 exceeds the 8-bit field");
}

// ---------------------------------------------------------------------------
// Concurrency
// ---------------------------------------------------------------------------

void TestConcurrentAllocationIsUnique() {
  std::cout << "[concurrency] parallel allocation" << std::endl;

  constexpr int kThreads = 8;
  constexpr int kPerThread = 500;

  std::vector<std::vector<IdAllocator::IdType>> per_thread(kThreads);
  std::vector<std::thread> threads;

  for (int t = 0; t < kThreads; ++t) {
    threads.emplace_back([&per_thread, t, kPerThread] {
      per_thread[t].reserve(kPerThread);
      for (int i = 0; i < kPerThread; ++i) {
        per_thread[t].push_back(IdAllocator::Allocate<MenuItem>());
      }
    });
  }
  for (auto& thread : threads) {
    thread.join();
  }

  std::set<IdAllocator::IdType> all;
  bool wrong_type = false;
  for (const auto& chunk : per_thread) {
    for (const auto id : chunk) {
      all.insert(id);
      if (IdAllocator::GetType(id) != IdTypeTag<MenuItem>::value) {
        wrong_type = true;
      }
    }
  }

  Check(all.size() == kThreads * kPerThread, "concurrent allocations are all distinct");
  Check(!wrong_type, "every concurrently allocated ID carries the correct type tag");
}

int RunTests() {
  TestTypeTagsAreCompileTimeConstants();
  TestTypeTagsAreDistinct();
  TestEncodedTypeIsIndependentOfAllocationOrder();
  TestIdEncoding();
  TestIdsAreUniquePerType();
  TestIdsDoNotCollideAcrossTypes();
  TestIsValidTypeRange();
  TestConcurrentAllocationIsUnique();

  if (g_failures != 0) {
    std::cerr << g_failures << " check(s) failed." << std::endl;
    return 1;
  }
  std::cout << "All id_allocator checks passed." << std::endl;
  return 0;
}

}  // namespace

int main() {
  return RunTests();
}
