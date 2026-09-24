// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public enum MessageDialogResult
{
    None = 0,
    Primary = 1,
    Secondary = 2,
    Close = 3,
}

/// <summary>Owned handle to a native MessageDialog.</summary>
public sealed partial class MessageDialog : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public MessageDialog(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~MessageDialog() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_message_dialog_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new MessageDialog; returns null if the native side failed.</summary>
    public static MessageDialog? Create(string title, string message)
    {
        var handle = Interop.native_message_dialog_create(title, message);
        return handle == 0 ? null : new MessageDialog(handle);
    }

    public static bool IsExtendedSupported()
    {
        var rawResult = Interop.native_message_dialog_is_extended_supported();
        return rawResult;
    }

    public bool SetButtons(string primary, string secondary, string close)
    {
        var rawResult = Interop.native_message_dialog_set_buttons(NativeHandle, primary, secondary, close);
        return rawResult;
    }

    public bool SetDefaultButton(MessageDialogResult button)
    {
        var rawResult = Interop.native_message_dialog_set_default_button(NativeHandle, (int)button);
        return rawResult;
    }

    public bool SetParentWindow(Window? window)
    {
        var rawResult = Interop.native_message_dialog_set_parent_window(NativeHandle, window?.NativeHandle ?? 0);
        return rawResult;
    }

    public MessageDialogResult Result
    {
        get
        {
            var rawResult = Interop.native_message_dialog_get_result(NativeHandle);
            return (MessageDialogResult)rawResult;
        }
    }

    public bool IsOpen
    {
        get
        {
            var rawResult = Interop.native_message_dialog_is_open(NativeHandle);
            return rawResult;
        }
    }

    public bool SetInputEnabled(bool enabled)
    {
        var rawResult = Interop.native_message_dialog_set_input_enabled(NativeHandle, enabled);
        return rawResult;
    }

    public bool SetInputText(string text)
    {
        var rawResult = Interop.native_message_dialog_set_input_text(NativeHandle, text);
        return rawResult;
    }

    public string? InputText
    {
        get
        {
            var rawResult = Interop.native_message_dialog_get_input_text(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public bool SetCheckbox(string label, bool @checked)
    {
        var rawResult = Interop.native_message_dialog_set_checkbox(NativeHandle, label, @checked);
        return rawResult;
    }

    public bool IsCheckboxChecked
    {
        get
        {
            var rawResult = Interop.native_message_dialog_is_checkbox_checked(NativeHandle);
            return rawResult;
        }
    }

    public bool SetProgress(double value)
    {
        var rawResult = Interop.native_message_dialog_set_progress(NativeHandle, value);
        return rawResult;
    }

    public void SetTitle(string title)
    {
        Interop.native_message_dialog_set_title(NativeHandle, title);
    }

    public string? Title
    {
        get
        {
            var rawResult = Interop.native_message_dialog_get_title(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public void SetMessage(string message)
    {
        Interop.native_message_dialog_set_message(NativeHandle, message);
    }

    public string? Message
    {
        get
        {
            var rawResult = Interop.native_message_dialog_get_message(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public DialogModality Modality
    {
        get
        {
            var rawResult = Interop.native_message_dialog_get_modality(NativeHandle);
            return (DialogModality)rawResult;
        }
    }

    public void SetModality(DialogModality modality)
    {
        Interop.native_message_dialog_set_modality(NativeHandle, (int)modality);
    }

    public bool Open()
    {
        var rawResult = Interop.native_message_dialog_open(NativeHandle);
        return rawResult;
    }

    public bool Close()
    {
        var rawResult = Interop.native_message_dialog_close(NativeHandle);
        return rawResult;
    }

}

