// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native } from "./runtime.ts";

export class DeviceInfo {
  private constructor() {}

  static getName(): string {
    return native.native_device_info_get_name();
  }

  static getModel(): string {
    return native.native_device_info_get_model();
  }

  static getManufacturer(): string {
    return native.native_device_info_get_manufacturer();
  }

  static getOsName(): string {
    return native.native_device_info_get_os_name();
  }

  static getOsVersion(): string {
    return native.native_device_info_get_os_version();
  }

  static getKernelVersion(): string {
    return native.native_device_info_get_kernel_version();
  }

  static getArchitecture(): string {
    return native.native_device_info_get_architecture();
  }
}
