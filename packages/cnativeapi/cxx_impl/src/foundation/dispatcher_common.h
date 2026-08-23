#pragma once

#include <thread>

namespace nativeapi {
namespace dispatcher_internal {

/**
 * @brief The thread treated as "main" on platforms where the OS cannot tell us.
 *
 * Dynamically initialized during static initialization, so it captures the
 * thread that loaded the library. For a normal application that is the same
 * thread that later enters main(); for an oddly-embedded plugin it may not be,
 * which is what SetMainThread() exists to correct.
 *
 * An inline variable gives exactly one instance across all translation units.
 * No synchronization: SetMainThread() is documented as "before any other use",
 * and after that point this is read-only.
 */
inline std::thread::id g_main_thread_id = std::this_thread::get_id();

inline bool IsMainThreadByCapturedId() {
  return std::this_thread::get_id() == g_main_thread_id;
}

inline void CaptureCallerAsMainThread() {
  g_main_thread_id = std::this_thread::get_id();
}

}  // namespace dispatcher_internal
}  // namespace nativeapi
