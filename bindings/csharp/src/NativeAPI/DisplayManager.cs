// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

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
    /// The delegate is kept alive until the listener is removed or its emitter
    /// destroyed; the core releases it then.
    /// </remarks>
    public ulong AddListener(Action<DisplayEvent> callback)
    {
        DisplayEventNativeCallback native = (evt, userData) =>
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
        };
        return Interop.native_display_manager_add_listener(native, CallbackKeeper.Hold(native), CallbackKeeper.Release);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_display_manager_remove_listener(listenerId);
    }

}

