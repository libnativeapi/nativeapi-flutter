// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace CNativeAPI;

[StructLayout(LayoutKind.Sequential)]
public struct native_shortcut_options_t
{
    public IntPtr accelerator;
    public IntPtr callback;
    public IntPtr callback_user_data;
    public IntPtr description;
    public int scope;
    public byte enabled;
}

[StructLayout(LayoutKind.Sequential)]
public struct native_shortcut_event_t
{
    public int type;
    public uint shortcut_id;
    public IntPtr accelerator;
    public DataUnion data;

    [StructLayout(LayoutKind.Explicit)]
    public struct DataUnion
    {
        [FieldOffset(0)] public RegistrationFailedData registration_failed;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RegistrationFailedData
    {
        public IntPtr error_message;
    }
}

[StructLayout(LayoutKind.Sequential)]
public struct native_shortcut_list_t
{
    public IntPtr shortcuts;
    public CLong count;
}

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void ShortcutCreateWithIdAndAcceleratorAndCallbackCallbackNativeCallback(IntPtr userData);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void ShortcutEventNativeCallback(IntPtr evt, IntPtr userData);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void ShortcutOptionsCallbackNativeCallback(IntPtr userData);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void ShortcutSetCallbackCallbackNativeCallback(IntPtr userData);

public static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_shortcut_is_enabled(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr native_shortcut_get_accelerator(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr native_shortcut_get_description(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern int native_shortcut_get_scope(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern uint native_shortcut_get_id(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_shortcut_create_with_id_and_accelerator_and_callback(uint id, [MarshalAs(UnmanagedType.LPUTF8Str)] string? accelerator, ShortcutCreateWithIdAndAcceleratorAndCallbackCallbackNativeCallback callback, IntPtr callback_user_data);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_shortcut_create_with_id_and_options(uint id, native_shortcut_options_t options);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_shortcut_free(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_shortcut_invoke(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_shortcut_list_release(ref native_shortcut_list_t list);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_shortcut_options_free(ref native_shortcut_options_t value);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_shortcut_set_callback(ulong self, ShortcutSetCallbackCallbackNativeCallback callback, IntPtr callback_user_data);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_shortcut_set_description(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? description);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_shortcut_set_enabled(ulong self, [MarshalAs(UnmanagedType.I1)] bool enabled);
}

