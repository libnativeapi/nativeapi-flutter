// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

/// <summary>Owned handle to a native Preferences.</summary>
public sealed partial class Preferences : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public Preferences(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~Preferences() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_preferences_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new Preferences; returns null if the native side failed.</summary>
    public static Preferences? Create()
    {
        var handle = Interop.native_preferences_create();
        return handle == 0 ? null : new Preferences(handle);
    }

    /// <summary>Creates a new Preferences; returns null if the native side failed.</summary>
    public static Preferences? CreateWithScope(string scope)
    {
        var handle = Interop.native_preferences_create_with_scope(scope);
        return handle == 0 ? null : new Preferences(handle);
    }

    public bool Set(string key, string value)
    {
        var rawResult = Interop.native_preferences_set(NativeHandle, key, value);
        return rawResult;
    }

    public string? Get(string key, string defaultValue)
    {
        var rawResult = Interop.native_preferences_get(NativeHandle, key, defaultValue);
        return Interop.ConsumeString(rawResult);
    }

    public bool Remove(string key)
    {
        var rawResult = Interop.native_preferences_remove(NativeHandle, key);
        return rawResult;
    }

    public bool Clear()
    {
        var rawResult = Interop.native_preferences_clear(NativeHandle);
        return rawResult;
    }

    public bool Contains(string key)
    {
        var rawResult = Interop.native_preferences_contains(NativeHandle, key);
        return rawResult;
    }

    public string[] Keys
    {
        get
        {
            var rawResult = Interop.native_preferences_get_keys(NativeHandle);
            return Interop.ConsumeStringList(ref rawResult);
        }
    }

    public ulong Size
    {
        get
        {
            var rawResult = Interop.native_preferences_get_size(NativeHandle);
            return (ulong)rawResult.Value;
        }
    }

    public Dictionary<string, string> All
    {
        get
        {
            var rawResult = Interop.native_preferences_get_all(NativeHandle);
            return Interop.ConsumeStringMap(ref rawResult);
        }
    }

    public string? Scope
    {
        get
        {
            var rawResult = Interop.native_preferences_get_scope(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

}

internal static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_preferences_clear(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_preferences_contains(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? key);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_preferences_remove(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? key);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_preferences_set(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? key, [MarshalAs(UnmanagedType.LPUTF8Str)] string? value);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern CULong native_preferences_get_size(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_preferences_get(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? key, [MarshalAs(UnmanagedType.LPUTF8Str)] string? defaultValue);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_preferences_get_scope(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_string_list_t native_preferences_get_keys(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_string_map_t native_preferences_get_all(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_preferences_create();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_preferences_create_with_scope([MarshalAs(UnmanagedType.LPUTF8Str)] string? scope);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_preferences_free(ulong handle);
}

