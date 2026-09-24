// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject } from "./runtime.ts";
import { type KeyboardEvent } from "./keyboard.ts";

/** A native KeyboardMonitor, held through an owned handle. */
export class KeyboardMonitor extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_keyboard_monitor_free : undefined);
  }

  static create(): KeyboardMonitor | null {
    const handle: bigint = native.native_keyboard_monitor_create();
    return handle ? new KeyboardMonitor(handle) : null;
  }

  start(): void {
    native.native_keyboard_monitor_start(this.nativeHandle);
  }

  stop(): void {
    native.native_keyboard_monitor_stop(this.nativeHandle);
  }

  get isMonitoring(): boolean {
    return native.native_keyboard_monitor_is_monitoring(this.nativeHandle);
  }

  /** Calls `listener` for every KeyboardEvent this KeyboardMonitor emits; returns the listener id. */
  addListener(listener: (event: KeyboardEvent) => void): number {
    return native.native_keyboard_monitor_add_listener(this.nativeHandle, listener);
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  removeListener(listenerId: number): boolean {
    return native.native_keyboard_monitor_remove_listener(this.nativeHandle, listenerId);
  }
}
