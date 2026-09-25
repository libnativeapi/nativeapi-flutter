// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native } from "./runtime.ts";

export interface Point {
  x: number;
  y: number;
}

export interface Size {
  width: number;
  height: number;
}

export interface Rectangle {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface EdgeInsets {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

export const EdgeInsets = {
  all(value: number): EdgeInsets {
    return native.native_edge_insets_all(value);
  },
  symmetric(vertical: number, horizontal: number): EdgeInsets {
    return native.native_edge_insets_symmetric(vertical, horizontal);
  },
};
