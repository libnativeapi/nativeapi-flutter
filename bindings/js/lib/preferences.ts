// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject } from "./runtime.ts";

/** A native Preferences, held through an owned handle. */
export class Preferences extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_preferences_free : undefined);
  }

  static create(): Preferences | null {
    const handle: bigint = native.native_preferences_create();
    return handle ? new Preferences(handle) : null;
  }

  static createWithScope(scope: string): Preferences | null {
    const handle: bigint = native.native_preferences_create_with_scope(scope);
    return handle ? new Preferences(handle) : null;
  }

  set(key: string, value: string): boolean {
    return native.native_preferences_set(this.nativeHandle, key, value);
  }

  get(key: string, defaultValue: string): string {
    return native.native_preferences_get(this.nativeHandle, key, defaultValue);
  }

  remove(key: string): boolean {
    return native.native_preferences_remove(this.nativeHandle, key);
  }

  clear(): boolean {
    return native.native_preferences_clear(this.nativeHandle);
  }

  contains(key: string): boolean {
    return native.native_preferences_contains(this.nativeHandle, key);
  }

  get keys(): string[] {
    return native.native_preferences_get_keys(this.nativeHandle);
  }

  get size(): number {
    return native.native_preferences_get_size(this.nativeHandle);
  }

  get all(): Record<string, string> {
    return native.native_preferences_get_all(this.nativeHandle);
  }

  get scope(): string {
    return native.native_preferences_get_scope(this.nativeHandle);
  }
}
