// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace CNativeAPI;

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void WindowManagerSetWillHideHookHookNativeCallback(uint arg0, IntPtr userData);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void WindowManagerSetWillShowHookHookNativeCallback(uint arg0, IntPtr userData);

public static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_window_manager_call_original_hide(uint id);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_window_manager_call_original_show(uint id);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_window_manager_has_will_hide_hook();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_window_manager_has_will_show_hook();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_window_manager_remove_listener(ulong listenerId);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern native_window_list_t native_window_manager_get_all();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_window_manager_add_listener(WindowEventNativeCallback callback, IntPtr userData, ReleaseUserDataNativeCallback releaseUserData);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_window_manager_get(uint id);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_window_manager_get_current();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_window_manager_get_window_at_point(native_point_t point, uint excludedWindowId);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_window_manager_handle_will_hide(uint id);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_window_manager_handle_will_show(uint id);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_window_manager_set_will_hide_hook(WindowManagerSetWillHideHookHookNativeCallback? hook, IntPtr hook_user_data, ReleaseUserDataNativeCallback hook_release_user_data);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_window_manager_set_will_show_hook(WindowManagerSetWillShowHookHookNativeCallback? hook, IntPtr hook_user_data, ReleaseUserDataNativeCallback hook_release_user_data);
}

