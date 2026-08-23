#include <iostream>
#include <string>
#include <vector>

#include "nativeapi.h"

using namespace nativeapi;

int main() {
  std::cout << "LaunchAtLogin Example\n";
  std::cout << "=================\n\n";

  // Check if launch-at-login is supported on this platform
  if (!LaunchAtLogin::IsSupported()) {
    std::cout << "LaunchAtLogin is not supported on this platform.\n";
    return 0;
  }

  std::cout << "LaunchAtLogin is supported on this platform.\n\n";

  // On macOS, the default constructor registers the main app with SMAppService.
  // Custom identifiers are for bundled login item helpers.
#if defined(__APPLE__)
  LaunchAtLogin launch_at_login;
#else
  LaunchAtLogin launch_at_login("com.example.myapp", "My Example App");
#endif

  // Display current configuration
  std::cout << "LaunchAtLogin configuration:\n";
  std::cout << "  ID:           " << launch_at_login.GetId() << "\n";
  std::cout << "  Display name: " << launch_at_login.GetDisplayName() << "\n";
  std::cout << "  Executable:   " << launch_at_login.GetExecutablePath() << "\n\n";

// macOS SMAppService main-app login items do not support arbitrary arguments.
#if !defined(__APPLE__)
  // Set a custom program path and arguments
  launch_at_login.SetProgram(launch_at_login.GetExecutablePath(),
                             {"--minimized", "--launch_at_login"});
#endif

  std::cout << "After SetProgram:\n";
  std::cout << "  Executable: " << launch_at_login.GetExecutablePath() << "\n";
  auto args = launch_at_login.GetArguments();
  std::cout << "  Arguments:  ";
  for (const auto& arg : args) {
    std::cout << arg << " ";
  }
  std::cout << "\n\n";

  // Check current state before enabling
  std::cout << "Is enabled (before Enable): " << (launch_at_login.IsEnabled() ? "yes" : "no")
            << "\n";

  // Enable launch-at-login
  std::cout << "Enabling launch-at-login...\n";
  if (launch_at_login.Enable()) {
    std::cout << "Launch-at-login enabled successfully.\n";
  } else {
    std::cout << "Failed to enable launch-at-login.\n";
    return 1;
  }

  // Verify it is now enabled
  std::cout << "Is enabled (after Enable):  " << (launch_at_login.IsEnabled() ? "yes" : "no")
            << "\n\n";

  // Update the display name and re-enable to update the stored entry
  launch_at_login.SetDisplayName("My Example App (Updated)");
  std::cout << "Updated display name to: " << launch_at_login.GetDisplayName() << "\n";
  launch_at_login.Enable();

  // Disable launch-at-login
  std::cout << "\nDisabling launch-at-login...\n";
  if (launch_at_login.Disable()) {
    std::cout << "Launch-at-login disabled successfully.\n";
  } else {
    std::cout << "Failed to disable launch-at-login.\n";
    return 1;
  }

  // Verify it is now disabled
  std::cout << "Is enabled (after Disable): " << (launch_at_login.IsEnabled() ? "yes" : "no")
            << "\n\n";

  std::cout << "Example completed successfully!\n\n";
  std::cout << "This example demonstrated:\n";
  std::cout << "  * LaunchAtLogin::IsSupported()    - Check platform support\n";
  std::cout << "  * LaunchAtLogin(id, name)         - Construct with identifier and display name\n";
  std::cout << "  * LaunchAtLogin::GetId()          - Get identifier\n";
  std::cout << "  * LaunchAtLogin::GetDisplayName() - Get display name\n";
  std::cout << "  * LaunchAtLogin::SetDisplayName() - Update display name\n";
  std::cout << "  * LaunchAtLogin::SetProgram()     - Set executable path and arguments\n";
  std::cout << "  * LaunchAtLogin::GetExecutablePath() - Get configured executable\n";
  std::cout << "  * LaunchAtLogin::GetArguments()   - Get configured arguments\n";
  std::cout << "  * LaunchAtLogin::Enable()         - Register launch-at-login with the OS\n";
  std::cout << "  * LaunchAtLogin::Disable()        - Remove launch-at-login from the OS\n";
  std::cout << "  * LaunchAtLogin::IsEnabled()      - Query current registration state\n";

  return 0;
}
