// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, wrapHandle } from "./runtime.ts";
import { Shortcut, type ShortcutEvent, type ShortcutId, type ShortcutOptions, ShortcutScope } from "./shortcut.ts";

export class ShortcutManager {
  private constructor() {}

  static isSupported(): boolean {
    return native.native_shortcut_manager_is_supported();
  }

  static registerWithAcceleratorAndCallback(accelerator: string, callback: () => void): Shortcut | null {
    return wrapHandle(Shortcut, native.native_shortcut_manager_register_with_accelerator_and_callback(accelerator, callback));
  }

  static registerWithOptions(options: ShortcutOptions): Shortcut | null {
    return wrapHandle(Shortcut, native.native_shortcut_manager_register_with_options(options));
  }

  static unregisterWithId(id: ShortcutId): boolean {
    return native.native_shortcut_manager_unregister_with_id(id);
  }

  static unregisterWithAccelerator(accelerator: string): boolean {
    return native.native_shortcut_manager_unregister_with_accelerator(accelerator);
  }

  static unregisterAll(): number {
    return native.native_shortcut_manager_unregister_all();
  }

  static getWithId(id: ShortcutId): Shortcut | null {
    return wrapHandle(Shortcut, native.native_shortcut_manager_get_with_id(id));
  }

  static getWithAccelerator(accelerator: string): Shortcut | null {
    return wrapHandle(Shortcut, native.native_shortcut_manager_get_with_accelerator(accelerator));
  }

  static getAll(): Shortcut[] {
    return (native.native_shortcut_manager_get_all() as bigint[]).map((handle) => new Shortcut(handle));
  }

  static getByScope(scope: ShortcutScope): Shortcut[] {
    return (native.native_shortcut_manager_get_by_scope(scope) as bigint[]).map((handle) => new Shortcut(handle));
  }

  static isAvailable(accelerator: string): boolean {
    return native.native_shortcut_manager_is_available(accelerator);
  }

  static isValidAccelerator(accelerator: string): boolean {
    return native.native_shortcut_manager_is_valid_accelerator(accelerator);
  }

  static setEnabled(enabled: boolean): void {
    native.native_shortcut_manager_set_enabled(enabled);
  }

  static isEnabled(): boolean {
    return native.native_shortcut_manager_is_enabled();
  }

  static emitShortcutActivated(id: ShortcutId, accelerator: string): void {
    native.native_shortcut_manager_emit_shortcut_activated(id, accelerator);
  }

  /** Calls `listener` for every ShortcutEvent this ShortcutManager emits; returns the listener id. */
  static addListener(listener: (event: ShortcutEvent) => void): number {
    return native.native_shortcut_manager_add_listener(listener);
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  static removeListener(listenerId: number): boolean {
    return native.native_shortcut_manager_remove_listener(listenerId);
  }
}
