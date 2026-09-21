// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

/// <summary>Owned handle to a native WindowShape.</summary>
public sealed partial class WindowShape : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public WindowShape(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~WindowShape() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_window_shape_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new WindowShape; returns null if the native side failed.</summary>
    public static WindowShape? Create()
    {
        var handle = Interop.native_window_shape_create();
        return handle == 0 ? null : new WindowShape(handle);
    }

    public bool AddPoint(Point point)
    {
        var rawPoint = point.ToRaw();
        var rawResult = Interop.native_window_shape_add_point(NativeHandle, rawPoint);
        return rawResult;
    }

    public void Clear()
    {
        Interop.native_window_shape_clear(NativeHandle);
    }

    public ulong PointCount
    {
        get
        {
            var rawResult = Interop.native_window_shape_get_point_count(NativeHandle);
            return (ulong)rawResult.Value;
        }
    }

    public Point GetPointAt(ulong index)
    {
        var rawResult = Interop.native_window_shape_get_point_at(NativeHandle, new CULong(checked((nuint)index)));
        return Point.FromRaw(in rawResult);
    }

}

