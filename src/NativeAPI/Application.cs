// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

/// <summary>One ApplicationEvent, in its concrete form.</summary>
public abstract record ApplicationEvent
{
    private ApplicationEvent() { }

    public sealed record Started : ApplicationEvent;
    public sealed record Exiting(int ExitCode) : ApplicationEvent;
    public sealed record Activated : ApplicationEvent;
    public sealed record Deactivated : ApplicationEvent;
    public sealed record QuitRequested : ApplicationEvent;

    internal static ApplicationEvent? FromRaw(in native_application_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Started();
            case 1: return new Exiting(raw.data.exiting.exit_code);
            case 2: return new Activated();
            case 3: return new Deactivated();
            case 4: return new QuitRequested();
            default: return null;
        }
    }
}

public sealed partial class Application
{
    /// <summary>The shared instance backed by the native singleton.</summary>
    public static Application Shared { get; } = new Application();

    private Application() { }

    public int Run()
    {
        var rawResult = Interop.native_application_run();
        return rawResult;
    }

    public int RunWithWindow(Window? window)
    {
        var rawResult = Interop.native_application_run_with_window(window?.NativeHandle ?? 0);
        return rawResult;
    }

    public void Quit(int exitCode)
    {
        Interop.native_application_quit(exitCode);
    }

    public bool IsRunning()
    {
        var rawResult = Interop.native_application_is_running();
        return rawResult;
    }

    public bool IsSingleInstance()
    {
        var rawResult = Interop.native_application_is_single_instance();
        return rawResult;
    }

    public bool SetIcon(string iconPath)
    {
        var rawResult = Interop.native_application_set_icon(iconPath);
        return rawResult;
    }

    public bool SetDockIconVisible(bool visible)
    {
        var rawResult = Interop.native_application_set_dock_icon_visible(visible);
        return rawResult;
    }

    public bool SetMenuBar(Menu? menu)
    {
        var rawResult = Interop.native_application_set_menu_bar(menu?.NativeHandle ?? 0);
        return rawResult;
    }

    public Window? GetPrimaryWindow()
    {
        var rawResult = Interop.native_application_get_primary_window();
        return rawResult == 0 ? null : new Window(rawResult);
    }

    public void SetPrimaryWindow(Window? window)
    {
        Interop.native_application_set_primary_window(window?.NativeHandle ?? 0);
    }

    public Window[] GetAllWindows()
    {
        var rawResult = Interop.native_application_get_all_windows();
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

    /// <summary>Registers <paramref name="callback"/> for every ApplicationEvent this Application emits.</summary>
    /// <remarks>
    /// The delegate is retained for good: the C ABI keeps the context
    /// pointer but offers no hook to release it, so removing the listener
    /// stops the calls without freeing the delegate.
    /// </remarks>
    public ulong AddListener(Action<ApplicationEvent> callback)
    {
        var native = CallbackKeeper.Retain<ApplicationEventNativeCallback>((evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = ApplicationEvent.FromRaw(Marshal.PtrToStructure<native_application_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        });
        return Interop.native_application_add_listener(native, IntPtr.Zero);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_application_remove_listener(listenerId);
    }

}

