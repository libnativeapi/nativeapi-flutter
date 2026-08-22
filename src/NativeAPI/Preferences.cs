// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

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

