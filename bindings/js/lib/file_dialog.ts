// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject } from "./runtime.ts";
import { DialogModality } from "./dialog.ts";
import { Window } from "./window.ts";

export const FileDialogMode = {
  OpenFile: 0,
  OpenFiles: 1,
  SaveFile: 2,
  SelectFolder: 3,
} as const;
export type FileDialogMode = (typeof FileDialogMode)[keyof typeof FileDialogMode];

export const FileDialogResult = {
  None: 0,
  Accepted: 1,
  Cancelled: 2,
  Failed: 3,
} as const;
export type FileDialogResult = (typeof FileDialogResult)[keyof typeof FileDialogResult];

/** A native FileDialog, held through an owned handle. */
export class FileDialog extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_file_dialog_free : undefined);
  }

  static create(mode: FileDialogMode): FileDialog | null {
    const handle: bigint = native.native_file_dialog_create(mode);
    return handle ? new FileDialog(handle) : null;
  }

  static isSupported(): boolean {
    return native.native_file_dialog_is_supported();
  }

  setParentWindow(window: Window | null): boolean {
    return native.native_file_dialog_set_parent_window(this.nativeHandle, window?.nativeHandle ?? 0n);
  }

  setFileTypes(extensions: string[]): boolean {
    return native.native_file_dialog_set_file_types(this.nativeHandle, extensions);
  }

  setSuggestedFileName(name: string): boolean {
    return native.native_file_dialog_set_suggested_file_name(this.nativeHandle, name);
  }

  get modality(): DialogModality {
    return native.native_file_dialog_get_modality(this.nativeHandle);
  }

  setModality(modality: DialogModality): void {
    native.native_file_dialog_set_modality(this.nativeHandle, modality);
  }

  open(): boolean {
    return native.native_file_dialog_open(this.nativeHandle);
  }

  close(): boolean {
    return native.native_file_dialog_close(this.nativeHandle);
  }

  get result(): FileDialogResult {
    return native.native_file_dialog_get_result(this.nativeHandle);
  }

  get paths(): string[] {
    return native.native_file_dialog_get_paths(this.nativeHandle);
  }

  get lastError(): string {
    return native.native_file_dialog_get_last_error(this.nativeHandle);
  }
}
