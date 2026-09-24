// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject, wrapHandle } from "./runtime.ts";
import { type Point, type Rectangle } from "./geometry.ts";
import { Window } from "./window.ts";

export const PositioningStrategyType = {
  Absolute: 0,
  CursorPosition: 1,
  Relative: 2,
} as const;
export type PositioningStrategyType = (typeof PositioningStrategyType)[keyof typeof PositioningStrategyType];

/** A native PositioningStrategy, held through an owned handle. */
export class PositioningStrategy extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_positioning_strategy_free : undefined);
  }

  static absolute(point: Point): PositioningStrategy | null {
    return wrapHandle(PositioningStrategy, native.native_positioning_strategy_absolute(point));
  }

  static cursorPosition(): PositioningStrategy | null {
    return wrapHandle(PositioningStrategy, native.native_positioning_strategy_cursor_position());
  }

  static relativeWithRectAndOffset(rect: Rectangle, offset: Point): PositioningStrategy | null {
    return wrapHandle(PositioningStrategy, native.native_positioning_strategy_relative_with_rect_and_offset(rect, offset));
  }

  static relativeWithWindowAndOffset(window: Window, offset: Point): PositioningStrategy | null {
    return wrapHandle(PositioningStrategy, native.native_positioning_strategy_relative_with_window_and_offset(window.nativeHandle, offset));
  }

  get type(): PositioningStrategyType {
    return native.native_positioning_strategy_get_type(this.nativeHandle);
  }

  get absolutePosition(): Point {
    return native.native_positioning_strategy_get_absolute_position(this.nativeHandle);
  }

  get relativeRectangle(): Rectangle {
    return native.native_positioning_strategy_get_relative_rectangle(this.nativeHandle);
  }

  get relativeOffset(): Point {
    return native.native_positioning_strategy_get_relative_offset(this.nativeHandle);
  }
}
