// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public enum DisplayOrientation
{
    Portrait = 0,
    Landscape = 90,
    PortraitFlipped = 180,
    LandscapeFlipped = 270,
}

/// <summary>One DisplayEvent, in its concrete form.</summary>
public abstract record DisplayEvent
{
    private DisplayEvent() { }

    public sealed record Added(Display Display) : DisplayEvent;
    public sealed record Removed(Display Display) : DisplayEvent;
    public sealed record Changed(Display Display) : DisplayEvent;

    internal static DisplayEvent? FromRaw(in native_display_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Added(new Display(raw.display, ownsHandle: false));
            case 1: return new Removed(new Display(raw.display, ownsHandle: false));
            case 2: return new Changed(new Display(raw.display, ownsHandle: false));
            default: return null;
        }
    }
}

/// <summary>Owned handle to a native Display.</summary>
public sealed partial class Display : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public Display(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~Display() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_display_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new Display; returns null if the native side failed.</summary>
    public static Display? Create(IntPtr display)
    {
        var handle = Interop.native_display_create(display);
        return handle == 0 ? null : new Display(handle);
    }

    public uint Id
    {
        get
        {
            var rawResult = Interop.native_display_get_id(NativeHandle);
            return rawResult;
        }
    }

    public string? Name
    {
        get
        {
            var rawResult = Interop.native_display_get_name(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public Point Position
    {
        get
        {
            var rawResult = Interop.native_display_get_position(NativeHandle);
            return Point.FromRaw(in rawResult);
        }
    }

    public Size Size
    {
        get
        {
            var rawResult = Interop.native_display_get_size(NativeHandle);
            return Size.FromRaw(in rawResult);
        }
    }

    public Rectangle WorkArea
    {
        get
        {
            var rawResult = Interop.native_display_get_work_area(NativeHandle);
            return Rectangle.FromRaw(in rawResult);
        }
    }

    public double ScaleFactor
    {
        get
        {
            var rawResult = Interop.native_display_get_scale_factor(NativeHandle);
            return rawResult;
        }
    }

    public bool IsPrimary
    {
        get
        {
            var rawResult = Interop.native_display_is_primary(NativeHandle);
            return rawResult;
        }
    }

    public DisplayOrientation Orientation
    {
        get
        {
            var rawResult = Interop.native_display_get_orientation(NativeHandle);
            return (DisplayOrientation)rawResult;
        }
    }

    public int RefreshRate
    {
        get
        {
            var rawResult = Interop.native_display_get_refresh_rate(NativeHandle);
            return rawResult;
        }
    }

    public int BitDepth
    {
        get
        {
            var rawResult = Interop.native_display_get_bit_depth(NativeHandle);
            return rawResult;
        }
    }

    /// <summary>Platform-specific native object behind this handle.</summary>
    public IntPtr NativeObject => Interop.native_display_get_native_object(NativeHandle);

}

