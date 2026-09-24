// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject, wrapHandle } from "./runtime.ts";
import { type Rectangle, type Size } from "./geometry.ts";
import { Image } from "./image.ts";
import { Menu } from "./menu.ts";

export type TrayIconId = number;

export const ContextMenuTrigger = {
  None: 0,
  Clicked: 1,
  RightClicked: 2,
  DoubleClicked: 3,
} as const;
export type ContextMenuTrigger = (typeof ContextMenuTrigger)[keyof typeof ContextMenuTrigger];

export const TrayIconPosition = {
  Left: 0,
  Right: 1,
} as const;
export type TrayIconPosition = (typeof TrayIconPosition)[keyof typeof TrayIconPosition];

export type TrayIconEvent =
  | { type: "clicked"; trayIconId: TrayIconId }
  | { type: "rightClicked"; trayIconId: TrayIconId }
  | { type: "doubleClicked"; trayIconId: TrayIconId };

/** A native TrayIcon, held through an owned handle. */
export class TrayIcon extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_tray_icon_free : undefined);
  }

  static create(): TrayIcon | null {
    const handle: bigint = native.native_tray_icon_create();
    return handle ? new TrayIcon(handle) : null;
  }

  static createWithTray(tray: bigint): TrayIcon | null {
    const handle: bigint = native.native_tray_icon_create_with_tray(tray);
    return handle ? new TrayIcon(handle) : null;
  }

  getId(): TrayIconId {
    return native.native_tray_icon_get_id(this.nativeHandle);
  }

  setIcon(image: Image | null): void {
    native.native_tray_icon_set_icon(this.nativeHandle, image?.nativeHandle ?? 0n);
  }

  get icon(): Image | null {
    return wrapHandle(Image, native.native_tray_icon_get_icon(this.nativeHandle));
  }

  setIconTemplate(isIconTemplate: boolean): void {
    native.native_tray_icon_set_icon_template(this.nativeHandle, isIconTemplate);
  }

  get isIconTemplate(): boolean {
    return native.native_tray_icon_is_icon_template(this.nativeHandle);
  }

  setIconSize(size: Size): void {
    native.native_tray_icon_set_icon_size(this.nativeHandle, size);
  }

  get iconSize(): Size {
    return native.native_tray_icon_get_icon_size(this.nativeHandle);
  }

  setIconPosition(position: TrayIconPosition): void {
    native.native_tray_icon_set_icon_position(this.nativeHandle, position);
  }

  get iconPosition(): TrayIconPosition {
    return native.native_tray_icon_get_icon_position(this.nativeHandle);
  }

  setTitle(title: string | null): void {
    native.native_tray_icon_set_title(this.nativeHandle, title);
  }

  getTitle(): string | null {
    return native.native_tray_icon_get_title(this.nativeHandle);
  }

  setTooltip(tooltip: string | null): void {
    native.native_tray_icon_set_tooltip(this.nativeHandle, tooltip);
  }

  getTooltip(): string | null {
    return native.native_tray_icon_get_tooltip(this.nativeHandle);
  }

  setContextMenu(menu: Menu | null): void {
    native.native_tray_icon_set_context_menu(this.nativeHandle, menu?.nativeHandle ?? 0n);
  }

  getContextMenu(): Menu | null {
    return wrapHandle(Menu, native.native_tray_icon_get_context_menu(this.nativeHandle));
  }

  setContextMenuTrigger(trigger: ContextMenuTrigger): void {
    native.native_tray_icon_set_context_menu_trigger(this.nativeHandle, trigger);
  }

  getContextMenuTrigger(): ContextMenuTrigger {
    return native.native_tray_icon_get_context_menu_trigger(this.nativeHandle);
  }

  getBounds(): Rectangle {
    return native.native_tray_icon_get_bounds(this.nativeHandle);
  }

  setVisible(visible: boolean): boolean {
    return native.native_tray_icon_set_visible(this.nativeHandle, visible);
  }

  isVisible(): boolean {
    return native.native_tray_icon_is_visible(this.nativeHandle);
  }

  openContextMenu(): boolean {
    return native.native_tray_icon_open_context_menu(this.nativeHandle);
  }

  closeContextMenu(): boolean {
    return native.native_tray_icon_close_context_menu(this.nativeHandle);
  }

  /** The platform object behind this handle, as an address. */
  get nativeObject(): bigint {
    return native.native_tray_icon_get_native_object(this.nativeHandle);
  }

  /** Calls `listener` for every TrayIconEvent this TrayIcon emits; returns the listener id. */
  addListener(listener: (event: TrayIconEvent) => void): number {
    return native.native_tray_icon_add_listener(this.nativeHandle, listener);
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  removeListener(listenerId: number): boolean {
    return native.native_tray_icon_remove_listener(this.nativeHandle, listenerId);
  }
}
