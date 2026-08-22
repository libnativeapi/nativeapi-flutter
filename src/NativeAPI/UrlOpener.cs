// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public enum UrlOpenErrorCode
{
    None = 0,
    InvalidUrlEmpty = 1,
    InvalidUrlMissingScheme = 2,
    InvalidUrlUnsupportedScheme = 3,
    UnsupportedPlatform = 4,
    InvocationFailed = 5,
}

public struct UrlOpenResult
{
    public bool Success;
    public UrlOpenErrorCode ErrorCode;
    public string? ErrorMessage;

    public UrlOpenResult(bool success, UrlOpenErrorCode errorCode, string? errorMessage)
    {
        Success = success;
        ErrorCode = errorCode;
        ErrorMessage = errorMessage;
    }

    internal static UrlOpenResult FromRaw(in native_url_open_result_t raw)
    {
        return new UrlOpenResult(raw.success != 0, (UrlOpenErrorCode)raw.error_code, Marshal.PtrToStringUTF8(raw.error_message));
    }

    internal native_url_open_result_t ToRaw()
    {
        var raw = new native_url_open_result_t();
        raw.success = (byte)(Success ? 1 : 0);
        raw.error_code = (int)ErrorCode;
        raw.error_message = Marshal.StringToCoTaskMemUTF8(ErrorMessage);
        return raw;
    }

    internal static void ReleaseRaw(ref native_url_open_result_t raw)
    {
        Marshal.FreeCoTaskMem(raw.error_message);
        raw.error_message = IntPtr.Zero;
    }
}

public sealed partial class UrlOpener
{
    /// <summary>The shared instance backed by the native singleton.</summary>
    public static UrlOpener Shared { get; } = new UrlOpener();

    private UrlOpener() { }

    public bool IsSupported()
    {
        var rawResult = Interop.native_url_opener_is_supported();
        return rawResult;
    }

    public bool CanOpen(string url)
    {
        var rawResult = Interop.native_url_opener_can_open(url);
        return rawResult;
    }

    public UrlOpenResult Open(string url)
    {
        var rawResult = Interop.native_url_opener_open(url);
        var result = UrlOpenResult.FromRaw(in rawResult);
        Interop.native_url_open_result_free(ref rawResult);
        return result;
    }

}

