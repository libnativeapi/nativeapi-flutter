// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native, NativeObject, wrapHandle } from "./runtime.ts";
import { type Size } from "./geometry.ts";

/** A native Image, held through an owned handle. */
export class Image extends NativeObject {
  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */
  constructor(handle: bigint, owned = true) {
    super(handle, owned ? native.native_image_free : undefined);
  }

  static fromFile(filePath: string): Image | null {
    return wrapHandle(Image, native.native_image_from_file(filePath));
  }

  static fromBase64(base64Data: string): Image | null {
    return wrapHandle(Image, native.native_image_from_base64(base64Data));
  }

  get size(): Size {
    return native.native_image_get_size(this.nativeHandle);
  }

  get format(): string {
    return native.native_image_get_format(this.nativeHandle);
  }

  toBase64(): string {
    return native.native_image_to_base64(this.nativeHandle);
  }

  saveToFile(filePath: string): boolean {
    return native.native_image_save_to_file(this.nativeHandle, filePath);
  }

  /** The platform object behind this handle, as an address. */
  get nativeObject(): bigint {
    return native.native_image_get_native_object(this.nativeHandle);
  }
}
