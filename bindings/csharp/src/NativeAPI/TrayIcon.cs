// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public enum ContextMenuTrigger
{
    None = 0,
    Clicked = 1,
    RightClicked = 2,
    DoubleClicked = 3,
}

public enum TrayIconPosition
{
    Left = 0,
    Right = 1,
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

    public void SetIconTemplate(bool isIconTemplate)
    {
        Interop.native_tray_icon_set_icon_template(NativeHandle, isIconTemplate);
    }

    public bool IsIconTemplate
    {
        get
        {
            var rawResult = Interop.native_tray_icon_is_icon_template(NativeHandle);
            return rawResult;
        }
    }

    public void SetIconSize(Size size)
    {
        var rawSize = size.ToRaw();
        Interop.native_tray_icon_set_icon_size(NativeHandle, rawSize);
    }

    public Size IconSize
    {
        get
        {
            var rawResult = Interop.native_tray_icon_get_icon_size(NativeHandle);
            return Size.FromRaw(in rawResult);
        }
    }

    public void SetIconPosition(TrayIconPosition position)
    {
        Interop.native_tray_icon_set_icon_position(NativeHandle, (int)position);
    }

    public TrayIconPosition IconPosition
    {
        get
        {
            var rawResult = Interop.native_tray_icon_get_icon_position(NativeHandle);
            return (TrayIconPosition)rawResult;
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
        Interop.native_tray_icon_set_context_menu_trigger(NativeHandle, (int)trigger);
    }

    public ContextMenuTrigger GetContextMenuTrigger()
    {
        var rawResult = Interop.native_tray_icon_get_context_menu_trigger(NativeHandle);
        return (ContextMenuTrigger)rawResult;
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
    /// The delegate is kept alive until the listener is removed or its emitter
    /// destroyed; the core releases it then.
    /// </remarks>
    public ulong AddListener(Action<TrayIconEvent> callback)
    {
        TrayIconEventNativeCallback native = (evt, userData) =>
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
        };
        return Interop.native_tray_icon_add_listener(NativeHandle, native, CallbackKeeper.Hold(native), CallbackKeeper.Release);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_tray_icon_remove_listener(NativeHandle, listenerId);
    }

}

