// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject, wrapHandle } from "./runtime.ts";
import { type Point } from "./geometry.ts";
import { Image } from "./image.ts";
import { Window, type WindowId } from "./window.ts";

export const DragOperation = {
  None: 0,
  Copy: 1,
  Move: 2,
  Link: 3,
} as const;
export type DragOperation = (typeof DragOperation)[keyof typeof DragOperation];

export type DragSourceEvent =
  | { type: "ended"; windowId: WindowId; position: Point; operation: DragOperation };

/** A native DragSource, held through an owned handle. */
export class DragSource extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_drag_source_free : undefined);
  }

  static create(): DragSource | null {
    const handle: bigint = native.native_drag_source_create();
    return handle ? new DragSource(handle) : null;
  }

  static isSupported(): boolean {
    return native.native_drag_source_is_supported();
  }

  setFilePaths(filePaths: string[]): void {
    native.native_drag_source_set_file_paths(this.nativeHandle, filePaths);
  }

  get filePaths(): string[] {
    return native.native_drag_source_get_file_paths(this.nativeHandle);
  }

  setText(text: string | null): void {
    native.native_drag_source_set_text(this.nativeHandle, text);
  }

  get text(): string | null {
    return native.native_drag_source_get_text(this.nativeHandle);
  }

  setImage(image: Image | null): void {
    native.native_drag_source_set_image(this.nativeHandle, image?.nativeHandle ?? 0n);
  }

  get image(): Image | null {
    return wrapHandle(Image, native.native_drag_source_get_image(this.nativeHandle));
  }

  setDragOperation(operation: DragOperation): void {
    native.native_drag_source_set_drag_operation(this.nativeHandle, operation);
  }

  get dragOperation(): DragOperation {
    return native.native_drag_source_get_drag_operation(this.nativeHandle);
  }

  startDragging(window: Window | null): boolean {
    return native.native_drag_source_start_dragging(this.nativeHandle, window?.nativeHandle ?? 0n);
  }

  get isDragging(): boolean {
    return native.native_drag_source_is_dragging(this.nativeHandle);
  }

  /** Calls `listener` for every DragSourceEvent this DragSource emits; returns the listener id. */
  addListener(listener: (event: DragSourceEvent) => void): number {
    return native.native_drag_source_add_listener(this.nativeHandle, listener);
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  removeListener(listenerId: number): boolean {
    return native.native_drag_source_remove_listener(this.nativeHandle, listenerId);
  }
}
