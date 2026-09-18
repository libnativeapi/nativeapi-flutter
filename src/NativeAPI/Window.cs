// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public enum TitleBarStyle
{
    Normal = 0,
    Hidden = 1,
}

public enum VisualEffect
{
    None = 0,
    Blur = 1,
    Acrylic = 2,
    Mica = 3,
}

public enum ResizeEdge
{
    Top = 0,
    Left = 1,
    Right = 2,
    Bottom = 3,
    TopLeft = 4,
    TopRight = 5,
    BottomLeft = 6,
    BottomRight = 7,
}

/// <summary>One WindowEvent, in its concrete form.</summary>
public abstract record WindowEvent
{
    private WindowEvent() { }

    public sealed record Focused(uint WindowId) : WindowEvent;
    public sealed record Blurred(uint WindowId) : WindowEvent;
    public sealed record Minimized(uint WindowId) : WindowEvent;
    public sealed record Maximized(uint WindowId) : WindowEvent;
    public sealed record Restored(uint WindowId) : WindowEvent;
    public sealed record Moved(uint WindowId, Point NewPosition) : WindowEvent;
    public sealed record Resized(uint WindowId, Size NewSize) : WindowEvent;

    internal static WindowEvent? FromRaw(in native_window_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Focused(raw.window_id);
            case 1: return new Blurred(raw.window_id);
            case 2: return new Minimized(raw.window_id);
            case 3: return new Maximized(raw.window_id);
            case 4: return new Restored(raw.window_id);
            case 5: return new Moved(raw.window_id, Point.FromRaw(in raw.data.moved.new_position));
            case 6: return new Resized(raw.window_id, Size.FromRaw(in raw.data.resized.new_size));
            default: return null;
        }
    }
}

/// <summary>Owned handle to a native Window.</summary>
public sealed partial class Window : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public Window(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~Window() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_window_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new Window; returns null if the native side failed.</summary>
    public static Window? Create()
    {
        var handle = Interop.native_window_create();
        return handle == 0 ? null : new Window(handle);
    }

    /// <summary>Creates a new Window; returns null if the native side failed.</summary>
    public static Window? CreateWithNativeWindow(IntPtr nativeWindow)
    {
        var handle = Interop.native_window_create_with_native_window(nativeWindow);
        return handle == 0 ? null : new Window(handle);
    }

    public uint Id
    {
        get
        {
            var rawResult = Interop.native_window_get_id(NativeHandle);
            return rawResult;
        }
    }

    public void Focus()
    {
        Interop.native_window_focus(NativeHandle);
    }

    public void Blur()
    {
        Interop.native_window_blur(NativeHandle);
    }

    public bool IsFocused
    {
        get
        {
            var rawResult = Interop.native_window_is_focused(NativeHandle);
            return rawResult;
        }
    }

    public void Show()
    {
        Interop.native_window_show(NativeHandle);
    }

    public void ShowInactive()
    {
        Interop.native_window_show_inactive(NativeHandle);
    }

    public void Hide()
    {
        Interop.native_window_hide(NativeHandle);
    }

    public bool IsVisible
    {
        get
        {
            var rawResult = Interop.native_window_is_visible(NativeHandle);
            return rawResult;
        }
    }

    public void Maximize()
    {
        Interop.native_window_maximize(NativeHandle);
    }

    public void Unmaximize()
    {
        Interop.native_window_unmaximize(NativeHandle);
    }

    public bool IsMaximized
    {
        get
        {
            var rawResult = Interop.native_window_is_maximized(NativeHandle);
            return rawResult;
        }
    }

    public void Minimize()
    {
        Interop.native_window_minimize(NativeHandle);
    }

    public void Restore()
    {
        Interop.native_window_restore(NativeHandle);
    }

    public bool IsMinimized
    {
        get
        {
            var rawResult = Interop.native_window_is_minimized(NativeHandle);
            return rawResult;
        }
    }

    public void SetFullScreen(bool isFullScreen)
    {
        Interop.native_window_set_full_screen(NativeHandle, isFullScreen);
    }

    public bool IsFullScreen
    {
        get
        {
            var rawResult = Interop.native_window_is_full_screen(NativeHandle);
            return rawResult;
        }
    }

    public void SetBounds(Rectangle bounds)
    {
        var rawBounds = bounds.ToRaw();
        Interop.native_window_set_bounds(NativeHandle, rawBounds);
    }

    public Rectangle Bounds
    {
        get
        {
            var rawResult = Interop.native_window_get_bounds(NativeHandle);
            return Rectangle.FromRaw(in rawResult);
        }
    }

    public void SetContentBounds(Rectangle bounds)
    {
        var rawBounds = bounds.ToRaw();
        Interop.native_window_set_content_bounds(NativeHandle, rawBounds);
    }

    public Rectangle ContentBounds
    {
        get
        {
            var rawResult = Interop.native_window_get_content_bounds(NativeHandle);
            return Rectangle.FromRaw(in rawResult);
        }
    }

    public void SetSize(Size size, bool animate)
    {
        var rawSize = size.ToRaw();
        Interop.native_window_set_size(NativeHandle, rawSize, animate);
    }

    public Size Size
    {
        get
        {
            var rawResult = Interop.native_window_get_size(NativeHandle);
            return Size.FromRaw(in rawResult);
        }
    }

    public void SetContentSize(Size size)
    {
        var rawSize = size.ToRaw();
        Interop.native_window_set_content_size(NativeHandle, rawSize);
    }

    public Size ContentSize
    {
        get
        {
            var rawResult = Interop.native_window_get_content_size(NativeHandle);
            return Size.FromRaw(in rawResult);
        }
    }

    public void SetMinimumSize(Size size)
    {
        var rawSize = size.ToRaw();
        Interop.native_window_set_minimum_size(NativeHandle, rawSize);
    }

    public Size MinimumSize
    {
        get
        {
            var rawResult = Interop.native_window_get_minimum_size(NativeHandle);
            return Size.FromRaw(in rawResult);
        }
    }

    public void SetMaximumSize(Size size)
    {
        var rawSize = size.ToRaw();
        Interop.native_window_set_maximum_size(NativeHandle, rawSize);
    }

    public Size MaximumSize
    {
        get
        {
            var rawResult = Interop.native_window_get_maximum_size(NativeHandle);
            return Size.FromRaw(in rawResult);
        }
    }

    public void SetAspectRatio(double aspectRatio)
    {
        Interop.native_window_set_aspect_ratio(NativeHandle, aspectRatio);
    }

    public double AspectRatio
    {
        get
        {
            var rawResult = Interop.native_window_get_aspect_ratio(NativeHandle);
            return rawResult;
        }
    }

    public void SetResizable(bool isResizable)
    {
        Interop.native_window_set_resizable(NativeHandle, isResizable);
    }

    public bool IsResizable
    {
        get
        {
            var rawResult = Interop.native_window_is_resizable(NativeHandle);
            return rawResult;
        }
    }

    public void SetMovable(bool isMovable)
    {
        Interop.native_window_set_movable(NativeHandle, isMovable);
    }

    public bool IsMovable
    {
        get
        {
            var rawResult = Interop.native_window_is_movable(NativeHandle);
            return rawResult;
        }
    }

    public void SetMinimizable(bool isMinimizable)
    {
        Interop.native_window_set_minimizable(NativeHandle, isMinimizable);
    }

    public bool IsMinimizable
    {
        get
        {
            var rawResult = Interop.native_window_is_minimizable(NativeHandle);
            return rawResult;
        }
    }

    public void SetMaximizable(bool isMaximizable)
    {
        Interop.native_window_set_maximizable(NativeHandle, isMaximizable);
    }

    public bool IsMaximizable
    {
        get
        {
            var rawResult = Interop.native_window_is_maximizable(NativeHandle);
            return rawResult;
        }
    }

    public void SetFullScreenable(bool isFullScreenable)
    {
        Interop.native_window_set_full_screenable(NativeHandle, isFullScreenable);
    }

    public bool IsFullScreenable
    {
        get
        {
            var rawResult = Interop.native_window_is_full_screenable(NativeHandle);
            return rawResult;
        }
    }

    public void SetClosable(bool isClosable)
    {
        Interop.native_window_set_closable(NativeHandle, isClosable);
    }

    public bool IsClosable
    {
        get
        {
            var rawResult = Interop.native_window_is_closable(NativeHandle);
            return rawResult;
        }
    }

    public void SetWindowControlButtonsVisible(bool isVisible)
    {
        Interop.native_window_set_window_control_buttons_visible(NativeHandle, isVisible);
    }

    public bool IsWindowControlButtonsVisible
    {
        get
        {
            var rawResult = Interop.native_window_is_window_control_buttons_visible(NativeHandle);
            return rawResult;
        }
    }

    public void SetAlwaysOnTop(bool isAlwaysOnTop)
    {
        Interop.native_window_set_always_on_top(NativeHandle, isAlwaysOnTop);
    }

    public bool IsAlwaysOnTop
    {
        get
        {
            var rawResult = Interop.native_window_is_always_on_top(NativeHandle);
            return rawResult;
        }
    }

    public void SetAlwaysOnBottom(bool isAlwaysOnBottom)
    {
        Interop.native_window_set_always_on_bottom(NativeHandle, isAlwaysOnBottom);
    }

    public bool IsAlwaysOnBottom
    {
        get
        {
            var rawResult = Interop.native_window_is_always_on_bottom(NativeHandle);
            return rawResult;
        }
    }

    public void SetNonActivating(bool isNonActivating)
    {
        Interop.native_window_set_non_activating(NativeHandle, isNonActivating);
    }

    public bool IsNonActivating
    {
        get
        {
            var rawResult = Interop.native_window_is_non_activating(NativeHandle);
            return rawResult;
        }
    }

    public void SetPosition(Point point)
    {
        var rawPoint = point.ToRaw();
        Interop.native_window_set_position(NativeHandle, rawPoint);
    }

    public Point Position
    {
        get
        {
            var rawResult = Interop.native_window_get_position(NativeHandle);
            return Point.FromRaw(in rawResult);
        }
    }

    public void Center()
    {
        Interop.native_window_center(NativeHandle);
    }

    public void SetTitle(string title)
    {
        Interop.native_window_set_title(NativeHandle, title);
    }

    public string? Title
    {
        get
        {
            var rawResult = Interop.native_window_get_title(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public bool SetTitleBarColors(Color background, Color foreground)
    {
        var rawBackground = background.ToRaw();
        var rawForeground = foreground.ToRaw();
        var rawResult = Interop.native_window_set_title_bar_colors(NativeHandle, rawBackground, rawForeground);
        return rawResult;
    }

    public bool ResetTitleBarColors()
    {
        var rawResult = Interop.native_window_reset_title_bar_colors(NativeHandle);
        return rawResult;
    }

    public void SetTitleBarStyle(TitleBarStyle style)
    {
        Interop.native_window_set_title_bar_style(NativeHandle, (int)style);
    }

    public TitleBarStyle TitleBarStyle
    {
        get
        {
            var rawResult = Interop.native_window_get_title_bar_style(NativeHandle);
            return (TitleBarStyle)rawResult;
        }
    }

    public void SetHasShadow(bool hasShadow)
    {
        Interop.native_window_set_has_shadow(NativeHandle, hasShadow);
    }

    public bool HasShadow
    {
        get
        {
            var rawResult = Interop.native_window_has_shadow(NativeHandle);
            return rawResult;
        }
    }

    public void SetOpacity(float opacity)
    {
        Interop.native_window_set_opacity(NativeHandle, opacity);
    }

    public float Opacity
    {
        get
        {
            var rawResult = Interop.native_window_get_opacity(NativeHandle);
            return rawResult;
        }
    }

    public void SetVisualEffect(VisualEffect effect)
    {
        Interop.native_window_set_visual_effect(NativeHandle, (int)effect);
    }

    public VisualEffect VisualEffect
    {
        get
        {
            var rawResult = Interop.native_window_get_visual_effect(NativeHandle);
            return (VisualEffect)rawResult;
        }
    }

    public void SetBackgroundColor(Color color)
    {
        var rawColor = color.ToRaw();
        Interop.native_window_set_background_color(NativeHandle, rawColor);
    }

    public Color BackgroundColor
    {
        get
        {
            var rawResult = Interop.native_window_get_background_color(NativeHandle);
            return Color.FromRaw(in rawResult);
        }
    }

    public void SetVisibleOnAllWorkspaces(bool isVisibleOnAllWorkspaces)
    {
        Interop.native_window_set_visible_on_all_workspaces(NativeHandle, isVisibleOnAllWorkspaces);
    }

    public bool IsVisibleOnAllWorkspaces
    {
        get
        {
            var rawResult = Interop.native_window_is_visible_on_all_workspaces(NativeHandle);
            return rawResult;
        }
    }

    public void SetVisibleInTaskbar(bool isVisibleInTaskbar)
    {
        Interop.native_window_set_visible_in_taskbar(NativeHandle, isVisibleInTaskbar);
    }

    public bool IsVisibleInTaskbar
    {
        get
        {
            var rawResult = Interop.native_window_is_visible_in_taskbar(NativeHandle);
            return rawResult;
        }
    }

    public void SetIgnoreMouseEvents(bool isIgnoreMouseEvents)
    {
        Interop.native_window_set_ignore_mouse_events(NativeHandle, isIgnoreMouseEvents);
    }

    public bool IsIgnoreMouseEvents
    {
        get
        {
            var rawResult = Interop.native_window_is_ignore_mouse_events(NativeHandle);
            return rawResult;
        }
    }

    public void SetFocusable(bool isFocusable)
    {
        Interop.native_window_set_focusable(NativeHandle, isFocusable);
    }

    public bool IsFocusable
    {
        get
        {
            var rawResult = Interop.native_window_is_focusable(NativeHandle);
            return rawResult;
        }
    }

    public void StartDragging()
    {
        Interop.native_window_start_dragging(NativeHandle);
    }

    public void StartResizing(ResizeEdge edge)
    {
        Interop.native_window_start_resizing(NativeHandle, (int)edge);
    }

    /// <summary>Platform-specific native object behind this handle.</summary>
    public IntPtr NativeObject => Interop.native_window_get_native_object(NativeHandle);

}

