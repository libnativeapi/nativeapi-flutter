// Hand-written runtime for the generated modules: loads the addon, owns
// handles, and pumps the platform event loop.

import { existsSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

// ---------------------------------------------------------------------------
// Addon
// ---------------------------------------------------------------------------

/**
 * The raw addon: one function per C ABI symbol, under the symbol's own name.
 * Generated modules call it; application code should not need to.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const native: Record<string, any> = loadAddon();

function loadAddon(): Record<string, unknown> {
  const require = createRequire(import.meta.url);
  const root = join(dirname(fileURLToPath(import.meta.url)), "..");
  const candidates = [
    process.env.NATIVEAPI_ADDON,
    join(root, "prebuilds", `${process.platform}-${process.arch}`, "nativeapi.node"),
    join(root, "build", "Release", "nativeapi.node"),
    join(root, "build", "Debug", "nativeapi.node"),
  ].filter((path): path is string => Boolean(path));
  const found = candidates.find((path) => existsSync(path));
  if (!found) {
    throw new Error(
      `nativeapi: no native addon for ${process.platform}-${process.arch}. ` +
        `Build it with \`npm run build\` in ${root}, or set NATIVEAPI_ADDON. Looked in:\n  ` +
        candidates.join("\n  "),
    );
  }
  return require(found);
}

// ---------------------------------------------------------------------------
// Handles
// ---------------------------------------------------------------------------

type Release = (handle: bigint) => void;

const finalizer = new FinalizationRegistry<{ release: Release; handle: bigint }>(
  ({ release, handle }) => release(handle),
);

/**
 * Base of every class wrapping a native object. An owned handle is released
 * by `dispose()` (or `using`), and otherwise when the wrapper is collected.
 * Handles are generation-checked, so a call on a released one fails safely.
 */
export abstract class NativeObject implements Disposable {
  #handle: bigint;
  #release: Release | undefined;

  protected constructor(handle: bigint, release: Release | undefined) {
    this.#handle = handle;
    this.#release = release;
    if (release && handle) {
      finalizer.register(this, { release, handle }, this);
    }
  }

  /** The raw C ABI handle; `0n` once disposed. */
  get nativeHandle(): bigint {
    return this.#handle;
  }

  /** Releases this reference now. The object itself lives on while others hold it. */
  dispose(): void {
    const release = this.#release;
    const handle = this.#handle;
    this.#release = undefined;
    this.#handle = 0n;
    if (release && handle) {
      finalizer.unregister(this);
      release(handle);
    }
  }

  [Symbol.dispose](): void {
    this.dispose();
  }
}

/** Wraps an owned handle, mapping the invalid handle to `null`. */
export function wrapHandle<T>(type: new (handle: bigint) => T, handle: bigint): T | null {
  return handle ? new type(handle) : null;
}

// ---------------------------------------------------------------------------
// Event loop
// ---------------------------------------------------------------------------

/** How often the platform queue is drained while nothing is happening, in ms. */
const IDLE_INTERVAL = 8;

let loop: { timer: ReturnType<typeof setTimeout>; resolve: (code: number) => void } | undefined;

/**
 * Whether a host already runs the platform loop and JS lives on another
 * thread, as under `deno desktop`. Native calls then hop to the UI thread, and
 * `runEventLoop()` has nothing to pump.
 */
export function isHostedEventLoop(): boolean {
  return !native.isMainThread();
}

/**
 * Runs the platform event loop from the JS event loop until
 * `stopEventLoop()` (or the platform quitting); resolves with the exit code.
 * Under a host that owns the loop, only waits for `stopEventLoop()`.
 */
export function runEventLoop(window: bigint): Promise<number> {
  if (loop) {
    return Promise.reject(new Error("nativeapi: the event loop is already running"));
  }
  if (isHostedEventLoop()) {
    return new Promise<number>((resolve) => {
      // Keeps the runtime alive the way the pump timer does, without pumping.
      loop = { timer: setInterval(() => {}, 1 << 30), resolve };
    });
  }
  native.startEventLoop(window);
  return new Promise<number>((resolve) => {
    const tick = () => {
      const exitCode: number = native.pumpEventLoop();
      if (exitCode >= 0) {
        stopEventLoop(exitCode);
      } else if (loop) {
        loop.timer = setTimeout(tick, IDLE_INTERVAL);
      }
    };
    loop = { timer: setTimeout(tick, 0), resolve };
  });
}

/** Stops the loop started by `runEventLoop()`, which resolves with `exitCode`. */
export function stopEventLoop(exitCode = 0): void {
  const current = loop;
  if (!current) {
    return;
  }
  loop = undefined;
  clearTimeout(current.timer);
  clearInterval(current.timer);
  current.resolve(exitCode);
}
