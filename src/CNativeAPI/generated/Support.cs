// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace CNativeAPI;

public static class Libraries
{
    public const string NativeApi = "nativeapi";
}

/// <summary>
/// Keeps callback delegates alive for the lifetime of the process: the C ABI
/// stores the function pointer but offers no hook to release it.
/// </summary>
public static class CallbackKeeper
{
    private static readonly List<Delegate> Retained = new();

    public static T Retain<T>(T callback) where T : Delegate
    {
        lock (Retained)
        {
            Retained.Add(callback);
        }
        return callback;
    }
}

[StructLayout(LayoutKind.Sequential)]
public struct native_string_list_t
{
    public IntPtr items;
    public CLong count;
}

[StructLayout(LayoutKind.Sequential)]
public struct native_string_map_t
{
    public IntPtr keys;
    public IntPtr values;
    public CLong count;
}

public static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void free_c_str(IntPtr str);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_string_list_free(ref native_string_list_t list);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_string_map_free(ref native_string_map_t map);

    /// <summary>Reads an owned C string and frees it.</summary>
    public static string? ConsumeString(IntPtr value)
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
    public static string[] ConsumeStringList(ref native_string_list_t list)
    {
        var items = ReadStringList(in list);
        native_string_list_free(ref list);
        return items;
    }

    /// <summary>Copies a borrowed C string list, leaving it to its owner.</summary>
    public static string[] ReadStringList(in native_string_list_t list)
    {
        var count = list.items == IntPtr.Zero ? 0 : checked((int)list.count.Value);
        var items = new string[count];
        for (var i = 0; i < count; i++)
        {
            var ptr = Marshal.ReadIntPtr(list.items, i * IntPtr.Size);
            items[i] = ptr == IntPtr.Zero ? string.Empty : Marshal.PtrToStringUTF8(ptr) ?? string.Empty;
        }
        return items;
    }

    /// <summary>Reads an owned C string map and frees it.</summary>
    public static Dictionary<string, string> ConsumeStringMap(ref native_string_map_t map)
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
    public static IntPtr[] AllocUtf8Array(IReadOnlyList<string> values)
    {
        var ptrs = new IntPtr[values.Count];
        for (var i = 0; i < values.Count; i++)
        {
            ptrs[i] = Marshal.StringToCoTaskMemUTF8(values[i]);
        }
        return ptrs;
    }

    /// <summary>Copies a pointer array into one unmanaged block.</summary>
    public static IntPtr AllocPointerArray(IntPtr[] values)
    {
        var block = Marshal.AllocHGlobal(IntPtr.Size * Math.Max(values.Length, 1));
        Marshal.Copy(values, 0, block, values.Length);
        return block;
    }

    public static void FreeUtf8Array(IntPtr[] values)
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
