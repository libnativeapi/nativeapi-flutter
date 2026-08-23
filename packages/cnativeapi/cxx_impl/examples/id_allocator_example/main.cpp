#include <algorithm>
#include <chrono>
#include <iostream>
#include <mutex>
#include <thread>
#include <vector>
#include "../../src/foundation/id_allocator.h"

using namespace nativeapi;

// Window, Menu, MenuItem, TrayIcon and Display come from the IdTypeTag registry
// in id_allocator.h. They are only ever used as template arguments here, so the
// forward declarations that header already provides are enough — no need to pull
// in the full class definitions.
//
// This example used to declare its own placeholder structs with these names.
// That worked back when type tags were assigned by a runtime counter and any
// type at all could be passed. Tags are now compile-time constants from a
// central registry, so a type must be registered to be allocatable.

int main() {
  std::cout << "IdAllocator Template Example" << std::endl;
  std::cout << "============================" << std::endl;

  // Example 1: Basic allocation for different object types
  std::cout << "\n1. Basic Allocation:" << std::endl;

  auto window_id = IdAllocator::Allocate<Window>();
  auto menu_id = IdAllocator::Allocate<Menu>();
  auto tray_id = IdAllocator::Allocate<TrayIcon>();

  std::cout << "Window ID: 0x" << std::hex << window_id << std::dec
            << " (Type: " << IdAllocator::GetType(window_id)
            << ", Sequence: " << IdAllocator::GetSequence(window_id) << ")" << std::endl;

  std::cout << "Menu ID: 0x" << std::hex << menu_id << std::dec
            << " (Type: " << IdAllocator::GetType(menu_id)
            << ", Sequence: " << IdAllocator::GetSequence(menu_id) << ")" << std::endl;

  std::cout << "Tray ID: 0x" << std::hex << tray_id << std::dec
            << " (Type: " << IdAllocator::GetType(tray_id)
            << ", Sequence: " << IdAllocator::GetSequence(tray_id) << ")" << std::endl;

  // Example 2: TryAllocate with error checking
  std::cout << "\n2. TryAllocate (safer allocation):" << std::endl;

  auto maybe_id = IdAllocator::TryAllocate<MenuItem>();
  if (maybe_id != IdAllocator::kInvalidId) {
    std::cout << "MenuItem ID allocated successfully: 0x" << std::hex << maybe_id << std::dec
              << std::endl;
  } else {
    std::cout << "MenuItem ID allocation failed" << std::endl;
  }

  // Example 3: ID validation and decomposition
  std::cout << "\n3. ID Validation and Decomposition:" << std::endl;

  std::cout << "Is window_id valid? " << (IdAllocator::IsValid(window_id) ? "Yes" : "No")
            << std::endl;

  auto decomposed = IdAllocator::Decompose(window_id);
  std::cout << "Window ID decomposed - Type: " << decomposed.first
            << ", Sequence: " << decomposed.second << std::endl;

  // Example 4: Current count query
  std::cout << "\n4. Current Counter Query:" << std::endl;

  std::cout << "Current Window counter (before allocation): "
            << IdAllocator::GetCurrentCount<Window>() << std::endl;

  auto new_window_id = IdAllocator::Allocate<Window>();
  std::cout << "New Window ID: 0x" << std::hex << new_window_id << std::dec
            << " (Sequence: " << IdAllocator::GetSequence(new_window_id) << ")" << std::endl;

  std::cout << "Current Window counter (after allocation): "
            << IdAllocator::GetCurrentCount<Window>() << std::endl;

  // Example 5: Multiple allocations
  std::cout << "\n5. Multiple Allocations:" << std::endl;

  std::vector<IdAllocator::IdType> window_ids;
  for (int i = 0; i < 5; ++i) {
    window_ids.push_back(IdAllocator::Allocate<Window>());
  }

  std::cout << "Allocated " << window_ids.size() << " Window IDs:" << std::endl;
  for (size_t i = 0; i < window_ids.size(); ++i) {
    std::cout << "  ID " << (i + 1) << ": 0x" << std::hex << window_ids[i] << std::dec
              << " (Sequence: " << IdAllocator::GetSequence(window_ids[i]) << ")" << std::endl;
  }

  // Example 6: Thread safety demonstration
  std::cout << "\n6. Thread Safety Demonstration:" << std::endl;

  std::vector<std::thread> threads;
  std::vector<IdAllocator::IdType> thread_ids;
  std::mutex ids_mutex;

  const int num_threads = 3;
  const int ids_per_thread = 10;

  auto start_time = std::chrono::high_resolution_clock::now();

  for (int i = 0; i < num_threads; ++i) {
    threads.emplace_back([&thread_ids, &ids_mutex, ids_per_thread, i]() {
      std::vector<IdAllocator::IdType> local_ids;

      for (int j = 0; j < ids_per_thread; ++j) {
        auto id = IdAllocator::Allocate<Display>();
        local_ids.push_back(id);
      }

      {
        std::lock_guard<std::mutex> lock(ids_mutex);
        thread_ids.insert(thread_ids.end(), local_ids.begin(), local_ids.end());
      }
    });
  }

  for (auto& thread : threads) {
    thread.join();
  }

  auto end_time = std::chrono::high_resolution_clock::now();
  auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_time - start_time);

  std::cout << "Allocated " << thread_ids.size() << " Display IDs from " << num_threads
            << " threads in " << duration.count() << " microseconds" << std::endl;

  // Verify all IDs are unique
  std::sort(thread_ids.begin(), thread_ids.end());
  auto it = std::unique(thread_ids.begin(), thread_ids.end());
  std::cout << "All IDs are unique: " << (it == thread_ids.end() ? "Yes" : "No") << std::endl;

  // Example 7: Different object types
  std::cout << "\n7. Different Object Types:" << std::endl;

  auto display_id = IdAllocator::Allocate<Display>();

  std::cout << "Display ID: 0x" << std::hex << display_id << std::dec
            << " (Type: " << IdAllocator::GetType(display_id) << ")" << std::endl;

  // Example 8: Reset functionality (for testing)
  std::cout << "\n8. Reset Functionality:" << std::endl;

  std::cout << "Menu counter before reset: " << IdAllocator::GetCurrentCount<Menu>() << std::endl;
  IdAllocator::Reset<Menu>();
  std::cout << "Menu counter after reset: " << IdAllocator::GetCurrentCount<Menu>() << std::endl;

  auto new_menu_id = IdAllocator::Allocate<Menu>();
  std::cout << "New Menu ID after reset: 0x" << std::hex << new_menu_id << std::dec
            << " (Sequence: " << IdAllocator::GetSequence(new_menu_id) << ")" << std::endl;

  // Example 9: Independent types after reset
  std::cout << "\n9. Independent Types After Reset:" << std::endl;

  auto window_after_reset = IdAllocator::Allocate<Window>();
  std::cout << "Window ID after Menu reset: 0x" << std::hex << window_after_reset << std::dec
            << " (Sequence: " << IdAllocator::GetSequence(window_after_reset) << ")" << std::endl;
  std::cout << "Window counter was not affected by Menu reset" << std::endl;

  std::cout << "\nExample completed successfully!" << std::endl;
  return 0;
}
