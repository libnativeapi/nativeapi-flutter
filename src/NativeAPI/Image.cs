// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

/// <summary>Owned handle to a native Image.</summary>
public sealed partial class Image : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public Image(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~Image() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_image_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    public static Image? FromFile(string filePath)
    {
        var rawResult = Interop.native_image_from_file(filePath);
        return rawResult == 0 ? null : new Image(rawResult);
    }

    public static Image? FromBase64(string base64Data)
    {
        var rawResult = Interop.native_image_from_base64(base64Data);
        return rawResult == 0 ? null : new Image(rawResult);
    }

    public Size Size
    {
        get
        {
            var rawResult = Interop.native_image_get_size(NativeHandle);
            return Size.FromRaw(in rawResult);
        }
    }

    public string? Format
    {
        get
        {
            var rawResult = Interop.native_image_get_format(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public string? ToBase64()
    {
        var rawResult = Interop.native_image_to_base64(NativeHandle);
        return Interop.ConsumeString(rawResult);
    }

    public bool SaveToFile(string filePath)
    {
        var rawResult = Interop.native_image_save_to_file(NativeHandle, filePath);
        return rawResult;
    }

    /// <summary>Platform-specific native object behind this handle.</summary>
    public IntPtr NativeObject => Interop.native_image_get_native_object(NativeHandle);

}

