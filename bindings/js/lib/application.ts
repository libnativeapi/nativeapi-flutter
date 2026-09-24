// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, wrapHandle, runEventLoop, stopEventLoop } from "./runtime.ts";
import { Menu } from "./menu.ts";
import { Window } from "./window.ts";

export const Brightness = {
  System: 0,
  Light: 1,
  Dark: 2,
} as const;
export type Brightness = (typeof Brightness)[keyof typeof Brightness];

export type ApplicationEvent =
  | { type: "started" }
  | { type: "exiting"; exitCode: number }
  | { type: "activated" }
  | { type: "deactivated" }
  | { type: "quitRequested" };

export class Application {
  private constructor() {}

  /**
   * Runs the platform event loop until `quit()`; resolves with the exit code.
   *
   * The loop is pumped from the JS event loop, so timers, promises and I/O
   * keep running. With `window`, it is shown and made the primary window.
   */
  static run(window?: Window): Promise<number> {
    return runEventLoop(window?.nativeHandle ?? 0n);
  }

  /** Stops the loop started by `run()`, which then resolves with `exitCode`. */
  static quit(exitCode = 0): void {
    stopEventLoop(exitCode);
  }

  static isRunning(): boolean {
    return native.native_application_is_running();
  }

  static isSingleInstance(): boolean {
    return native.native_application_is_single_instance();
  }

  static setIcon(iconPath: string): boolean {
    return native.native_application_set_icon(iconPath);
  }

  static setDockIconVisible(visible: boolean): boolean {
    return native.native_application_set_dock_icon_visible(visible);
  }

  static setProgressBar(progress: number): boolean {
    return native.native_application_set_progress_bar(progress);
  }

  static setBadgeLabel(label: string): boolean {
    return native.native_application_set_badge_label(label);
  }

  static setBrightness(brightness: Brightness): boolean {
    return native.native_application_set_brightness(brightness);
  }

  static setMenuBar(menu: Menu | null): boolean {
    return native.native_application_set_menu_bar(menu?.nativeHandle ?? 0n);
  }

  static getPrimaryWindow(): Window | null {
    return wrapHandle(Window, native.native_application_get_primary_window());
  }

  static setPrimaryWindow(window: Window | null): void {
    native.native_application_set_primary_window(window?.nativeHandle ?? 0n);
  }

  static getAllWindows(): Window[] {
    return (native.native_application_get_all_windows() as bigint[]).map((handle) => new Window(handle));
  }

  /** Calls `listener` for every ApplicationEvent this Application emits; returns the listener id. */
  static addListener(listener: (event: ApplicationEvent) => void): number {
    return native.native_application_add_listener(listener);
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  static removeListener(listenerId: number): boolean {
    return native.native_application_remove_listener(listenerId);
  }
}
