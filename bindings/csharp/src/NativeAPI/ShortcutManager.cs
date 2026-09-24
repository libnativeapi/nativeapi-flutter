// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using CNativeAPI;

namespace NativeAPI;

public sealed partial class ShortcutManager
{
    /// <summary>The shared instance backed by the native singleton.</summary>
    public static ShortcutManager Shared { get; } = new ShortcutManager();

    private ShortcutManager() { }

    public bool IsSupported()
    {
        var rawResult = Interop.native_shortcut_manager_is_supported();
        return rawResult;
    }

    public Shortcut? RegisterWithAcceleratorAndCallback(string accelerator, Action callback)
    {
        var nativeCallback = CallbackKeeper.Retain<ShortcutManagerRegisterWithAcceleratorAndCallbackCallbackNativeCallback>((userData) => callback());
        var rawResult = Interop.native_shortcut_manager_register_with_accelerator_and_callback(accelerator, nativeCallback, IntPtr.Zero);
        return rawResult == 0 ? null : new Shortcut(rawResult);
    }

    public Shortcut? RegisterWithOptions(ShortcutOptions options)
    {
        var rawOptions = options.ToRaw();
        var rawResult = Interop.native_shortcut_manager_register_with_options(rawOptions);
        ShortcutOptions.ReleaseRaw(ref rawOptions);
        return rawResult == 0 ? null : new Shortcut(rawResult);
    }

    public bool UnregisterWithId(uint id)
    {
        var rawResult = Interop.native_shortcut_manager_unregister_with_id(id);
        return rawResult;
    }

    public bool UnregisterWithAccelerator(string accelerator)
    {
        var rawResult = Interop.native_shortcut_manager_unregister_with_accelerator(accelerator);
        return rawResult;
    }

    public int UnregisterAll()
    {
        var rawResult = Interop.native_shortcut_manager_unregister_all();
        return rawResult;
    }

    public Shortcut? GetWithId(uint id)
    {
        var rawResult = Interop.native_shortcut_manager_get_with_id(id);
        return rawResult == 0 ? null : new Shortcut(rawResult);
    }

    public Shortcut? GetWithAccelerator(string accelerator)
    {
        var rawResult = Interop.native_shortcut_manager_get_with_accelerator(accelerator);
        return rawResult == 0 ? null : new Shortcut(rawResult);
    }

    public Shortcut[] GetAll()
    {
        var rawResult = Interop.native_shortcut_manager_get_all();
        var count = rawResult.shortcuts == IntPtr.Zero ? 0 : checked((int)rawResult.count.Value);
        var items = new Shortcut[count];
        for (var i = 0; i < count; i++)
        {
            items[i] = new Shortcut((ulong)Marshal.ReadInt64(rawResult.shortcuts, i * 8));
        }
        // The handles now belong to `items`; free just the array.
        Interop.native_shortcut_list_release(ref rawResult);
        return items;
    }

    public Shortcut[] GetByScope(ShortcutScope scope)
    {
        var rawResult = Interop.native_shortcut_manager_get_by_scope((int)scope);
        var count = rawResult.shortcuts == IntPtr.Zero ? 0 : checked((int)rawResult.count.Value);
        var items = new Shortcut[count];
        for (var i = 0; i < count; i++)
        {
            items[i] = new Shortcut((ulong)Marshal.ReadInt64(rawResult.shortcuts, i * 8));
        }
        // The handles now belong to `items`; free just the array.
        Interop.native_shortcut_list_release(ref rawResult);
        return items;
    }

    public bool IsAvailable(string accelerator)
    {
        var rawResult = Interop.native_shortcut_manager_is_available(accelerator);
        return rawResult;
    }

    public bool IsValidAccelerator(string accelerator)
    {
        var rawResult = Interop.native_shortcut_manager_is_valid_accelerator(accelerator);
        return rawResult;
    }

    public void SetEnabled(bool enabled)
    {
        Interop.native_shortcut_manager_set_enabled(enabled);
    }

    public bool IsEnabled()
    {
        var rawResult = Interop.native_shortcut_manager_is_enabled();
        return rawResult;
    }

    public void EmitShortcutActivated(uint id, string accelerator)
    {
        Interop.native_shortcut_manager_emit_shortcut_activated(id, accelerator);
    }

    /// <summary>Registers <paramref name="callback"/> for every ShortcutEvent this ShortcutManager emits.</summary>
    /// <remarks>
    /// The delegate is retained for good: the C ABI keeps the context
    /// pointer but offers no hook to release it, so removing the listener
    /// stops the calls without freeing the delegate.
    /// </remarks>
    public ulong AddListener(Action<ShortcutEvent> callback)
    {
        var native = CallbackKeeper.Retain<ShortcutEventNativeCallback>((evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = ShortcutEvent.FromRaw(Marshal.PtrToStructure<native_shortcut_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        });
        return Interop.native_shortcut_manager_add_listener(native, IntPtr.Zero);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_shortcut_manager_remove_listener(listenerId);
    }

}

