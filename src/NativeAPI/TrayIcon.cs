// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

public enum ContextMenuTrigger
{
    None = 0,
    Clicked = 1,
    RightClicked = 2,
    DoubleClicked = 3,
}

[StructLayout(LayoutKind.Sequential)]
internal struct native_tray_icon_event_t
{
    internal int type;
    internal DataUnion data;

    [StructLayout(LayoutKind.Explicit)]
    internal struct DataUnion
    {
        [FieldOffset(0)] internal ClickedData clicked;
        [FieldOffset(0)] internal RightClickedData right_clicked;
        [FieldOffset(0)] internal DoubleClickedData double_clicked;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct ClickedData
    {
        internal uint tray_icon_id;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct RightClickedData
    {
        internal uint tray_icon_id;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct DoubleClickedData
    {
        internal uint tray_icon_id;
    }
}

/// <summary>One TrayIconEvent, in its concrete form.</summary>
public abstract record TrayIconEvent
{
    private TrayIconEvent() { }

    public sealed record Clicked(uint TrayIconId) : TrayIconEvent;
    public sealed record RightClicked(uint TrayIconId) : TrayIconEvent;
    public sealed record DoubleClicked(uint TrayIconId) : TrayIconEvent;

    internal static TrayIconEvent? FromRaw(in native_tray_icon_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Clicked(raw.data.clicked.tray_icon_id);
            case 1: return new RightClicked(raw.data.right_clicked.tray_icon_id);
            case 2: return new DoubleClicked(raw.data.double_clicked.tray_icon_id);
            default: return null;
        }
    }
}

[StructLayout(LayoutKind.Sequential)]
internal struct native_tray_icon_list_t
{
    internal IntPtr tray_icons;
    internal CLong count;
}

/// <summary>Owned handle to a native TrayIcon.</summary>
public sealed partial class TrayIcon : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public TrayIcon(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~TrayIcon() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_tray_icon_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new TrayIcon; returns null if the native side failed.</summary>
    public static TrayIcon? Create()
    {
        var handle = Interop.native_tray_icon_create();
        return handle == 0 ? null : new TrayIcon(handle);
    }

    /// <summary>Creates a new TrayIcon; returns null if the native side failed.</summary>
    public static TrayIcon? CreateWithTray(IntPtr tray)
    {
        var handle = Interop.native_tray_icon_create_with_tray(tray);
        return handle == 0 ? null : new TrayIcon(handle);
    }

    public uint GetId()
    {
        var rawResult = Interop.native_tray_icon_get_id(NativeHandle);
        return rawResult;
    }

    public void SetIcon(Image? image)
    {
        Interop.native_tray_icon_set_icon(NativeHandle, image?.NativeHandle ?? 0);
    }

    public Image? Icon
    {
        get
        {
            var rawResult = Interop.native_tray_icon_get_icon(NativeHandle);
            return rawResult == 0 ? null : new Image(rawResult);
        }
    }

    public void SetTitle(string? title)
    {
        Interop.native_tray_icon_set_title(NativeHandle, title);
    }

    public string? GetTitle()
    {
        var rawResult = Interop.native_tray_icon_get_title(NativeHandle);
        return Interop.ConsumeString(rawResult);
    }

    public void SetTooltip(string? tooltip)
    {
        Interop.native_tray_icon_set_tooltip(NativeHandle, tooltip);
    }

    public string? GetTooltip()
    {
        var rawResult = Interop.native_tray_icon_get_tooltip(NativeHandle);
        return Interop.ConsumeString(rawResult);
    }

    public void SetContextMenu(Menu? menu)
    {
        Interop.native_tray_icon_set_context_menu(NativeHandle, menu?.NativeHandle ?? 0);
    }

    public Menu? GetContextMenu()
    {
        var rawResult = Interop.native_tray_icon_get_context_menu(NativeHandle);
        return rawResult == 0 ? null : new Menu(rawResult);
    }

    public void SetContextMenuTrigger(ContextMenuTrigger trigger)
    {
        Interop.native_tray_icon_set_context_menu_trigger(NativeHandle, trigger);
    }

    public ContextMenuTrigger GetContextMenuTrigger()
    {
        var rawResult = Interop.native_tray_icon_get_context_menu_trigger(NativeHandle);
        return rawResult;
    }

    public Rectangle GetBounds()
    {
        var rawResult = Interop.native_tray_icon_get_bounds(NativeHandle);
        return Rectangle.FromRaw(in rawResult);
    }

    public bool SetVisible(bool visible)
    {
        var rawResult = Interop.native_tray_icon_set_visible(NativeHandle, visible);
        return rawResult;
    }

    public bool IsVisible()
    {
        var rawResult = Interop.native_tray_icon_is_visible(NativeHandle);
        return rawResult;
    }

    public bool OpenContextMenu()
    {
        var rawResult = Interop.native_tray_icon_open_context_menu(NativeHandle);
        return rawResult;
    }

    public bool CloseContextMenu()
    {
        var rawResult = Interop.native_tray_icon_close_context_menu(NativeHandle);
        return rawResult;
    }

    /// <summary>Platform-specific native object behind this handle.</summary>
    public IntPtr NativeObject => Interop.native_tray_icon_get_native_object(NativeHandle);

    /// <summary>Registers <paramref name="callback"/> for every TrayIconEvent this TrayIcon emits.</summary>
    /// <remarks>
    /// The delegate is retained for good: the C ABI keeps the context
    /// pointer but offers no hook to release it, so removing the listener
    /// stops the calls without freeing the delegate.
    /// </remarks>
    public ulong AddListener(Action<TrayIconEvent> callback)
    {
        var native = CallbackKeeper.Retain<TrayIconEventNativeCallback>((evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = TrayIconEvent.FromRaw(Marshal.PtrToStructure<native_tray_icon_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        });
        return Interop.native_tray_icon_add_listener(NativeHandle, native, IntPtr.Zero);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_tray_icon_remove_listener(NativeHandle, listenerId);
    }

}

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
internal delegate void TrayIconEventNativeCallback(IntPtr evt, IntPtr userData);

internal static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_tray_icon_close_context_menu(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_tray_icon_is_visible(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_tray_icon_open_context_menu(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_tray_icon_remove_listener(ulong self, ulong listenerId);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_tray_icon_set_visible(ulong self, [MarshalAs(UnmanagedType.I1)] bool visible);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ContextMenuTrigger native_tray_icon_get_context_menu_trigger(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_tray_icon_get_native_object(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_tray_icon_get_title(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_tray_icon_get_tooltip(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_rectangle_t native_tray_icon_get_bounds(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern uint native_tray_icon_get_id(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_tray_icon_add_listener(ulong self, TrayIconEventNativeCallback callback, IntPtr userData);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_tray_icon_create();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_tray_icon_create_with_tray(IntPtr tray);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_tray_icon_get_context_menu(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_tray_icon_get_icon(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_tray_icon_free(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_tray_icon_list_release(ref native_tray_icon_list_t list);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_tray_icon_set_context_menu(ulong self, ulong menu);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_tray_icon_set_context_menu_trigger(ulong self, ContextMenuTrigger trigger);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_tray_icon_set_icon(ulong self, ulong image);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_tray_icon_set_title(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? title);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_tray_icon_set_tooltip(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? tooltip);
}

