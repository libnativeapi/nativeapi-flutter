// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

/// <summary>One DropTargetEvent, in its concrete form.</summary>
public abstract record DropTargetEvent
{
    private DropTargetEvent() { }

    public sealed record Entered(uint WindowId, Point Position) : DropTargetEvent;
    public sealed record Moved(uint WindowId, Point Position) : DropTargetEvent;
    public sealed record Exited(uint WindowId, Point Position) : DropTargetEvent;
    public sealed record Dropped(uint WindowId, Point Position, string?[] FilePaths, string? Text) : DropTargetEvent;

    internal static DropTargetEvent? FromRaw(in native_drop_target_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Entered(raw.window_id, Point.FromRaw(in raw.position));
            case 1: return new Moved(raw.window_id, Point.FromRaw(in raw.position));
            case 2: return new Exited(raw.window_id, Point.FromRaw(in raw.position));
            case 3: return new Dropped(raw.window_id, Point.FromRaw(in raw.position), Interop.ReadStringList(in raw.data.dropped.file_paths), Marshal.PtrToStringUTF8(raw.data.dropped.text));
            default: return null;
        }
    }
}

/// <summary>Owned handle to a native DropTarget.</summary>
public sealed partial class DropTarget : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public DropTarget(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~DropTarget() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_drop_target_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new DropTarget; returns null if the native side failed.</summary>
    public static DropTarget? Create(Window? window)
    {
        var handle = Interop.native_drop_target_create(window?.NativeHandle ?? 0);
        return handle == 0 ? null : new DropTarget(handle);
    }

    public static bool IsSupported()
    {
        var rawResult = Interop.native_drop_target_is_supported();
        return rawResult;
    }

    public uint WindowId
    {
        get
        {
            var rawResult = Interop.native_drop_target_get_window_id(NativeHandle);
            return rawResult;
        }
    }

    public void SetDropOperation(DragOperation operation)
    {
        Interop.native_drop_target_set_drop_operation(NativeHandle, (int)operation);
    }

    public DragOperation DropOperation
    {
        get
        {
            var rawResult = Interop.native_drop_target_get_drop_operation(NativeHandle);
            return (DragOperation)rawResult;
        }
    }

    public bool IsActive
    {
        get
        {
            var rawResult = Interop.native_drop_target_is_active(NativeHandle);
            return rawResult;
        }
    }

    /// <summary>Registers <paramref name="callback"/> for every DropTargetEvent this DropTarget emits.</summary>
    /// <remarks>
    /// The delegate is retained for good: the C ABI keeps the context
    /// pointer but offers no hook to release it, so removing the listener
    /// stops the calls without freeing the delegate.
    /// </remarks>
    public ulong AddListener(Action<DropTargetEvent> callback)
    {
        var native = CallbackKeeper.Retain<DropTargetEventNativeCallback>((evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = DropTargetEvent.FromRaw(Marshal.PtrToStructure<native_drop_target_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        });
        return Interop.native_drop_target_add_listener(NativeHandle, native, IntPtr.Zero);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_drop_target_remove_listener(NativeHandle, listenerId);
    }

}

