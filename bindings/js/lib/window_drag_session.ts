// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject } from "./runtime.ts";
import { type Point } from "./geometry.ts";
import { Window, type WindowId } from "./window.ts";

export type WindowDragEvent =
  | { type: "moved"; windowId: WindowId; cursorPosition: Point }
  | { type: "ended"; windowId: WindowId; cursorPosition: Point }
  | { type: "cancelled"; windowId: WindowId; cursorPosition: Point };

/** A native WindowDragSession, held through an owned handle. */
export class WindowDragSession extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_window_drag_session_free : undefined);
  }

  static create(): WindowDragSession | null {
    const handle: bigint = native.native_window_drag_session_create();
    return handle ? new WindowDragSession(handle) : null;
  }

  start(window: Window | null, anchor: Point): boolean {
    return native.native_window_drag_session_start(this.nativeHandle, window?.nativeHandle ?? 0n, anchor);
  }

  cancel(): void {
    native.native_window_drag_session_cancel(this.nativeHandle);
  }

  get isActive(): boolean {
    return native.native_window_drag_session_is_active(this.nativeHandle);
  }

  get windowId(): WindowId {
    return native.native_window_drag_session_get_window_id(this.nativeHandle);
  }

  get anchor(): Point {
    return native.native_window_drag_session_get_anchor(this.nativeHandle);
  }

  /** Calls `listener` for every WindowDragEvent this WindowDragSession emits; returns the listener id. */
  addListener(listener: (event: WindowDragEvent) => void): number {
    return native.native_window_drag_session_add_listener(this.nativeHandle, listener);
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  removeListener(listenerId: number): boolean {
    return native.native_window_drag_session_remove_listener(this.nativeHandle, listenerId);
  }
}
