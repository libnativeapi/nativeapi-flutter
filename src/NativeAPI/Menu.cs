// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#nullable enable

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NativeAPI;

public enum MenuItemType
{
    Normal = 0,
    Checkbox = 1,
    Radio = 2,
    Separator = 3,
    Submenu = 4,
}

public enum MenuItemState
{
    Unchecked = 0,
    Checked = 1,
    Mixed = 2,
}

[StructLayout(LayoutKind.Sequential)]
internal struct native_menu_event_t
{
    internal int type;
    internal DataUnion data;

    [StructLayout(LayoutKind.Explicit)]
    internal struct DataUnion
    {
        [FieldOffset(0)] internal OpenedData opened;
        [FieldOffset(0)] internal ClosedData closed;
        [FieldOffset(0)] internal ItemClickedData item_clicked;
        [FieldOffset(0)] internal ItemSubmenuOpenedData item_submenu_opened;
        [FieldOffset(0)] internal ItemSubmenuClosedData item_submenu_closed;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct OpenedData
    {
        internal uint menu_id;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct ClosedData
    {
        internal uint menu_id;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct ItemClickedData
    {
        internal uint item_id;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct ItemSubmenuOpenedData
    {
        internal uint item_id;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct ItemSubmenuClosedData
    {
        internal uint item_id;
    }
}

/// <summary>One MenuEvent, in its concrete form.</summary>
public abstract record MenuEvent
{
    private MenuEvent() { }

    public sealed record Opened(uint MenuId) : MenuEvent;
    public sealed record Closed(uint MenuId) : MenuEvent;
    public sealed record ItemClicked(uint ItemId) : MenuEvent;
    public sealed record ItemSubmenuOpened(uint ItemId) : MenuEvent;
    public sealed record ItemSubmenuClosed(uint ItemId) : MenuEvent;

    internal static MenuEvent? FromRaw(in native_menu_event_t raw)
    {
        switch (raw.type)
        {
            case 0: return new Opened(raw.data.opened.menu_id);
            case 1: return new Closed(raw.data.closed.menu_id);
            case 2: return new ItemClicked(raw.data.item_clicked.item_id);
            case 3: return new ItemSubmenuOpened(raw.data.item_submenu_opened.item_id);
            case 4: return new ItemSubmenuClosed(raw.data.item_submenu_closed.item_id);
            default: return null;
        }
    }
}

[StructLayout(LayoutKind.Sequential)]
internal struct native_menu_item_list_t
{
    internal IntPtr menu_items;
    internal CLong count;
}

/// <summary>Owned handle to a native MenuItem.</summary>
public sealed partial class MenuItem : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public MenuItem(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~MenuItem() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_menu_item_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new MenuItem; returns null if the native side failed.</summary>
    public static MenuItem? CreateWithLabelAndType(string label, MenuItemType type)
    {
        var handle = Interop.native_menu_item_create_with_label_and_type(label, type);
        return handle == 0 ? null : new MenuItem(handle);
    }

    /// <summary>Creates a new MenuItem; returns null if the native side failed.</summary>
    public static MenuItem? CreateWithNativeItem(IntPtr nativeItem)
    {
        var handle = Interop.native_menu_item_create_with_native_item(nativeItem);
        return handle == 0 ? null : new MenuItem(handle);
    }

    public uint Id
    {
        get
        {
            var rawResult = Interop.native_menu_item_get_id(NativeHandle);
            return rawResult;
        }
    }

    public MenuItemType Type
    {
        get
        {
            var rawResult = Interop.native_menu_item_get_type(NativeHandle);
            return rawResult;
        }
    }

    public void SetLabel(string? label)
    {
        Interop.native_menu_item_set_label(NativeHandle, label);
    }

    public string? Label
    {
        get
        {
            var rawResult = Interop.native_menu_item_get_label(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public void SetIcon(Image? image)
    {
        Interop.native_menu_item_set_icon(NativeHandle, image?.NativeHandle ?? 0);
    }

    public Image? Icon
    {
        get
        {
            var rawResult = Interop.native_menu_item_get_icon(NativeHandle);
            return rawResult == 0 ? null : new Image(rawResult);
        }
    }

    public void SetTooltip(string? tooltip)
    {
        Interop.native_menu_item_set_tooltip(NativeHandle, tooltip);
    }

    public string? Tooltip
    {
        get
        {
            var rawResult = Interop.native_menu_item_get_tooltip(NativeHandle);
            return Interop.ConsumeString(rawResult);
        }
    }

    public void SetAccelerator(KeyboardAccelerator? accelerator)
    {
        var ptrAccelerator = IntPtr.Zero;
        if (accelerator is { } valueAccelerator)
        {
            var rawAccelerator = valueAccelerator.ToRaw();
            ptrAccelerator = Marshal.AllocHGlobal(Marshal.SizeOf<native_keyboard_accelerator_t>());
            Marshal.StructureToPtr(rawAccelerator, ptrAccelerator, false);
        }
        Interop.native_menu_item_set_accelerator(NativeHandle, ptrAccelerator);
        if (ptrAccelerator != IntPtr.Zero)
        {
            var ownedAccelerator = Marshal.PtrToStructure<native_keyboard_accelerator_t>(ptrAccelerator);
            KeyboardAccelerator.ReleaseRaw(ref ownedAccelerator);
            Marshal.FreeHGlobal(ptrAccelerator);
        }
    }

    public KeyboardAccelerator Accelerator
    {
        get
        {
            var rawResult = Interop.native_menu_item_get_accelerator(NativeHandle);
            var result = KeyboardAccelerator.FromRaw(in rawResult);
            Interop.native_keyboard_accelerator_free(ref rawResult);
            return result;
        }
    }

    public void SetEnabled(bool enabled)
    {
        Interop.native_menu_item_set_enabled(NativeHandle, enabled);
    }

    public bool IsEnabled
    {
        get
        {
            var rawResult = Interop.native_menu_item_is_enabled(NativeHandle);
            return rawResult;
        }
    }

    public void SetState(MenuItemState state)
    {
        Interop.native_menu_item_set_state(NativeHandle, state);
    }

    public MenuItemState State
    {
        get
        {
            var rawResult = Interop.native_menu_item_get_state(NativeHandle);
            return rawResult;
        }
    }

    public void SetRadioGroup(int groupId)
    {
        Interop.native_menu_item_set_radio_group(NativeHandle, groupId);
    }

    public int RadioGroup
    {
        get
        {
            var rawResult = Interop.native_menu_item_get_radio_group(NativeHandle);
            return rawResult;
        }
    }

    public void SetSubmenu(Menu? submenu)
    {
        Interop.native_menu_item_set_submenu(NativeHandle, submenu?.NativeHandle ?? 0);
    }

    public Menu? Submenu
    {
        get
        {
            var rawResult = Interop.native_menu_item_get_submenu(NativeHandle);
            return rawResult == 0 ? null : new Menu(rawResult);
        }
    }

    /// <summary>Platform-specific native object behind this handle.</summary>
    public IntPtr NativeObject => Interop.native_menu_item_get_native_object(NativeHandle);

    /// <summary>Registers <paramref name="callback"/> for every MenuEvent this MenuItem emits.</summary>
    /// <remarks>
    /// The delegate is retained for good: the C ABI keeps the context
    /// pointer but offers no hook to release it, so removing the listener
    /// stops the calls without freeing the delegate.
    /// </remarks>
    public ulong AddListener(Action<MenuEvent> callback)
    {
        var native = CallbackKeeper.Retain<MenuEventNativeCallback>((evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = MenuEvent.FromRaw(Marshal.PtrToStructure<native_menu_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        });
        return Interop.native_menu_item_add_listener(NativeHandle, native, IntPtr.Zero);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_menu_item_remove_listener(NativeHandle, listenerId);
    }

}

/// <summary>Owned handle to a native Menu.</summary>
public sealed partial class Menu : IDisposable
{
    public ulong NativeHandle { get; private set; }
    private readonly bool _ownsHandle;

    public Menu(ulong nativeHandle, bool ownsHandle = true)
    {
        NativeHandle = nativeHandle;
        _ownsHandle = ownsHandle;
    }

    ~Menu() => ReleaseHandle();

    public void Dispose()
    {
        ReleaseHandle();
        GC.SuppressFinalize(this);
    }

    private void ReleaseHandle()
    {
        if (_ownsHandle && NativeHandle != 0)
        {
            Interop.native_menu_free(NativeHandle);
            NativeHandle = 0;
        }
    }

    /// <summary>Creates a new Menu; returns null if the native side failed.</summary>
    public static Menu? Create()
    {
        var handle = Interop.native_menu_create();
        return handle == 0 ? null : new Menu(handle);
    }

    /// <summary>Creates a new Menu; returns null if the native side failed.</summary>
    public static Menu? CreateWithNativeMenu(IntPtr nativeMenu)
    {
        var handle = Interop.native_menu_create_with_native_menu(nativeMenu);
        return handle == 0 ? null : new Menu(handle);
    }

    public uint Id
    {
        get
        {
            var rawResult = Interop.native_menu_get_id(NativeHandle);
            return rawResult;
        }
    }

    public void AddItem(MenuItem? item)
    {
        Interop.native_menu_add_item(NativeHandle, item?.NativeHandle ?? 0);
    }

    public void InsertItem(ulong index, MenuItem? item)
    {
        Interop.native_menu_insert_item(NativeHandle, new CULong(checked((nuint)index)), item?.NativeHandle ?? 0);
    }

    public bool RemoveItem(MenuItem? item)
    {
        var rawResult = Interop.native_menu_remove_item(NativeHandle, item?.NativeHandle ?? 0);
        return rawResult;
    }

    public bool RemoveItemById(uint itemId)
    {
        var rawResult = Interop.native_menu_remove_item_by_id(NativeHandle, itemId);
        return rawResult;
    }

    public bool RemoveItemAt(ulong index)
    {
        var rawResult = Interop.native_menu_remove_item_at(NativeHandle, new CULong(checked((nuint)index)));
        return rawResult;
    }

    public void Clear()
    {
        Interop.native_menu_clear(NativeHandle);
    }

    public void AddSeparator()
    {
        Interop.native_menu_add_separator(NativeHandle);
    }

    public void InsertSeparator(ulong index)
    {
        Interop.native_menu_insert_separator(NativeHandle, new CULong(checked((nuint)index)));
    }

    public ulong ItemCount
    {
        get
        {
            var rawResult = Interop.native_menu_get_item_count(NativeHandle);
            return (ulong)rawResult.Value;
        }
    }

    public MenuItem? GetItemAt(ulong index)
    {
        var rawResult = Interop.native_menu_get_item_at(NativeHandle, new CULong(checked((nuint)index)));
        return rawResult == 0 ? null : new MenuItem(rawResult);
    }

    public MenuItem? GetItemById(uint itemId)
    {
        var rawResult = Interop.native_menu_get_item_by_id(NativeHandle, itemId);
        return rawResult == 0 ? null : new MenuItem(rawResult);
    }

    public MenuItem[] AllItems
    {
        get
        {
            var rawResult = Interop.native_menu_get_all_items(NativeHandle);
            var count = rawResult.menu_items == IntPtr.Zero ? 0 : checked((int)rawResult.count.Value);
            var items = new MenuItem[count];
            for (var i = 0; i < count; i++)
            {
                items[i] = new MenuItem((ulong)Marshal.ReadInt64(rawResult.menu_items, i * 8));
            }
            // The handles now belong to `items`; free just the array.
            Interop.native_menu_item_list_release(ref rawResult);
            return items;
        }
    }

    public bool Open(PositioningStrategy strategy, Placement placement)
    {
        var rawResult = Interop.native_menu_open(NativeHandle, strategy.NativeHandle, placement);
        return rawResult;
    }

    public bool Close()
    {
        var rawResult = Interop.native_menu_close(NativeHandle);
        return rawResult;
    }

    /// <summary>Platform-specific native object behind this handle.</summary>
    public IntPtr NativeObject => Interop.native_menu_get_native_object(NativeHandle);

    /// <summary>Registers <paramref name="callback"/> for every MenuEvent this Menu emits.</summary>
    /// <remarks>
    /// The delegate is retained for good: the C ABI keeps the context
    /// pointer but offers no hook to release it, so removing the listener
    /// stops the calls without freeing the delegate.
    /// </remarks>
    public ulong AddListener(Action<MenuEvent> callback)
    {
        var native = CallbackKeeper.Retain<MenuEventNativeCallback>((evt, userData) =>
        {
            if (evt == IntPtr.Zero)
            {
                return;
            }
            var value = MenuEvent.FromRaw(Marshal.PtrToStructure<native_menu_event_t>(evt));
            if (value is not null)
            {
                callback(value);
            }
        });
        return Interop.native_menu_add_listener(NativeHandle, native, IntPtr.Zero);
    }

    /// <summary>Unregisters a listener. Returns false if unknown.</summary>
    public bool RemoveListener(ulong listenerId)
    {
        return Interop.native_menu_remove_listener(NativeHandle, listenerId);
    }

}

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
internal delegate void MenuEventNativeCallback(IntPtr evt, IntPtr userData);

internal static partial class Interop
{
    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_menu_close(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_menu_item_is_enabled(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_menu_item_remove_listener(ulong self, ulong listenerId);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_menu_open(ulong self, ulong strategy, Placement placement);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_menu_remove_item(ulong self, ulong item);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_menu_remove_item_at(ulong self, CULong index);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_menu_remove_item_by_id(ulong self, uint itemId);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    internal static extern bool native_menu_remove_listener(ulong self, ulong listenerId);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern CULong native_menu_get_item_count(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_menu_get_native_object(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_menu_item_get_label(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_menu_item_get_native_object(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr native_menu_item_get_tooltip(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern MenuItemState native_menu_item_get_state(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern MenuItemType native_menu_item_get_type(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int native_menu_item_get_radio_group(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_keyboard_accelerator_t native_menu_item_get_accelerator(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern native_menu_item_list_t native_menu_get_all_items(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern uint native_menu_get_id(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern uint native_menu_item_get_id(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_menu_add_listener(ulong self, MenuEventNativeCallback callback, IntPtr userData);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_menu_create();

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_menu_create_with_native_menu(IntPtr nativeMenu);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_menu_get_item_at(ulong self, CULong index);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_menu_get_item_by_id(ulong self, uint itemId);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_menu_item_add_listener(ulong self, MenuEventNativeCallback callback, IntPtr userData);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_menu_item_create_with_label_and_type([MarshalAs(UnmanagedType.LPUTF8Str)] string? label, MenuItemType type);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_menu_item_create_with_native_item(IntPtr nativeItem);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_menu_item_get_icon(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong native_menu_item_get_submenu(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_add_item(ulong self, ulong item);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_add_separator(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_clear(ulong self);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_free(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_insert_item(ulong self, CULong index, ulong item);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_insert_separator(ulong self, CULong index);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_item_free(ulong handle);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_item_list_release(ref native_menu_item_list_t list);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_item_set_accelerator(ulong self, IntPtr accelerator);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_item_set_enabled(ulong self, [MarshalAs(UnmanagedType.I1)] bool enabled);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_item_set_icon(ulong self, ulong image);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_item_set_label(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? label);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_item_set_radio_group(ulong self, int groupId);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_item_set_state(ulong self, MenuItemState state);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_item_set_submenu(ulong self, ulong submenu);

    [DllImport(Libraries.NativeApi, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void native_menu_item_set_tooltip(ulong self, [MarshalAs(UnmanagedType.LPUTF8Str)] string? tooltip);
}

