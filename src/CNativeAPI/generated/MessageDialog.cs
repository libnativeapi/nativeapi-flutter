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
    public static extern bool native_message_dialog_close(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_message_dialog_open(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr native_message_dialog_get_message(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr native_message_dialog_get_title(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern int native_message_dialog_get_modality(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_message_dialog_create([MarshalAs(UnmanagedType.LPUTF8Str)] string? title, [MarshalAs(UnmanagedType.LPUTF8Str)] string? message);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_message_dialog_free(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_message_dialog_set_message(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? message);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_message_dialog_set_modality(ulong self, int modality);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_message_dialog_set_title(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? title);
}

