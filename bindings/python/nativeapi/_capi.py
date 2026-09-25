# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""The C ABI as ctypes declarations, one to one. Application code should use
the public modules instead."""

from ctypes import (
    CFUNCTYPE,
    POINTER,
    Structure,
    Union,
    c_bool,
    c_char_p,
    c_double,
    c_float,
    c_int,
    c_long,
    c_ubyte,
    c_uint,
    c_uint64,
    c_ulong,
    c_void_p,
)

from ._library import constant, function

# --- string containers (string_utils_c.h) ---


class native_string_list_t(Structure):
    _fields_ = [("items", POINTER(c_char_p)), ("count", c_long)]


class native_string_map_t(Structure):
    _fields_ = [
        ("keys", POINTER(c_char_p)),
        ("values", POINTER(c_char_p)),
        ("count", c_long),
    ]


free_c_str = function("free_c_str", None, [c_void_p])
native_string_list_free = function(
    "native_string_list_free",
    None,
    [
        POINTER(native_string_list_t),
    ],
)
native_string_map_free = function(
    "native_string_map_free",
    None,
    [
        POINTER(native_string_map_t),
    ],
)

# --- structures ---


class native_point_t(Structure):
    pass


class native_size_t(Structure):
    pass


class native_rectangle_t(Structure):
    pass


class native_color_t(Structure):
    pass


class native_keyboard_accelerator_t(Structure):
    pass


class native_keyboard_event_modifier_keys_changed_t(Structure):
    pass


class native_keyboard_event_data_t(Union):
    pass


class native_keyboard_event_t(Structure):
    pass


class native_display_event_t(Structure):
    pass


class native_url_open_result_t(Structure):
    pass


class native_notification_event_activated_t(Structure):
    pass


class native_notification_event_data_t(Union):
    pass


class native_notification_event_t(Structure):
    pass


class native_window_event_moved_t(Structure):
    pass


class native_window_event_resized_t(Structure):
    pass


class native_window_event_data_t(Union):
    pass


class native_window_event_t(Structure):
    pass


class native_window_drag_event_t(Structure):
    pass


class native_drag_source_event_ended_t(Structure):
    pass


class native_drag_source_event_data_t(Union):
    pass


class native_drag_source_event_t(Structure):
    pass


class native_drop_target_event_dropped_t(Structure):
    pass


class native_drop_target_event_data_t(Union):
    pass


class native_drop_target_event_t(Structure):
    pass


class native_menu_event_opened_t(Structure):
    pass


class native_menu_event_closed_t(Structure):
    pass


class native_menu_event_item_clicked_t(Structure):
    pass


class native_menu_event_item_submenu_opened_t(Structure):
    pass


class native_menu_event_item_submenu_closed_t(Structure):
    pass


class native_menu_event_data_t(Union):
    pass


class native_menu_event_t(Structure):
    pass


class native_tray_icon_event_clicked_t(Structure):
    pass


class native_tray_icon_event_right_clicked_t(Structure):
    pass


class native_tray_icon_event_double_clicked_t(Structure):
    pass


class native_tray_icon_event_data_t(Union):
    pass


class native_tray_icon_event_t(Structure):
    pass


class native_shortcut_options_t(Structure):
    pass


class native_shortcut_event_registration_failed_t(Structure):
    pass


class native_shortcut_event_data_t(Union):
    pass


class native_shortcut_event_t(Structure):
    pass


class native_application_event_exiting_t(Structure):
    pass


class native_application_event_data_t(Union):
    pass


class native_application_event_t(Structure):
    pass


class native_display_list_t(Structure):
    pass


class native_menu_item_list_t(Structure):
    pass


class native_shortcut_list_t(Structure):
    pass


class native_tray_icon_list_t(Structure):
    pass


class native_window_list_t(Structure):
    pass


# --- callbacks ---

native_application_event_callback_t = CFUNCTYPE(
    None,
    POINTER(native_application_event_t),
    c_void_p,
)
native_display_event_callback_t = CFUNCTYPE(
    None,
    POINTER(native_display_event_t),
    c_void_p,
)
native_drag_source_event_callback_t = CFUNCTYPE(
    None,
    POINTER(native_drag_source_event_t),
    c_void_p,
)
native_drop_target_event_callback_t = CFUNCTYPE(
    None,
    POINTER(native_drop_target_event_t),
    c_void_p,
)
native_keyboard_event_callback_t = CFUNCTYPE(
    None,
    POINTER(native_keyboard_event_t),
    c_void_p,
)
native_menu_event_callback_t = CFUNCTYPE(None, POINTER(native_menu_event_t), c_void_p)
native_notification_event_callback_t = CFUNCTYPE(
    None,
    POINTER(native_notification_event_t),
    c_void_p,
)
native_release_user_data_t = CFUNCTYPE(None, c_void_p)
native_shortcut_event_callback_t = CFUNCTYPE(
    None,
    POINTER(native_shortcut_event_t),
    c_void_p,
)
native_tray_icon_event_callback_t = CFUNCTYPE(
    None,
    POINTER(native_tray_icon_event_t),
    c_void_p,
)
native_uint_callback_t = CFUNCTYPE(None, c_uint, c_void_p)
native_void_callback_t = CFUNCTYPE(None, c_void_p)
native_window_drag_event_callback_t = CFUNCTYPE(
    None,
    POINTER(native_window_drag_event_t),
    c_void_p,
)
native_window_event_callback_t = CFUNCTYPE(
    None,
    POINTER(native_window_event_t),
    c_void_p,
)

# --- structure layouts, in dependency order ---

native_point_t._fields_ = [
    ("x", c_double),
    ("y", c_double),
]
native_size_t._fields_ = [
    ("width", c_double),
    ("height", c_double),
]
native_rectangle_t._fields_ = [
    ("x", c_double),
    ("y", c_double),
    ("width", c_double),
    ("height", c_double),
]
native_color_t._fields_ = [
    ("r", c_ubyte),
    ("g", c_ubyte),
    ("b", c_ubyte),
    ("a", c_ubyte),
]
native_keyboard_accelerator_t._fields_ = [
    ("modifiers", c_int),
    ("key", c_char_p),
]
native_keyboard_event_modifier_keys_changed_t._fields_ = [
    ("modifier_keys", c_uint),
]
native_keyboard_event_data_t._fields_ = [
    ("modifier_keys_changed", native_keyboard_event_modifier_keys_changed_t),
]
native_keyboard_event_t._fields_ = [
    ("type", c_int),
    ("keycode", c_int),
    ("data", native_keyboard_event_data_t),
]
native_display_event_t._fields_ = [
    ("type", c_int),
    ("display", c_uint64),
]
native_url_open_result_t._fields_ = [
    ("success", c_bool),
    ("error_code", c_int),
    ("error_message", c_char_p),
]
native_notification_event_activated_t._fields_ = [
    ("argument", c_char_p),
]
native_notification_event_data_t._fields_ = [
    ("activated", native_notification_event_activated_t),
]
native_notification_event_t._fields_ = [
    ("type", c_int),
    ("data", native_notification_event_data_t),
]
native_window_event_moved_t._fields_ = [
    ("new_position", native_point_t),
]
native_window_event_resized_t._fields_ = [
    ("new_size", native_size_t),
]
native_window_event_data_t._fields_ = [
    ("moved", native_window_event_moved_t),
    ("resized", native_window_event_resized_t),
]
native_window_event_t._fields_ = [
    ("type", c_int),
    ("window_id", c_uint),
    ("data", native_window_event_data_t),
]
native_window_drag_event_t._fields_ = [
    ("type", c_int),
    ("window_id", c_uint),
    ("cursor_position", native_point_t),
]
native_drag_source_event_ended_t._fields_ = [
    ("operation", c_int),
]
native_drag_source_event_data_t._fields_ = [
    ("ended", native_drag_source_event_ended_t),
]
native_drag_source_event_t._fields_ = [
    ("type", c_int),
    ("window_id", c_uint),
    ("position", native_point_t),
    ("data", native_drag_source_event_data_t),
]
native_drop_target_event_dropped_t._fields_ = [
    ("file_paths", native_string_list_t),
    ("text", c_char_p),
]
native_drop_target_event_data_t._fields_ = [
    ("dropped", native_drop_target_event_dropped_t),
]
native_drop_target_event_t._fields_ = [
    ("type", c_int),
    ("window_id", c_uint),
    ("position", native_point_t),
    ("data", native_drop_target_event_data_t),
]
native_menu_event_opened_t._fields_ = [
    ("menu_id", c_uint),
]
native_menu_event_closed_t._fields_ = [
    ("menu_id", c_uint),
]
native_menu_event_item_clicked_t._fields_ = [
    ("item_id", c_uint),
]
native_menu_event_item_submenu_opened_t._fields_ = [
    ("item_id", c_uint),
]
native_menu_event_item_submenu_closed_t._fields_ = [
    ("item_id", c_uint),
]
native_menu_event_data_t._fields_ = [
    ("opened", native_menu_event_opened_t),
    ("closed", native_menu_event_closed_t),
    ("item_clicked", native_menu_event_item_clicked_t),
    ("item_submenu_opened", native_menu_event_item_submenu_opened_t),
    ("item_submenu_closed", native_menu_event_item_submenu_closed_t),
]
native_menu_event_t._fields_ = [
    ("type", c_int),
    ("data", native_menu_event_data_t),
]
native_tray_icon_event_clicked_t._fields_ = [
    ("tray_icon_id", c_uint),
]
native_tray_icon_event_right_clicked_t._fields_ = [
    ("tray_icon_id", c_uint),
]
native_tray_icon_event_double_clicked_t._fields_ = [
    ("tray_icon_id", c_uint),
]
native_tray_icon_event_data_t._fields_ = [
    ("clicked", native_tray_icon_event_clicked_t),
    ("right_clicked", native_tray_icon_event_right_clicked_t),
    ("double_clicked", native_tray_icon_event_double_clicked_t),
]
native_tray_icon_event_t._fields_ = [
    ("type", c_int),
    ("data", native_tray_icon_event_data_t),
]
native_shortcut_options_t._fields_ = [
    ("accelerator", c_char_p),
    ("callback", native_void_callback_t),
    ("callback_user_data", c_void_p),
    ("callback_release_user_data", native_release_user_data_t),
    ("description", c_char_p),
    ("scope", c_int),
    ("enabled", c_bool),
]
native_shortcut_event_registration_failed_t._fields_ = [
    ("error_message", c_char_p),
]
native_shortcut_event_data_t._fields_ = [
    ("registration_failed", native_shortcut_event_registration_failed_t),
]
native_shortcut_event_t._fields_ = [
    ("type", c_int),
    ("shortcut_id", c_uint),
    ("accelerator", c_char_p),
    ("data", native_shortcut_event_data_t),
]
native_application_event_exiting_t._fields_ = [
    ("exit_code", c_int),
]
native_application_event_data_t._fields_ = [
    ("exiting", native_application_event_exiting_t),
]
native_application_event_t._fields_ = [
    ("type", c_int),
    ("data", native_application_event_data_t),
]
native_display_list_t._fields_ = [
    ("displays", POINTER(c_uint64)),
    ("count", c_long),
]
native_menu_item_list_t._fields_ = [
    ("menu_items", POINTER(c_uint64)),
    ("count", c_long),
]
native_shortcut_list_t._fields_ = [
    ("shortcuts", POINTER(c_uint64)),
    ("count", c_long),
]
native_tray_icon_list_t._fields_ = [
    ("tray_icons", POINTER(c_uint64)),
    ("count", c_long),
]
native_window_list_t._fields_ = [
    ("windows", POINTER(c_uint64)),
    ("count", c_long),
]

# --- constants ---

NATIVE_COLOR_TRANSPARENT = constant("NATIVE_COLOR_TRANSPARENT", native_color_t)
NATIVE_COLOR_BLACK = constant("NATIVE_COLOR_BLACK", native_color_t)
NATIVE_COLOR_WHITE = constant("NATIVE_COLOR_WHITE", native_color_t)
NATIVE_COLOR_RED = constant("NATIVE_COLOR_RED", native_color_t)
NATIVE_COLOR_GREEN = constant("NATIVE_COLOR_GREEN", native_color_t)
NATIVE_COLOR_BLUE = constant("NATIVE_COLOR_BLUE", native_color_t)
NATIVE_COLOR_YELLOW = constant("NATIVE_COLOR_YELLOW", native_color_t)
NATIVE_COLOR_CYAN = constant("NATIVE_COLOR_CYAN", native_color_t)
NATIVE_COLOR_MAGENTA = constant("NATIVE_COLOR_MAGENTA", native_color_t)

# --- functions ---

# foundation/color.h

native_color_from_rgba = function(
    "native_color_from_rgba",
    native_color_t,
    [
        c_ubyte,
        c_ubyte,
        c_ubyte,
        c_ubyte,
    ],
)
native_color_from_hex = function("native_color_from_hex", native_color_t, [c_char_p])
native_color_to_rgba = function("native_color_to_rgba", c_uint, [native_color_t])
native_color_to_argb = function("native_color_to_argb", c_uint, [native_color_t])

# foundation/keyboard.h

native_keyboard_accelerator_free = function(
    "native_keyboard_accelerator_free",
    None,
    [
        POINTER(native_keyboard_accelerator_t),
    ],
)
native_keyboard_accelerator_to_string = function(
    "native_keyboard_accelerator_to_string",
    c_void_p,
    [
        native_keyboard_accelerator_t,
    ],
)
native_keyboard_accelerator_is_empty = function(
    "native_keyboard_accelerator_is_empty",
    c_bool,
    [
        native_keyboard_accelerator_t,
    ],
)

# accessibility_manager.h

native_accessibility_manager_enable = function(
    "native_accessibility_manager_enable",
    None,
    [
    ],
)
native_accessibility_manager_is_enabled = function(
    "native_accessibility_manager_is_enabled",
    c_bool,
    [
    ],
)

# display.h

native_display_list_free = function(
    "native_display_list_free",
    None,
    [
        POINTER(native_display_list_t),
    ],
)
native_display_list_release = function(
    "native_display_list_release",
    None,
    [
        POINTER(native_display_list_t),
    ],
)
native_display_free = function("native_display_free", None, [c_uint64])
native_display_get_native_object = function(
    "native_display_get_native_object",
    c_void_p,
    [
        c_uint64,
    ],
)
native_display_create = function("native_display_create", c_uint64, [c_void_p])
native_display_get_id = function("native_display_get_id", c_uint, [c_uint64])
native_display_get_name = function("native_display_get_name", c_void_p, [c_uint64])
native_display_get_position = function(
    "native_display_get_position",
    native_point_t,
    [
        c_uint64,
    ],
)
native_display_get_size = function("native_display_get_size", native_size_t, [c_uint64])
native_display_get_work_area = function(
    "native_display_get_work_area",
    native_rectangle_t,
    [
        c_uint64,
    ],
)
native_display_get_scale_factor = function(
    "native_display_get_scale_factor",
    c_double,
    [
        c_uint64,
    ],
)
native_display_is_primary = function("native_display_is_primary", c_bool, [c_uint64])
native_display_get_orientation = function(
    "native_display_get_orientation",
    c_int,
    [
        c_uint64,
    ],
)
native_display_get_refresh_rate = function(
    "native_display_get_refresh_rate",
    c_int,
    [
        c_uint64,
    ],
)
native_display_get_bit_depth = function(
    "native_display_get_bit_depth",
    c_int,
    [
        c_uint64,
    ],
)

# display_manager.h

native_display_manager_get_all = function(
    "native_display_manager_get_all",
    native_display_list_t,
    [
    ],
)
native_display_manager_get_primary = function(
    "native_display_manager_get_primary",
    c_uint64,
    [
    ],
)
native_display_manager_get_cursor_position = function(
    "native_display_manager_get_cursor_position",
    native_point_t,
    [
    ],
)
native_display_manager_add_listener = function(
    "native_display_manager_add_listener",
    c_uint64,
    [
        native_display_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_display_manager_remove_listener = function(
    "native_display_manager_remove_listener",
    c_bool,
    [
        c_uint64,
    ],
)

# url_opener.h

native_url_open_result_free = function(
    "native_url_open_result_free",
    None,
    [
        POINTER(native_url_open_result_t),
    ],
)
native_url_opener_is_supported = function("native_url_opener_is_supported", c_bool, [])
native_url_opener_can_open = function("native_url_opener_can_open", c_bool, [c_char_p])
native_url_opener_open = function(
    "native_url_opener_open",
    native_url_open_result_t,
    [
        c_char_p,
    ],
)

# app_info.h

native_app_info_get_name = function("native_app_info_get_name", c_void_p, [])
native_app_info_get_identifier = function(
    "native_app_info_get_identifier",
    c_void_p,
    [
    ],
)
native_app_info_get_version = function("native_app_info_get_version", c_void_p, [])
native_app_info_get_build_number = function(
    "native_app_info_get_build_number",
    c_void_p,
    [
    ],
)

# device_info.h

native_device_info_get_name = function("native_device_info_get_name", c_void_p, [])
native_device_info_get_model = function("native_device_info_get_model", c_void_p, [])
native_device_info_get_manufacturer = function(
    "native_device_info_get_manufacturer",
    c_void_p,
    [
    ],
)
native_device_info_get_os_name = function(
    "native_device_info_get_os_name",
    c_void_p,
    [
    ],
)
native_device_info_get_os_version = function(
    "native_device_info_get_os_version",
    c_void_p,
    [
    ],
)
native_device_info_get_kernel_version = function(
    "native_device_info_get_kernel_version",
    c_void_p,
    [
    ],
)
native_device_info_get_architecture = function(
    "native_device_info_get_architecture",
    c_void_p,
    [
    ],
)

# preferences.h

native_preferences_free = function("native_preferences_free", None, [c_uint64])
native_preferences_create = function("native_preferences_create", c_uint64, [])
native_preferences_create_with_scope = function(
    "native_preferences_create_with_scope",
    c_uint64,
    [
        c_char_p,
    ],
)
native_preferences_set = function(
    "native_preferences_set",
    c_bool,
    [
        c_uint64,
        c_char_p,
        c_char_p,
    ],
)
native_preferences_get = function(
    "native_preferences_get",
    c_void_p,
    [
        c_uint64,
        c_char_p,
        c_char_p,
    ],
)
native_preferences_remove = function(
    "native_preferences_remove",
    c_bool,
    [
        c_uint64,
        c_char_p,
    ],
)
native_preferences_clear = function("native_preferences_clear", c_bool, [c_uint64])
native_preferences_contains = function(
    "native_preferences_contains",
    c_bool,
    [
        c_uint64,
        c_char_p,
    ],
)
native_preferences_get_keys = function(
    "native_preferences_get_keys",
    native_string_list_t,
    [
        c_uint64,
    ],
)
native_preferences_get_size = function(
    "native_preferences_get_size",
    c_ulong,
    [
        c_uint64,
    ],
)
native_preferences_get_all = function(
    "native_preferences_get_all",
    native_string_map_t,
    [
        c_uint64,
    ],
)
native_preferences_get_scope = function(
    "native_preferences_get_scope",
    c_void_p,
    [
        c_uint64,
    ],
)

# secure_storage.h

native_secure_storage_free = function("native_secure_storage_free", None, [c_uint64])
native_secure_storage_create = function("native_secure_storage_create", c_uint64, [])
native_secure_storage_create_with_scope = function(
    "native_secure_storage_create_with_scope",
    c_uint64,
    [
        c_char_p,
    ],
)
native_secure_storage_set = function(
    "native_secure_storage_set",
    c_bool,
    [
        c_uint64,
        c_char_p,
        c_char_p,
    ],
)
native_secure_storage_get = function(
    "native_secure_storage_get",
    c_void_p,
    [
        c_uint64,
        c_char_p,
        c_char_p,
    ],
)
native_secure_storage_remove = function(
    "native_secure_storage_remove",
    c_bool,
    [
        c_uint64,
        c_char_p,
    ],
)
native_secure_storage_clear = function(
    "native_secure_storage_clear",
    c_bool,
    [
        c_uint64,
    ],
)
native_secure_storage_contains = function(
    "native_secure_storage_contains",
    c_bool,
    [
        c_uint64,
        c_char_p,
    ],
)
native_secure_storage_get_keys = function(
    "native_secure_storage_get_keys",
    native_string_list_t,
    [
        c_uint64,
    ],
)
native_secure_storage_get_size = function(
    "native_secure_storage_get_size",
    c_ulong,
    [
        c_uint64,
    ],
)
native_secure_storage_get_all = function(
    "native_secure_storage_get_all",
    native_string_map_t,
    [
        c_uint64,
    ],
)
native_secure_storage_get_scope = function(
    "native_secure_storage_get_scope",
    c_void_p,
    [
        c_uint64,
    ],
)
native_secure_storage_is_available = function(
    "native_secure_storage_is_available",
    c_bool,
    [
    ],
)

# launch_at_login.h

native_launch_at_login_free = function("native_launch_at_login_free", None, [c_uint64])
native_launch_at_login_create = function("native_launch_at_login_create", c_uint64, [])
native_launch_at_login_create_with_id = function(
    "native_launch_at_login_create_with_id",
    c_uint64,
    [
        c_char_p,
    ],
)
native_launch_at_login_create_with_id_and_display_name = function(
    "native_launch_at_login_create_with_id_and_display_name",
    c_uint64,
    [
        c_char_p,
        c_char_p,
    ],
)
native_launch_at_login_is_supported = function(
    "native_launch_at_login_is_supported",
    c_bool,
    [
    ],
)
native_launch_at_login_get_id = function(
    "native_launch_at_login_get_id",
    c_void_p,
    [
        c_uint64,
    ],
)
native_launch_at_login_get_display_name = function(
    "native_launch_at_login_get_display_name",
    c_void_p,
    [
        c_uint64,
    ],
)
native_launch_at_login_set_display_name = function(
    "native_launch_at_login_set_display_name",
    c_bool,
    [
        c_uint64,
        c_char_p,
    ],
)
native_launch_at_login_set_program = function(
    "native_launch_at_login_set_program",
    c_bool,
    [
        c_uint64,
        c_char_p,
        native_string_list_t,
    ],
)
native_launch_at_login_get_executable_path = function(
    "native_launch_at_login_get_executable_path",
    c_void_p,
    [
        c_uint64,
    ],
)
native_launch_at_login_get_arguments = function(
    "native_launch_at_login_get_arguments",
    native_string_list_t,
    [
        c_uint64,
    ],
)
native_launch_at_login_enable = function(
    "native_launch_at_login_enable",
    c_bool,
    [
        c_uint64,
    ],
)
native_launch_at_login_disable = function(
    "native_launch_at_login_disable",
    c_bool,
    [
        c_uint64,
    ],
)
native_launch_at_login_is_enabled = function(
    "native_launch_at_login_is_enabled",
    c_bool,
    [
        c_uint64,
    ],
)

# message_dialog.h

native_message_dialog_free = function("native_message_dialog_free", None, [c_uint64])
native_message_dialog_create = function(
    "native_message_dialog_create",
    c_uint64,
    [
        c_char_p,
        c_char_p,
    ],
)
native_message_dialog_is_extended_supported = function(
    "native_message_dialog_is_extended_supported",
    c_bool,
    [
    ],
)
native_message_dialog_set_buttons = function(
    "native_message_dialog_set_buttons",
    c_bool,
    [
        c_uint64,
        c_char_p,
        c_char_p,
        c_char_p,
    ],
)
native_message_dialog_set_default_button = function(
    "native_message_dialog_set_default_button",
    c_bool,
    [
        c_uint64,
        c_int,
    ],
)
native_message_dialog_set_parent_window = function(
    "native_message_dialog_set_parent_window",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)
native_message_dialog_get_result = function(
    "native_message_dialog_get_result",
    c_int,
    [
        c_uint64,
    ],
)
native_message_dialog_is_open = function(
    "native_message_dialog_is_open",
    c_bool,
    [
        c_uint64,
    ],
)
native_message_dialog_set_input_enabled = function(
    "native_message_dialog_set_input_enabled",
    c_bool,
    [
        c_uint64,
        c_bool,
    ],
)
native_message_dialog_set_input_text = function(
    "native_message_dialog_set_input_text",
    c_bool,
    [
        c_uint64,
        c_char_p,
    ],
)
native_message_dialog_get_input_text = function(
    "native_message_dialog_get_input_text",
    c_void_p,
    [
        c_uint64,
    ],
)
native_message_dialog_set_checkbox = function(
    "native_message_dialog_set_checkbox",
    c_bool,
    [
        c_uint64,
        c_char_p,
        c_bool,
    ],
)
native_message_dialog_is_checkbox_checked = function(
    "native_message_dialog_is_checkbox_checked",
    c_bool,
    [
        c_uint64,
    ],
)
native_message_dialog_set_progress = function(
    "native_message_dialog_set_progress",
    c_bool,
    [
        c_uint64,
        c_double,
    ],
)
native_message_dialog_set_title = function(
    "native_message_dialog_set_title",
    None,
    [
        c_uint64,
        c_char_p,
    ],
)
native_message_dialog_get_title = function(
    "native_message_dialog_get_title",
    c_void_p,
    [
        c_uint64,
    ],
)
native_message_dialog_set_message = function(
    "native_message_dialog_set_message",
    None,
    [
        c_uint64,
        c_char_p,
    ],
)
native_message_dialog_get_message = function(
    "native_message_dialog_get_message",
    c_void_p,
    [
        c_uint64,
    ],
)
native_message_dialog_get_modality = function(
    "native_message_dialog_get_modality",
    c_int,
    [
        c_uint64,
    ],
)
native_message_dialog_set_modality = function(
    "native_message_dialog_set_modality",
    None,
    [
        c_uint64,
        c_int,
    ],
)
native_message_dialog_open = function("native_message_dialog_open", c_bool, [c_uint64])
native_message_dialog_close = function(
    "native_message_dialog_close",
    c_bool,
    [
        c_uint64,
    ],
)

# file_dialog.h

native_file_dialog_free = function("native_file_dialog_free", None, [c_uint64])
native_file_dialog_create = function("native_file_dialog_create", c_uint64, [c_int])
native_file_dialog_is_supported = function(
    "native_file_dialog_is_supported",
    c_bool,
    [
    ],
)
native_file_dialog_set_parent_window = function(
    "native_file_dialog_set_parent_window",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)
native_file_dialog_set_file_types = function(
    "native_file_dialog_set_file_types",
    c_bool,
    [
        c_uint64,
        native_string_list_t,
    ],
)
native_file_dialog_set_suggested_file_name = function(
    "native_file_dialog_set_suggested_file_name",
    c_bool,
    [
        c_uint64,
        c_char_p,
    ],
)
native_file_dialog_get_modality = function(
    "native_file_dialog_get_modality",
    c_int,
    [
        c_uint64,
    ],
)
native_file_dialog_set_modality = function(
    "native_file_dialog_set_modality",
    None,
    [
        c_uint64,
        c_int,
    ],
)
native_file_dialog_open = function("native_file_dialog_open", c_bool, [c_uint64])
native_file_dialog_close = function("native_file_dialog_close", c_bool, [c_uint64])
native_file_dialog_get_result = function(
    "native_file_dialog_get_result",
    c_int,
    [
        c_uint64,
    ],
)
native_file_dialog_get_paths = function(
    "native_file_dialog_get_paths",
    native_string_list_t,
    [
        c_uint64,
    ],
)
native_file_dialog_get_last_error = function(
    "native_file_dialog_get_last_error",
    c_void_p,
    [
        c_uint64,
    ],
)

# notification_manager.h

native_notification_manager_is_supported = function(
    "native_notification_manager_is_supported",
    c_bool,
    [
    ],
)
native_notification_manager_initialize = function(
    "native_notification_manager_initialize",
    c_bool,
    [
    ],
)
native_notification_manager_shutdown = function(
    "native_notification_manager_shutdown",
    None,
    [
    ],
)
native_notification_manager_show = function(
    "native_notification_manager_show",
    c_bool,
    [
        c_char_p,
        c_char_p,
        c_char_p,
        c_char_p,
    ],
)
native_notification_manager_remove = function(
    "native_notification_manager_remove",
    c_bool,
    [
        c_char_p,
    ],
)
native_notification_manager_get_last_error = function(
    "native_notification_manager_get_last_error",
    c_void_p,
    [
    ],
)
native_notification_manager_add_listener = function(
    "native_notification_manager_add_listener",
    c_uint64,
    [
        native_notification_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_notification_manager_remove_listener = function(
    "native_notification_manager_remove_listener",
    c_bool,
    [
        c_uint64,
    ],
)

# image.h

native_image_free = function("native_image_free", None, [c_uint64])
native_image_get_native_object = function(
    "native_image_get_native_object",
    c_void_p,
    [
        c_uint64,
    ],
)
native_image_from_file = function("native_image_from_file", c_uint64, [c_char_p])
native_image_from_base64 = function("native_image_from_base64", c_uint64, [c_char_p])
native_image_get_size = function("native_image_get_size", native_size_t, [c_uint64])
native_image_get_format = function("native_image_get_format", c_void_p, [c_uint64])
native_image_to_base64 = function("native_image_to_base64", c_void_p, [c_uint64])
native_image_save_to_file = function(
    "native_image_save_to_file",
    c_bool,
    [
        c_uint64,
        c_char_p,
    ],
)

# window_shape.h

native_window_shape_free = function("native_window_shape_free", None, [c_uint64])
native_window_shape_create = function("native_window_shape_create", c_uint64, [])
native_window_shape_add_point = function(
    "native_window_shape_add_point",
    c_bool,
    [
        c_uint64,
        native_point_t,
    ],
)
native_window_shape_clear = function("native_window_shape_clear", None, [c_uint64])
native_window_shape_get_point_count = function(
    "native_window_shape_get_point_count",
    c_ulong,
    [
        c_uint64,
    ],
)
native_window_shape_get_point_at = function(
    "native_window_shape_get_point_at",
    native_point_t,
    [
        c_uint64,
        c_ulong,
    ],
)

# window_shadow.h

native_window_shadow_free = function("native_window_shadow_free", None, [c_uint64])
native_window_shadow_create = function("native_window_shadow_create", c_uint64, [])
native_window_shadow_set_color = function(
    "native_window_shadow_set_color",
    None,
    [
        c_uint64,
        native_color_t,
    ],
)
native_window_shadow_get_color = function(
    "native_window_shadow_get_color",
    native_color_t,
    [
        c_uint64,
    ],
)
native_window_shadow_set_blur_radius = function(
    "native_window_shadow_set_blur_radius",
    c_bool,
    [
        c_uint64,
        c_double,
    ],
)
native_window_shadow_get_blur_radius = function(
    "native_window_shadow_get_blur_radius",
    c_double,
    [
        c_uint64,
    ],
)
native_window_shadow_set_offset = function(
    "native_window_shadow_set_offset",
    c_bool,
    [
        c_uint64,
        native_point_t,
    ],
)
native_window_shadow_get_offset = function(
    "native_window_shadow_get_offset",
    native_point_t,
    [
        c_uint64,
    ],
)

# window.h

native_window_list_free = function(
    "native_window_list_free",
    None,
    [
        POINTER(native_window_list_t),
    ],
)
native_window_list_release = function(
    "native_window_list_release",
    None,
    [
        POINTER(native_window_list_t),
    ],
)
native_window_free = function("native_window_free", None, [c_uint64])
native_window_get_native_object = function(
    "native_window_get_native_object",
    c_void_p,
    [
        c_uint64,
    ],
)
native_window_create = function("native_window_create", c_uint64, [])
native_window_create_with_native_window = function(
    "native_window_create_with_native_window",
    c_uint64,
    [
        c_void_p,
    ],
)
native_window_get_id = function("native_window_get_id", c_uint, [c_uint64])
native_window_focus = function("native_window_focus", None, [c_uint64])
native_window_blur = function("native_window_blur", None, [c_uint64])
native_window_is_focused = function("native_window_is_focused", c_bool, [c_uint64])
native_window_show = function("native_window_show", None, [c_uint64])
native_window_show_inactive = function("native_window_show_inactive", None, [c_uint64])
native_window_hide = function("native_window_hide", None, [c_uint64])
native_window_is_visible = function("native_window_is_visible", c_bool, [c_uint64])
native_window_maximize = function("native_window_maximize", None, [c_uint64])
native_window_unmaximize = function("native_window_unmaximize", None, [c_uint64])
native_window_is_maximized = function("native_window_is_maximized", c_bool, [c_uint64])
native_window_minimize = function("native_window_minimize", None, [c_uint64])
native_window_restore = function("native_window_restore", None, [c_uint64])
native_window_is_minimized = function("native_window_is_minimized", c_bool, [c_uint64])
native_window_set_full_screen = function(
    "native_window_set_full_screen",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_full_screen = function(
    "native_window_is_full_screen",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_bounds = function(
    "native_window_set_bounds",
    None,
    [
        c_uint64,
        native_rectangle_t,
    ],
)
native_window_get_bounds = function(
    "native_window_get_bounds",
    native_rectangle_t,
    [
        c_uint64,
    ],
)
native_window_set_content_bounds = function(
    "native_window_set_content_bounds",
    None,
    [
        c_uint64,
        native_rectangle_t,
    ],
)
native_window_get_content_bounds = function(
    "native_window_get_content_bounds",
    native_rectangle_t,
    [
        c_uint64,
    ],
)
native_window_set_size = function(
    "native_window_set_size",
    None,
    [
        c_uint64,
        native_size_t,
        c_bool,
    ],
)
native_window_get_size = function("native_window_get_size", native_size_t, [c_uint64])
native_window_set_content_size = function(
    "native_window_set_content_size",
    None,
    [
        c_uint64,
        native_size_t,
    ],
)
native_window_get_content_size = function(
    "native_window_get_content_size",
    native_size_t,
    [
        c_uint64,
    ],
)
native_window_set_minimum_size = function(
    "native_window_set_minimum_size",
    None,
    [
        c_uint64,
        native_size_t,
    ],
)
native_window_get_minimum_size = function(
    "native_window_get_minimum_size",
    native_size_t,
    [
        c_uint64,
    ],
)
native_window_set_maximum_size = function(
    "native_window_set_maximum_size",
    None,
    [
        c_uint64,
        native_size_t,
    ],
)
native_window_get_maximum_size = function(
    "native_window_get_maximum_size",
    native_size_t,
    [
        c_uint64,
    ],
)
native_window_set_aspect_ratio = function(
    "native_window_set_aspect_ratio",
    None,
    [
        c_uint64,
        c_double,
    ],
)
native_window_get_aspect_ratio = function(
    "native_window_get_aspect_ratio",
    c_double,
    [
        c_uint64,
    ],
)
native_window_set_resizable = function(
    "native_window_set_resizable",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_resizable = function("native_window_is_resizable", c_bool, [c_uint64])
native_window_set_movable = function(
    "native_window_set_movable",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_movable = function("native_window_is_movable", c_bool, [c_uint64])
native_window_set_minimizable = function(
    "native_window_set_minimizable",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_minimizable = function(
    "native_window_is_minimizable",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_maximizable = function(
    "native_window_set_maximizable",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_maximizable = function(
    "native_window_is_maximizable",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_full_screenable = function(
    "native_window_set_full_screenable",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_full_screenable = function(
    "native_window_is_full_screenable",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_closable = function(
    "native_window_set_closable",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_closable = function("native_window_is_closable", c_bool, [c_uint64])
native_window_set_window_control_buttons_visible = function(
    "native_window_set_window_control_buttons_visible",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_window_control_buttons_visible = function(
    "native_window_is_window_control_buttons_visible",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_always_on_top = function(
    "native_window_set_always_on_top",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_always_on_top = function(
    "native_window_is_always_on_top",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_always_on_bottom = function(
    "native_window_set_always_on_bottom",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_always_on_bottom = function(
    "native_window_is_always_on_bottom",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_parent_window = function(
    "native_window_set_parent_window",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)
native_window_get_parent_window = function(
    "native_window_get_parent_window",
    c_uint64,
    [
        c_uint64,
    ],
)
native_window_set_non_activating = function(
    "native_window_set_non_activating",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_non_activating = function(
    "native_window_is_non_activating",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_position = function(
    "native_window_set_position",
    None,
    [
        c_uint64,
        native_point_t,
    ],
)
native_window_get_position = function(
    "native_window_get_position",
    native_point_t,
    [
        c_uint64,
    ],
)
native_window_center = function("native_window_center", None, [c_uint64])
native_window_set_title = function(
    "native_window_set_title",
    None,
    [
        c_uint64,
        c_char_p,
    ],
)
native_window_get_title = function("native_window_get_title", c_void_p, [c_uint64])
native_window_set_title_bar_colors = function(
    "native_window_set_title_bar_colors",
    c_bool,
    [
        c_uint64,
        native_color_t,
        native_color_t,
    ],
)
native_window_reset_title_bar_colors = function(
    "native_window_reset_title_bar_colors",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_title_bar_style = function(
    "native_window_set_title_bar_style",
    None,
    [
        c_uint64,
        c_int,
    ],
)
native_window_get_title_bar_style = function(
    "native_window_get_title_bar_style",
    c_int,
    [
        c_uint64,
    ],
)
native_window_set_content_under_title_bar = function(
    "native_window_set_content_under_title_bar",
    c_bool,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_content_under_title_bar = function(
    "native_window_is_content_under_title_bar",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_is_content_under_title_bar_supported = function(
    "native_window_is_content_under_title_bar_supported",
    c_bool,
    [
    ],
)
native_window_set_has_shadow = function(
    "native_window_set_has_shadow",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_has_shadow = function("native_window_has_shadow", c_bool, [c_uint64])
native_window_set_custom_shadow = function(
    "native_window_set_custom_shadow",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)
native_window_get_custom_shadow = function(
    "native_window_get_custom_shadow",
    c_uint64,
    [
        c_uint64,
    ],
)
native_window_set_opacity = function(
    "native_window_set_opacity",
    None,
    [
        c_uint64,
        c_float,
    ],
)
native_window_get_opacity = function("native_window_get_opacity", c_float, [c_uint64])
native_window_set_visual_effect = function(
    "native_window_set_visual_effect",
    c_bool,
    [
        c_uint64,
        c_int,
    ],
)
native_window_get_visual_effect = function(
    "native_window_get_visual_effect",
    c_int,
    [
        c_uint64,
    ],
)
native_window_is_visual_effect_supported = function(
    "native_window_is_visual_effect_supported",
    c_bool,
    [
        c_int,
    ],
)
native_window_set_shape = function(
    "native_window_set_shape",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)
native_window_is_shaped = function("native_window_is_shaped", c_bool, [c_uint64])
native_window_is_shape_supported = function(
    "native_window_is_shape_supported",
    c_bool,
    [
    ],
)
native_window_set_input_shape = function(
    "native_window_set_input_shape",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)
native_window_is_input_shaped = function(
    "native_window_is_input_shaped",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_is_input_shape_supported = function(
    "native_window_is_input_shape_supported",
    c_bool,
    [
    ],
)
native_window_set_background_color = function(
    "native_window_set_background_color",
    None,
    [
        c_uint64,
        native_color_t,
    ],
)
native_window_get_background_color = function(
    "native_window_get_background_color",
    native_color_t,
    [
        c_uint64,
    ],
)
native_window_set_visible_on_all_workspaces = function(
    "native_window_set_visible_on_all_workspaces",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_visible_on_all_workspaces = function(
    "native_window_is_visible_on_all_workspaces",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_visible_in_taskbar = function(
    "native_window_set_visible_in_taskbar",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_visible_in_taskbar = function(
    "native_window_is_visible_in_taskbar",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_ignore_mouse_events = function(
    "native_window_set_ignore_mouse_events",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_ignore_mouse_events = function(
    "native_window_is_ignore_mouse_events",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_set_focusable = function(
    "native_window_set_focusable",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_window_is_focusable = function("native_window_is_focusable", c_bool, [c_uint64])
native_window_start_dragging = function(
    "native_window_start_dragging",
    None,
    [
        c_uint64,
    ],
)
native_window_start_resizing = function(
    "native_window_start_resizing",
    None,
    [
        c_uint64,
        c_int,
    ],
)

# window_manager.h

native_window_manager_get = function("native_window_manager_get", c_uint64, [c_uint])
native_window_manager_get_all = function(
    "native_window_manager_get_all",
    native_window_list_t,
    [
    ],
)
native_window_manager_get_current = function(
    "native_window_manager_get_current",
    c_uint64,
    [
    ],
)
native_window_manager_get_window_at_point = function(
    "native_window_manager_get_window_at_point",
    c_uint64,
    [
        native_point_t,
        c_uint,
    ],
)
native_window_manager_set_will_show_hook = function(
    "native_window_manager_set_will_show_hook",
    None,
    [
        native_uint_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_window_manager_set_will_hide_hook = function(
    "native_window_manager_set_will_hide_hook",
    None,
    [
        native_uint_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_window_manager_has_will_show_hook = function(
    "native_window_manager_has_will_show_hook",
    c_bool,
    [
    ],
)
native_window_manager_has_will_hide_hook = function(
    "native_window_manager_has_will_hide_hook",
    c_bool,
    [
    ],
)
native_window_manager_handle_will_show = function(
    "native_window_manager_handle_will_show",
    None,
    [
        c_uint,
    ],
)
native_window_manager_handle_will_hide = function(
    "native_window_manager_handle_will_hide",
    None,
    [
        c_uint,
    ],
)
native_window_manager_call_original_show = function(
    "native_window_manager_call_original_show",
    c_bool,
    [
        c_uint,
    ],
)
native_window_manager_call_original_hide = function(
    "native_window_manager_call_original_hide",
    c_bool,
    [
        c_uint,
    ],
)
native_window_manager_add_listener = function(
    "native_window_manager_add_listener",
    c_uint64,
    [
        native_window_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_window_manager_remove_listener = function(
    "native_window_manager_remove_listener",
    c_bool,
    [
        c_uint64,
    ],
)

# window_drag_session.h

native_window_drag_session_free = function(
    "native_window_drag_session_free",
    None,
    [
        c_uint64,
    ],
)
native_window_drag_session_create = function(
    "native_window_drag_session_create",
    c_uint64,
    [
    ],
)
native_window_drag_session_start = function(
    "native_window_drag_session_start",
    c_bool,
    [
        c_uint64,
        c_uint64,
        native_point_t,
    ],
)
native_window_drag_session_cancel = function(
    "native_window_drag_session_cancel",
    None,
    [
        c_uint64,
    ],
)
native_window_drag_session_is_active = function(
    "native_window_drag_session_is_active",
    c_bool,
    [
        c_uint64,
    ],
)
native_window_drag_session_get_window_id = function(
    "native_window_drag_session_get_window_id",
    c_uint,
    [
        c_uint64,
    ],
)
native_window_drag_session_get_anchor = function(
    "native_window_drag_session_get_anchor",
    native_point_t,
    [
        c_uint64,
    ],
)
native_window_drag_session_add_listener = function(
    "native_window_drag_session_add_listener",
    c_uint64,
    [
        c_uint64,
        native_window_drag_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_window_drag_session_remove_listener = function(
    "native_window_drag_session_remove_listener",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)

# drag_source.h

native_drag_source_free = function("native_drag_source_free", None, [c_uint64])
native_drag_source_create = function("native_drag_source_create", c_uint64, [])
native_drag_source_is_supported = function(
    "native_drag_source_is_supported",
    c_bool,
    [
    ],
)
native_drag_source_set_file_paths = function(
    "native_drag_source_set_file_paths",
    None,
    [
        c_uint64,
        native_string_list_t,
    ],
)
native_drag_source_get_file_paths = function(
    "native_drag_source_get_file_paths",
    native_string_list_t,
    [
        c_uint64,
    ],
)
native_drag_source_set_text = function(
    "native_drag_source_set_text",
    None,
    [
        c_uint64,
        c_char_p,
    ],
)
native_drag_source_get_text = function(
    "native_drag_source_get_text",
    c_void_p,
    [
        c_uint64,
    ],
)
native_drag_source_set_image = function(
    "native_drag_source_set_image",
    None,
    [
        c_uint64,
        c_uint64,
    ],
)
native_drag_source_get_image = function(
    "native_drag_source_get_image",
    c_uint64,
    [
        c_uint64,
    ],
)
native_drag_source_set_drag_operation = function(
    "native_drag_source_set_drag_operation",
    None,
    [
        c_uint64,
        c_int,
    ],
)
native_drag_source_get_drag_operation = function(
    "native_drag_source_get_drag_operation",
    c_int,
    [
        c_uint64,
    ],
)
native_drag_source_start_dragging = function(
    "native_drag_source_start_dragging",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)
native_drag_source_is_dragging = function(
    "native_drag_source_is_dragging",
    c_bool,
    [
        c_uint64,
    ],
)
native_drag_source_add_listener = function(
    "native_drag_source_add_listener",
    c_uint64,
    [
        c_uint64,
        native_drag_source_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_drag_source_remove_listener = function(
    "native_drag_source_remove_listener",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)

# drop_target.h

native_drop_target_free = function("native_drop_target_free", None, [c_uint64])
native_drop_target_create = function("native_drop_target_create", c_uint64, [c_uint64])
native_drop_target_is_supported = function(
    "native_drop_target_is_supported",
    c_bool,
    [
    ],
)
native_drop_target_get_window_id = function(
    "native_drop_target_get_window_id",
    c_uint,
    [
        c_uint64,
    ],
)
native_drop_target_set_drop_operation = function(
    "native_drop_target_set_drop_operation",
    None,
    [
        c_uint64,
        c_int,
    ],
)
native_drop_target_get_drop_operation = function(
    "native_drop_target_get_drop_operation",
    c_int,
    [
        c_uint64,
    ],
)
native_drop_target_is_active = function(
    "native_drop_target_is_active",
    c_bool,
    [
        c_uint64,
    ],
)
native_drop_target_add_listener = function(
    "native_drop_target_add_listener",
    c_uint64,
    [
        c_uint64,
        native_drop_target_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_drop_target_remove_listener = function(
    "native_drop_target_remove_listener",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)

# positioning_strategy.h

native_positioning_strategy_free = function(
    "native_positioning_strategy_free",
    None,
    [
        c_uint64,
    ],
)
native_positioning_strategy_absolute = function(
    "native_positioning_strategy_absolute",
    c_uint64,
    [
        native_point_t,
    ],
)
native_positioning_strategy_cursor_position = function(
    "native_positioning_strategy_cursor_position",
    c_uint64,
    [
    ],
)
native_positioning_strategy_relative_with_rect_and_offset = function(
    "native_positioning_strategy_relative_with_rect_and_offset",
    c_uint64,
    [
        native_rectangle_t,
        native_point_t,
    ],
)
native_positioning_strategy_relative_with_window_and_offset = function(
    "native_positioning_strategy_relative_with_window_and_offset",
    c_uint64,
    [
        c_uint64,
        native_point_t,
    ],
)
native_positioning_strategy_get_type = function(
    "native_positioning_strategy_get_type",
    c_int,
    [
        c_uint64,
    ],
)
native_positioning_strategy_get_absolute_position = function(
    "native_positioning_strategy_get_absolute_position",
    native_point_t,
    [
        c_uint64,
    ],
)
native_positioning_strategy_get_relative_rectangle = function(
    "native_positioning_strategy_get_relative_rectangle",
    native_rectangle_t,
    [
        c_uint64,
    ],
)
native_positioning_strategy_get_relative_offset = function(
    "native_positioning_strategy_get_relative_offset",
    native_point_t,
    [
        c_uint64,
    ],
)

# menu.h

native_menu_item_list_free = function(
    "native_menu_item_list_free",
    None,
    [
        POINTER(native_menu_item_list_t),
    ],
)
native_menu_item_list_release = function(
    "native_menu_item_list_release",
    None,
    [
        POINTER(native_menu_item_list_t),
    ],
)
native_menu_item_free = function("native_menu_item_free", None, [c_uint64])
native_menu_item_get_native_object = function(
    "native_menu_item_get_native_object",
    c_void_p,
    [
        c_uint64,
    ],
)
native_menu_item_create_with_label_and_type = function(
    "native_menu_item_create_with_label_and_type",
    c_uint64,
    [
        c_char_p,
        c_int,
    ],
)
native_menu_item_create_with_native_item = function(
    "native_menu_item_create_with_native_item",
    c_uint64,
    [
        c_void_p,
    ],
)
native_menu_item_get_id = function("native_menu_item_get_id", c_uint, [c_uint64])
native_menu_item_get_type = function("native_menu_item_get_type", c_int, [c_uint64])
native_menu_item_set_label = function(
    "native_menu_item_set_label",
    None,
    [
        c_uint64,
        c_char_p,
    ],
)
native_menu_item_get_label = function(
    "native_menu_item_get_label",
    c_void_p,
    [
        c_uint64,
    ],
)
native_menu_item_set_icon = function(
    "native_menu_item_set_icon",
    None,
    [
        c_uint64,
        c_uint64,
    ],
)
native_menu_item_get_icon = function("native_menu_item_get_icon", c_uint64, [c_uint64])
native_menu_item_set_tooltip = function(
    "native_menu_item_set_tooltip",
    None,
    [
        c_uint64,
        c_char_p,
    ],
)
native_menu_item_get_tooltip = function(
    "native_menu_item_get_tooltip",
    c_void_p,
    [
        c_uint64,
    ],
)
native_menu_item_set_accelerator = function(
    "native_menu_item_set_accelerator",
    None,
    [
        c_uint64,
        POINTER(native_keyboard_accelerator_t),
    ],
)
native_menu_item_get_accelerator = function(
    "native_menu_item_get_accelerator",
    native_keyboard_accelerator_t,
    [
        c_uint64,
    ],
)
native_menu_item_set_enabled = function(
    "native_menu_item_set_enabled",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_menu_item_is_enabled = function(
    "native_menu_item_is_enabled",
    c_bool,
    [
        c_uint64,
    ],
)
native_menu_item_set_state = function(
    "native_menu_item_set_state",
    None,
    [
        c_uint64,
        c_int,
    ],
)
native_menu_item_get_state = function("native_menu_item_get_state", c_int, [c_uint64])
native_menu_item_set_radio_group = function(
    "native_menu_item_set_radio_group",
    None,
    [
        c_uint64,
        c_int,
    ],
)
native_menu_item_get_radio_group = function(
    "native_menu_item_get_radio_group",
    c_int,
    [
        c_uint64,
    ],
)
native_menu_item_set_submenu = function(
    "native_menu_item_set_submenu",
    None,
    [
        c_uint64,
        c_uint64,
    ],
)
native_menu_item_get_submenu = function(
    "native_menu_item_get_submenu",
    c_uint64,
    [
        c_uint64,
    ],
)
native_menu_item_add_listener = function(
    "native_menu_item_add_listener",
    c_uint64,
    [
        c_uint64,
        native_menu_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_menu_item_remove_listener = function(
    "native_menu_item_remove_listener",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)
native_menu_free = function("native_menu_free", None, [c_uint64])
native_menu_get_native_object = function(
    "native_menu_get_native_object",
    c_void_p,
    [
        c_uint64,
    ],
)
native_menu_create = function("native_menu_create", c_uint64, [])
native_menu_create_with_native_menu = function(
    "native_menu_create_with_native_menu",
    c_uint64,
    [
        c_void_p,
    ],
)
native_menu_get_id = function("native_menu_get_id", c_uint, [c_uint64])
native_menu_set_backend = function("native_menu_set_backend", c_bool, [c_uint64, c_int])
native_menu_get_backend = function("native_menu_get_backend", c_int, [c_uint64])
native_menu_is_backend_supported = function(
    "native_menu_is_backend_supported",
    c_bool,
    [
        c_int,
    ],
)
native_menu_add_item = function("native_menu_add_item", None, [c_uint64, c_uint64])
native_menu_insert_item = function(
    "native_menu_insert_item",
    None,
    [
        c_uint64,
        c_ulong,
        c_uint64,
    ],
)
native_menu_remove_item = function(
    "native_menu_remove_item",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)
native_menu_remove_item_by_id = function(
    "native_menu_remove_item_by_id",
    c_bool,
    [
        c_uint64,
        c_uint,
    ],
)
native_menu_remove_item_at = function(
    "native_menu_remove_item_at",
    c_bool,
    [
        c_uint64,
        c_ulong,
    ],
)
native_menu_clear = function("native_menu_clear", None, [c_uint64])
native_menu_add_separator = function("native_menu_add_separator", None, [c_uint64])
native_menu_insert_separator = function(
    "native_menu_insert_separator",
    None,
    [
        c_uint64,
        c_ulong,
    ],
)
native_menu_get_item_count = function("native_menu_get_item_count", c_ulong, [c_uint64])
native_menu_get_item_at = function(
    "native_menu_get_item_at",
    c_uint64,
    [
        c_uint64,
        c_ulong,
    ],
)
native_menu_get_item_by_id = function(
    "native_menu_get_item_by_id",
    c_uint64,
    [
        c_uint64,
        c_uint,
    ],
)
native_menu_get_all_items = function(
    "native_menu_get_all_items",
    native_menu_item_list_t,
    [
        c_uint64,
    ],
)
native_menu_open = function("native_menu_open", c_bool, [c_uint64, c_uint64, c_int])
native_menu_close = function("native_menu_close", c_bool, [c_uint64])
native_menu_add_listener = function(
    "native_menu_add_listener",
    c_uint64,
    [
        c_uint64,
        native_menu_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_menu_remove_listener = function(
    "native_menu_remove_listener",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)

# tray_icon.h

native_tray_icon_list_free = function(
    "native_tray_icon_list_free",
    None,
    [
        POINTER(native_tray_icon_list_t),
    ],
)
native_tray_icon_list_release = function(
    "native_tray_icon_list_release",
    None,
    [
        POINTER(native_tray_icon_list_t),
    ],
)
native_tray_icon_free = function("native_tray_icon_free", None, [c_uint64])
native_tray_icon_get_native_object = function(
    "native_tray_icon_get_native_object",
    c_void_p,
    [
        c_uint64,
    ],
)
native_tray_icon_create = function("native_tray_icon_create", c_uint64, [])
native_tray_icon_create_with_tray = function(
    "native_tray_icon_create_with_tray",
    c_uint64,
    [
        c_void_p,
    ],
)
native_tray_icon_get_id = function("native_tray_icon_get_id", c_uint, [c_uint64])
native_tray_icon_set_icon = function(
    "native_tray_icon_set_icon",
    None,
    [
        c_uint64,
        c_uint64,
    ],
)
native_tray_icon_get_icon = function("native_tray_icon_get_icon", c_uint64, [c_uint64])
native_tray_icon_set_icon_template = function(
    "native_tray_icon_set_icon_template",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_tray_icon_is_icon_template = function(
    "native_tray_icon_is_icon_template",
    c_bool,
    [
        c_uint64,
    ],
)
native_tray_icon_set_icon_size = function(
    "native_tray_icon_set_icon_size",
    None,
    [
        c_uint64,
        native_size_t,
    ],
)
native_tray_icon_get_icon_size = function(
    "native_tray_icon_get_icon_size",
    native_size_t,
    [
        c_uint64,
    ],
)
native_tray_icon_set_icon_position = function(
    "native_tray_icon_set_icon_position",
    None,
    [
        c_uint64,
        c_int,
    ],
)
native_tray_icon_get_icon_position = function(
    "native_tray_icon_get_icon_position",
    c_int,
    [
        c_uint64,
    ],
)
native_tray_icon_set_title = function(
    "native_tray_icon_set_title",
    None,
    [
        c_uint64,
        c_char_p,
    ],
)
native_tray_icon_get_title = function(
    "native_tray_icon_get_title",
    c_void_p,
    [
        c_uint64,
    ],
)
native_tray_icon_set_tooltip = function(
    "native_tray_icon_set_tooltip",
    None,
    [
        c_uint64,
        c_char_p,
    ],
)
native_tray_icon_get_tooltip = function(
    "native_tray_icon_get_tooltip",
    c_void_p,
    [
        c_uint64,
    ],
)
native_tray_icon_set_context_menu = function(
    "native_tray_icon_set_context_menu",
    None,
    [
        c_uint64,
        c_uint64,
    ],
)
native_tray_icon_get_context_menu = function(
    "native_tray_icon_get_context_menu",
    c_uint64,
    [
        c_uint64,
    ],
)
native_tray_icon_set_context_menu_trigger = function(
    "native_tray_icon_set_context_menu_trigger",
    None,
    [
        c_uint64,
        c_int,
    ],
)
native_tray_icon_get_context_menu_trigger = function(
    "native_tray_icon_get_context_menu_trigger",
    c_int,
    [
        c_uint64,
    ],
)
native_tray_icon_get_bounds = function(
    "native_tray_icon_get_bounds",
    native_rectangle_t,
    [
        c_uint64,
    ],
)
native_tray_icon_set_visible = function(
    "native_tray_icon_set_visible",
    c_bool,
    [
        c_uint64,
        c_bool,
    ],
)
native_tray_icon_is_visible = function(
    "native_tray_icon_is_visible",
    c_bool,
    [
        c_uint64,
    ],
)
native_tray_icon_open_context_menu = function(
    "native_tray_icon_open_context_menu",
    c_bool,
    [
        c_uint64,
    ],
)
native_tray_icon_close_context_menu = function(
    "native_tray_icon_close_context_menu",
    c_bool,
    [
        c_uint64,
    ],
)
native_tray_icon_add_listener = function(
    "native_tray_icon_add_listener",
    c_uint64,
    [
        c_uint64,
        native_tray_icon_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_tray_icon_remove_listener = function(
    "native_tray_icon_remove_listener",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)

# tray_manager.h

native_tray_manager_is_supported = function(
    "native_tray_manager_is_supported",
    c_bool,
    [
    ],
)
native_tray_manager_get = function("native_tray_manager_get", c_uint64, [c_uint])
native_tray_manager_get_all = function(
    "native_tray_manager_get_all",
    native_tray_icon_list_t,
    [
    ],
)

# shortcut.h

native_shortcut_options_free = function(
    "native_shortcut_options_free",
    None,
    [
        POINTER(native_shortcut_options_t),
    ],
)
native_shortcut_list_free = function(
    "native_shortcut_list_free",
    None,
    [
        POINTER(native_shortcut_list_t),
    ],
)
native_shortcut_list_release = function(
    "native_shortcut_list_release",
    None,
    [
        POINTER(native_shortcut_list_t),
    ],
)
native_shortcut_free = function("native_shortcut_free", None, [c_uint64])
native_shortcut_create_with_id_and_options = function(
    "native_shortcut_create_with_id_and_options",
    c_uint64,
    [
        c_uint,
        native_shortcut_options_t,
    ],
)
native_shortcut_create_with_id_and_accelerator_and_callback = function(
    "native_shortcut_create_with_id_and_accelerator_and_callback",
    c_uint64,
    [
        c_uint,
        c_char_p,
        native_void_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_shortcut_get_id = function("native_shortcut_get_id", c_uint, [c_uint64])
native_shortcut_get_accelerator = function(
    "native_shortcut_get_accelerator",
    c_void_p,
    [
        c_uint64,
    ],
)
native_shortcut_get_description = function(
    "native_shortcut_get_description",
    c_void_p,
    [
        c_uint64,
    ],
)
native_shortcut_set_description = function(
    "native_shortcut_set_description",
    None,
    [
        c_uint64,
        c_char_p,
    ],
)
native_shortcut_get_scope = function("native_shortcut_get_scope", c_int, [c_uint64])
native_shortcut_set_enabled = function(
    "native_shortcut_set_enabled",
    None,
    [
        c_uint64,
        c_bool,
    ],
)
native_shortcut_is_enabled = function("native_shortcut_is_enabled", c_bool, [c_uint64])
native_shortcut_invoke = function("native_shortcut_invoke", None, [c_uint64])
native_shortcut_set_callback = function(
    "native_shortcut_set_callback",
    None,
    [
        c_uint64,
        native_void_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)

# shortcut_manager.h

native_shortcut_manager_is_supported = function(
    "native_shortcut_manager_is_supported",
    c_bool,
    [
    ],
)
native_shortcut_manager_register_with_accelerator_and_callback = function(
    "native_shortcut_manager_register_with_accelerator_and_callback",
    c_uint64,
    [
        c_char_p,
        native_void_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_shortcut_manager_register_with_options = function(
    "native_shortcut_manager_register_with_options",
    c_uint64,
    [
        native_shortcut_options_t,
    ],
)
native_shortcut_manager_unregister_with_id = function(
    "native_shortcut_manager_unregister_with_id",
    c_bool,
    [
        c_uint,
    ],
)
native_shortcut_manager_unregister_with_accelerator = function(
    "native_shortcut_manager_unregister_with_accelerator",
    c_bool,
    [
        c_char_p,
    ],
)
native_shortcut_manager_unregister_all = function(
    "native_shortcut_manager_unregister_all",
    c_int,
    [
    ],
)
native_shortcut_manager_get_with_id = function(
    "native_shortcut_manager_get_with_id",
    c_uint64,
    [
        c_uint,
    ],
)
native_shortcut_manager_get_with_accelerator = function(
    "native_shortcut_manager_get_with_accelerator",
    c_uint64,
    [
        c_char_p,
    ],
)
native_shortcut_manager_get_all = function(
    "native_shortcut_manager_get_all",
    native_shortcut_list_t,
    [
    ],
)
native_shortcut_manager_get_by_scope = function(
    "native_shortcut_manager_get_by_scope",
    native_shortcut_list_t,
    [
        c_int,
    ],
)
native_shortcut_manager_is_available = function(
    "native_shortcut_manager_is_available",
    c_bool,
    [
        c_char_p,
    ],
)
native_shortcut_manager_is_valid_accelerator = function(
    "native_shortcut_manager_is_valid_accelerator",
    c_bool,
    [
        c_char_p,
    ],
)
native_shortcut_manager_set_enabled = function(
    "native_shortcut_manager_set_enabled",
    None,
    [
        c_bool,
    ],
)
native_shortcut_manager_is_enabled = function(
    "native_shortcut_manager_is_enabled",
    c_bool,
    [
    ],
)
native_shortcut_manager_emit_shortcut_activated = function(
    "native_shortcut_manager_emit_shortcut_activated",
    None,
    [
        c_uint,
        c_char_p,
    ],
)
native_shortcut_manager_add_listener = function(
    "native_shortcut_manager_add_listener",
    c_uint64,
    [
        native_shortcut_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_shortcut_manager_remove_listener = function(
    "native_shortcut_manager_remove_listener",
    c_bool,
    [
        c_uint64,
    ],
)

# keyboard_monitor.h

native_keyboard_monitor_free = function(
    "native_keyboard_monitor_free",
    None,
    [
        c_uint64,
    ],
)
native_keyboard_monitor_create = function(
    "native_keyboard_monitor_create",
    c_uint64,
    [
    ],
)
native_keyboard_monitor_start = function(
    "native_keyboard_monitor_start",
    None,
    [
        c_uint64,
    ],
)
native_keyboard_monitor_stop = function(
    "native_keyboard_monitor_stop",
    None,
    [
        c_uint64,
    ],
)
native_keyboard_monitor_is_monitoring = function(
    "native_keyboard_monitor_is_monitoring",
    c_bool,
    [
        c_uint64,
    ],
)
native_keyboard_monitor_add_listener = function(
    "native_keyboard_monitor_add_listener",
    c_uint64,
    [
        c_uint64,
        native_keyboard_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_keyboard_monitor_remove_listener = function(
    "native_keyboard_monitor_remove_listener",
    c_bool,
    [
        c_uint64,
        c_uint64,
    ],
)

# application.h

native_application_run = function("native_application_run", c_int, [])
native_application_run_with_window = function(
    "native_application_run_with_window",
    c_int,
    [
        c_uint64,
    ],
)
native_application_quit = function("native_application_quit", None, [c_int])
native_application_is_running = function("native_application_is_running", c_bool, [])
native_application_is_single_instance = function(
    "native_application_is_single_instance",
    c_bool,
    [
    ],
)
native_application_set_icon = function(
    "native_application_set_icon",
    c_bool,
    [
        c_char_p,
    ],
)
native_application_set_dock_icon_visible = function(
    "native_application_set_dock_icon_visible",
    c_bool,
    [
        c_bool,
    ],
)
native_application_set_progress_bar = function(
    "native_application_set_progress_bar",
    c_bool,
    [
        c_double,
    ],
)
native_application_set_badge_label = function(
    "native_application_set_badge_label",
    c_bool,
    [
        c_char_p,
    ],
)
native_application_set_brightness = function(
    "native_application_set_brightness",
    c_bool,
    [
        c_int,
    ],
)
native_application_set_menu_bar = function(
    "native_application_set_menu_bar",
    c_bool,
    [
        c_uint64,
    ],
)
native_application_get_primary_window = function(
    "native_application_get_primary_window",
    c_uint64,
    [
    ],
)
native_application_set_primary_window = function(
    "native_application_set_primary_window",
    None,
    [
        c_uint64,
    ],
)
native_application_get_all_windows = function(
    "native_application_get_all_windows",
    native_window_list_t,
    [
    ],
)
native_application_add_listener = function(
    "native_application_add_listener",
    c_uint64,
    [
        native_application_event_callback_t,
        c_void_p,
        native_release_user_data_t,
    ],
)
native_application_remove_listener = function(
    "native_application_remove_listener",
    c_bool,
    [
        c_uint64,
    ],
)
