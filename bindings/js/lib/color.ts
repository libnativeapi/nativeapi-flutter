// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native } from "./runtime.ts";

export interface Color {
  r: number;
  g: number;
  b: number;
  a: number;
}

export const Color = {
  Transparent: Object.freeze(native.NATIVE_COLOR_TRANSPARENT as Color),
  Black: Object.freeze(native.NATIVE_COLOR_BLACK as Color),
  White: Object.freeze(native.NATIVE_COLOR_WHITE as Color),
  Red: Object.freeze(native.NATIVE_COLOR_RED as Color),
  Green: Object.freeze(native.NATIVE_COLOR_GREEN as Color),
  Blue: Object.freeze(native.NATIVE_COLOR_BLUE as Color),
  Yellow: Object.freeze(native.NATIVE_COLOR_YELLOW as Color),
  Cyan: Object.freeze(native.NATIVE_COLOR_CYAN as Color),
  Magenta: Object.freeze(native.NATIVE_COLOR_MAGENTA as Color),
  fromRgba(red: number, green: number, blue: number, alpha: number): Color {
    return native.native_color_from_rgba(red, green, blue, alpha);
  },
  fromHex(hex: string): Color {
    return native.native_color_from_hex(hex);
  },
  toRgba(color: Color): number {
    return native.native_color_to_rgba(color);
  },
  toArgb(color: Color): number {
    return native.native_color_to_argb(color);
  },
};
