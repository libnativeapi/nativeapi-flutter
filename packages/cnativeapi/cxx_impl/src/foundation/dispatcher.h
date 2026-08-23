#pragma once

#include <functional>

namespace nativeapi {

/**
 * @file dispatcher.h
 * @brief Main/UI thread dispatch primitives.
 *
 * Every platform this library targets requires UI objects (windows, menus, tray
 * icons) to be touched only from the platform's main thread. Before this
 * abstraction existed, the rule was stated in doc comments but the library had
 * no way to honour it: background threads delivered events straight into user
 * callbacks, and each platform file open-coded its own `dispatch_async` /
 * `PostMessage` when it happened to remember.
 *
 * This header is the single place that knowledge now lives.
 */

/** Function that queues work to run on the main thread. @see SetMainThreadDispatcher. */
using MainThreadDispatchFn = std::function<bool(std::function<void()>)>;

/** Predicate reporting whether the caller is on the main thread. */
using MainThreadPredicateFn = std::function<bool()>;

/**
 * @brief Whether the calling thread is the platform's main/UI thread.
 *
 * On Apple platforms this is answered by the OS. Elsewhere the main thread is
 * the one that ran this module's static initializers — i.e. the thread that
 * loaded the library, which for a normal application is the thread that later
 * enters main(). Call SetMainThread() if that assumption does not hold for your
 * embedding (for example, a plugin loaded from a worker thread).
 */
bool IsMainThread();

/**
 * @brief Declare the calling thread to be the main/UI thread.
 *
 * Only needed when the automatic detection above is wrong. Must be called
 * before any other dispatcher use. Has no effect on Apple platforms, where the
 * OS is authoritative.
 *
 * On Windows this additionally primes the message-only window used for
 * dispatch, so calling it once during startup is good practice there.
 */
void SetMainThread();

/**
 * @brief Whether RunOnMainThread() can actually deliver on this platform.
 *
 * Returns false where no main-thread dispatch mechanism is wired up yet
 * (currently Android and OpenHarmony). Callers that must not silently drop work
 * should check this first.
 */
bool IsMainThreadDispatchSupported();

/**
 * @brief Post @p fn to run on the platform's main/UI thread.
 *
 * Always asynchronous: the function returns as soon as the work is queued, even
 * when called from the main thread itself. That is deliberate — it means the
 * ordering guarantees do not depend on which thread the caller happens to be
 * on, and it guarantees the callee never runs while the caller still holds a
 * lock it took before calling.
 *
 * Callers that want "run inline if already on the main thread" should compose
 * it explicitly:
 *
 * @code
 * if (IsMainThread()) {
 *   fn();
 * } else {
 *   RunOnMainThread(std::move(fn));
 * }
 * @endcode
 *
 * @param fn Work to run. Ignored if empty.
 * @return true if the work was queued. false if there is no main-thread
 *         dispatch mechanism, in which case @p fn is NOT run.
 */
bool RunOnMainThread(std::function<void()> fn);

/**
 * @brief Route main-thread dispatch through a caller-supplied scheduler.
 *
 * Two audiences:
 *
 *  - Embedders that already own the main loop (Qt, a game engine, a host
 *    application with its own task queue) and want library callbacks to arrive
 *    through the same scheduler rather than a second, parallel mechanism.
 *  - Tests, which have no run loop at all and need to drain queued work
 *    deterministically.
 *
 * Pass @p dispatch as nullptr to restore the platform default. When @p predicate
 * is null the platform's own main-thread detection stays in effect.
 *
 * Must be called before other threads start using the dispatcher; the override
 * is not synchronized against concurrent dispatch.
 */
void SetMainThreadDispatcher(MainThreadDispatchFn dispatch, MainThreadPredicateFn predicate);

/**
 * @brief Service main-thread work for up to @p timeout_ms, then return.
 *
 * Who needs this: console tools, tests, and any embedding that has no UI
 * framework of its own. Since RunOnMainThread() hands work to the platform's
 * main loop (the GCD main queue, the Win32 message queue, the GLib main
 * context), something has to actually run that loop or the work never happens.
 *
 * Who must NOT call this: applications already running a UI event loop — Cocoa,
 * Win32, GTK, Flutter, Qt. Their loop services the same queue, and nesting a
 * second one invites re-entrancy bugs.
 *
 * Must be called from the main thread.
 *
 * @param timeout_ms How long to service work before returning. 0 drains only
 *                   what is already pending and returns immediately.
 * @return false if the platform has no main-loop integration (Android/OHOS),
 *         in which case nothing was serviced.
 */
bool RunMainThreadLoopFor(int timeout_ms);

}  // namespace nativeapi
