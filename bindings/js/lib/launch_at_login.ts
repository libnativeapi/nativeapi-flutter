// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject } from "./runtime.ts";

/** A native LaunchAtLogin, held through an owned handle. */
export class LaunchAtLogin extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_launch_at_login_free : undefined);
  }

  static create(): LaunchAtLogin | null {
    const handle: bigint = native.native_launch_at_login_create();
    return handle ? new LaunchAtLogin(handle) : null;
  }

  static createWithId(id: string): LaunchAtLogin | null {
    const handle: bigint = native.native_launch_at_login_create_with_id(id);
    return handle ? new LaunchAtLogin(handle) : null;
  }

  static createWithIdAndDisplayName(id: string, displayName: string): LaunchAtLogin | null {
    const handle: bigint = native.native_launch_at_login_create_with_id_and_display_name(id, displayName);
    return handle ? new LaunchAtLogin(handle) : null;
  }

  static isSupported(): boolean {
    return native.native_launch_at_login_is_supported();
  }

  get id(): string {
    return native.native_launch_at_login_get_id(this.nativeHandle);
  }

  get displayName(): string {
    return native.native_launch_at_login_get_display_name(this.nativeHandle);
  }

  setDisplayName(displayName: string): boolean {
    return native.native_launch_at_login_set_display_name(this.nativeHandle, displayName);
  }

  setProgram(executablePath: string, arguments_: string[]): boolean {
    return native.native_launch_at_login_set_program(this.nativeHandle, executablePath, arguments_);
  }

  get executablePath(): string {
    return native.native_launch_at_login_get_executable_path(this.nativeHandle);
  }

  get arguments_(): string[] {
    return native.native_launch_at_login_get_arguments(this.nativeHandle);
  }

  enable(): boolean {
    return native.native_launch_at_login_enable(this.nativeHandle);
  }

  disable(): boolean {
    return native.native_launch_at_login_disable(this.nativeHandle);
  }

  get isEnabled(): boolean {
    return native.native_launch_at_login_is_enabled(this.nativeHandle);
  }
}
