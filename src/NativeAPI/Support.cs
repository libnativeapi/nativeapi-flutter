// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

internal static class Libraries
{
    internal const string NativeApi = "nativeapi";
}

/// <summary>
/// Keeps callback delegates alive for the lifetime of the process: the C ABI
/// stores the function pointer but offers no hook to release it.
/// </summary>
internal static class CallbackKeeper
{
    private static readonly List<Delegate> Retained = new();

    internal static T Retain<T>(T callback) where T : Delegate
    {
        lock (Retained)
        {
            Retained.Add(callback);
        }
        return callback;
    }
}

[StructLayout(LayoutKind.Sequential)]
internal struct native_string_list_t
{
    internal IntPtr items;
    internal CLong count;
}

[StructLayout(LayoutKind.Sequential)]
internal struct native_string_map_t
{
    internal IntPtr keys;
    internal IntPtr values;
    internal CLong count;
}

internal static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void free_c_str(IntPtr str);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_string_list_free(ref native_string_list_t list);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_string_map_free(ref native_string_map_t map);

    /// <summary>Reads an owned C string and frees it.</summary>
    internal static string? ConsumeString(IntPtr value)
    {
        if (value == IntPtr.Zero)
        {
            return null;
        }
        try
        {
            return Marshal.PtrToStringUTF8(value);
        }
        finally
        {
            free_c_str(value);
        }
    }

    /// <summary>Reads an owned C string list and frees it.</summary>
    internal static string[] ConsumeStringList(ref native_string_list_t list)
    {
        var count = list.items == IntPtr.Zero ? 0 : checked((int)list.count.Value);
        var items = new string[count];
        for (var i = 0; i < count; i++)
        {
            var ptr = Marshal.ReadIntPtr(list.items, i * IntPtr.Size);
            items[i] = ptr == IntPtr.Zero ? string.Empty : Marshal.PtrToStringUTF8(ptr) ?? string.Empty;
        }
        native_string_list_free(ref list);
        return items;
    }

    /// <summary>Reads an owned C string map and frees it.</summary>
    internal static Dictionary<string, string> ConsumeStringMap(ref native_string_map_t map)
    {
        var count = map.keys == IntPtr.Zero || map.values == IntPtr.Zero
            ? 0
            : checked((int)map.count.Value);
        var entries = new Dictionary<string, string>(count);
        for (var i = 0; i < count; i++)
        {
            var keyPtr = Marshal.ReadIntPtr(map.keys, i * IntPtr.Size);
            if (keyPtr == IntPtr.Zero)
            {
                continue;
            }
            var valuePtr = Marshal.ReadIntPtr(map.values, i * IntPtr.Size);
            var value = valuePtr == IntPtr.Zero ? string.Empty : Marshal.PtrToStringUTF8(valuePtr) ?? string.Empty;
            entries[Marshal.PtrToStringUTF8(keyPtr) ?? string.Empty] = value;
        }
        native_string_map_free(ref map);
        return entries;
    }

    /// <summary>Copies strings into unmanaged UTF-8 buffers.</summary>
    internal static IntPtr[] AllocUtf8Array(IReadOnlyList<string> values)
    {
        var ptrs = new IntPtr[values.Count];
        for (var i = 0; i < values.Count; i++)
        {
            ptrs[i] = Marshal.StringToCoTaskMemUTF8(values[i]);
        }
        return ptrs;
    }

    /// <summary>Copies a pointer array into one unmanaged block.</summary>
    internal static IntPtr AllocPointerArray(IntPtr[] values)
    {
        var block = Marshal.AllocHGlobal(IntPtr.Size * Math.Max(values.Length, 1));
        Marshal.Copy(values, 0, block, values.Length);
        return block;
    }

    internal static void FreeUtf8Array(IntPtr[] values)
    {
        foreach (var ptr in values)
        {
            if (ptr != IntPtr.Zero)
            {
                Marshal.FreeCoTaskMem(ptr);
            }
        }
    }
}
