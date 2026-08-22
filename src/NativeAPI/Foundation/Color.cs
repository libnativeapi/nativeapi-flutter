// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

[StructLayout(LayoutKind.Sequential)]
internal struct native_color_t
{
    internal byte r;
    internal byte g;
    internal byte b;
    internal byte a;
}

public struct Color
{
    public byte R;
    public byte G;
    public byte B;
    public byte A;

    public Color(byte r, byte g, byte b, byte a)
    {
        R = r;
        G = g;
        B = b;
        A = a;
    }

    internal static Color FromRaw(in native_color_t raw)
    {
        return new Color(raw.r, raw.g, raw.b, raw.a);
    }

    internal native_color_t ToRaw()
    {
        var raw = new native_color_t();
        raw.r = R;
        raw.g = G;
        raw.b = B;
        raw.a = A;
        return raw;
    }
}

