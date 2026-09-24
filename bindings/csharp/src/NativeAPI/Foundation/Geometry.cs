// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public struct Point
{
    public double X;
    public double Y;

    public Point(double x, double y)
    {
        X = x;
        Y = y;
    }

    internal static Point FromRaw(in native_point_t raw)
    {
        return new Point(raw.x, raw.y);
    }

    internal native_point_t ToRaw()
    {
        var raw = new native_point_t();
        raw.x = X;
        raw.y = Y;
        return raw;
    }
}

public struct Size
{
    public double Width;
    public double Height;

    public Size(double width, double height)
    {
        Width = width;
        Height = height;
    }

    internal static Size FromRaw(in native_size_t raw)
    {
        return new Size(raw.width, raw.height);
    }

    internal native_size_t ToRaw()
    {
        var raw = new native_size_t();
        raw.width = Width;
        raw.height = Height;
        return raw;
    }
}

public struct Rectangle
{
    public double X;
    public double Y;
    public double Width;
    public double Height;

    public Rectangle(double x, double y, double width, double height)
    {
        X = x;
        Y = y;
        Width = width;
        Height = height;
    }

    internal static Rectangle FromRaw(in native_rectangle_t raw)
    {
        return new Rectangle(raw.x, raw.y, raw.width, raw.height);
    }

    internal native_rectangle_t ToRaw()
    {
        var raw = new native_rectangle_t();
        raw.x = X;
        raw.y = Y;
        raw.width = Width;
        raw.height = Height;
        return raw;
    }
}

