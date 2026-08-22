// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

public enum ShortcutScope
{
    Global = 0,
    Application = 1,
}

[StructLayout(LayoutKind.Sequential)]
internal struct native_shortcut_options_t
{
    internal IntPtr accelerator;
    internal IntPtr callback;
    internal IntPtr callback_user_data;
    internal IntPtr description;
    internal ShortcutScope scope;
    internal byte enabled;
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
        return new ShortcutOptions(Marshal.PtrToStringUTF8(raw.accelerator), null, Marshal.PtrToStringUTF8(raw.description), raw.scope, raw.enabled != 0);
    }

    internal native_shortcut_options_t ToRaw()
    {
        var raw = new native_shortcut_options_t();
        raw.accelerator = Marshal.StringToCoTaskMemUTF8(Accelerator);
        if (Callback is { } callbackBody)
        {
            var callbackNative = CallbackKeeper.Retain<ShortcutOptionsCallbackNativeCallback>((userData) => callbackBody());
            raw.callback = Marshal.GetFunctionPointerForDelegate(callbackNative);
            raw.callback_user_data = IntPtr.Zero;
        }
        raw.description = Marshal.StringToCoTaskMemUTF8(Description);
        raw.scope = Scope;
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

[StructLayout(LayoutKind.Sequential)]
internal struct native_shortcut_event_t
{
    internal int type;
    internal uint shortcut_id;
    internal IntPtr accelerator;
    internal DataUnion data;

    [StructLayout(LayoutKind.Explicit)]
    internal struct DataUnion
    {
        [FieldOffset(0)] internal RegistrationFailedData registration_failed;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct RegistrationFailedData
    {
        internal IntPtr error_message;
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

[StructLayout(LayoutKind.Sequential)]
internal struct native_shortcut_list_t
{
    internal IntPtr shortcuts;
    internal CLong count;
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
        var nativeCallback = CallbackKeeper.Retain<ShortcutCreateWithIdAndAcceleratorAndCallbackCallbackNativeCallback>((userData) => callback());
        var handle = Interop.native_shortcut_create_with_id_and_accelerator_and_callback(id, accelerator, nativeCallback, IntPtr.Zero);
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
            return rawResult;
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
        var nativeCallback = CallbackKeeper.Retain<ShortcutSetCallbackCallbackNativeCallback>((userData) => callback());
        Interop.native_shortcut_set_callback(NativeHandle, nativeCallback, IntPtr.Zero);
    }

}

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
internal delegate void ShortcutCreateWithIdAndAcceleratorAndCallbackCallbackNativeCallback(IntPtr userData);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
internal delegate void ShortcutEventNativeCallback(IntPtr evt, IntPtr userData);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
internal delegate void ShortcutOptionsCallbackNativeCallback(IntPtr userData);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
internal delegate void ShortcutSetCallbackCallbackNativeCallback(IntPtr userData);

internal static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_shortcut_is_enabled(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_shortcut_get_accelerator(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_shortcut_get_description(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ShortcutScope native_shortcut_get_scope(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern uint native_shortcut_get_id(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_shortcut_create_with_id_and_accelerator_and_callback(uint id, [MarshalAs(UnmanagedType.LPUTF8Str)] string? accelerator, ShortcutCreateWithIdAndAcceleratorAndCallbackCallbackNativeCallback callback, IntPtr callback_user_data);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_shortcut_create_with_id_and_options(uint id, native_shortcut_options_t options);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_shortcut_free(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_shortcut_invoke(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_shortcut_list_release(ref native_shortcut_list_t list);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_shortcut_options_free(ref native_shortcut_options_t value);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_shortcut_set_callback(ulong self, ShortcutSetCallbackCallbackNativeCallback callback, IntPtr callback_user_data);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_shortcut_set_description(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? description);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_shortcut_set_enabled(ulong self, [MarshalAs(UnmanagedType.I1)] bool enabled);
}

