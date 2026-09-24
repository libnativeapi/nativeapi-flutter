// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject } from "./runtime.ts";
import { DragOperation } from "./drag_source.ts";
import { type Point } from "./geometry.ts";
import { Window, type WindowId } from "./window.ts";

export type DropTargetEvent =
  | { type: "entered"; windowId: WindowId; position: Point }
  | { type: "moved"; windowId: WindowId; position: Point }
  | { type: "exited"; windowId: WindowId; position: Point }
  | { type: "dropped"; windowId: WindowId; position: Point; filePaths: string[]; text: string | null };

/** A native DropTarget, held through an owned handle. */
export class DropTarget extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_drop_target_free : undefined);
  }

  static create(window: Window | null): DropTarget | null {
    const handle: bigint = native.native_drop_target_create(window?.nativeHandle ?? 0n);
    return handle ? new DropTarget(handle) : null;
  }

  static isSupported(): boolean {
    return native.native_drop_target_is_supported();
  }

  get windowId(): WindowId {
    return native.native_drop_target_get_window_id(this.nativeHandle);
  }

  setDropOperation(operation: DragOperation): void {
    native.native_drop_target_set_drop_operation(this.nativeHandle, operation);
  }

  get dropOperation(): DragOperation {
    return native.native_drop_target_get_drop_operation(this.nativeHandle);
  }

  get isActive(): boolean {
    return native.native_drop_target_is_active(this.nativeHandle);
  }

  /** Calls `listener` for every DropTargetEvent this DropTarget emits; returns the listener id. */
  addListener(listener: (event: DropTargetEvent) => void): number {
    return native.native_drop_target_add_listener(this.nativeHandle, listener);
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  removeListener(listenerId: number): boolean {
    return native.native_drop_target_remove_listener(this.nativeHandle, listenerId);
  }
}
