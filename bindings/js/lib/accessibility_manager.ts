// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native } from "./runtime.ts";

export class AccessibilityManager {
  private constructor() {}

  static enable(): void {
    native.native_accessibility_manager_enable();
  }

  static isEnabled(): boolean {
    return native.native_accessibility_manager_is_enabled();
  }
}
