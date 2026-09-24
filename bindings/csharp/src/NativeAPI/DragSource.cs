// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public enum DragOperation
{
    None = 0,
    Copy = 1,
    Move = 2,
    Link = 3,
}

/// <summary>One DragSourceEvent, in its concrete form.</summary>
public abstract record DragSourceEvent
{
    private DragSourceEvent() { }

    public sealed record Ended(uint WindowId, Point Position, DragOperation Operation) : DragSourceEvent;

    internal static DragSourceEvent? FromRaw(in native_drag_source_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Ended(raw.window_id, Point.FromRaw(in raw.position), (DragOperation)raw.data.ended.operation);
            default: return null;
        }
    }
}

/// <summary>Owned handle to a native DragSource.</summary>
public sealed partial class DragSource : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public DragSource(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~DragSource() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_drag_source_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new DragSource; returns null if the native side failed.</summary>
    public static DragSource? Create()
    {
        var handle = Interop.native_drag_source_create();
        return handle == 0 ? null : new DragSource(handle);
    }

    public static bool IsSupported()
    {
        var rawResult = Interop.native_drag_source_is_supported();
        return rawResult;
    }

    public void SetFilePaths(IReadOnlyList<string> filePaths)
    {
        var itemsFilePaths = Interop.AllocUtf8Array(filePaths);
        var blockFilePaths = Interop.AllocPointerArray(itemsFilePaths);
        var listFilePaths = new native_string_list_t { items = blockFilePaths, count = new CLong(itemsFilePaths.Length) };
        Interop.native_drag_source_set_file_paths(NativeHandle, listFilePaths);
        Interop.FreeUtf8Array(itemsFilePaths);
        Marshal.FreeHGlobal(blockFilePaths);
    }

    public string[] FilePaths
    {
        get
        {
            var rawResult = Interop.native_drag_source_get_file_paths(NativeHandle);
            return Interop.ConsumeStringList(ref rawResult);
        }
    }

    public void SetText(string? text)
    {
        Interop.native_drag_source_set_text(NativeHandle, text);
    }

    public string? Text
    {
        get
        {
            var rawResult = Interop.native_drag_source_get_text(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public void SetImage(Image? image)
    {
        Interop.native_drag_source_set_image(NativeHandle, image?.NativeHandle ?? 0);
    }

    public Image? Image
    {
        get
        {
            var rawResult = Interop.native_drag_source_get_image(NativeHandle);
            return rawResult == 0 ? null : new Image(rawResult);
        }
    }

    public void SetDragOperation(DragOperation operation)
    {
        Interop.native_drag_source_set_drag_operation(NativeHandle, (int)operation);
    }

    public DragOperation DragOperation
    {
        get
        {
            var rawResult = Interop.native_drag_source_get_drag_operation(NativeHandle);
            return (DragOperation)rawResult;
        }
    }

    public bool StartDragging(Window? window)
    {
        var rawResult = Interop.native_drag_source_start_dragging(NativeHandle, window?.NativeHandle ?? 0);
        return rawResult;
    }

    public bool IsDragging
    {
        get
        {
            var rawResult = Interop.native_drag_source_is_dragging(NativeHandle);
            return rawResult;
        }
    }

    /// <summary>Registers <paramref name="callback"/> for every DragSourceEvent this DragSource emits.</summary>
    /// <remarks>
    /// The delegate is retained for good: the C ABI keeps the context
    /// pointer but offers no hook to release it, so removing the listener
    /// stops the calls without freeing the delegate.
    /// </remarks>
    public ulong AddListener(Action<DragSourceEvent> callback)
    {
        var native = CallbackKeeper.Retain<DragSourceEventNativeCallback>((evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = DragSourceEvent.FromRaw(Marshal.PtrToStructure<native_drag_source_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        });
        return Interop.native_drag_source_add_listener(NativeHandle, native, IntPtr.Zero);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_drag_source_remove_listener(NativeHandle, listenerId);
    }

}

