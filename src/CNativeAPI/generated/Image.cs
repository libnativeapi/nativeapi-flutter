// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace CNativeAPI;

public static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_image_save_to_file(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? filePath);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr native_image_get_format(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr native_image_get_native_object(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr native_image_to_base64(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern native_size_t native_image_get_size(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_image_from_base64([MarshalAs(UnmanagedType.LPUTF8Str)] string? base64Data);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_image_from_file([MarshalAs(UnmanagedType.LPUTF8Str)] string? filePath);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_image_free(ulong handle);
}

