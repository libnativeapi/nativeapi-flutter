// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

/// <summary>Owned handle to a native WindowShadow.</summary>
public sealed partial class WindowShadow : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public WindowShadow(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~WindowShadow() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_window_shadow_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new WindowShadow; returns null if the native side failed.</summary>
    public static WindowShadow? Create()
    {
        var handle = Interop.native_window_shadow_create();
        return handle == 0 ? null : new WindowShadow(handle);
    }

    public void SetColor(Color color)
    {
        var rawColor = color.ToRaw();
        Interop.native_window_shadow_set_color(NativeHandle, rawColor);
    }

    public Color Color
    {
        get
        {
            var rawResult = Interop.native_window_shadow_get_color(NativeHandle);
            return Color.FromRaw(in rawResult);
        }
    }

    public bool SetBlurRadius(double radius)
    {
        var rawResult = Interop.native_window_shadow_set_blur_radius(NativeHandle, radius);
        return rawResult;
    }

    public double BlurRadius
    {
        get
        {
            var rawResult = Interop.native_window_shadow_get_blur_radius(NativeHandle);
            return rawResult;
        }
    }

    public bool SetOffset(Point offset)
    {
        var rawOffset = offset.ToRaw();
        var rawResult = Interop.native_window_shadow_set_offset(NativeHandle, rawOffset);
        return rawResult;
    }

    public Point Offset
    {
        get
        {
            var rawResult = Interop.native_window_shadow_get_offset(NativeHandle);
            return Point.FromRaw(in rawResult);
        }
    }

}

