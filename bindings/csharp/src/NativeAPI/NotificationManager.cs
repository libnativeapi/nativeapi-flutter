// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

/// <summary>One NotificationEvent, in its concrete form.</summary>
public abstract record NotificationEvent
{
    private NotificationEvent() { }

    public sealed record Activated(string? Argument) : NotificationEvent;

    internal static NotificationEvent? FromRaw(in native_notification_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Activated(Marshal.PtrToStringUTF8(raw.data.activated.argument));
            default: return null;
        }
    }
}

public sealed partial class NotificationManager
{
    /// <summary>The shared instance backed by the native singleton.</summary>
    public static NotificationManager Shared { get; } = new NotificationManager();

    private NotificationManager() { }

    public bool IsSupported()
    {
        var rawResult = Interop.native_notification_manager_is_supported();
        return rawResult;
    }

    public bool Initialize()
    {
        var rawResult = Interop.native_notification_manager_initialize();
        return rawResult;
    }

    public void Shutdown()
    {
        Interop.native_notification_manager_shutdown();
    }

    public bool Show(string title, string message, string tag, string buttonLabel)
    {
        var rawResult = Interop.native_notification_manager_show(title, message, tag, buttonLabel);
        return rawResult;
    }

    public bool Remove(string tag)
    {
        var rawResult = Interop.native_notification_manager_remove(tag);
        return rawResult;
    }

    public string? GetLastError()
    {
        var rawResult = Interop.native_notification_manager_get_last_error();
        return Interop.ConsumeString(rawResult);
    }

    /// <summary>Registers <paramref name="callback"/> for every NotificationEvent this NotificationManager emits.</summary>
    /// <remarks>
    /// The delegate is kept alive until the listener is removed or its emitter
    /// destroyed; the core releases it then.
    /// </remarks>
    public ulong AddListener(Action<NotificationEvent> callback)
    {
        NotificationEventNativeCallback native = (evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = NotificationEvent.FromRaw(Marshal.PtrToStructure<native_notification_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        };
        return Interop.native_notification_manager_add_listener(native, CallbackKeeper.Hold(native), CallbackKeeper.Release);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_notification_manager_remove_listener(listenerId);
    }

}

