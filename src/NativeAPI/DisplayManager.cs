// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

public sealed partial class DisplayManager
{
    /// <summary>The shared instance backed by the native singleton.</summary>
    public static DisplayManager Shared { get; } = new DisplayManager();

    private DisplayManager() { }

    public Display[] GetAll()
    {
        var rawResult = Interop.native_display_manager_get_all();
        var count = rawResult.displays == IntPtr.Zero ? 0 : checked((int)rawResult.count.Value);
        var items = new Display[count];
        for (var i = 0; i < count; i++)
        {
            items[i] = new Display((ulong)Marshal.ReadInt64(rawResult.displays, i * 8));
        }
        // The handles now belong to `items`; free just the array.
        Interop.native_display_list_release(ref rawResult);
        return items;
    }

    public Display? GetPrimary()
    {
        var rawResult = Interop.native_display_manager_get_primary();
        return rawResult == 0 ? null : new Display(rawResult);
    }

    public Point GetCursorPosition()
    {
        var rawResult = Interop.native_display_manager_get_cursor_position();
        return Point.FromRaw(in rawResult);
    }

    /// <summary>Registers <paramref name="callback"/> for every DisplayEvent this DisplayManager emits.</summary>
    /// <remarks>
    /// The delegate is retained for good: the C ABI keeps the context
    /// pointer but offers no hook to release it, so removing the listener
    /// stops the calls without freeing the delegate.
    /// </remarks>
    public ulong AddListener(Action<DisplayEvent> callback)
    {
        var native = CallbackKeeper.Retain<DisplayEventNativeCallback>((evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = DisplayEvent.FromRaw(Marshal.PtrToStructure<native_display_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        });
        return Interop.native_display_manager_add_listener(native, IntPtr.Zero);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_display_manager_remove_listener(listenerId);
    }

}

internal static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_display_manager_remove_listener(ulong listenerId);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_display_list_t native_display_manager_get_all();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_point_t native_display_manager_get_cursor_position();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_display_manager_add_listener(DisplayEventNativeCallback callback, IntPtr userData);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_display_manager_get_primary();
}

