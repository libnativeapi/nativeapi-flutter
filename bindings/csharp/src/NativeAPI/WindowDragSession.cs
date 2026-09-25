// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

/// <summary>One WindowDragEvent, in its concrete form.</summary>
public abstract record WindowDragEvent
{
    private WindowDragEvent() { }

    public sealed record Moved(uint WindowId, Point CursorPosition) : WindowDragEvent;
    public sealed record Ended(uint WindowId, Point CursorPosition) : WindowDragEvent;
    public sealed record Cancelled(uint WindowId, Point CursorPosition) : WindowDragEvent;

    internal static WindowDragEvent? FromRaw(in native_window_drag_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Moved(raw.window_id, Point.FromRaw(in raw.cursor_position));
            case 1: return new Ended(raw.window_id, Point.FromRaw(in raw.cursor_position));
            case 2: return new Cancelled(raw.window_id, Point.FromRaw(in raw.cursor_position));
            default: return null;
        }
    }
}

/// <summary>Owned handle to a native WindowDragSession.</summary>
public sealed partial class WindowDragSession : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public WindowDragSession(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~WindowDragSession() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_window_drag_session_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new WindowDragSession; returns null if the native side failed.</summary>
    public static WindowDragSession? Create()
    {
        var handle = Interop.native_window_drag_session_create();
        return handle == 0 ? null : new WindowDragSession(handle);
    }

    public bool Start(Window? window, Point anchor)
    {
        var rawAnchor = anchor.ToRaw();
        var rawResult = Interop.native_window_drag_session_start(NativeHandle, window?.NativeHandle ?? 0, rawAnchor);
        return rawResult;
    }

    public void Cancel()
    {
        Interop.native_window_drag_session_cancel(NativeHandle);
    }

    public bool IsActive
    {
        get
        {
            var rawResult = Interop.native_window_drag_session_is_active(NativeHandle);
            return rawResult;
        }
    }

    public uint WindowId
    {
        get
        {
            var rawResult = Interop.native_window_drag_session_get_window_id(NativeHandle);
            return rawResult;
        }
    }

    public Point Anchor
    {
        get
        {
            var rawResult = Interop.native_window_drag_session_get_anchor(NativeHandle);
            return Point.FromRaw(in rawResult);
        }
    }

    /// <summary>Registers <paramref name="callback"/> for every WindowDragEvent this WindowDragSession emits.</summary>
    /// <remarks>
    /// The delegate is kept alive until the listener is removed or its emitter
    /// destroyed; the core releases it then.
    /// </remarks>
    public ulong AddListener(Action<WindowDragEvent> callback)
    {
        WindowDragEventNativeCallback native = (evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = WindowDragEvent.FromRaw(Marshal.PtrToStructure<native_window_drag_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        };
        return Interop.native_window_drag_session_add_listener(NativeHandle, native, CallbackKeeper.Hold(native), CallbackKeeper.Release);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_window_drag_session_remove_listener(NativeHandle, listenerId);
    }

}

