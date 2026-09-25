// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject, wrapHandle } from "./runtime.ts";
import { Color } from "./color.ts";
import { EdgeInsets, type Rectangle, type Size } from "./geometry.ts";
import { Image } from "./image.ts";
import { Window } from "./window.ts";

export type ViewId = number;

export const ViewLayout = {
  Absolute: 0,
  Row: 1,
  Column: 2,
} as const;
export type ViewLayout = (typeof ViewLayout)[keyof typeof ViewLayout];

export const ViewAlignment = {
  Stretch: 0,
  Start: 1,
  Center: 2,
  End: 3,
} as const;
export type ViewAlignment = (typeof ViewAlignment)[keyof typeof ViewAlignment];

export const TextAlignment = {
  Start: 0,
  Center: 1,
  End: 2,
} as const;
export type TextAlignment = (typeof TextAlignment)[keyof typeof TextAlignment];

export const ViewBackend = {
  Native: 0,
  WinUi3: 1,
} as const;
export type ViewBackend = (typeof ViewBackend)[keyof typeof ViewBackend];

export type ViewEvent =
  | { type: "focused"; viewId: ViewId }
  | { type: "blurred"; viewId: ViewId }
  | { type: "buttonClicked"; viewId: ViewId }
  | { type: "textFieldChanged"; viewId: ViewId; text: string | null }
  | { type: "textFieldSubmitted"; viewId: ViewId };

/** A native View, held through an owned handle. */
export class View extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_view_free : undefined);
  }

  static create(): View | null {
    const handle: bigint = native.native_view_create();
    return handle ? new View(handle) : null;
  }

  static createWithNativeView(nativeView: bigint): View | null {
    const handle: bigint = native.native_view_create_with_native_view(nativeView);
    return handle ? new View(handle) : null;
  }

  static isSupported(): boolean {
    return native.native_view_is_supported();
  }

  static isBackendSupported(backend: ViewBackend): boolean {
    return native.native_view_is_backend_supported(backend);
  }

  static setDefaultBackend(backend: ViewBackend): boolean {
    return native.native_view_set_default_backend(backend);
  }

  static getDefaultBackend(): ViewBackend {
    return native.native_view_get_default_backend();
  }

  get id(): ViewId {
    return native.native_view_get_id(this.nativeHandle);
  }

  get backend(): ViewBackend {
    return native.native_view_get_backend(this.nativeHandle);
  }

  addSubview(subview: View | null): void {
    native.native_view_add_subview(this.nativeHandle, subview?.nativeHandle ?? 0n);
  }

  insertSubview(index: number, subview: View | null): void {
    native.native_view_insert_subview(this.nativeHandle, index, subview?.nativeHandle ?? 0n);
  }

  removeSubview(subview: View | null): boolean {
    return native.native_view_remove_subview(this.nativeHandle, subview?.nativeHandle ?? 0n);
  }

  removeSubviewAt(index: number): boolean {
    return native.native_view_remove_subview_at(this.nativeHandle, index);
  }

  clearSubviews(): void {
    native.native_view_clear_subviews(this.nativeHandle);
  }

  get subviewCount(): number {
    return native.native_view_get_subview_count(this.nativeHandle);
  }

  getSubviewAt(index: number): View | null {
    return wrapHandle(View, native.native_view_get_subview_at(this.nativeHandle, index));
  }

  get subviews(): View[] {
    return (native.native_view_get_subviews(this.nativeHandle) as bigint[]).map((handle) => new View(handle));
  }

  get parent(): View | null {
    return wrapHandle(View, native.native_view_get_parent(this.nativeHandle));
  }

  get window(): Window | null {
    return wrapHandle(Window, native.native_view_get_window(this.nativeHandle));
  }

  setFrame(frame: Rectangle): void {
    native.native_view_set_frame(this.nativeHandle, frame);
  }

  get frame(): Rectangle {
    return native.native_view_get_frame(this.nativeHandle);
  }

  setPreferredSize(size: Size): void {
    native.native_view_set_preferred_size(this.nativeHandle, size);
  }

  get preferredSize(): Size {
    return native.native_view_get_preferred_size(this.nativeHandle);
  }

  get intrinsicSize(): Size {
    return native.native_view_get_intrinsic_size(this.nativeHandle);
  }

  setFlex(flex: number): void {
    native.native_view_set_flex(this.nativeHandle, flex);
  }

  get flex(): number {
    return native.native_view_get_flex(this.nativeHandle);
  }

  setAlignment(alignment: ViewAlignment): void {
    native.native_view_set_alignment(this.nativeHandle, alignment);
  }

  get alignment(): ViewAlignment {
    return native.native_view_get_alignment(this.nativeHandle);
  }

  setLayout(layout: ViewLayout): void {
    native.native_view_set_layout(this.nativeHandle, layout);
  }

  get layout(): ViewLayout {
    return native.native_view_get_layout(this.nativeHandle);
  }

  setSpacing(spacing: number): void {
    native.native_view_set_spacing(this.nativeHandle, spacing);
  }

  get spacing(): number {
    return native.native_view_get_spacing(this.nativeHandle);
  }

  setPadding(padding: EdgeInsets): void {
    native.native_view_set_padding(this.nativeHandle, padding);
  }

  get padding(): EdgeInsets {
    return native.native_view_get_padding(this.nativeHandle);
  }

  setVisible(isVisible: boolean): void {
    native.native_view_set_visible(this.nativeHandle, isVisible);
  }

  get isVisible(): boolean {
    return native.native_view_is_visible(this.nativeHandle);
  }

  setEnabled(isEnabled: boolean): void {
    native.native_view_set_enabled(this.nativeHandle, isEnabled);
  }

  get isEnabled(): boolean {
    return native.native_view_is_enabled(this.nativeHandle);
  }

  setBackgroundColor(color: Color): void {
    native.native_view_set_background_color(this.nativeHandle, color);
  }

  get backgroundColor(): Color {
    return native.native_view_get_background_color(this.nativeHandle);
  }

  setTooltip(tooltip: string | null): void {
    native.native_view_set_tooltip(this.nativeHandle, tooltip);
  }

  get tooltip(): string | null {
    return native.native_view_get_tooltip(this.nativeHandle);
  }

  focus(): void {
    native.native_view_focus(this.nativeHandle);
  }

  blur(): void {
    native.native_view_blur(this.nativeHandle);
  }

  get isFocused(): boolean {
    return native.native_view_is_focused(this.nativeHandle);
  }

  /** The platform object behind this handle, as an address. */
  get nativeObject(): bigint {
    return native.native_view_get_native_object(this.nativeHandle);
  }

  /** Calls `listener` for every ViewEvent this View emits; returns the listener id. */
  addListener(listener: (event: ViewEvent) => void): number {
    return native.native_view_add_listener(this.nativeHandle, listener);
  }

  /** Unregisters a listener; returns false if the id is unknown. */
  removeListener(listenerId: number): boolean {
    return native.native_view_remove_listener(this.nativeHandle, listenerId);
  }
}

/** A native Label, held through an owned handle. */
export class Label extends View {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned);
  }

  static create(text: string = ""): Label | null {
    const handle: bigint = native.native_label_create(text);
    return handle ? new Label(handle) : null;
  }

  setText(text: string): void {
    native.native_label_set_text(this.nativeHandle, text);
  }

  get text(): string {
    return native.native_label_get_text(this.nativeHandle);
  }

  setTextColor(color: Color): void {
    native.native_label_set_text_color(this.nativeHandle, color);
  }

  get textColor(): Color {
    return native.native_label_get_text_color(this.nativeHandle);
  }

  setFontSize(size: number): void {
    native.native_label_set_font_size(this.nativeHandle, size);
  }

  get fontSize(): number {
    return native.native_label_get_font_size(this.nativeHandle);
  }

  setTextAlignment(alignment: TextAlignment): void {
    native.native_label_set_text_alignment(this.nativeHandle, alignment);
  }

  get textAlignment(): TextAlignment {
    return native.native_label_get_text_alignment(this.nativeHandle);
  }
}

/** A native Button, held through an owned handle. */
export class Button extends View {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned);
  }

  static create(text: string = ""): Button | null {
    const handle: bigint = native.native_button_create(text);
    return handle ? new Button(handle) : null;
  }

  setText(text: string): void {
    native.native_button_set_text(this.nativeHandle, text);
  }

  get text(): string {
    return native.native_button_get_text(this.nativeHandle);
  }
}

/** A native TextField, held through an owned handle. */
export class TextField extends View {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned);
  }

  static create(text: string = ""): TextField | null {
    const handle: bigint = native.native_text_field_create(text);
    return handle ? new TextField(handle) : null;
  }

  setText(text: string): void {
    native.native_text_field_set_text(this.nativeHandle, text);
  }

  get text(): string {
    return native.native_text_field_get_text(this.nativeHandle);
  }

  setTextColor(color: Color): void {
    native.native_text_field_set_text_color(this.nativeHandle, color);
  }

  get textColor(): Color {
    return native.native_text_field_get_text_color(this.nativeHandle);
  }

  setFontSize(size: number): void {
    native.native_text_field_set_font_size(this.nativeHandle, size);
  }

  get fontSize(): number {
    return native.native_text_field_get_font_size(this.nativeHandle);
  }

  setTextAlignment(alignment: TextAlignment): void {
    native.native_text_field_set_text_alignment(this.nativeHandle, alignment);
  }

  get textAlignment(): TextAlignment {
    return native.native_text_field_get_text_alignment(this.nativeHandle);
  }

  setPlaceholder(placeholder: string | null): void {
    native.native_text_field_set_placeholder(this.nativeHandle, placeholder);
  }

  get placeholder(): string | null {
    return native.native_text_field_get_placeholder(this.nativeHandle);
  }

  setEditable(isEditable: boolean): void {
    native.native_text_field_set_editable(this.nativeHandle, isEditable);
  }

  get isEditable(): boolean {
    return native.native_text_field_is_editable(this.nativeHandle);
  }

  setSecure(isSecure: boolean): void {
    native.native_text_field_set_secure(this.nativeHandle, isSecure);
  }

  get isSecure(): boolean {
    return native.native_text_field_is_secure(this.nativeHandle);
  }

  setMultiline(isMultiline: boolean): void {
    native.native_text_field_set_multiline(this.nativeHandle, isMultiline);
  }

  get isMultiline(): boolean {
    return native.native_text_field_is_multiline(this.nativeHandle);
  }
}

/** A native ImageView, held through an owned handle. */
export class ImageView extends View {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned);
  }

  static create(): ImageView | null {
    const handle: bigint = native.native_image_view_create();
    return handle ? new ImageView(handle) : null;
  }

  setImage(image: Image | null): void {
    native.native_image_view_set_image(this.nativeHandle, image?.nativeHandle ?? 0n);
  }

  get image(): Image | null {
    return wrapHandle(Image, native.native_image_view_get_image(this.nativeHandle));
  }
}
