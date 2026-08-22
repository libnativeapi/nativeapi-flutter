// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

/// <summary>Owned handle to a native LaunchAtLogin.</summary>
public sealed partial class LaunchAtLogin : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public LaunchAtLogin(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~LaunchAtLogin() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_launch_at_login_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new LaunchAtLogin; returns null if the native side failed.</summary>
    public static LaunchAtLogin? Create()
    {
        var handle = Interop.native_launch_at_login_create();
        return handle == 0 ? null : new LaunchAtLogin(handle);
    }

    /// <summary>Creates a new LaunchAtLogin; returns null if the native side failed.</summary>
    public static LaunchAtLogin? CreateWithId(string id)
    {
        var handle = Interop.native_launch_at_login_create_with_id(id);
        return handle == 0 ? null : new LaunchAtLogin(handle);
    }

    /// <summary>Creates a new LaunchAtLogin; returns null if the native side failed.</summary>
    public static LaunchAtLogin? CreateWithIdAndDisplayName(string id, string displayName)
    {
        var handle = Interop.native_launch_at_login_create_with_id_and_display_name(id, displayName);
        return handle == 0 ? null : new LaunchAtLogin(handle);
    }

    public static bool IsSupported()
    {
        var rawResult = Interop.native_launch_at_login_is_supported();
        return rawResult;
    }

    public string? Id
    {
        get
        {
            var rawResult = Interop.native_launch_at_login_get_id(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public string? DisplayName
    {
        get
        {
            var rawResult = Interop.native_launch_at_login_get_display_name(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public bool SetDisplayName(string displayName)
    {
        var rawResult = Interop.native_launch_at_login_set_display_name(NativeHandle, displayName);
        return rawResult;
    }

    public bool SetProgram(string executablePath, IReadOnlyList<string> arguments)
    {
        var itemsArguments = Interop.AllocUtf8Array(arguments);
        var blockArguments = Interop.AllocPointerArray(itemsArguments);
        var listArguments = new native_string_list_t { items = blockArguments, count = new CLong(itemsArguments.Length) };
        var rawResult = Interop.native_launch_at_login_set_program(NativeHandle, executablePath, listArguments);
        Interop.FreeUtf8Array(itemsArguments);
        Marshal.FreeHGlobal(blockArguments);
        return rawResult;
    }

    public string? ExecutablePath
    {
        get
        {
            var rawResult = Interop.native_launch_at_login_get_executable_path(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public string[] Arguments
    {
        get
        {
            var rawResult = Interop.native_launch_at_login_get_arguments(NativeHandle);
            return Interop.ConsumeStringList(ref rawResult);
        }
    }

    public bool Enable()
    {
        var rawResult = Interop.native_launch_at_login_enable(NativeHandle);
        return rawResult;
    }

    public bool Disable()
    {
        var rawResult = Interop.native_launch_at_login_disable(NativeHandle);
        return rawResult;
    }

    public bool IsEnabled
    {
        get
        {
            var rawResult = Interop.native_launch_at_login_is_enabled(NativeHandle);
            return rawResult;
        }
    }

}

internal static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_launch_at_login_disable(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_launch_at_login_enable(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_launch_at_login_is_enabled(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_launch_at_login_is_supported();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_launch_at_login_set_display_name(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? displayName);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_launch_at_login_set_program(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? executablePath, native_string_list_t arguments);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_launch_at_login_get_display_name(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_launch_at_login_get_executable_path(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_launch_at_login_get_id(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_string_list_t native_launch_at_login_get_arguments(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_launch_at_login_create();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_launch_at_login_create_with_id([MarshalAs(UnmanagedType.LPUTF8Str)] string? id);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_launch_at_login_create_with_id_and_display_name([MarshalAs(UnmanagedType.LPUTF8Str)] string? id, [MarshalAs(UnmanagedType.LPUTF8Str)] string? displayName);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_launch_at_login_free(ulong handle);
}

