// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public sealed partial class WindowManager
{
    /// <summary>The shared instance backed by the native singleton.</summary>
    public static WindowManager Shared { get; } = new WindowManager();

    private WindowManager() { }

    public Window? Get(uint id)
    {
        var rawResult = Interop.native_window_manager_get(id);
        return rawResult == 0 ? null : new Window(rawResult);
    }

    public Window[] GetAll()
    {
        var rawResult = Interop.native_window_manager_get_all();
        var count = rawResult.windows == IntPtr.Zero ? 0 : checked((int)rawResult.count.Value);
        var items = new Window[count];
        for (var i = 0; i < count; i++)
        {
            items[i] = new Window((ulong)Marshal.ReadInt64(rawResult.windows, i * 8));
        }
        // The handles now belong to `items`; free just the array.
        Interop.native_window_list_release(ref rawResult);
        return items;
    }

    public Window? GetCurrent()
    {
        var rawResult = Interop.native_window_manager_get_current();
        return rawResult == 0 ? null : new Window(rawResult);
    }

    public void SetWillShowHook(Action<uint>? hook)
    {
        WindowManagerSetWillShowHookHookNativeCallback? nativeHook = null;
        if (hook is { } bodyHook)
        {
            nativeHook = CallbackKeeper.Retain<WindowManagerSetWillShowHookHookNativeCallback>((arg0, userData) => bodyHook(arg0));
        }
        Interop.native_window_manager_set_will_show_hook(nativeHook, IntPtr.Zero);
    }

    public void SetWillHideHook(Action<uint>? hook)
    {
        WindowManagerSetWillHideHookHookNativeCallback? nativeHook = null;
        if (hook is { } bodyHook)
        {
            nativeHook = CallbackKeeper.Retain<WindowManagerSetWillHideHookHookNativeCallback>((arg0, userData) => bodyHook(arg0));
        }
        Interop.native_window_manager_set_will_hide_hook(nativeHook, IntPtr.Zero);
    }

    public bool HasWillShowHook()
    {
        var rawResult = Interop.native_window_manager_has_will_show_hook();
        return rawResult;
    }

    public bool HasWillHideHook()
    {
        var rawResult = Interop.native_window_manager_has_will_hide_hook();
        return rawResult;
    }

    public void HandleWillShow(uint id)
    {
        Interop.native_window_manager_handle_will_show(id);
    }

    public void HandleWillHide(uint id)
    {
        Interop.native_window_manager_handle_will_hide(id);
    }

    public bool CallOriginalShow(uint id)
    {
        var rawResult = Interop.native_window_manager_call_original_show(id);
        return rawResult;
    }

    public bool CallOriginalHide(uint id)
    {
        var rawResult = Interop.native_window_manager_call_original_hide(id);
        return rawResult;
    }

    /// <summary>Registers <paramref name="callback"/> for every WindowEvent this WindowManager emits.</summary>
    /// <remarks>
    /// The delegate is retained for good: the C ABI keeps the context
    /// pointer but offers no hook to release it, so removing the listener
    /// stops the calls without freeing the delegate.
    /// </remarks>
    public ulong AddListener(Action<WindowEvent> callback)
    {
        var native = CallbackKeeper.Retain<WindowEventNativeCallback>((evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = WindowEvent.FromRaw(Marshal.PtrToStructure<native_window_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        });
        return Interop.native_window_manager_add_listener(native, IntPtr.Zero);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_window_manager_remove_listener(listenerId);
    }

}

