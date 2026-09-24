// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject, wrapHandle } from "./runtime.ts";
import { Image } from "./image.ts";
import { KeyboardAccelerator } from "./keyboard.ts";
import { Placement } from "./placement.ts";
import { PositioningStrategy } from "./positioning_strategy.ts";

export type MenuId = number;

export type MenuItemId = number;

export const MenuBackend = {
  Native: 0,
  WinUi3: 1,
} as const;
export type MenuBackend = (typeof MenuBackend)[keyof typeof MenuBackend];

export const MenuItemType = {
  Normal: 0,
  Checkbox: 1,
  Radio: 2,
  Separator: 3,
  Submenu: 4,
} as const;
export type MenuItemType = (typeof MenuItemType)[keyof typeof MenuItemType];

export const MenuItemState = {
  Unchecked: 0,
  Checked: 1,
  Mixed: 2,
} as const;
export type MenuItemState = (typeof MenuItemState)[keyof typeof MenuItemState];

export type MenuEvent =
  | { type: "opened"; menuId: MenuId }
  | { type: "closed"; menuId: MenuId }
  | { type: "itemClicked"; itemId: MenuItemId }
  | { type: "itemSubmenuOpened"; itemId: MenuItemId }
  | { type: "itemSubmenuClosed"; itemId: MenuItemId };

/** A native MenuItem, held through an owned handle. */
export class MenuItem extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_menu_item_free : undefined);
  }

  static createWithLabelAndType(label: string, type: MenuItemType): MenuItem | null {
    const handle: bigint = native.native_menu_item_create_with_label_and_type(label, type);
    return handle ? new MenuItem(handle) : null;
  }

  static createWithNativeItem(nativeItem: bigint): MenuItem | null {
    const handle: bigint = native.native_menu_item_create_with_native_item(nativeItem);
    return handle ? new MenuItem(handle) : null;
  }

  get id(): MenuItemId {
    return native.native_menu_item_get_id(this.nativeHandle);
  }

  get type(): MenuItemType {
    return native.native_menu_item_get_type(this.nativeHandle);
  }

  setLabel(label: string | null): void {
    native.native_menu_item_set_label(this.nativeHandle, label);
  }

  get label(): string | null {
    return native.native_menu_item_get_label(this.nativeHandle);
  }

  setIcon(image: Image | null): void {
    native.native_menu_item_set_icon(this.nativeHandle, image?.nativeHandle ?? 0n);
  }

  get icon(): Image | null {
    return wrapHandle(Image, native.native_menu_item_get_icon(this.nativeHandle));
  }

  setTooltip(tooltip: string | null): void {
    native.native_menu_item_set_tooltip(this.nativeHandle, tooltip);
  }

  get tooltip(): string | null {
    return native.native_menu_item_get_tooltip(this.nativeHandle);
  }

  setAccelerator(accelerator: KeyboardAccelerator | null): void {
    native.native_menu_item_set_accelerator(this.nativeHandle, accelerator);
  }

  get accelerator(): KeyboardAccelerator {
    return native.native_menu_item_get_accelerator(this.nativeHandle);
  }

  setEnabled(enabled: boolean): void {
    native.native_menu_item_set_enabled(this.nativeHandle, enabled);
  }

  get isEnabled(): boolean {
    return native.native_menu_item_is_enabled(this.nativeHandle);
  }

  setState(state: MenuItemState): void {
    native.native_menu_item_set_state(this.nativeHandle, state);
  }

  get state(): MenuItemState {
    return native.native_menu_item_get_state(this.nativeHandle);
  }

  setRadioGroup(groupId: number): void {
    native.native_menu_item_set_radio_group(this.nativeHandle, groupId);
  }

  get radioGroup(): number {
    return native.native_menu_item_get_radio_group(this.nativeHandle);
  }

  setSubmenu(submenu: Menu | null): void {
    native.native_menu_item_set_submenu(this.nativeHandle, submenu?.nativeHandle ?? 0n);
  }

  get submenu(): Menu | null {
    return wrapHandle(Menu, native.native_menu_item_get_submenu(this.nativeHandle));
  }

  /** The platform object behind this handle, as an address. */
  get nativeObject(): bigint {
    return native.native_menu_item_get_native_object(this.nativeHandle);
  }

  /** Calls `listener` for every MenuEvent this MenuItem emits; returns the listener id. */
  addListener(listener: (event: MenuEvent) => void): number {
    return native.native_menu_item_add_listener(this.nativeHandle, listener);
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  removeListener(listenerId: number): boolean {
    return native.native_menu_item_remove_listener(this.nativeHandle, listenerId);
  }
}

/** A native Menu, held through an owned handle. */
export class Menu extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_menu_free : undefined);
  }

  static create(): Menu | null {
    const handle: bigint = native.native_menu_create();
    return handle ? new Menu(handle) : null;
  }

  static createWithNativeMenu(nativeMenu: bigint): Menu | null {
    const handle: bigint = native.native_menu_create_with_native_menu(nativeMenu);
    return handle ? new Menu(handle) : null;
  }

  get id(): MenuId {
    return native.native_menu_get_id(this.nativeHandle);
  }

  setBackend(backend: MenuBackend): boolean {
    return native.native_menu_set_backend(this.nativeHandle, backend);
  }

  get backend(): MenuBackend {
    return native.native_menu_get_backend(this.nativeHandle);
  }

  static isBackendSupported(backend: MenuBackend): boolean {
    return native.native_menu_is_backend_supported(backend);
  }

  addItem(item: MenuItem | null): void {
    native.native_menu_add_item(this.nativeHandle, item?.nativeHandle ?? 0n);
  }

  insertItem(index: number, item: MenuItem | null): void {
    native.native_menu_insert_item(this.nativeHandle, index, item?.nativeHandle ?? 0n);
  }

  removeItem(item: MenuItem | null): boolean {
    return native.native_menu_remove_item(this.nativeHandle, item?.nativeHandle ?? 0n);
  }

  removeItemById(itemId: MenuItemId): boolean {
    return native.native_menu_remove_item_by_id(this.nativeHandle, itemId);
  }

  removeItemAt(index: number): boolean {
    return native.native_menu_remove_item_at(this.nativeHandle, index);
  }

  clear(): void {
    native.native_menu_clear(this.nativeHandle);
  }

  addSeparator(): void {
    native.native_menu_add_separator(this.nativeHandle);
  }

  insertSeparator(index: number): void {
    native.native_menu_insert_separator(this.nativeHandle, index);
  }

  get itemCount(): number {
    return native.native_menu_get_item_count(this.nativeHandle);
  }

  getItemAt(index: number): MenuItem | null {
    return wrapHandle(MenuItem, native.native_menu_get_item_at(this.nativeHandle, index));
  }

  getItemById(itemId: MenuItemId): MenuItem | null {
    return wrapHandle(MenuItem, native.native_menu_get_item_by_id(this.nativeHandle, itemId));
  }

  get allItems(): MenuItem[] {
    return (native.native_menu_get_all_items(this.nativeHandle) as bigint[]).map((handle) => new MenuItem(handle));
  }

  open(strategy: PositioningStrategy, placement: Placement): boolean {
    return native.native_menu_open(this.nativeHandle, strategy.nativeHandle, placement);
  }

  close(): boolean {
    return native.native_menu_close(this.nativeHandle);
  }

  /** The platform object behind this handle, as an address. */
  get nativeObject(): bigint {
    return native.native_menu_get_native_object(this.nativeHandle);
  }

  /** Calls `listener` for every MenuEvent this Menu emits; returns the listener id. */
  addListener(listener: (event: MenuEvent) => void): number {
    return native.native_menu_add_listener(this.nativeHandle, listener);
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  removeListener(listenerId: number): boolean {
    return native.native_menu_remove_listener(this.nativeHandle, listenerId);
  }
}
