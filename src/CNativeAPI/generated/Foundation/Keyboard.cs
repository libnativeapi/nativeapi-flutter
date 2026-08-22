// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace CNativeAPI;

[StructLayout(LayoutKind.Sequential)]
public struct native_keyboard_accelerator_t
{
    public int modifiers;
    public IntPtr key;
}

[StructLayout(LayoutKind.Sequential)]
public struct native_keyboard_event_t
{
    public int type;
    public int keycode;
    public DataUnion data;

    [StructLayout(LayoutKind.Explicit)]
    public struct DataUnion
    {
        [FieldOffset(0)] public ModifierKeysChangedData modifier_keys_changed;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct ModifierKeysChangedData
    {
        public uint modifier_keys;
    }
}

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void KeyboardEventNativeCallback(IntPtr evt, IntPtr userData);

public static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    public static extern void native_keyboard_accelerator_free(ref native_keyboard_accelerator_t value);
}

