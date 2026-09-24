// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace CNativeAPI;

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void ShortcutManagerRegisterWithAcceleratorAndCallbackCallbackNativeCallback(IntPtr userData);

public static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_shortcut_manager_is_available([MarshalAs(UnmanagedType.LPUTF8Str)] string? accelerator);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_shortcut_manager_is_enabled();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_shortcut_manager_is_supported();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_shortcut_manager_is_valid_accelerator([MarshalAs(UnmanagedType.LPUTF8Str)] string? accelerator);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_shortcut_manager_remove_listener(ulong listenerId);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_shortcut_manager_unregister_with_accelerator([MarshalAs(UnmanagedType.LPUTF8Str)] string? accelerator);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_shortcut_manager_unregister_with_id(uint id);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern int native_shortcut_manager_unregister_all();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern native_shortcut_list_t native_shortcut_manager_get_all();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern native_shortcut_list_t native_shortcut_manager_get_by_scope(int scope);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_shortcut_manager_add_listener(ShortcutEventNativeCallback callback, IntPtr userData);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_shortcut_manager_get_with_accelerator([MarshalAs(UnmanagedType.LPUTF8Str)] string? accelerator);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_shortcut_manager_get_with_id(uint id);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_shortcut_manager_register_with_accelerator_and_callback([MarshalAs(UnmanagedType.LPUTF8Str)] string? accelerator, ShortcutManagerRegisterWithAcceleratorAndCallbackCallbackNativeCallback callback, IntPtr callback_user_data);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_shortcut_manager_register_with_options(native_shortcut_options_t options);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_shortcut_manager_emit_shortcut_activated(uint id, [MarshalAs(UnmanagedType.LPUTF8Str)] string? accelerator);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_shortcut_manager_set_enabled([MarshalAs(UnmanagedType.I1)] bool enabled);
}

