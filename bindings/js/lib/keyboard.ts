// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native } from "./runtime.ts";

export const ModifierKey = {
  None: 0,
  Shift: 1,
  Ctrl: 2,
  Alt: 4,
  Meta: 8,
  Fn: 16,
  CapsLock: 32,
  NumLock: 64,
  ScrollLock: 128,
} as const;
export type ModifierKey = (typeof ModifierKey)[keyof typeof ModifierKey];

export interface KeyboardAccelerator {
  modifiers: ModifierKey;
  key: string;
}

export const KeyboardAccelerator = {
  toString(keyboardAccelerator: KeyboardAccelerator): string {
    return native.native_keyboard_accelerator_to_string(keyboardAccelerator);
  },
  isEmpty(keyboardAccelerator: KeyboardAccelerator): boolean {
    return native.native_keyboard_accelerator_is_empty(keyboardAccelerator);
  },
};

export type KeyboardEvent =
  | { type: "keyPressed"; keycode: number }
  | { type: "keyReleased"; keycode: number }
  | { type: "modifierKeysChanged"; keycode: number; modifierKeys: number };
