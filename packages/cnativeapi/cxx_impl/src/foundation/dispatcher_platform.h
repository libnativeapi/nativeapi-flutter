#pragma once

#include <functional>

namespace nativeapi {
namespace dispatcher_platform {

/**
 * @file dispatcher_platform.h
 * @brief Internal seam between the public dispatcher API and each platform.
 *
 * Platform files under src/platform/<os>/dispatcher_<os>.* implement these.
 * The public entry points in dispatcher.cpp own the override logic and forward
 * here when no override is installed, so platform code never has to know about
 * embedder-supplied schedulers.
 */

bool PlatformIsMainThread();
void PlatformSetMainThread();
bool PlatformIsMainThreadDispatchSupported();
bool PlatformRunOnMainThread(std::function<void()> fn);
bool PlatformRunMainThreadLoopFor(int timeout_ms);

}  // namespace dispatcher_platform
}  // namespace nativeapi
