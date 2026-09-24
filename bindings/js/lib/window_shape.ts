// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject } from "./runtime.ts";
import { type Point } from "./geometry.ts";

/** A native WindowShape, held through an owned handle. */
export class WindowShape extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_window_shape_free : undefined);
  }

  static create(): WindowShape | null {
    const handle: bigint = native.native_window_shape_create();
    return handle ? new WindowShape(handle) : null;
  }

  addPoint(point: Point): boolean {
    return native.native_window_shape_add_point(this.nativeHandle, point);
  }

  clear(): void {
    native.native_window_shape_clear(this.nativeHandle);
  }

  get pointCount(): number {
    return native.native_window_shape_get_point_count(this.nativeHandle);
  }

  getPointAt(index: number): Point {
    return native.native_window_shape_get_point_at(this.nativeHandle, index);
  }
}
