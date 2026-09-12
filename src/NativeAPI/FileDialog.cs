// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public enum FileDialogMode
{
    OpenFile = 0,
    OpenFiles = 1,
    SaveFile = 2,
    SelectFolder = 3,
}

public enum FileDialogResult
{
    None = 0,
    Accepted = 1,
    Cancelled = 2,
    Failed = 3,
}

/// <summary>Owned handle to a native FileDialog.</summary>
public sealed partial class FileDialog : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public FileDialog(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~FileDialog() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_file_dialog_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new FileDialog; returns null if the native side failed.</summary>
    public static FileDialog? Create(FileDialogMode mode)
    {
        var handle = Interop.native_file_dialog_create((int)mode);
        return handle == 0 ? null : new FileDialog(handle);
    }

    public static bool IsSupported()
    {
        var rawResult = Interop.native_file_dialog_is_supported();
        return rawResult;
    }

    public bool SetParentWindow(Window? window)
    {
        var rawResult = Interop.native_file_dialog_set_parent_window(NativeHandle, window?.NativeHandle ?? 0);
        return rawResult;
    }

    public bool SetFileTypes(IReadOnlyList<string> extensions)
    {
        var itemsExtensions = Interop.AllocUtf8Array(extensions);
        var blockExtensions = Interop.AllocPointerArray(itemsExtensions);
        var listExtensions = new native_string_list_t { items = blockExtensions, count = new CLong(itemsExtensions.Length) };
        var rawResult = Interop.native_file_dialog_set_file_types(NativeHandle, listExtensions);
        Interop.FreeUtf8Array(itemsExtensions);
        Marshal.FreeHGlobal(blockExtensions);
        return rawResult;
    }

    public bool SetSuggestedFileName(string name)
    {
        var rawResult = Interop.native_file_dialog_set_suggested_file_name(NativeHandle, name);
        return rawResult;
    }

    public DialogModality Modality
    {
        get
        {
            var rawResult = Interop.native_file_dialog_get_modality(NativeHandle);
            return (DialogModality)rawResult;
        }
    }

    public void SetModality(DialogModality modality)
    {
        Interop.native_file_dialog_set_modality(NativeHandle, (int)modality);
    }

    public bool Open()
    {
        var rawResult = Interop.native_file_dialog_open(NativeHandle);
        return rawResult;
    }

    public bool Close()
    {
        var rawResult = Interop.native_file_dialog_close(NativeHandle);
        return rawResult;
    }

    public FileDialogResult Result
    {
        get
        {
            var rawResult = Interop.native_file_dialog_get_result(NativeHandle);
            return (FileDialogResult)rawResult;
        }
    }

    public string[] Paths
    {
        get
        {
            var rawResult = Interop.native_file_dialog_get_paths(NativeHandle);
            return Interop.ConsumeStringList(ref rawResult);
        }
    }

    public string? LastError
    {
        get
        {
            var rawResult = Interop.native_file_dialog_get_last_error(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

}

