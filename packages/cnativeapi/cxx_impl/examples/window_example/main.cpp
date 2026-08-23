#include <iostream>
#include "nativeapi.h"

using nativeapi::Application;
using nativeapi::Display;
using nativeapi::DisplayAddedEvent;
using nativeapi::DisplayManager;
using nativeapi::DisplayRemovedEvent;
using nativeapi::Menu;
using nativeapi::MenuClosedEvent;
using nativeapi::MenuItem;
using nativeapi::MenuItemClickedEvent;
using nativeapi::MenuItemState;
using nativeapi::MenuItemSubmenuClosedEvent;
using nativeapi::MenuItemSubmenuOpenedEvent;
using nativeapi::MenuItemType;
using nativeapi::MenuOpenedEvent;
using nativeapi::TrayIcon;
using nativeapi::TrayIconClickedEvent;
using nativeapi::TrayIconDoubleClickedEvent;
using nativeapi::TrayIconRightClickedEvent;
using nativeapi::TrayManager;
using nativeapi::Window;
using nativeapi::WindowManager;

int main() {
  native_accessibility_manager_enable();
  bool is_enabled = native_accessibility_manager_is_enabled();
  std::cout << "is_enabled: " << is_enabled << std::endl;

  DisplayManager& display_manager = DisplayManager::GetInstance();
  TrayManager& tray_manager = TrayManager::GetInstance();
  WindowManager& window_manager = WindowManager::GetInstance();

  // Create a new window (automatically registered)
  std::shared_ptr<Window> window_ptr = std::make_shared<Window>();
  window_ptr->SetTitle("Window Example");
  window_ptr->SetSize({800, 600}, false);
  window_ptr->SetMinimumSize({400, 300});
  window_ptr->SetMaximumSize({1920, 1080});
  window_ptr->Center();

  std::shared_ptr<TrayIcon> tray_icon_ptr = std::make_shared<TrayIcon>();
  if (tray_icon_ptr != nullptr) {
    TrayIcon& tray_icon = *tray_icon_ptr;
    auto icon = nativeapi::Image::FromBase64(
        "data:image/"
        "png;base64,"
        "iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAABGdBTUEAALGPC/"
        "xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAhGVY"
        "SWZNTQAqAAAACAAFARIAAwAAAAEAAQAAARoABQAAAAEAAABKARsABQAAAAEAAABSASgAAw"
        "AAAAEAAgAAh2kABAAAAAEAAABaAAAAAAAAAEgAAAABAAAASAAAAAEAA6ABAAMAAAABAAEA"
        "AKACAAQAAAABAAAAFKADAAQAAAABAAAAFAAAAABB553+"
        "AAAACXBIWXMAAAsTAAALEwEAmpwYAAABWWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPH"
        "g6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUg"
        "Ni4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OT"
        "kvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjph"
        "Ym91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3"
        "RpZmYvMS4wLyI+"
        "CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+"
        "CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+"
        "CjwveDp4bXBtZXRhPgoZXuEHAAADOElEQVQ4EY1USUtbURQ+N+/"
        "Fh1O04IxYHFAQNKiIIOJGV10oVbEb3fgHJLpKf0DjQuim3RS3roR25c7qzoWgkCAiiAM4I"
        "W5MnPUlt+c75j6iCdILN+/cM3xnzFFEpPjqYDD4WWsd4htUSgXAS8v4k3VExroJ1o3y/"
        "R6NRv+wlrKg2t7e/s2yrB+2bX8sKChwwHNdl/"
        "Xg6+WwMTmOQ+Alk0mR+Xw+Bzb8+FJRUeFcXFz8VYiMBb/ZzE0kEnp/"
        "f99mWnV2dtLz87MAAMzv99PR0RGVlJRQaWkpQCkvL49F2oV+KpWy+Y5YlZWVv+"
        "Dl6uoq2dra6p+enlYtLS20vr4uhqwkYCcnJzQ0NCQ8dkqFhYW0tbWlzs/"
        "PrcfHx2RZWZnFAdRQW1tbvLe3FzVJzc/Pw6OOxWJ4a/C5HLqvr0/"
        "ex8fHenV1VWjIFxcX9cHBgR4YGEg1Nzfrjo6OuM35BwCCsPnKQTo4SJNrQysrKzQxMUG1t"
        "bVSRxGm5aDZXBrLZMD3FgwK5uzs7AhYXV0dhUIhYZeXl9PS0pLQ4+"
        "Pj1NDQQLu7u1RUVKS4kdrHEi8yA4RO4kxNTdHm5iZtb28TmvSSCNHY2BhdXl7S2toajY6O"
        "UiAQINQarfcZYwOGr+"
        "FVV1dTU1MTFRcXe2IDyk2gxsZG6TqPC3FjRQcRZh14w5mZmRGDcDhMp6en4gjOuLs0OTlJ"
        "KMXy8jLV19cTd1psXmCFzP7p7++XVObm5kQYiUTo+"
        "vqahoeHCWPE3ae7uztvXqGUM0IDDa83NzcEYIDy4NPe3p6ADQ4Oypsb4ZUIdrapiQHJ/"
        "CI9GDw8PAh7YWGBzs7OhI7H45mqHo2UX82gJ0kTAEVa3d3dNDs7Kw3q6uoSJ6Z5GTYag22"
        "GMmt8TPT8XxeAnp4e+Q+jFLnAGFghZaygV+uKN484hZEBBX1/f+/"
        "xM6ICqVmOBZGwqqqqPrHRx/z8fPf29tbiJUH8f6XDw0PiVSZdfmOc6+lyFohi47/"
        "WVy6ENA/1l/"
        "XFg23zDhiRuqUXbBi1whJ9enqSQUWa7x3IcWHH0xDhLfUVYSpsWt6LMfZQwwX/"
        "wLVwWPG97osM9Wf7Df6GGOwnsP4BQFiPuOZ8wJUAAAAASUVORK5CYII=");
    tray_icon.SetIcon(icon);
    std::cout << "Tray ID: " << tray_icon.GetId() << std::endl;
    auto title = tray_icon.GetTitle();
    std::cout << "Tray Title: " << (title.has_value() ? title.value() : "(no title)") << std::endl;
    tray_icon.SetVisible(true);

    // Create context menu
    auto context_menu = std::make_shared<Menu>();

    context_menu->AddListener<MenuOpenedEvent>(
        [](const MenuOpenedEvent& event) { std::cout << "Menu opened" << std::endl; });

    context_menu->AddListener<MenuClosedEvent>(
        [](const MenuClosedEvent& event) { std::cout << "Menu closed" << std::endl; });

    // Add menu items
    auto show_window_item = std::make_shared<MenuItem>("Show Window", MenuItemType::Normal);
    show_window_item->AddListener<MenuItemClickedEvent>(
        [window_ptr](const MenuItemClickedEvent& event) {
          std::cout << "Show Window clicked from context menu" << std::endl;
          if (window_ptr) {
            window_ptr->Show();
            window_ptr->Focus();
          }
        });
    context_menu->AddItem(show_window_item);

    auto hide_window_item = std::make_shared<MenuItem>("Hide Window", MenuItemType::Normal);
    hide_window_item->AddListener<MenuItemClickedEvent>(
        [window_ptr](const MenuItemClickedEvent& event) {
          std::cout << "Hide Window clicked from context menu" << std::endl;
          if (window_ptr) {
            window_ptr->Hide();
          }
        });
    context_menu->AddItem(hide_window_item);

    // Add separator
    context_menu->AddSeparator();

    // Add about item
    auto about_item = std::make_shared<MenuItem>("About", MenuItemType::Normal);
    about_item->AddListener<MenuItemClickedEvent>([](const MenuItemClickedEvent& event) {
      std::cout << "About clicked from context menu" << std::endl;
      std::cout << "Window Example v1.0 - Native API Demo" << std::endl;
    });
    context_menu->AddItem(about_item);

    // Create Tools submenu with submenu event handling
    auto tools_submenu = std::make_shared<Menu>();

    // Add items to tools submenu
    auto clear_cache_item = std::make_shared<MenuItem>("Clear Cache", MenuItemType::Normal);
    clear_cache_item->AddListener<MenuItemClickedEvent>([](const MenuItemClickedEvent& event) {
      std::cout << "Clear Cache clicked from submenu" << std::endl;
    });
    tools_submenu->AddItem(clear_cache_item);

    auto reset_settings_item = std::make_shared<MenuItem>("Reset Settings", MenuItemType::Normal);
    reset_settings_item->AddListener<MenuItemClickedEvent>([](const MenuItemClickedEvent& event) {
      std::cout << "Reset Settings clicked from submenu" << std::endl;
    });
    tools_submenu->AddItem(reset_settings_item);

    tools_submenu->AddSeparator();

    auto debug_mode_item = std::make_shared<MenuItem>("Debug Mode", MenuItemType::Checkbox);
    debug_mode_item->SetState(MenuItemState::Unchecked);
    debug_mode_item->AddListener<MenuItemClickedEvent>([debug_mode_item](
                                                           const MenuItemClickedEvent& event) {
      auto current_state = debug_mode_item->GetState();
      MenuItemState new_state = (current_state == MenuItemState::Checked) ? MenuItemState::Unchecked
                                                                          : MenuItemState::Checked;
      debug_mode_item->SetState(new_state);
      std::cout << "Debug Mode " << (new_state == MenuItemState::Checked ? "enabled" : "disabled")
                << std::endl;
    });
    tools_submenu->AddItem(debug_mode_item);

    // Create the submenu parent item
    auto tools_item = std::make_shared<MenuItem>("Tools", MenuItemType::Submenu);
    tools_item->SetSubmenu(tools_submenu);

    // Add submenu event listeners
    tools_item->AddListener<MenuItemSubmenuOpenedEvent>(
        [](const MenuItemSubmenuOpenedEvent& event) {
          std::cout << "Tools submenu opened (ID: " << event.GetItemId() << ")" << std::endl;
        });

    tools_item->AddListener<MenuItemSubmenuClosedEvent>(
        [](const MenuItemSubmenuClosedEvent& event) {
          std::cout << "Tools submenu closed (ID: " << event.GetItemId() << ")" << std::endl;
        });

    context_menu->AddItem(tools_item);

    // Add separator before preferences
    context_menu->AddSeparator();

    // Add preferences section (not a submenu, just a label)
    auto preferences_item = std::make_shared<MenuItem>("Preferences", MenuItemType::Normal);
    context_menu->AddItem(preferences_item);

    // Add checkbox menu items
    auto auto_start_item = std::make_shared<MenuItem>("Auto Start", MenuItemType::Checkbox);
    auto_start_item->SetState(MenuItemState::Checked);  // Initially checked
    auto_start_item->AddListener<MenuItemClickedEvent>([auto_start_item](
                                                           const MenuItemClickedEvent& event) {
      auto current_state = auto_start_item->GetState();
      MenuItemState new_state = (current_state == MenuItemState::Checked) ? MenuItemState::Unchecked
                                                                          : MenuItemState::Checked;
      auto_start_item->SetState(new_state);
      std::cout << "Auto Start " << (new_state == MenuItemState::Checked ? "enabled" : "disabled")
                << std::endl;
    });
    context_menu->AddItem(auto_start_item);

    auto notifications_item =
        std::make_shared<MenuItem>("Show Notifications", MenuItemType::Checkbox);
    notifications_item->SetState(MenuItemState::Unchecked);  // Initially unchecked
    notifications_item->AddListener<MenuItemClickedEvent>([notifications_item](
                                                              const MenuItemClickedEvent& event) {
      auto current_state = notifications_item->GetState();
      MenuItemState new_state = (current_state == MenuItemState::Checked) ? MenuItemState::Unchecked
                                                                          : MenuItemState::Checked;
      notifications_item->SetState(new_state);
      std::cout << "Notifications "
                << (new_state == MenuItemState::Checked ? "enabled" : "disabled") << std::endl;
    });
    context_menu->AddItem(notifications_item);

    // Add three-state checkbox example
    auto sync_item = std::make_shared<MenuItem>("Sync Status", MenuItemType::Checkbox);
    sync_item->SetState(MenuItemState::Mixed);  // Initially mixed/indeterminate
    sync_item->AddListener<MenuItemClickedEvent>([sync_item](const MenuItemClickedEvent& event) {
      auto current_state = sync_item->GetState();
      MenuItemState next_state;
      std::string state_name;

      // Cycle through states: Mixed -> Checked -> Unchecked -> Mixed
      switch (current_state) {
        case MenuItemState::Mixed:
          next_state = MenuItemState::Checked;
          state_name = "enabled";
          break;
        case MenuItemState::Checked:
          next_state = MenuItemState::Unchecked;
          state_name = "disabled";
          break;
        case MenuItemState::Unchecked:
        default:
          next_state = MenuItemState::Mixed;
          state_name = "partial";
          break;
      }

      sync_item->SetState(next_state);
      std::cout << "Sync Status: " << state_name << std::endl;
    });
    context_menu->AddItem(sync_item);

    // Add separator before radio group
    context_menu->AddSeparator();

    // Add radio button group for theme selection
    auto theme_label = std::make_shared<MenuItem>("Theme:", MenuItemType::Normal);
    context_menu->AddItem(theme_label);

    auto light_theme_item = std::make_shared<MenuItem>("Light Theme", MenuItemType::Radio);
    light_theme_item->SetRadioGroup(0);                  // Group 0
    light_theme_item->SetState(MenuItemState::Checked);  // Default selection
    light_theme_item->AddListener<MenuItemClickedEvent>(
        [light_theme_item](const MenuItemClickedEvent& event) {
          light_theme_item->SetState(MenuItemState::Checked);
          std::cout << "Light theme selected" << std::endl;
        });
    context_menu->AddItem(light_theme_item);

    auto dark_theme_item = std::make_shared<MenuItem>("Dark Theme", MenuItemType::Radio);
    dark_theme_item->SetRadioGroup(0);  // Same group as light theme
    dark_theme_item->AddListener<MenuItemClickedEvent>(
        [dark_theme_item](const MenuItemClickedEvent& event) {
          dark_theme_item->SetState(MenuItemState::Checked);
          std::cout << "Dark theme selected" << std::endl;
        });
    context_menu->AddItem(dark_theme_item);

    auto auto_theme_item = std::make_shared<MenuItem>("Auto Theme", MenuItemType::Radio);
    auto_theme_item->SetRadioGroup(0);  // Same group
    auto_theme_item->AddListener<MenuItemClickedEvent>(
        [auto_theme_item](const MenuItemClickedEvent& event) {
          auto_theme_item->SetState(MenuItemState::Checked);
          std::cout << "Auto theme selected" << std::endl;
        });
    context_menu->AddItem(auto_theme_item);

    // Add another separator
    context_menu->AddSeparator();

    // Add exit item
    auto exit_item = std::make_shared<MenuItem>("Exit", MenuItemType::Normal);
    exit_item->AddListener<MenuItemClickedEvent>([window_ptr](const MenuItemClickedEvent& event) {
      std::cout << "Exit clicked from context menu" << std::endl;
      // Close the window to trigger app exit
      if (window_ptr) {
        window_ptr->Hide();
      }
    });
    context_menu->AddItem(exit_item);

    // Set the context menu to the tray icon
    tray_icon.SetContextMenu(context_menu);

    // Set up event listeners
    tray_icon.AddListener<TrayIconClickedEvent>([&tray_icon](const TrayIconClickedEvent& event) {
      std::cout << "*** TRAY ICON LEFT CLICKED! ***" << std::endl;
      std::cout << "This is the left click handler working!" << std::endl;
      std::cout << "Tray icon ID: " << event.GetTrayIconId() << std::endl;

      // Open context menu on left click
      tray_icon.OpenContextMenu();
    });

    tray_icon.AddListener<TrayIconRightClickedEvent>([](const TrayIconRightClickedEvent& event) {
      std::cout << "*** TRAY ICON RIGHT CLICKED! ***" << std::endl;
      std::cout << "This is the right click handler working!" << std::endl;
      std::cout << "Tray icon ID: " << event.GetTrayIconId() << std::endl;
    });

    tray_icon.AddListener<TrayIconDoubleClickedEvent>([](const TrayIconDoubleClickedEvent& event) {
      std::cout << "*** TRAY ICON DOUBLE CLICKED! ***" << std::endl;
      std::cout << "This is the double click handler working!" << std::endl;
      std::cout << "Tray icon ID: " << event.GetTrayIconId() << std::endl;
    });
  } else {
    std::cerr << "Failed to create tray." << std::endl;
  }

  display_manager.AddListener<nativeapi::DisplayAddedEvent>(
      [](const nativeapi::DisplayAddedEvent& event) {
        std::cout << "Display added: " << event.GetDisplay()->GetId() << std::endl;
      });
  display_manager.AddListener<nativeapi::DisplayRemovedEvent>(
      [](const nativeapi::DisplayRemovedEvent& event) {
        std::cout << "Display removed: " << event.GetDisplay()->GetId() << std::endl;
      });

  auto& app = Application::GetInstance();
  app.Run(window_ptr);

  return 0;
}
