// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject, wrapHandle } from "./runtime.ts";
import { Color } from "./color.ts";
import { type Point, type Rectangle, type Size } from "./geometry.ts";
import { View } from "./view.ts";
import { WindowShadow } from "./window_shadow.ts";
import { WindowShape } from "./window_shape.ts";

export type WindowId = number;

export const TitleBarStyle = {
  Normal: 0,
  Hidden: 1,
} as const;
export type TitleBarStyle = (typeof TitleBarStyle)[keyof typeof TitleBarStyle];

export const VisualEffect = {
  None: 0,
  Blur: 1,
  Acrylic: 2,
  Mica: 3,
  MicaAlt: 4,
  Hud: 5,
  Popover: 6,
  Menu: 7,
} as const;
export type VisualEffect = (typeof VisualEffect)[keyof typeof VisualEffect];

export const ResizeEdge = {
  Top: 0,
  Left: 1,
  Right: 2,
  Bottom: 3,
  TopLeft: 4,
  TopRight: 5,
  BottomLeft: 6,
  BottomRight: 7,
} as const;
export type ResizeEdge = (typeof ResizeEdge)[keyof typeof ResizeEdge];

export type WindowEvent =
  | { type: "focused"; windowId: WindowId }
  | { type: "blurred"; windowId: WindowId }
  | { type: "minimized"; windowId: WindowId }
  | { type: "maximized"; windowId: WindowId }
  | { type: "restored"; windowId: WindowId }
  | { type: "moved"; windowId: WindowId; newPosition: Point }
  | { type: "resized"; windowId: WindowId; newSize: Size }
  | { type: "created"; windowId: WindowId }
  | { type: "closed"; windowId: WindowId };

/** A native Window, held through an owned handle. */
export class Window extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_window_free : undefined);
  }

  static create(): Window | null {
    const handle: bigint = native.native_window_create();
    return handle ? new Window(handle) : null;
  }

  static createWithNativeWindow(nativeWindow: bigint): Window | null {
    const handle: bigint = native.native_window_create_with_native_window(nativeWindow);
    return handle ? new Window(handle) : null;
  }

  get id(): WindowId {
    return native.native_window_get_id(this.nativeHandle);
  }

  get contentView(): View | null {
    return wrapHandle(View, native.native_window_get_content_view(this.nativeHandle));
  }

  focus(): void {
    native.native_window_focus(this.nativeHandle);
  }

  blur(): void {
    native.native_window_blur(this.nativeHandle);
  }

  get isFocused(): boolean {
    return native.native_window_is_focused(this.nativeHandle);
  }

  show(): void {
    native.native_window_show(this.nativeHandle);
  }

  showInactive(): void {
    native.native_window_show_inactive(this.nativeHandle);
  }

  hide(): void {
    native.native_window_hide(this.nativeHandle);
  }

  get isVisible(): boolean {
    return native.native_window_is_visible(this.nativeHandle);
  }

  maximize(): void {
    native.native_window_maximize(this.nativeHandle);
  }

  unmaximize(): void {
    native.native_window_unmaximize(this.nativeHandle);
  }

  get isMaximized(): boolean {
    return native.native_window_is_maximized(this.nativeHandle);
  }

  minimize(): void {
    native.native_window_minimize(this.nativeHandle);
  }

  restore(): void {
    native.native_window_restore(this.nativeHandle);
  }

  get isMinimized(): boolean {
    return native.native_window_is_minimized(this.nativeHandle);
  }

  setFullScreen(isFullScreen: boolean): void {
    native.native_window_set_full_screen(this.nativeHandle, isFullScreen);
  }

  get isFullScreen(): boolean {
    return native.native_window_is_full_screen(this.nativeHandle);
  }

  setBounds(bounds: Rectangle): void {
    native.native_window_set_bounds(this.nativeHandle, bounds);
  }

  get bounds(): Rectangle {
    return native.native_window_get_bounds(this.nativeHandle);
  }

  setContentBounds(bounds: Rectangle): void {
    native.native_window_set_content_bounds(this.nativeHandle, bounds);
  }

  get contentBounds(): Rectangle {
    return native.native_window_get_content_bounds(this.nativeHandle);
  }

  setSize(size: Size, animate: boolean): void {
    native.native_window_set_size(this.nativeHandle, size, animate);
  }

  get size(): Size {
    return native.native_window_get_size(this.nativeHandle);
  }

  setContentSize(size: Size): void {
    native.native_window_set_content_size(this.nativeHandle, size);
  }

  get contentSize(): Size {
    return native.native_window_get_content_size(this.nativeHandle);
  }

  setMinimumSize(size: Size): void {
    native.native_window_set_minimum_size(this.nativeHandle, size);
  }

  get minimumSize(): Size {
    return native.native_window_get_minimum_size(this.nativeHandle);
  }

  setMaximumSize(size: Size): void {
    native.native_window_set_maximum_size(this.nativeHandle, size);
  }

  get maximumSize(): Size {
    return native.native_window_get_maximum_size(this.nativeHandle);
  }

  setAspectRatio(aspectRatio: number): void {
    native.native_window_set_aspect_ratio(this.nativeHandle, aspectRatio);
  }

  get aspectRatio(): number {
    return native.native_window_get_aspect_ratio(this.nativeHandle);
  }

  setResizable(isResizable: boolean): void {
    native.native_window_set_resizable(this.nativeHandle, isResizable);
  }

  get isResizable(): boolean {
    return native.native_window_is_resizable(this.nativeHandle);
  }

  setMovable(isMovable: boolean): void {
    native.native_window_set_movable(this.nativeHandle, isMovable);
  }

  get isMovable(): boolean {
    return native.native_window_is_movable(this.nativeHandle);
  }

  setMinimizable(isMinimizable: boolean): void {
    native.native_window_set_minimizable(this.nativeHandle, isMinimizable);
  }

  get isMinimizable(): boolean {
    return native.native_window_is_minimizable(this.nativeHandle);
  }

  setMaximizable(isMaximizable: boolean): void {
    native.native_window_set_maximizable(this.nativeHandle, isMaximizable);
  }

  get isMaximizable(): boolean {
    return native.native_window_is_maximizable(this.nativeHandle);
  }

  setFullScreenable(isFullScreenable: boolean): void {
    native.native_window_set_full_screenable(this.nativeHandle, isFullScreenable);
  }

  get isFullScreenable(): boolean {
    return native.native_window_is_full_screenable(this.nativeHandle);
  }

  setClosable(isClosable: boolean): void {
    native.native_window_set_closable(this.nativeHandle, isClosable);
  }

  get isClosable(): boolean {
    return native.native_window_is_closable(this.nativeHandle);
  }

  setWindowControlButtonsVisible(isVisible: boolean): void {
    native.native_window_set_window_control_buttons_visible(this.nativeHandle, isVisible);
  }

  get isWindowControlButtonsVisible(): boolean {
    return native.native_window_is_window_control_buttons_visible(this.nativeHandle);
  }

  setAlwaysOnTop(isAlwaysOnTop: boolean): void {
    native.native_window_set_always_on_top(this.nativeHandle, isAlwaysOnTop);
  }

  get isAlwaysOnTop(): boolean {
    return native.native_window_is_always_on_top(this.nativeHandle);
  }

  setAlwaysOnBottom(isAlwaysOnBottom: boolean): void {
    native.native_window_set_always_on_bottom(this.nativeHandle, isAlwaysOnBottom);
  }

  get isAlwaysOnBottom(): boolean {
    return native.native_window_is_always_on_bottom(this.nativeHandle);
  }

  setParentWindow(parent: Window | null): boolean {
    return native.native_window_set_parent_window(this.nativeHandle, parent?.nativeHandle ?? 0n);
  }

  get parentWindow(): Window | null {
    return wrapHandle(Window, native.native_window_get_parent_window(this.nativeHandle));
  }

  setNonActivating(isNonActivating: boolean): void {
    native.native_window_set_non_activating(this.nativeHandle, isNonActivating);
  }

  get isNonActivating(): boolean {
    return native.native_window_is_non_activating(this.nativeHandle);
  }

  setPosition(point: Point): void {
    native.native_window_set_position(this.nativeHandle, point);
  }

  get position(): Point {
    return native.native_window_get_position(this.nativeHandle);
  }

  center(): void {
    native.native_window_center(this.nativeHandle);
  }

  setTitle(title: string): void {
    native.native_window_set_title(this.nativeHandle, title);
  }

  get title(): string {
    return native.native_window_get_title(this.nativeHandle);
  }

  setTitleBarColors(background: Color, foreground: Color): boolean {
    return native.native_window_set_title_bar_colors(this.nativeHandle, background, foreground);
  }

  resetTitleBarColors(): boolean {
    return native.native_window_reset_title_bar_colors(this.nativeHandle);
  }

  setTitleBarStyle(style: TitleBarStyle): void {
    native.native_window_set_title_bar_style(this.nativeHandle, style);
  }

  get titleBarStyle(): TitleBarStyle {
    return native.native_window_get_title_bar_style(this.nativeHandle);
  }

  setContentUnderTitleBar(isContentUnderTitleBar: boolean): boolean {
    return native.native_window_set_content_under_title_bar(this.nativeHandle, isContentUnderTitleBar);
  }

  get isContentUnderTitleBar(): boolean {
    return native.native_window_is_content_under_title_bar(this.nativeHandle);
  }

  static isContentUnderTitleBarSupported(): boolean {
    return native.native_window_is_content_under_title_bar_supported();
  }

  setHasShadow(hasShadow: boolean): void {
    native.native_window_set_has_shadow(this.nativeHandle, hasShadow);
  }

  get hasShadow(): boolean {
    return native.native_window_has_shadow(this.nativeHandle);
  }

  setCustomShadow(shadow: WindowShadow | null): boolean {
    return native.native_window_set_custom_shadow(this.nativeHandle, shadow?.nativeHandle ?? 0n);
  }

  get customShadow(): WindowShadow | null {
    return wrapHandle(WindowShadow, native.native_window_get_custom_shadow(this.nativeHandle));
  }

  setOpacity(opacity: number): void {
    native.native_window_set_opacity(this.nativeHandle, opacity);
  }

  get opacity(): number {
    return native.native_window_get_opacity(this.nativeHandle);
  }

  setVisualEffect(effect: VisualEffect): boolean {
    return native.native_window_set_visual_effect(this.nativeHandle, effect);
  }

  get visualEffect(): VisualEffect {
    return native.native_window_get_visual_effect(this.nativeHandle);
  }

  static isVisualEffectSupported(effect: VisualEffect): boolean {
    return native.native_window_is_visual_effect_supported(effect);
  }

  setShape(shape: WindowShape | null): boolean {
    return native.native_window_set_shape(this.nativeHandle, shape?.nativeHandle ?? 0n);
  }

  get isShaped(): boolean {
    return native.native_window_is_shaped(this.nativeHandle);
  }

  static isShapeSupported(): boolean {
    return native.native_window_is_shape_supported();
  }

  setInputShape(shape: WindowShape | null): boolean {
    return native.native_window_set_input_shape(this.nativeHandle, shape?.nativeHandle ?? 0n);
  }

  get isInputShaped(): boolean {
    return native.native_window_is_input_shaped(this.nativeHandle);
  }

  static isInputShapeSupported(): boolean {
    return native.native_window_is_input_shape_supported();
  }

  setBackgroundColor(color: Color): void {
    native.native_window_set_background_color(this.nativeHandle, color);
  }

  get backgroundColor(): Color {
    return native.native_window_get_background_color(this.nativeHandle);
  }

  setVisibleOnAllWorkspaces(isVisibleOnAllWorkspaces: boolean): void {
    native.native_window_set_visible_on_all_workspaces(this.nativeHandle, isVisibleOnAllWorkspaces);
  }

  get isVisibleOnAllWorkspaces(): boolean {
    return native.native_window_is_visible_on_all_workspaces(this.nativeHandle);
  }

  setVisibleInTaskbar(isVisibleInTaskbar: boolean): void {
    native.native_window_set_visible_in_taskbar(this.nativeHandle, isVisibleInTaskbar);
  }

  get isVisibleInTaskbar(): boolean {
    return native.native_window_is_visible_in_taskbar(this.nativeHandle);
  }

  setIgnoreMouseEvents(isIgnoreMouseEvents: boolean): void {
    native.native_window_set_ignore_mouse_events(this.nativeHandle, isIgnoreMouseEvents);
  }

  get isIgnoreMouseEvents(): boolean {
    return native.native_window_is_ignore_mouse_events(this.nativeHandle);
  }

  setFocusable(isFocusable: boolean): void {
    native.native_window_set_focusable(this.nativeHandle, isFocusable);
  }

  get isFocusable(): boolean {
    return native.native_window_is_focusable(this.nativeHandle);
  }

  startDragging(): void {
    native.native_window_start_dragging(this.nativeHandle);
  }

  startResizing(edge: ResizeEdge): void {
    native.native_window_start_resizing(this.nativeHandle, edge);
  }

  /** The platform object behind this handle, as an address. */
  get nativeObject(): bigint {
    return native.native_window_get_native_object(this.nativeHandle);
  }
}
