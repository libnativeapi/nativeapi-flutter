// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject } from "./runtime.ts";
import { type Point, type Rectangle, type Size } from "./geometry.ts";

export type DisplayId = number;

export const DisplayOrientation = {
  Portrait: 0,
  Landscape: 90,
  PortraitFlipped: 180,
  LandscapeFlipped: 270,
} as const;
export type DisplayOrientation = (typeof DisplayOrientation)[keyof typeof DisplayOrientation];

export type DisplayEvent =
  | { type: "added"; display: Display | null }
  | { type: "removed"; display: Display | null }
  | { type: "changed"; display: Display | null };

/** A native Display, held through an owned handle. */
export class Display extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_display_free : undefined);
  }

  static create(display: bigint): Display | null {
    const handle: bigint = native.native_display_create(display);
    return handle ? new Display(handle) : null;
  }

  get id(): DisplayId {
    return native.native_display_get_id(this.nativeHandle);
  }

  get name(): string {
    return native.native_display_get_name(this.nativeHandle);
  }

  get position(): Point {
    return native.native_display_get_position(this.nativeHandle);
  }

  get size(): Size {
    return native.native_display_get_size(this.nativeHandle);
  }

  get workArea(): Rectangle {
    return native.native_display_get_work_area(this.nativeHandle);
  }

  get scaleFactor(): number {
    return native.native_display_get_scale_factor(this.nativeHandle);
  }

  get isPrimary(): boolean {
    return native.native_display_is_primary(this.nativeHandle);
  }

  get orientation(): DisplayOrientation {
    return native.native_display_get_orientation(this.nativeHandle);
  }

  get refreshRate(): number {
    return native.native_display_get_refresh_rate(this.nativeHandle);
  }

  get bitDepth(): number {
    return native.native_display_get_bit_depth(this.nativeHandle);
  }

  /** The platform object behind this handle, as an address. */
  get nativeObject(): bigint {
    return native.native_display_get_native_object(this.nativeHandle);
  }
}
