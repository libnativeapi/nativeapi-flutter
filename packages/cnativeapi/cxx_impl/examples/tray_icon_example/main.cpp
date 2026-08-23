#include <chrono>
#include <iostream>
#include <memory>
#include <thread>

#include "../../src/application.h"
#include "../../src/image.h"
#include "../../src/menu.h"
#include "../../src/tray_icon.h"
#include "../../src/tray_manager.h"

using namespace nativeapi;
using nativeapi::Menu;
using nativeapi::MenuItem;
using nativeapi::MenuItemClickedEvent;
using nativeapi::MenuItemType;

int main() {
  std::cout << "Starting TrayIcon Example..." << std::endl;

  // Get the Application instance - this handles platform initialization
  Application& app = Application::GetInstance();

  // Check if tray icons are supported
  TrayManager& trayManager = TrayManager::GetInstance();
  if (!trayManager.IsSupported()) {
    std::cerr << "Tray icons are not supported on this platform!" << std::endl;
    return 1;
  }

  // Create a tray icon directly
  auto trayIcon = std::make_shared<TrayIcon>();
  if (!trayIcon) {
    std::cerr << "Failed to create tray icon!" << std::endl;
    return 1;
  }

  // Set up the tray icon
  trayIcon->SetTitle("Test App");
  trayIcon->SetTooltip("This is a test tray icon");

  // Set up event listeners
  trayIcon->AddListener<TrayIconClickedEvent>([](const TrayIconClickedEvent& event) {
    std::cout << "*** TRAY ICON LEFT CLICKED! ***" << std::endl;
    std::cout << "This is the left click handler working!" << std::endl;
    std::cout << "Tray icon ID: " << event.GetTrayIconId() << std::endl;
  });

  trayIcon->AddListener<TrayIconRightClickedEvent>([](const TrayIconRightClickedEvent& event) {
    std::cout << "*** TRAY ICON RIGHT CLICKED! ***" << std::endl;
    std::cout << "This is the right click handler working!" << std::endl;
    std::cout << "Tray icon ID: " << event.GetTrayIconId() << std::endl;
    // Note: Context menu will be auto-triggered by SetContextMenuTrigger below
  });

  trayIcon->AddListener<TrayIconDoubleClickedEvent>([](const TrayIconDoubleClickedEvent& event) {
    std::cout << "*** TRAY ICON DOUBLE CLICKED! ***" << std::endl;
    std::cout << "This is the double click handler working!" << std::endl;
    std::cout << "Tray icon ID: " << event.GetTrayIconId() << std::endl;
  });

  // Create context menu
  auto context_menu = std::make_shared<Menu>();

  // Add menu items
  auto status_item = std::make_shared<MenuItem>("Status: Running", MenuItemType::Normal);
  status_item->AddListener<MenuItemClickedEvent>([](const MenuItemClickedEvent& event) {
    std::cout << "Status clicked from context menu" << std::endl;
  });
  context_menu->AddItem(status_item);

  // Add separator
  context_menu->AddSeparator();

  // Add settings item
  auto settings_item = std::make_shared<MenuItem>("Settings...", MenuItemType::Normal);
  settings_item->AddListener<MenuItemClickedEvent>([](const MenuItemClickedEvent& event) {
    std::cout << "Settings clicked from context menu" << std::endl;
    std::cout << "Opening settings dialog..." << std::endl;
  });
  context_menu->AddItem(settings_item);

  // Add about item
  auto about_item = std::make_shared<MenuItem>("About", MenuItemType::Normal);
  about_item->AddListener<MenuItemClickedEvent>([](const MenuItemClickedEvent& event) {
    std::cout << "About clicked from context menu" << std::endl;
    std::cout << "TrayIcon Example v1.0 - Native API Demo" << std::endl;
  });
  context_menu->AddItem(about_item);

  // Add another separator
  context_menu->AddSeparator();

  // Add exit item
  auto exit_item = std::make_shared<MenuItem>("Exit", MenuItemType::Normal);
  exit_item->AddListener<MenuItemClickedEvent>([&app](const MenuItemClickedEvent& event) {
    std::cout << "Exit clicked from context menu" << std::endl;
    app.Quit(0);
  });
  context_menu->AddItem(exit_item);

  // Set the context menu to the tray icon
  trayIcon->SetContextMenu(context_menu);

  // Set context menu trigger to automatically show menu on right click
  // This is the common behavior on Windows and most desktop environments
  trayIcon->SetContextMenuTrigger(ContextMenuTrigger::RightClicked);

  // Get and display the current trigger mode
  ContextMenuTrigger currentTrigger = trayIcon->GetContextMenuTrigger();
  std::cout << "Context menu trigger mode: ";
  switch (currentTrigger) {
    case ContextMenuTrigger::None:
      std::cout << "None (manual control)";
      break;
    case ContextMenuTrigger::Clicked:
      std::cout << "Left Click";
      break;
    case ContextMenuTrigger::RightClicked:
      std::cout << "Right Click";
      break;
    case ContextMenuTrigger::DoubleClicked:
      std::cout << "Double Click";
      break;
  }
  std::cout << std::endl;

  // Show the tray icon
  if (trayIcon->SetVisible(true)) {
    std::cout << "Tray icon is now visible!" << std::endl;
  } else {
    std::cerr << "Failed to show tray icon!" << std::endl;
    return 1;
  }

  // Get and display bounds
  Rectangle bounds = trayIcon->GetBounds();
  std::cout << "Tray icon bounds: x=" << bounds.x << ", y=" << bounds.y
            << ", width=" << bounds.width << ", height=" << bounds.height << std::endl;

  std::cout << "========================================" << std::endl;
  std::cout << "Tray icon example is now running!" << std::endl;
  std::cout << "Try clicking on the tray icon:" << std::endl;
  std::cout << "- Left click: Single click event" << std::endl;
  std::cout << "- Right click: Auto-opens context menu (via SetContextMenuTrigger)" << std::endl;
  std::cout << "- Double click: Quick double click event" << std::endl;
  std::cout << "- Context menu: Right-click to see options including Exit" << std::endl;
  std::cout << std::endl;
  std::cout << "Note: The context menu is automatically shown on right-click" << std::endl;
  std::cout << "      because we set ContextMenuTrigger::RightClicked." << std::endl;
  std::cout << "      You can also use Clicked, DoubleClicked, or None for manual control."
            << std::endl;
  std::cout << std::endl;
  std::cout << "Use the Exit menu item to quit the application." << std::endl;
  std::cout << "========================================" << std::endl;

  // Set up application event listeners
  app.AddListener<ApplicationExitingEvent>([&trayIcon](const ApplicationExitingEvent& event) {
    std::cout << "Application is exiting with code: " << event.GetExitCode() << std::endl;
    // Hide the tray icon before exiting
    if (trayIcon) {
      trayIcon->SetVisible(false);
    }
  });

  // Run the application event loop - this will block until app.Quit() is called
  int exit_code = app.Run();

  std::cout << "Exiting TrayIcon Example..." << std::endl;
  return exit_code;
}
