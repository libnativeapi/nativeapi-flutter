// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

public enum ModifierKey
{
    None = 0,
    Shift = 1,
    Ctrl = 2,
    Alt = 4,
    Meta = 8,
    Fn = 16,
    CapsLock = 32,
    NumLock = 64,
    ScrollLock = 128,
}

[StructLayout(LayoutKind.Sequential)]
internal struct native_keyboard_accelerator_t
{
    internal ModifierKey modifiers;
    internal IntPtr key;
}

public struct KeyboardAccelerator
{
    public ModifierKey Modifiers;
    public string? Key;

    public KeyboardAccelerator(ModifierKey modifiers, string? key)
    {
        Modifiers = modifiers;
        Key = key;
    }

    internal static KeyboardAccelerator FromRaw(in native_keyboard_accelerator_t raw)
    {
        return new KeyboardAccelerator(raw.modifiers, Marshal.PtrToStringUTF8(raw.key));
    }

    internal native_keyboard_accelerator_t ToRaw()
    {
        var raw = new native_keyboard_accelerator_t();
        raw.modifiers = Modifiers;
        raw.key = Marshal.StringToCoTaskMemUTF8(Key);
        return raw;
    }

    internal static void ReleaseRaw(ref native_keyboard_accelerator_t raw)
    {
        Marshal.FreeCoTaskMem(raw.key);
        raw.key = IntPtr.Zero;
    }
}

[StructLayout(LayoutKind.Sequential)]
internal struct native_keyboard_event_t
{
    internal int type;
    internal int keycode;
    internal DataUnion data;

    [StructLayout(LayoutKind.Explicit)]
    internal struct DataUnion
    {
        [FieldOffset(0)] internal ModifierKeysChangedData modifier_keys_changed;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct ModifierKeysChangedData
    {
        internal uint modifier_keys;
    }
}

/// <summary>One KeyboardEvent, in its concrete form.</summary>
public abstract record KeyboardEvent
{
    private KeyboardEvent() { }

    public sealed record KeyPressed(int Keycode) : KeyboardEvent;
    public sealed record KeyReleased(int Keycode) : KeyboardEvent;
    public sealed record ModifierKeysChanged(int Keycode, uint ModifierKeys) : KeyboardEvent;

    internal static KeyboardEvent? FromRaw(in native_keyboard_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new KeyPressed(raw.keycode);
            case 1: return new KeyReleased(raw.keycode);
            case 2: return new ModifierKeysChanged(raw.keycode, raw.data.modifier_keys_changed.modifier_keys);
            default: return null;
        }
    }
}

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
internal delegate void KeyboardEventNativeCallback(IntPtr evt, IntPtr userData);

internal static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_keyboard_accelerator_free(ref native_keyboard_accelerator_t value);
}

