// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

public sealed partial class TrayManager
{
    /// <summary>The shared instance backed by the native singleton.</summary>
    public static TrayManager Shared { get; } = new TrayManager();

    private TrayManager() { }

    public bool IsSupported()
    {
        var rawResult = Interop.native_tray_manager_is_supported();
        return rawResult;
    }

    public TrayIcon? Get(uint id)
    {
        var rawResult = Interop.native_tray_manager_get(id);
        return rawResult == 0 ? null : new TrayIcon(rawResult);
    }

    public TrayIcon[] GetAll()
    {
        var rawResult = Interop.native_tray_manager_get_all();
        var count = rawResult.tray_icons == IntPtr.Zero ? 0 : checked((int)rawResult.count.Value);
        var items = new TrayIcon[count];
        for (var i = 0; i < count; i++)
        {
            items[i] = new TrayIcon((ulong)Marshal.ReadInt64(rawResult.tray_icons, i * 8));
        }
        // The handles now belong to `items`; free just the array.
        Interop.native_tray_icon_list_release(ref rawResult);
        return items;
    }

}

internal static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_tray_manager_is_supported();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_tray_icon_list_t native_tray_manager_get_all();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_tray_manager_get(uint id);
}

