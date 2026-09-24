// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, wrapHandle } from "./runtime.ts";
import { TrayIcon, type TrayIconId } from "./tray_icon.ts";

export class TrayManager {
  private constructor() {}

  static isSupported(): boolean {
    return native.native_tray_manager_is_supported();
  }

  static get(id: TrayIconId): TrayIcon | null {
    return wrapHandle(TrayIcon, native.native_tray_manager_get(id));
  }

  static getAll(): TrayIcon[] {
    return (native.native_tray_manager_get_all() as bigint[]).map((handle) => new TrayIcon(handle));
  }
}
