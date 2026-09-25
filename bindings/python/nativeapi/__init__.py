# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Native desktop APIs (windows, tray icons, menus, displays, shortcuts,
dialogs, storage) for Python, over the libnativeapi C ABI."""

from ._runtime import (
    NativeApiError,
    NativeObject,
    is_event_loop_running,
)
from .accessibility_manager import (
    AccessibilityManager,
)
from .app_info import (
    AppInfo,
)
from .application import (
    Application,
    ApplicationActivatedEvent,
    ApplicationDeactivatedEvent,
    ApplicationEvent,
    ApplicationExitingEvent,
    ApplicationQuitRequestedEvent,
    ApplicationStartedEvent,
    Brightness,
)
from .color import (
    Color,
)
from .device_info import (
    DeviceInfo,
)
from .dialog import (
    DialogModality,
)
from .display import (
    Display,
    DisplayAddedEvent,
    DisplayChangedEvent,
    DisplayEvent,
    DisplayId,
    DisplayOrientation,
    DisplayRemovedEvent,
)
from .display_manager import (
    DisplayManager,
)
from .drag_source import (
    DragOperation,
    DragSource,
    DragSourceEndedEvent,
    DragSourceEvent,
)
from .drop_target import (
    DropTarget,
    DropTargetDroppedEvent,
    DropTargetEnteredEvent,
    DropTargetEvent,
    DropTargetExitedEvent,
    DropTargetMovedEvent,
)
from .file_dialog import (
    FileDialog,
    FileDialogMode,
    FileDialogResult,
)
from .geometry import (
    EdgeInsets,
    Point,
    Rectangle,
    Size,
)
from .image import (
    Image,
)
from .keyboard import (
    KeyboardAccelerator,
    KeyboardEvent,
    KeyPressedEvent,
    KeyReleasedEvent,
    ModifierKey,
    ModifierKeysChangedEvent,
)
from .keyboard_monitor import (
    KeyboardMonitor,
)
from .launch_at_login import (
    LaunchAtLogin,
)
from .menu import (
    Menu,
    MenuBackend,
    MenuClosedEvent,
    MenuEvent,
    MenuId,
    MenuItem,
    MenuItemClickedEvent,
    MenuItemId,
    MenuItemState,
    MenuItemSubmenuClosedEvent,
    MenuItemSubmenuOpenedEvent,
    MenuItemType,
    MenuOpenedEvent,
)
from .message_dialog import (
    MessageDialog,
    MessageDialogResult,
)
from .notification_manager import (
    NotificationActivatedEvent,
    NotificationEvent,
    NotificationManager,
)
from .placement import (
    Placement,
)
from .positioning_strategy import (
    PositioningStrategy,
    PositioningStrategyType,
)
from .preferences import (
    Preferences,
)
from .secure_storage import (
    SecureStorage,
)
from .shortcut import (
    Shortcut,
    ShortcutActivatedEvent,
    ShortcutEvent,
    ShortcutId,
    ShortcutOptions,
    ShortcutRegisteredEvent,
    ShortcutRegistrationFailedEvent,
    ShortcutScope,
    ShortcutUnregisteredEvent,
)
from .shortcut_manager import (
    ShortcutManager,
)
from .tray_icon import (
    ContextMenuTrigger,
    TrayIcon,
    TrayIconClickedEvent,
    TrayIconDoubleClickedEvent,
    TrayIconEvent,
    TrayIconId,
    TrayIconPosition,
    TrayIconRightClickedEvent,
)
from .tray_manager import (
    TrayManager,
)
from .url_opener import (
    UrlOpener,
    UrlOpenErrorCode,
    UrlOpenResult,
)
from .view import (
    Button,
    ButtonClickedEvent,
    ImageView,
    Label,
    TextAlignment,
    TextField,
    TextFieldChangedEvent,
    TextFieldSubmittedEvent,
    View,
    ViewAlignment,
    ViewBlurredEvent,
    ViewEvent,
    ViewFocusedEvent,
    ViewId,
    ViewLayout,
)
from .window import (
    ResizeEdge,
    TitleBarStyle,
    VisualEffect,
    Window,
    WindowBlurredEvent,
    WindowClosedEvent,
    WindowCreatedEvent,
    WindowEvent,
    WindowFocusedEvent,
    WindowId,
    WindowMaximizedEvent,
    WindowMinimizedEvent,
    WindowMovedEvent,
    WindowResizedEvent,
    WindowRestoredEvent,
)
from .window_drag_session import (
    WindowDragCancelledEvent,
    WindowDragEndedEvent,
    WindowDragEvent,
    WindowDragMovedEvent,
    WindowDragSession,
)
from .window_manager import (
    WindowManager,
)
from .window_shadow import (
    WindowShadow,
)
from .window_shape import (
    WindowShape,
)

__all__ = [
    "AccessibilityManager",
    "AppInfo",
    "Application",
    "ApplicationActivatedEvent",
    "ApplicationDeactivatedEvent",
    "ApplicationEvent",
    "ApplicationExitingEvent",
    "ApplicationQuitRequestedEvent",
    "ApplicationStartedEvent",
    "Brightness",
    "Button",
    "ButtonClickedEvent",
    "Color",
    "ContextMenuTrigger",
    "DeviceInfo",
    "DialogModality",
    "Display",
    "DisplayAddedEvent",
    "DisplayChangedEvent",
    "DisplayEvent",
    "DisplayId",
    "DisplayManager",
    "DisplayOrientation",
    "DisplayRemovedEvent",
    "DragOperation",
    "DragSource",
    "DragSourceEndedEvent",
    "DragSourceEvent",
    "DropTarget",
    "DropTargetDroppedEvent",
    "DropTargetEnteredEvent",
    "DropTargetEvent",
    "DropTargetExitedEvent",
    "DropTargetMovedEvent",
    "EdgeInsets",
    "FileDialog",
    "FileDialogMode",
    "FileDialogResult",
    "Image",
    "ImageView",
    "KeyPressedEvent",
    "KeyReleasedEvent",
    "KeyboardAccelerator",
    "KeyboardEvent",
    "KeyboardMonitor",
    "Label",
    "LaunchAtLogin",
    "Menu",
    "MenuBackend",
    "MenuClosedEvent",
    "MenuEvent",
    "MenuId",
    "MenuItem",
    "MenuItemClickedEvent",
    "MenuItemId",
    "MenuItemState",
    "MenuItemSubmenuClosedEvent",
    "MenuItemSubmenuOpenedEvent",
    "MenuItemType",
    "MenuOpenedEvent",
    "MessageDialog",
    "MessageDialogResult",
    "ModifierKey",
    "ModifierKeysChangedEvent",
    "NativeApiError",
    "NativeObject",
    "NotificationActivatedEvent",
    "NotificationEvent",
    "NotificationManager",
    "Placement",
    "Point",
    "PositioningStrategy",
    "PositioningStrategyType",
    "Preferences",
    "Rectangle",
    "ResizeEdge",
    "SecureStorage",
    "Shortcut",
    "ShortcutActivatedEvent",
    "ShortcutEvent",
    "ShortcutId",
    "ShortcutManager",
    "ShortcutOptions",
    "ShortcutRegisteredEvent",
    "ShortcutRegistrationFailedEvent",
    "ShortcutScope",
    "ShortcutUnregisteredEvent",
    "Size",
    "TextAlignment",
    "TextField",
    "TextFieldChangedEvent",
    "TextFieldSubmittedEvent",
    "TitleBarStyle",
    "TrayIcon",
    "TrayIconClickedEvent",
    "TrayIconDoubleClickedEvent",
    "TrayIconEvent",
    "TrayIconId",
    "TrayIconPosition",
    "TrayIconRightClickedEvent",
    "TrayManager",
    "UrlOpenErrorCode",
    "UrlOpenResult",
    "UrlOpener",
    "View",
    "ViewAlignment",
    "ViewBlurredEvent",
    "ViewEvent",
    "ViewFocusedEvent",
    "ViewId",
    "ViewLayout",
    "VisualEffect",
    "Window",
    "WindowBlurredEvent",
    "WindowClosedEvent",
    "WindowCreatedEvent",
    "WindowDragCancelledEvent",
    "WindowDragEndedEvent",
    "WindowDragEvent",
    "WindowDragMovedEvent",
    "WindowDragSession",
    "WindowEvent",
    "WindowFocusedEvent",
    "WindowId",
    "WindowManager",
    "WindowMaximizedEvent",
    "WindowMinimizedEvent",
    "WindowMovedEvent",
    "WindowResizedEvent",
    "WindowRestoredEvent",
    "WindowShadow",
    "WindowShape",
    "is_event_loop_running",
]
