// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native } from "./runtime.ts";

export class AppInfo {
  private constructor() {}

  static getName(): string {
    return native.native_app_info_get_name();
  }

  static getIdentifier(): string {
    return native.native_app_info_get_identifier();
  }

  static getVersion(): string {
    return native.native_app_info_get_version();
  }

  static getBuildNumber(): string {
    return native.native_app_info_get_build_number();
  }
}
