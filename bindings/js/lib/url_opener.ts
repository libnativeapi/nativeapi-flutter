// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

import { native } from "./runtime.ts";

export const UrlOpenErrorCode = {
  None: 0,
  InvalidUrlEmpty: 1,
  InvalidUrlMissingScheme: 2,
  InvalidUrlUnsupportedScheme: 3,
  UnsupportedPlatform: 4,
  InvocationFailed: 5,
} as const;
export type UrlOpenErrorCode = (typeof UrlOpenErrorCode)[keyof typeof UrlOpenErrorCode];

export interface UrlOpenResult {
  success: boolean;
  errorCode: UrlOpenErrorCode;
  errorMessage: string;
}

export class UrlOpener {
  private constructor() {}

  static isSupported(): boolean {
    return native.native_url_opener_is_supported();
  }

  static canOpen(url: string): boolean {
    return native.native_url_opener_can_open(url);
  }

  static open(url: string): UrlOpenResult {
    return native.native_url_opener_open(url);
  }
}
