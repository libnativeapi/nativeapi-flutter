// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

/// <summary>Owned handle to a native MessageDialog.</summary>
public sealed partial class MessageDialog : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public MessageDialog(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~MessageDialog() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_message_dialog_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new MessageDialog; returns null if the native side failed.</summary>
    public static MessageDialog? Create(string title, string message)
    {
        var handle = Interop.native_message_dialog_create(title, message);
        return handle == 0 ? null : new MessageDialog(handle);
    }

    public void SetTitle(string title)
    {
        Interop.native_message_dialog_set_title(NativeHandle, title);
    }

    public string? Title
    {
        get
        {
            var rawResult = Interop.native_message_dialog_get_title(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public void SetMessage(string message)
    {
        Interop.native_message_dialog_set_message(NativeHandle, message);
    }

    public string? Message
    {
        get
        {
            var rawResult = Interop.native_message_dialog_get_message(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public DialogModality Modality
    {
        get
        {
            var rawResult = Interop.native_message_dialog_get_modality(NativeHandle);
            return rawResult;
        }
    }

    public void SetModality(DialogModality modality)
    {
        Interop.native_message_dialog_set_modality(NativeHandle, modality);
    }

    public bool Open()
    {
        var rawResult = Interop.native_message_dialog_open(NativeHandle);
        return rawResult;
    }

    public bool Close()
    {
        var rawResult = Interop.native_message_dialog_close(NativeHandle);
        return rawResult;
    }

}

internal static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_message_dialog_close(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_message_dialog_open(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern DialogModality native_message_dialog_get_modality(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_message_dialog_get_message(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_message_dialog_get_title(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_message_dialog_create([MarshalAs(UnmanagedType.LPUTF8Str)] string? title, [MarshalAs(UnmanagedType.LPUTF8Str)] string? message);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_message_dialog_free(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_message_dialog_set_message(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? message);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_message_dialog_set_modality(ulong self, DialogModality modality);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_message_dialog_set_title(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? title);
}

