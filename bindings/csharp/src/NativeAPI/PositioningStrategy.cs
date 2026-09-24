// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public enum PositioningStrategyType
{
    Absolute = 0,
    CursorPosition = 1,
    Relative = 2,
}

/// <summary>Owned handle to a native PositioningStrategy.</summary>
public sealed partial class PositioningStrategy : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public PositioningStrategy(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~PositioningStrategy() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_positioning_strategy_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    public static PositioningStrategy? Absolute(Point point)
    {
        var rawPoint = point.ToRaw();
        var rawResult = Interop.native_positioning_strategy_absolute(rawPoint);
        return rawResult == 0 ? null : new PositioningStrategy(rawResult);
    }

    public static PositioningStrategy? CursorPosition()
    {
        var rawResult = Interop.native_positioning_strategy_cursor_position();
        return rawResult == 0 ? null : new PositioningStrategy(rawResult);
    }

    public static PositioningStrategy? RelativeWithRectAndOffset(Rectangle rect, Point offset)
    {
        var rawRect = rect.ToRaw();
        var rawOffset = offset.ToRaw();
        var rawResult = Interop.native_positioning_strategy_relative_with_rect_and_offset(rawRect, rawOffset);
        return rawResult == 0 ? null : new PositioningStrategy(rawResult);
    }

    public static PositioningStrategy? RelativeWithWindowAndOffset(Window window, Point offset)
    {
        var rawOffset = offset.ToRaw();
        var rawResult = Interop.native_positioning_strategy_relative_with_window_and_offset(window.NativeHandle, rawOffset);
        return rawResult == 0 ? null : new PositioningStrategy(rawResult);
    }

    public PositioningStrategyType Type
    {
        get
        {
            var rawResult = Interop.native_positioning_strategy_get_type(NativeHandle);
            return (PositioningStrategyType)rawResult;
        }
    }

    public Point AbsolutePosition
    {
        get
        {
            var rawResult = Interop.native_positioning_strategy_get_absolute_position(NativeHandle);
            return Point.FromRaw(in rawResult);
        }
    }

    public Rectangle RelativeRectangle
    {
        get
        {
            var rawResult = Interop.native_positioning_strategy_get_relative_rectangle(NativeHandle);
            return Rectangle.FromRaw(in rawResult);
        }
    }

    public Point RelativeOffset
    {
        get
        {
            var rawResult = Interop.native_positioning_strategy_get_relative_offset(NativeHandle);
            return Point.FromRaw(in rawResult);
        }
    }

}

