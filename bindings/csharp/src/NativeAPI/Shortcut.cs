// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public enum ShortcutScope
{
    Global = 0,
    Application = 1,
}

public struct ShortcutOptions
{
    public string? Accelerator;
    public Action? Callback;
    public string? Description;
    public ShortcutScope Scope;
    public bool Enabled;

    public ShortcutOptions(string? accelerator, Action? callback, string? description, ShortcutScope scope, bool enabled)
    {
        Accelerator = accelerator;
        Callback = callback;
        Description = description;
        Scope = scope;
        Enabled = enabled;
    }

    internal static ShortcutOptions FromRaw(in native_shortcut_options_t raw)
    {
        return new ShortcutOptions(Marshal.PtrToStringUTF8(raw.accelerator), null, Marshal.PtrToStringUTF8(raw.description), (ShortcutScope)raw.scope, raw.enabled != 0);
    }

    internal native_shortcut_options_t ToRaw()
    {
        var raw = new native_shortcut_options_t();
        raw.accelerator = Marshal.StringToCoTaskMemUTF8(Accelerator);
        if (Callback is { } callbackBody)
        {
            ShortcutOptionsCallbackNativeCallback callbackNative = (userData) => callbackBody();
            raw.callback = Marshal.GetFunctionPointerForDelegate(callbackNative);
            raw.callback_user_data = CallbackKeeper.Hold(callbackNative);
            raw.callback_release_user_data = CallbackKeeper.ReleasePointer;
        }
        raw.description = Marshal.StringToCoTaskMemUTF8(Description);
        raw.scope = (int)Scope;
        raw.enabled = (byte)(Enabled ? 1 : 0);
        return raw;
    }

    internal static void ReleaseRaw(ref native_shortcut_options_t raw)
    {
        Marshal.FreeCoTaskMem(raw.accelerator);
        raw.accelerator = IntPtr.Zero;
        Marshal.FreeCoTaskMem(raw.description);
        raw.description = IntPtr.Zero;
    }
}

/// <summary>One ShortcutEvent, in its concrete form.</summary>
public abstract record ShortcutEvent
{
    private ShortcutEvent() { }

    public sealed record Activated(uint ShortcutId, string? Accelerator) : ShortcutEvent;
    public sealed record Registered(uint ShortcutId, string? Accelerator) : ShortcutEvent;
    public sealed record Unregistered(uint ShortcutId, string? Accelerator) : ShortcutEvent;
    public sealed record RegistrationFailed(uint ShortcutId, string? Accelerator, string? ErrorMessage) : ShortcutEvent;

    internal static ShortcutEvent? FromRaw(in native_shortcut_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Activated(raw.shortcut_id, Marshal.PtrToStringUTF8(raw.accelerator));
            case 1: return new Registered(raw.shortcut_id, Marshal.PtrToStringUTF8(raw.accelerator));
            case 2: return new Unregistered(raw.shortcut_id, Marshal.PtrToStringUTF8(raw.accelerator));
            case 3: return new RegistrationFailed(raw.shortcut_id, Marshal.PtrToStringUTF8(raw.accelerator), Marshal.PtrToStringUTF8(raw.data.registration_failed.error_message));
            default: return null;
        }
    }
}

/// <summary>Owned handle to a native Shortcut.</summary>
public sealed partial class Shortcut : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public Shortcut(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~Shortcut() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_shortcut_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new Shortcut; returns null if the native side failed.</summary>
    public static Shortcut? CreateWithIdAndOptions(uint id, ShortcutOptions options)
    {
        var rawOptions = options.ToRaw();
        var handle = Interop.native_shortcut_create_with_id_and_options(id, rawOptions);
        ShortcutOptions.ReleaseRaw(ref rawOptions);
        return handle == 0 ? null : new Shortcut(handle);
    }

    /// <summary>Creates a new Shortcut; returns null if the native side failed.</summary>
    public static Shortcut? CreateWithIdAndAcceleratorAndCallback(uint id, string accelerator, Action callback)
    {
        ShortcutCreateWithIdAndAcceleratorAndCallbackCallbackNativeCallback nativeCallback = (userData) => callback();
        var handle = Interop.native_shortcut_create_with_id_and_accelerator_and_callback(id, accelerator, nativeCallback, CallbackKeeper.Hold(nativeCallback), CallbackKeeper.Release);
        return handle == 0 ? null : new Shortcut(handle);
    }

    public uint Id
    {
        get
        {
            var rawResult = Interop.native_shortcut_get_id(NativeHandle);
            return rawResult;
        }
    }

    public string? Accelerator
    {
        get
        {
            var rawResult = Interop.native_shortcut_get_accelerator(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public string? Description
    {
        get
        {
            var rawResult = Interop.native_shortcut_get_description(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public void SetDescription(string description)
    {
        Interop.native_shortcut_set_description(NativeHandle, description);
    }

    public ShortcutScope Scope
    {
        get
        {
            var rawResult = Interop.native_shortcut_get_scope(NativeHandle);
            return (ShortcutScope)rawResult;
        }
    }

    public void SetEnabled(bool enabled)
    {
        Interop.native_shortcut_set_enabled(NativeHandle, enabled);
    }

    public bool IsEnabled
    {
        get
        {
            var rawResult = Interop.native_shortcut_is_enabled(NativeHandle);
            return rawResult;
        }
    }

    public void Invoke()
    {
        Interop.native_shortcut_invoke(NativeHandle);
    }

    public void SetCallback(Action callback)
    {
        ShortcutSetCallbackCallbackNativeCallback nativeCallback = (userData) => callback();
        Interop.native_shortcut_set_callback(NativeHandle, nativeCallback, CallbackKeeper.Hold(nativeCallback), CallbackKeeper.Release);
    }

}

