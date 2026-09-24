// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, wrapHandle } from "./runtime.ts";
import { type Point } from "./geometry.ts";
import { Window, type WindowEvent, type WindowId } from "./window.ts";

export class WindowManager {
  private constructor() {}

  static get(id: WindowId): Window | null {
    return wrapHandle(Window, native.native_window_manager_get(id));
  }

  static getAll(): Window[] {
    return (native.native_window_manager_get_all() as bigint[]).map((handle) => new Window(handle));
  }

  static getCurrent(): Window | null {
    return wrapHandle(Window, native.native_window_manager_get_current());
  }

  static getWindowAtPoint(point: Point, excludedWindowId: WindowId): Window | null {
    return wrapHandle(Window, native.native_window_manager_get_window_at_point(point, excludedWindowId));
  }

  static setWillShowHook(hook: ((arg0: number) => void) | null): void {
    native.native_window_manager_set_will_show_hook(hook);
  }

  static setWillHideHook(hook: ((arg0: number) => void) | null): void {
    native.native_window_manager_set_will_hide_hook(hook);
  }

  static hasWillShowHook(): boolean {
    return native.native_window_manager_has_will_show_hook();
  }

  static hasWillHideHook(): boolean {
    return native.native_window_manager_has_will_hide_hook();
  }

  static handleWillShow(id: WindowId): void {
    native.native_window_manager_handle_will_show(id);
  }

  static handleWillHide(id: WindowId): void {
    native.native_window_manager_handle_will_hide(id);
  }

  static callOriginalShow(id: WindowId): boolean {
    return native.native_window_manager_call_original_show(id);
  }

  static callOriginalHide(id: WindowId): boolean {
    return native.native_window_manager_call_original_hide(id);
  }

  /** Calls `listener` for every WindowEvent this WindowManager emits; returns the listener id. */
  static addListener(listener: (event: WindowEvent) => void): number {
    return native.native_window_manager_add_listener(listener);
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  static removeListener(listenerId: number): boolean {
    return native.native_window_manager_remove_listener(listenerId);
  }
}
