// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject } from "./runtime.ts";

export type ShortcutId = number;

export const ShortcutScope = {
  Global: 0,
  Application: 1,
} as const;
export type ShortcutScope = (typeof ShortcutScope)[keyof typeof ShortcutScope];

export interface ShortcutOptions {
  accelerator: string;
  callback?: () => void;
  description: string;
  scope: ShortcutScope;
  enabled: boolean;
}

export type ShortcutEvent =
  | { type: "activated"; shortcutId: ShortcutId; accelerator: string | null }
  | { type: "registered"; shortcutId: ShortcutId; accelerator: string | null }
  | { type: "unregistered"; shortcutId: ShortcutId; accelerator: string | null }
  | { type: "registrationFailed"; shortcutId: ShortcutId; accelerator: string | null; errorMessage: string | null };

/** A native Shortcut, held through an owned handle. */
export class Shortcut extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_shortcut_free : undefined);
  }

  static createWithIdAndOptions(id: ShortcutId, options: ShortcutOptions): Shortcut | null {
    const handle: bigint = native.native_shortcut_create_with_id_and_options(id, options);
    return handle ? new Shortcut(handle) : null;
  }

  static createWithIdAndAcceleratorAndCallback(id: ShortcutId, accelerator: string, callback: () => void): Shortcut | null {
    const handle: bigint = native.native_shortcut_create_with_id_and_accelerator_and_callback(id, accelerator, callback);
    return handle ? new Shortcut(handle) : null;
  }

  get id(): ShortcutId {
    return native.native_shortcut_get_id(this.nativeHandle);
  }

  get accelerator(): string {
    return native.native_shortcut_get_accelerator(this.nativeHandle);
  }

  get description(): string {
    return native.native_shortcut_get_description(this.nativeHandle);
  }

  setDescription(description: string): void {
    native.native_shortcut_set_description(this.nativeHandle, description);
  }

  get scope(): ShortcutScope {
    return native.native_shortcut_get_scope(this.nativeHandle);
  }

  setEnabled(enabled: boolean): void {
    native.native_shortcut_set_enabled(this.nativeHandle, enabled);
  }

  get isEnabled(): boolean {
    return native.native_shortcut_is_enabled(this.nativeHandle);
  }

  invoke(): void {
    native.native_shortcut_invoke(this.nativeHandle);
  }

  setCallback(callback: () => void): void {
    native.native_shortcut_set_callback(this.nativeHandle, callback);
  }
}
