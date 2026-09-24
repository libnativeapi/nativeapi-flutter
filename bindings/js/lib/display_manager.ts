// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, wrapHandle } from "./runtime.ts";
import { Display, type DisplayEvent } from "./display.ts";
import { type Point } from "./geometry.ts";

export class DisplayManager {
  private constructor() {}

  static getAll(): Display[] {
    return (native.native_display_manager_get_all() as bigint[]).map((handle) => new Display(handle));
  }

  static getPrimary(): Display | null {
    return wrapHandle(Display, native.native_display_manager_get_primary());
  }

  static getCursorPosition(): Point {
    return native.native_display_manager_get_cursor_position();
  }

  /** Calls `listener` for every DisplayEvent this DisplayManager emits; returns the listener id. */
  static addListener(listener: (event: DisplayEvent) => void): number {
    return native.native_display_manager_add_listener((event: Record<string, unknown>) => {
      if (typeof event.display === "bigint") {
        event.display = event.display ? new Display(event.display, false) : null;
      }
      listener(event as unknown as DisplayEvent);
    });
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  static removeListener(listenerId: number): boolean {
    return native.native_display_manager_remove_listener(listenerId);
  }
}
