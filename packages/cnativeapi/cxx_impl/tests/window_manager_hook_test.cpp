// Unit tests for WindowManager will-show/hide/close hook infrastructure.
//
// These tests verify the hook storage and dispatch logic without requiring
// a real platform window. The swizzle-based interception is exercised by
// the examples and integration tests on each platform.

#include <atomic>
#include <chrono>
#include <cstdlib>
#include <iostream>
#include <thread>

#include "../src/window_manager.h"
#include "../src/window.h"

namespace {

using namespace nativeapi;

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

// Setting a hook should make HasWillCloseHook return true; clearing it
// (passing nullopt) should make it return false.
bool test_set_and_clear_will_close_hook() {
  auto& manager = WindowManager::GetInstance();

  // Clear any existing hook
  manager.SetWillCloseHook(std::nullopt);
  if (manager.HasWillCloseHook()) {
    std::cerr << "FAIL: HasWillCloseHook should be false after clear\n";
    return false;
  }

  // Set a hook
  manager.SetWillCloseHook([](WindowId) {});
  if (!manager.HasWillCloseHook()) {
    std::cerr << "FAIL: HasWillCloseHook should be true after set\n";
    return false;
  }

  // Clear it
  manager.SetWillCloseHook(std::nullopt);
  if (manager.HasWillCloseHook()) {
    std::cerr << "FAIL: HasWillCloseHook should be false after second clear\n";
    return false;
  }

  return true;
}

// HandleWillClose should invoke the registered hook with the correct ID.
bool test_handle_will_close_invokes_hook() {
  auto& manager = WindowManager::GetInstance();

  const WindowId test_id = 42;
  std::atomic<WindowId> received_id{0};
  std::atomic<bool> was_called{false};

  manager.SetWillCloseHook([&](WindowId id) {
    received_id = id;
    was_called = true;
  });

  manager.HandleWillClose(test_id);

  // Give async dispatch a moment (HandleWillClose is synchronous, but
  // be defensive in case the platform routes through a dispatcher).
  for (int i = 0; i < 100 && !was_called; ++i) {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }

  if (!was_called) {
    std::cerr << "FAIL: will-close hook was not invoked\n";
    manager.SetWillCloseHook(std::nullopt);
    return false;
  }

  if (received_id != test_id) {
    std::cerr << "FAIL: will-close hook received wrong id: " << received_id
              << " expected " << test_id << "\n";
    manager.SetWillCloseHook(std::nullopt);
    return false;
  }

  // Cleanup
  manager.SetWillCloseHook(std::nullopt);
  return true;
}

// HandleWillClose with no hook set should be a no-op (not crash).
bool test_handle_will_close_no_hook_is_safe() {
  auto& manager = WindowManager::GetInstance();
  manager.SetWillCloseHook(std::nullopt);

  // Should not crash
  manager.HandleWillClose(99);

  return true;
}

// All three hooks (show, hide, close) should coexist independently.
bool test_all_hooks_coexist() {
  auto& manager = WindowManager::GetInstance();

  std::atomic<bool> show_called{false};
  std::atomic<bool> hide_called{false};
  std::atomic<bool> close_called{false};

  manager.SetWillShowHook([&](WindowId) { show_called = true; });
  manager.SetWillHideHook([&](WindowId) { hide_called = true; });
  manager.SetWillCloseHook([&](WindowId) { close_called = true; });

  if (!manager.HasWillShowHook() || !manager.HasWillHideHook() ||
      !manager.HasWillCloseHook()) {
    std::cerr << "FAIL: not all hooks report as set\n";
    manager.SetWillShowHook(std::nullopt);
    manager.SetWillHideHook(std::nullopt);
    manager.SetWillCloseHook(std::nullopt);
    return false;
  }

  manager.HandleWillShow(1);
  manager.HandleWillHide(1);
  manager.HandleWillClose(1);

  for (int i = 0; i < 100 && (!show_called || !hide_called || !close_called); ++i) {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }

  if (!show_called || !hide_called || !close_called) {
    std::cerr << "FAIL: not all hooks were invoked (show=" << show_called
              << " hide=" << hide_called << " close=" << close_called << ")\n";
    manager.SetWillShowHook(std::nullopt);
    manager.SetWillHideHook(std::nullopt);
    manager.SetWillCloseHook(std::nullopt);
    return false;
  }

  // Cleanup
  manager.SetWillShowHook(std::nullopt);
  manager.SetWillHideHook(std::nullopt);
  manager.SetWillCloseHook(std::nullopt);
  return true;
}

}  // namespace

int main() {
  struct TestCase {
    const char* name;
    bool (*fn)();
  };

  TestCase tests[] = {
      {"set_and_clear_will_close_hook", test_set_and_clear_will_close_hook},
      {"handle_will_close_invokes_hook", test_handle_will_close_invokes_hook},
      {"handle_will_close_no_hook_is_safe",
       test_handle_will_close_no_hook_is_safe},
      {"all_hooks_coexist", test_all_hooks_coexist},
  };

  int failures = 0;
  for (const auto& tc : tests) {
    std::cout << "RUN  " << tc.name << "\n";
    if (tc.fn()) {
      std::cout << "PASS " << tc.name << "\n";
    } else {
      std::cout << "FAIL " << tc.name << "\n";
      ++failures;
    }
  }

  if (failures > 0) {
    std::cout << "\n" << failures << " test(s) failed\n";
    return 1;
  }

  std::cout << "\nAll tests passed\n";
  return 0;
}
