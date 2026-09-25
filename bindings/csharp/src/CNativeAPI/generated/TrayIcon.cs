// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace CNativeAPI;

[StructLayout(LayoutKind.Sequential)]
public struct native_tray_icon_event_t
{
    public int type;
    public DataUnion data;

    [StructLayout(LayoutKind.Explicit)]
    public struct DataUnion
    {
        [FieldOffset(0)] public ClickedData clicked;
        [FieldOffset(0)] public RightClickedData right_clicked;
        [FieldOffset(0)] public DoubleClickedData double_clicked;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct ClickedData
    {
        public uint tray_icon_id;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RightClickedData
    {
        public uint tray_icon_id;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DoubleClickedData
    {
        public uint tray_icon_id;
    }
}

[StructLayout(LayoutKind.Sequential)]
public struct native_tray_icon_list_t
{
    public IntPtr tray_icons;
    public CLong count;
}

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void TrayIconEventNativeCallback(IntPtr evt, IntPtr userData);

public static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_tray_icon_close_context_menu(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_tray_icon_is_icon_template(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_tray_icon_is_visible(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_tray_icon_open_context_menu(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_tray_icon_remove_listener(ulong self, ulong listenerId);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool native_tray_icon_set_visible(ulong self, [MarshalAs(UnmanagedType.I1)] bool visible);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr native_tray_icon_get_native_object(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr native_tray_icon_get_title(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr native_tray_icon_get_tooltip(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern int native_tray_icon_get_context_menu_trigger(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern int native_tray_icon_get_icon_position(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern native_rectangle_t native_tray_icon_get_bounds(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern native_size_t native_tray_icon_get_icon_size(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern uint native_tray_icon_get_id(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_tray_icon_add_listener(ulong self, TrayIconEventNativeCallback callback, IntPtr userData, ReleaseUserDataNativeCallback releaseUserData);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_tray_icon_create();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_tray_icon_create_with_tray(IntPtr tray);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_tray_icon_get_context_menu(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong native_tray_icon_get_icon(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_tray_icon_free(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_tray_icon_list_release(ref native_tray_icon_list_t list);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_tray_icon_set_context_menu(ulong self, ulong menu);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_tray_icon_set_context_menu_trigger(ulong self, int trigger);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_tray_icon_set_icon(ulong self, ulong image);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_tray_icon_set_icon_position(ulong self, int position);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_tray_icon_set_icon_size(ulong self, native_size_t size);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_tray_icon_set_icon_template(ulong self, [MarshalAs(UnmanagedType.I1)] bool isIconTemplate);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_tray_icon_set_title(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? title);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_tray_icon_set_tooltip(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? tooltip);
}

