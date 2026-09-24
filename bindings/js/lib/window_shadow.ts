// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject } from "./runtime.ts";
import { Color } from "./color.ts";
import { type Point } from "./geometry.ts";

/** A native WindowShadow, held through an owned handle. */
export class WindowShadow extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_window_shadow_free : undefined);
  }

  static create(): WindowShadow | null {
    const handle: bigint = native.native_window_shadow_create();
    return handle ? new WindowShadow(handle) : null;
  }

  setColor(color: Color): void {
    native.native_window_shadow_set_color(this.nativeHandle, color);
  }

  get color(): Color {
    return native.native_window_shadow_get_color(this.nativeHandle);
  }

  setBlurRadius(radius: number): boolean {
    return native.native_window_shadow_set_blur_radius(this.nativeHandle, radius);
  }

  get blurRadius(): number {
    return native.native_window_shadow_get_blur_radius(this.nativeHandle);
  }

  setOffset(offset: Point): boolean {
    return native.native_window_shadow_set_offset(this.nativeHandle, offset);
  }

  get offset(): Point {
    return native.native_window_shadow_get_offset(this.nativeHandle);
  }
}
