// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public enum ViewLayout
{
    Absolute = 0,
    Row = 1,
    Column = 2,
}

public enum ViewAlignment
{
    Stretch = 0,
    Start = 1,
    Center = 2,
    End = 3,
}

public enum TextAlignment
{
    Start = 0,
    Center = 1,
    End = 2,
}

public enum ViewBackend
{
    Native = 0,
    WinUi3 = 1,
}

/// <summary>One ViewEvent, in its concrete form.</summary>
public abstract record ViewEvent
{
    private ViewEvent() { }

    public sealed record Focused(uint ViewId) : ViewEvent;
    public sealed record Blurred(uint ViewId) : ViewEvent;
    public sealed record ButtonClicked(uint ViewId) : ViewEvent;
    public sealed record TextFieldChanged(uint ViewId, string? Text) : ViewEvent;
    public sealed record TextFieldSubmitted(uint ViewId) : ViewEvent;

    internal static ViewEvent? FromRaw(in native_view_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Focused(raw.view_id);
            case 1: return new Blurred(raw.view_id);
            case 2: return new ButtonClicked(raw.view_id);
            case 3: return new TextFieldChanged(raw.view_id, Marshal.PtrToStringUTF8(raw.data.text_field_changed.text));
            case 4: return new TextFieldSubmitted(raw.view_id);
            default: return null;
        }
    }
}

/// <summary>Owned handle to a native View.</summary>
public partial class View : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public View(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~View() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_view_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new View; returns null if the native side failed.</summary>
    public static View? Create()
    {
        var handle = Interop.native_view_create();
        return handle == 0 ? null : new View(handle);
    }

    /// <summary>Creates a new View; returns null if the native side failed.</summary>
    public static View? CreateWithNativeView(IntPtr nativeView)
    {
        var handle = Interop.native_view_create_with_native_view(nativeView);
        return handle == 0 ? null : new View(handle);
    }

    public static bool IsSupported()
    {
        var rawResult = Interop.native_view_is_supported();
        return rawResult;
    }

    public static bool IsBackendSupported(ViewBackend backend)
    {
        var rawResult = Interop.native_view_is_backend_supported((int)backend);
        return rawResult;
    }

    public static bool SetDefaultBackend(ViewBackend backend)
    {
        var rawResult = Interop.native_view_set_default_backend((int)backend);
        return rawResult;
    }

    public static ViewBackend GetDefaultBackend()
    {
        var rawResult = Interop.native_view_get_default_backend();
        return (ViewBackend)rawResult;
    }

    public uint Id
    {
        get
        {
            var rawResult = Interop.native_view_get_id(NativeHandle);
            return rawResult;
        }
    }

    public ViewBackend Backend
    {
        get
        {
            var rawResult = Interop.native_view_get_backend(NativeHandle);
            return (ViewBackend)rawResult;
        }
    }

    public void AddSubview(View? subview)
    {
        Interop.native_view_add_subview(NativeHandle, subview?.NativeHandle ?? 0);
    }

    public void InsertSubview(ulong index, View? subview)
    {
        Interop.native_view_insert_subview(NativeHandle, new CULong(checked((nuint)index)), subview?.NativeHandle ?? 0);
    }

    public bool RemoveSubview(View? subview)
    {
        var rawResult = Interop.native_view_remove_subview(NativeHandle, subview?.NativeHandle ?? 0);
        return rawResult;
    }

    public bool RemoveSubviewAt(ulong index)
    {
        var rawResult = Interop.native_view_remove_subview_at(NativeHandle, new CULong(checked((nuint)index)));
        return rawResult;
    }

    public void ClearSubviews()
    {
        Interop.native_view_clear_subviews(NativeHandle);
    }

    public ulong SubviewCount
    {
        get
        {
            var rawResult = Interop.native_view_get_subview_count(NativeHandle);
            return (ulong)rawResult.Value;
        }
    }

    public View? GetSubviewAt(ulong index)
    {
        var rawResult = Interop.native_view_get_subview_at(NativeHandle, new CULong(checked((nuint)index)));
        return rawResult == 0 ? null : new View(rawResult);
    }

    public View[] Subviews
    {
        get
        {
            var rawResult = Interop.native_view_get_subviews(NativeHandle);
            var count = rawResult.views == IntPtr.Zero ? 0 : checked((int)rawResult.count.Value);
            var items = new View[count];
            for (var i = 0; i < count; i++)
            {
                items[i] = new View((ulong)Marshal.ReadInt64(rawResult.views, i * 8));
            }
            // The handles now belong to `items`; free just the array.
            Interop.native_view_list_release(ref rawResult);
            return items;
        }
    }

    public View? Parent
    {
        get
        {
            var rawResult = Interop.native_view_get_parent(NativeHandle);
            return rawResult == 0 ? null : new View(rawResult);
        }
    }

    public Window? Window
    {
        get
        {
            var rawResult = Interop.native_view_get_window(NativeHandle);
            return rawResult == 0 ? null : new Window(rawResult);
        }
    }

    public void SetFrame(Rectangle frame)
    {
        var rawFrame = frame.ToRaw();
        Interop.native_view_set_frame(NativeHandle, rawFrame);
    }

    public Rectangle Frame
    {
        get
        {
            var rawResult = Interop.native_view_get_frame(NativeHandle);
            return Rectangle.FromRaw(in rawResult);
        }
    }

    public void SetPreferredSize(Size size)
    {
        var rawSize = size.ToRaw();
        Interop.native_view_set_preferred_size(NativeHandle, rawSize);
    }

    public Size PreferredSize
    {
        get
        {
            var rawResult = Interop.native_view_get_preferred_size(NativeHandle);
            return Size.FromRaw(in rawResult);
        }
    }

    public Size IntrinsicSize
    {
        get
        {
            var rawResult = Interop.native_view_get_intrinsic_size(NativeHandle);
            return Size.FromRaw(in rawResult);
        }
    }

    public void SetFlex(double flex)
    {
        Interop.native_view_set_flex(NativeHandle, flex);
    }

    public double Flex
    {
        get
        {
            var rawResult = Interop.native_view_get_flex(NativeHandle);
            return rawResult;
        }
    }

    public void SetAlignment(ViewAlignment alignment)
    {
        Interop.native_view_set_alignment(NativeHandle, (int)alignment);
    }

    public ViewAlignment Alignment
    {
        get
        {
            var rawResult = Interop.native_view_get_alignment(NativeHandle);
            return (ViewAlignment)rawResult;
        }
    }

    public void SetLayout(ViewLayout layout)
    {
        Interop.native_view_set_layout(NativeHandle, (int)layout);
    }

    public ViewLayout Layout
    {
        get
        {
            var rawResult = Interop.native_view_get_layout(NativeHandle);
            return (ViewLayout)rawResult;
        }
    }

    public void SetSpacing(double spacing)
    {
        Interop.native_view_set_spacing(NativeHandle, spacing);
    }

    public double Spacing
    {
        get
        {
            var rawResult = Interop.native_view_get_spacing(NativeHandle);
            return rawResult;
        }
    }

    public void SetPadding(EdgeInsets padding)
    {
        var rawPadding = padding.ToRaw();
        Interop.native_view_set_padding(NativeHandle, rawPadding);
    }

    public EdgeInsets Padding
    {
        get
        {
            var rawResult = Interop.native_view_get_padding(NativeHandle);
            return EdgeInsets.FromRaw(in rawResult);
        }
    }

    public void SetVisible(bool isVisible)
    {
        Interop.native_view_set_visible(NativeHandle, isVisible);
    }

    public bool IsVisible
    {
        get
        {
            var rawResult = Interop.native_view_is_visible(NativeHandle);
            return rawResult;
        }
    }

    public void SetEnabled(bool isEnabled)
    {
        Interop.native_view_set_enabled(NativeHandle, isEnabled);
    }

    public bool IsEnabled
    {
        get
        {
            var rawResult = Interop.native_view_is_enabled(NativeHandle);
            return rawResult;
        }
    }

    public void SetBackgroundColor(Color color)
    {
        var rawColor = color.ToRaw();
        Interop.native_view_set_background_color(NativeHandle, rawColor);
    }

    public Color BackgroundColor
    {
        get
        {
            var rawResult = Interop.native_view_get_background_color(NativeHandle);
            return Color.FromRaw(in rawResult);
        }
    }

    public void SetTooltip(string? tooltip)
    {
        Interop.native_view_set_tooltip(NativeHandle, tooltip);
    }

    public string? Tooltip
    {
        get
        {
            var rawResult = Interop.native_view_get_tooltip(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public void Focus()
    {
        Interop.native_view_focus(NativeHandle);
    }

    public void Blur()
    {
        Interop.native_view_blur(NativeHandle);
    }

    public bool IsFocused
    {
        get
        {
            var rawResult = Interop.native_view_is_focused(NativeHandle);
            return rawResult;
        }
    }

    /// <summary>Platform-specific native object behind this handle.</summary>
    public IntPtr NativeObject => Interop.native_view_get_native_object(NativeHandle);

    /// <summary>Registers <paramref name="callback"/> for every ViewEvent this View emits.</summary>
    /// <remarks>
    /// The delegate is kept alive until the listener is removed or its emitter
    /// destroyed; the core releases it then.
    /// </remarks>
    public ulong AddListener(Action<ViewEvent> callback)
    {
        ViewEventNativeCallback native = (evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = ViewEvent.FromRaw(Marshal.PtrToStructure<native_view_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        };
        return Interop.native_view_add_listener(NativeHandle, native, CallbackKeeper.Hold(native), CallbackKeeper.Release);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_view_remove_listener(NativeHandle, listenerId);
    }

}

/// <summary>Owned handle to a native Label.</summary>
public partial class Label : View
{
    public Label(ulong nativeHandle, bool ownsHandle = true) : base(nativeHandle, ownsHandle) { }

    /// <summary>Creates a new Label; returns null if the native side failed.</summary>
    public static Label? Create(string text)
    {
        var handle = Interop.native_label_create(text);
        return handle == 0 ? null : new Label(handle);
    }

    public void SetText(string text)
    {
        Interop.native_label_set_text(NativeHandle, text);
    }

    public string? Text
    {
        get
        {
            var rawResult = Interop.native_label_get_text(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public void SetTextColor(Color color)
    {
        var rawColor = color.ToRaw();
        Interop.native_label_set_text_color(NativeHandle, rawColor);
    }

    public Color TextColor
    {
        get
        {
            var rawResult = Interop.native_label_get_text_color(NativeHandle);
            return Color.FromRaw(in rawResult);
        }
    }

    public void SetFontSize(double size)
    {
        Interop.native_label_set_font_size(NativeHandle, size);
    }

    public double FontSize
    {
        get
        {
            var rawResult = Interop.native_label_get_font_size(NativeHandle);
            return rawResult;
        }
    }

    public void SetTextAlignment(TextAlignment alignment)
    {
        Interop.native_label_set_text_alignment(NativeHandle, (int)alignment);
    }

    public TextAlignment TextAlignment
    {
        get
        {
            var rawResult = Interop.native_label_get_text_alignment(NativeHandle);
            return (TextAlignment)rawResult;
        }
    }

}

/// <summary>Owned handle to a native Button.</summary>
public partial class Button : View
{
    public Button(ulong nativeHandle, bool ownsHandle = true) : base(nativeHandle, ownsHandle) { }

    /// <summary>Creates a new Button; returns null if the native side failed.</summary>
    public static Button? Create(string text)
    {
        var handle = Interop.native_button_create(text);
        return handle == 0 ? null : new Button(handle);
    }

    public void SetText(string text)
    {
        Interop.native_button_set_text(NativeHandle, text);
    }

    public string? Text
    {
        get
        {
            var rawResult = Interop.native_button_get_text(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

}

/// <summary>Owned handle to a native TextField.</summary>
public partial class TextField : View
{
    public TextField(ulong nativeHandle, bool ownsHandle = true) : base(nativeHandle, ownsHandle) { }

    /// <summary>Creates a new TextField; returns null if the native side failed.</summary>
    public static TextField? Create(string text)
    {
        var handle = Interop.native_text_field_create(text);
        return handle == 0 ? null : new TextField(handle);
    }

    public void SetText(string text)
    {
        Interop.native_text_field_set_text(NativeHandle, text);
    }

    public string? Text
    {
        get
        {
            var rawResult = Interop.native_text_field_get_text(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public void SetTextColor(Color color)
    {
        var rawColor = color.ToRaw();
        Interop.native_text_field_set_text_color(NativeHandle, rawColor);
    }

    public Color TextColor
    {
        get
        {
            var rawResult = Interop.native_text_field_get_text_color(NativeHandle);
            return Color.FromRaw(in rawResult);
        }
    }

    public void SetFontSize(double size)
    {
        Interop.native_text_field_set_font_size(NativeHandle, size);
    }

    public double FontSize
    {
        get
        {
            var rawResult = Interop.native_text_field_get_font_size(NativeHandle);
            return rawResult;
        }
    }

    public void SetTextAlignment(TextAlignment alignment)
    {
        Interop.native_text_field_set_text_alignment(NativeHandle, (int)alignment);
    }

    public TextAlignment TextAlignment
    {
        get
        {
            var rawResult = Interop.native_text_field_get_text_alignment(NativeHandle);
            return (TextAlignment)rawResult;
        }
    }

    public void SetPlaceholder(string? placeholder)
    {
        Interop.native_text_field_set_placeholder(NativeHandle, placeholder);
    }

    public string? Placeholder
    {
        get
        {
            var rawResult = Interop.native_text_field_get_placeholder(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public void SetEditable(bool isEditable)
    {
        Interop.native_text_field_set_editable(NativeHandle, isEditable);
    }

    public bool IsEditable
    {
        get
        {
            var rawResult = Interop.native_text_field_is_editable(NativeHandle);
            return rawResult;
        }
    }

    public void SetSecure(bool isSecure)
    {
        Interop.native_text_field_set_secure(NativeHandle, isSecure);
    }

    public bool IsSecure
    {
        get
        {
            var rawResult = Interop.native_text_field_is_secure(NativeHandle);
            return rawResult;
        }
    }

    public void SetMultiline(bool isMultiline)
    {
        Interop.native_text_field_set_multiline(NativeHandle, isMultiline);
    }

    public bool IsMultiline
    {
        get
        {
            var rawResult = Interop.native_text_field_is_multiline(NativeHandle);
            return rawResult;
        }
    }

}

/// <summary>Owned handle to a native ImageView.</summary>
public partial class ImageView : View
{
    public ImageView(ulong nativeHandle, bool ownsHandle = true) : base(nativeHandle, ownsHandle) { }

    /// <summary>Creates a new ImageView; returns null if the native side failed.</summary>
    public static ImageView? Create()
    {
        var handle = Interop.native_image_view_create();
        return handle == 0 ? null : new ImageView(handle);
    }

    public void SetImage(Image? image)
    {
        Interop.native_image_view_set_image(NativeHandle, image?.NativeHandle ?? 0);
    }

    public Image? Image
    {
        get
        {
            var rawResult = Interop.native_image_view_get_image(NativeHandle);
            return rawResult == 0 ? null : new Image(rawResult);
        }
    }

}

