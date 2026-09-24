// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

/// <summary>Owned handle to a native KeyboardMonitor.</summary>
public sealed partial class KeyboardMonitor : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public KeyboardMonitor(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~KeyboardMonitor() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_keyboard_monitor_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new KeyboardMonitor; returns null if the native side failed.</summary>
    public static KeyboardMonitor? Create()
    {
        var handle = Interop.native_keyboard_monitor_create();
        return handle == 0 ? null : new KeyboardMonitor(handle);
    }

    public void Start()
    {
        Interop.native_keyboard_monitor_start(NativeHandle);
    }

    public void Stop()
    {
        Interop.native_keyboard_monitor_stop(NativeHandle);
    }

    public bool IsMonitoring
    {
        get
        {
            var rawResult = Interop.native_keyboard_monitor_is_monitoring(NativeHandle);
            return rawResult;
        }
    }

    /// <summary>Registers <paramref name="callback"/> for every KeyboardEvent this KeyboardMonitor emits.</summary>
    /// <remarks>
    /// The delegate is retained for good: the C ABI keeps the context
    /// pointer but offers no hook to release it, so removing the listener
    /// stops the calls without freeing the delegate.
    /// </remarks>
    public ulong AddListener(Action<KeyboardEvent> callback)
    {
        var native = CallbackKeeper.Retain<KeyboardEventNativeCallback>((evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = KeyboardEvent.FromRaw(Marshal.PtrToStructure<native_keyboard_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        });
        return Interop.native_keyboard_monitor_add_listener(NativeHandle, native, IntPtr.Zero);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_keyboard_monitor_remove_listener(NativeHandle, listenerId);
    }

}

