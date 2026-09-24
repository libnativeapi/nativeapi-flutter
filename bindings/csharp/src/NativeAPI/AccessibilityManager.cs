// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public sealed partial class AccessibilityManager
{
    /// <summary>The shared instance backed by the native singleton.</summary>
    public static AccessibilityManager Shared { get; } = new AccessibilityManager();

    private AccessibilityManager() { }

    public void Enable()
    {
        Interop.native_accessibility_manager_enable();
    }

    public bool IsEnabled()
    {
        var rawResult = Interop.native_accessibility_manager_is_enabled();
        return rawResult;
    }

}

