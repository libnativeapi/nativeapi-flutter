// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject } from "./runtime.ts";
import { DialogModality } from "./dialog.ts";
import { Window } from "./window.ts";

export const MessageDialogResult = {
  None: 0,
  Primary: 1,
  Secondary: 2,
  Close: 3,
} as const;
export type MessageDialogResult = (typeof MessageDialogResult)[keyof typeof MessageDialogResult];

/** A native MessageDialog, held through an owned handle. */
export class MessageDialog extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_message_dialog_free : undefined);
  }

  static create(title: string, message: string): MessageDialog | null {
    const handle: bigint = native.native_message_dialog_create(title, message);
    return handle ? new MessageDialog(handle) : null;
  }

  static isExtendedSupported(): boolean {
    return native.native_message_dialog_is_extended_supported();
  }

  setButtons(primary: string, secondary: string, close: string): boolean {
    return native.native_message_dialog_set_buttons(this.nativeHandle, primary, secondary, close);
  }

  setDefaultButton(button: MessageDialogResult): boolean {
    return native.native_message_dialog_set_default_button(this.nativeHandle, button);
  }

  setParentWindow(window: Window | null): boolean {
    return native.native_message_dialog_set_parent_window(this.nativeHandle, window?.nativeHandle ?? 0n);
  }

  get result(): MessageDialogResult {
    return native.native_message_dialog_get_result(this.nativeHandle);
  }

  get isOpen(): boolean {
    return native.native_message_dialog_is_open(this.nativeHandle);
  }

  setInputEnabled(enabled: boolean): boolean {
    return native.native_message_dialog_set_input_enabled(this.nativeHandle, enabled);
  }

  setInputText(text: string): boolean {
    return native.native_message_dialog_set_input_text(this.nativeHandle, text);
  }

  get inputText(): string {
    return native.native_message_dialog_get_input_text(this.nativeHandle);
  }

  setCheckbox(label: string, checked: boolean): boolean {
    return native.native_message_dialog_set_checkbox(this.nativeHandle, label, checked);
  }

  get isCheckboxChecked(): boolean {
    return native.native_message_dialog_is_checkbox_checked(this.nativeHandle);
  }

  setProgress(value: number): boolean {
    return native.native_message_dialog_set_progress(this.nativeHandle, value);
  }

  setTitle(title: string): void {
    native.native_message_dialog_set_title(this.nativeHandle, title);
  }

  get title(): string {
    return native.native_message_dialog_get_title(this.nativeHandle);
  }

  setMessage(message: string): void {
    native.native_message_dialog_set_message(this.nativeHandle, message);
  }

  get message(): string {
    return native.native_message_dialog_get_message(this.nativeHandle);
  }

  get modality(): DialogModality {
    return native.native_message_dialog_get_modality(this.nativeHandle);
  }

  setModality(modality: DialogModality): void {
    native.native_message_dialog_set_modality(this.nativeHandle, modality);
  }

  open(): boolean {
    return native.native_message_dialog_open(this.nativeHandle);
  }

  close(): boolean {
    return native.native_message_dialog_close(this.nativeHandle);
  }
}
