// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public sealed partial class AppInfo
{
    /// <summary>The shared instance backed by the native singleton.</summary>
    public static AppInfo Shared { get; } = new AppInfo();

    private AppInfo() { }

    public string? GetName()
    {
        var rawResult = Interop.native_app_info_get_name();
        return Interop.ConsumeString(rawResult);
    }

    public string? GetIdentifier()
    {
        var rawResult = Interop.native_app_info_get_identifier();
        return Interop.ConsumeString(rawResult);
    }

    public string? GetVersion()
    {
        var rawResult = Interop.native_app_info_get_version();
        return Interop.ConsumeString(rawResult);
    }

    public string? GetBuildNumber()
    {
        var rawResult = Interop.native_app_info_get_build_number();
        return Interop.ConsumeString(rawResult);
    }

}

