// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

public enum DisplayOrientation
{
    Portrait = 0,
    Landscape = 90,
    PortraitFlipped = 180,
    LandscapeFlipped = 270,
}

[StructLayout(LayoutKind.Sequential)]
internal struct native_display_event_t
{
    internal int type;
    internal ulong display;
    internal DataUnion data;

    [StructLayout(LayoutKind.Explicit)]
    internal struct DataUnion
    {
        [FieldOffset(0)] internal ChangedData changed;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct ChangedData
    {
        internal ulong old_display;
        internal ulong new_display;
    }
}

/// <summary>One DisplayEvent, in its concrete form.</summary>
public abstract record DisplayEvent
{
    private DisplayEvent() { }

    public sealed record Added(Display Display) : DisplayEvent;
    public sealed record Removed(Display Display) : DisplayEvent;
    public sealed record Changed(Display Display, Display OldDisplay, Display NewDisplay) : DisplayEvent;

    internal static DisplayEvent? FromRaw(in native_display_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Added(new Display(raw.display, ownsHandle: false));
            case 1: return new Removed(new Display(raw.display, ownsHandle: false));
            case 2: return new Changed(new Display(raw.display, ownsHandle: false), new Display(raw.data.changed.old_display, ownsHandle: false), new Display(raw.data.changed.new_display, ownsHandle: false));
            default: return null;
        }
    }
}

[StructLayout(LayoutKind.Sequential)]
internal struct native_display_list_t
{
    internal IntPtr displays;
    internal CLong count;
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
    public static Display? Create()
    {
        var handle = Interop.native_display_create();
        return handle == 0 ? null : new Display(handle);
    }

    /// <summary>Creates a new Display; returns null if the native side failed.</summary>
    public static Display? CreateWithDisplay(IntPtr display)
    {
        var handle = Interop.native_display_create_with_display(display);
        return handle == 0 ? null : new Display(handle);
    }

    public string? Id
    {
        get
        {
            var rawResult = Interop.native_display_get_id(NativeHandle);
            return Interop.ConsumeString(rawResult);
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
            return rawResult;
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

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
internal delegate void DisplayEventNativeCallback(IntPtr evt, IntPtr userData);

internal static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_display_is_primary(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern DisplayOrientation native_display_get_orientation(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_display_get_id(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_display_get_name(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_display_get_native_object(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern double native_display_get_scale_factor(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int native_display_get_bit_depth(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int native_display_get_refresh_rate(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_point_t native_display_get_position(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_rectangle_t native_display_get_work_area(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_size_t native_display_get_size(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_display_create();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_display_create_with_display(IntPtr display);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_display_free(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_display_list_release(ref native_display_list_t list);
}

