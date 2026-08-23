#include <signal.h>
#include <chrono>
#include <iostream>
#include <memory>
#include <thread>

#include "nativeapi.h"

using namespace nativeapi;

// Global flag for graceful shutdown
static bool g_running = true;

// Signal handler for graceful shutdown
void signal_handler(int sig) {
  std::cout << "\nReceived signal " << sig << ", shutting down...\n";
  g_running = false;
}

int main() {
  std::cout << "ShortcutManager Example\n";
  std::cout << "=======================\n\n";

  // Set up signal handlers
  signal(SIGINT, signal_handler);
  signal(SIGTERM, signal_handler);

  // Get the ShortcutManager singleton instance
  auto& manager = ShortcutManager::GetInstance();

  // Check if global shortcuts are supported
  if (!manager.IsSupported()) {
    std::cout << "⚠️  Global shortcuts are not supported on this platform or configuration.\n";
    std::cout << "This may be due to:\n";
    std::cout << "  - Missing accessibility permissions (macOS)\n";
    std::cout << "  - No display server available (Linux)\n";
    std::cout << "  - Platform limitations\n\n";
    std::cout << "The example will continue, but shortcuts won't be triggered.\n\n";
  } else {
    std::cout << "✓ Global shortcuts are supported\n\n";
  }

  // Add event listener for shortcut activations
  auto activation_listener =
      manager.AddListener<ShortcutActivatedEvent>([](const ShortcutActivatedEvent& event) {
        std::cout << "🔔 Shortcut activated: " << event.GetAccelerator()
                  << " (ID: " << event.GetShortcutId() << ")\n";
      });

  // Add event listener for registration events
  auto registration_listener =
      manager.AddListener<ShortcutRegisteredEvent>([](const ShortcutRegisteredEvent& event) {
        std::cout << "✓ Shortcut registered: " << event.GetAccelerator()
                  << " (ID: " << event.GetShortcutId() << ")\n";
      });

  // Add event listener for unregistration events
  auto unregistration_listener =
      manager.AddListener<ShortcutUnregisteredEvent>([](const ShortcutUnregisteredEvent& event) {
        std::cout << "✗ Shortcut unregistered: " << event.GetAccelerator()
                  << " (ID: " << event.GetShortcutId() << ")\n";
      });

  // Add event listener for registration failures
  auto failure_listener = manager.AddListener<ShortcutRegistrationFailedEvent>(
      [](const ShortcutRegistrationFailedEvent& event) {
        std::cout << "❌ Failed to register shortcut: " << event.GetAccelerator() << " - "
                  << event.GetErrorMessage() << "\n";
      });

  std::cout << "Event listeners registered\n\n";

  // Register shortcuts with simple callback
  std::cout << "Registering shortcuts...\n";

  auto shortcut1 =
      manager.Register("Ctrl+Shift+A", []() { std::cout << "  → Action A triggered!\n"; });

  auto shortcut2 =
      manager.Register("Ctrl+Shift+B", []() { std::cout << "  → Action B triggered!\n"; });

  auto shortcut3 =
      manager.Register("Ctrl+Shift+C", []() { std::cout << "  → Action C triggered!\n"; });

  // Register shortcut with detailed options
  ShortcutOptions options;
  options.accelerator = "Ctrl+Shift+Q";
  options.description = "Quick quit action";
  options.scope = ShortcutScope::Global;
  options.callback = []() {
    std::cout << "  → Quick quit triggered! (This would normally quit the app)\n";
  };

  auto shortcut4 = manager.Register(options);

  std::cout << "\n";

  // Display registered shortcuts
  auto all_shortcuts = manager.GetAll();
  std::cout << "Currently registered shortcuts (" << all_shortcuts.size() << "):\n";
  for (const auto& shortcut : all_shortcuts) {
    std::cout << "  • " << shortcut->GetAccelerator();
    if (!shortcut->GetDescription().empty()) {
      std::cout << " - " << shortcut->GetDescription();
    }
    std::cout << " (ID: " << shortcut->GetId() << ", Scope: "
              << (shortcut->GetScope() == ShortcutScope::Global ? "Global" : "Application")
              << ", Enabled: " << (shortcut->IsEnabled() ? "Yes" : "No") << ")\n";
  }
  std::cout << "\n";

  // Demonstrate validation
  std::cout << "Testing accelerator validation:\n";
  std::vector<std::string> test_accelerators = {
      "Ctrl+A",         // Valid
      "Ctrl+Shift+F1",  // Valid
      "Invalid",        // Invalid
      "Ctrl++",         // Invalid
      "Alt+Space",      // Valid
  };

  for (const auto& acc : test_accelerators) {
    bool valid = manager.IsValidAccelerator(acc);
    bool available = manager.IsAvailable(acc);
    std::cout << "  • \"" << acc << "\" - Valid: " << (valid ? "Yes" : "No")
              << ", Available: " << (available ? "Yes" : "No") << "\n";
  }
  std::cout << "\n";

  // Demonstrate enable/disable
  std::cout << "Demonstrating enable/disable:\n";
  if (shortcut1) {
    std::cout << "  • Disabling shortcut: " << shortcut1->GetAccelerator() << "\n";
    shortcut1->SetEnabled(false);
    std::cout << "    Shortcut is now disabled. Pressing it won't trigger the callback.\n";

    std::this_thread::sleep_for(std::chrono::seconds(2));

    std::cout << "  • Re-enabling shortcut: " << shortcut1->GetAccelerator() << "\n";
    shortcut1->SetEnabled(true);
    std::cout << "    Shortcut is now enabled again.\n";
  }
  std::cout << "\n";

  // Demonstrate programmatic invocation
  std::cout << "Demonstrating programmatic invocation:\n";
  if (shortcut2) {
    std::cout << "  • Manually invoking shortcut: " << shortcut2->GetAccelerator() << "\n";
    shortcut2->Invoke();
  }
  std::cout << "\n";

  // Demonstrate getting shortcuts by scope
  std::cout << "Shortcuts by scope:\n";
  auto global_shortcuts = manager.GetByScope(ShortcutScope::Global);
  auto app_shortcuts = manager.GetByScope(ShortcutScope::Application);
  std::cout << "  • Global shortcuts: " << global_shortcuts.size() << "\n";
  std::cout << "  • Application shortcuts: " << app_shortcuts.size() << "\n";
  std::cout << "\n";

  // Main loop
  std::cout << "📋 Available shortcuts:\n";
  std::cout << "  • Ctrl+Shift+A - Trigger Action A\n";
  std::cout << "  • Ctrl+Shift+B - Trigger Action B\n";
  std::cout << "  • Ctrl+Shift+C - Trigger Action C\n";
  std::cout << "  • Ctrl+Shift+Q - Quick quit action\n";
  std::cout << "\n";
  std::cout << "Press the shortcuts above to see them in action.\n";
  std::cout << "Press Ctrl+C to exit.\n\n";

  // Keep the main thread alive AND service the main-thread work queue.
  //
  // Events are delivered on the main thread, which means something has to run
  // the platform main loop. A GUI app gets that from its UI framework; a console
  // program like this one asks the library to do it. Plain sleeping here would
  // keep the process alive but no event would ever arrive.
  int seconds = 0;
  while (g_running) {
    if (!RunMainThreadLoopFor(1000)) {
      // Platform without main-loop integration — fall back to sleeping so the
      // example still terminates cleanly.
      std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    seconds++;

    // After 10 seconds, demonstrate unregistering a shortcut
    if (seconds == 10 && shortcut3) {
      std::cout << "\n⏰ 10 seconds elapsed. Unregistering shortcut: "
                << shortcut3->GetAccelerator() << "\n\n";
      manager.Unregister(shortcut3->GetId());
    }

    // After 20 seconds, demonstrate disabling all shortcuts
    if (seconds == 20) {
      std::cout << "\n⏰ 20 seconds elapsed. Disabling all shortcut processing.\n";
      std::cout << "Shortcuts will remain registered but won't trigger.\n\n";
      manager.SetEnabled(false);
    }

    // After 25 seconds, re-enable
    if (seconds == 25) {
      std::cout << "\n⏰ 25 seconds elapsed. Re-enabling shortcut processing.\n\n";
      manager.SetEnabled(true);
    }
  }

  // Cleanup
  std::cout << "\nCleaning up...\n";

  // Remove event listeners
  manager.RemoveListener(activation_listener);
  manager.RemoveListener(registration_listener);
  manager.RemoveListener(unregistration_listener);
  manager.RemoveListener(failure_listener);

  // Unregister all shortcuts
  int count = manager.UnregisterAll();
  std::cout << "Unregistered " << count << " shortcuts\n";

  std::cout << "\nExample completed successfully!\n";
  std::cout << "\nThis example demonstrated:\n";
  std::cout << "  • ShortcutManager::GetInstance() - Get singleton instance\n";
  std::cout << "  • ShortcutManager::IsSupported() - Check platform support\n";
  std::cout << "  • ShortcutManager::Register() - Register shortcuts\n";
  std::cout << "  • ShortcutManager::Unregister() - Unregister shortcuts\n";
  std::cout << "  • ShortcutManager::GetAll() - Get all shortcuts\n";
  std::cout << "  • ShortcutManager::GetByScope() - Filter by scope\n";
  std::cout << "  • ShortcutManager::IsValidAccelerator() - Validate format\n";
  std::cout << "  • ShortcutManager::IsAvailable() - Check availability\n";
  std::cout << "  • ShortcutManager::SetEnabled() - Enable/disable processing\n";
  std::cout << "  • Shortcut::SetEnabled() - Enable/disable individual shortcuts\n";
  std::cout << "  • Shortcut::Invoke() - Programmatic invocation\n";
  std::cout << "  • Event listeners for activation, registration, and errors\n";

  return 0;
}
