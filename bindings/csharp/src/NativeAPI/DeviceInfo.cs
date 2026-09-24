// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public sealed partial class DeviceInfo
{
    /// <summary>The shared instance backed by the native singleton.</summary>
    public static DeviceInfo Shared { get; } = new DeviceInfo();

    private DeviceInfo() { }

    public string? GetName()
    {
        var rawResult = Interop.native_device_info_get_name();
        return Interop.ConsumeString(rawResult);
    }

    public string? GetModel()
    {
        var rawResult = Interop.native_device_info_get_model();
        return Interop.ConsumeString(rawResult);
    }

    public string? GetManufacturer()
    {
        var rawResult = Interop.native_device_info_get_manufacturer();
        return Interop.ConsumeString(rawResult);
    }

    public string? GetOsName()
    {
        var rawResult = Interop.native_device_info_get_os_name();
        return Interop.ConsumeString(rawResult);
    }

    public string? GetOsVersion()
    {
        var rawResult = Interop.native_device_info_get_os_version();
        return Interop.ConsumeString(rawResult);
    }

    public string? GetKernelVersion()
    {
        var rawResult = Interop.native_device_info_get_kernel_version();
        return Interop.ConsumeString(rawResult);
    }

    public string? GetArchitecture()
    {
        var rawResult = Interop.native_device_info_get_architecture();
        return Interop.ConsumeString(rawResult);
    }

}

