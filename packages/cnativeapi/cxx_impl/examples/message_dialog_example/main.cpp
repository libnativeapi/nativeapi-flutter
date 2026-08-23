#include <iostream>
#include <memory>
#include "nativeapi.h"

using namespace nativeapi;

int main() {
  std::cout << "=== MessageDialog Example ===" << std::endl;

  // Get the Application instance to initialize platform
  Application& app = Application::GetInstance();

  try {
    std::cout << "\n1. Creating a simple informational dialog..." << std::endl;

    // Create a simple informational message dialog
    auto info_dialog = std::make_shared<MessageDialog>(
        "Information",
        "This is an informational message dialog.\n\n"
        "MessageDialog can be used to display various types of messages to users.");

    info_dialog->SetModality(DialogModality::Application);

    std::cout << "Dialog title: " << info_dialog->GetTitle() << std::endl;
    std::cout << "Dialog message: " << info_dialog->GetMessage() << std::endl;
    std::cout << "Opening dialog..." << std::endl;

    // Open the dialog (this will block until user dismisses it)
    if (info_dialog->Open()) {
      std::cout << "Dialog was opened successfully" << std::endl;
    } else {
      std::cout << "Failed to open dialog" << std::endl;
    }

    std::cout << "\n2. Creating a warning dialog..." << std::endl;

    // Create a warning dialog
    auto warning_dialog = std::make_shared<MessageDialog>(
        "Warning",
        "This is a warning message.\n\n"
        "Warning dialogs are used to alert users about potential issues.");

    warning_dialog->SetModality(DialogModality::Application);
    warning_dialog->Open();

    std::cout << "\n3. Creating a dialog with updated content..." << std::endl;

    // Create a dialog and update its content
    auto dynamic_dialog = std::make_shared<MessageDialog>("Update Available", "Initial message");

    // Update the title and message before opening
    dynamic_dialog->SetTitle("System Update");
    dynamic_dialog->SetMessage(
        "A new version of the application is available.\n\n"
        "Version 2.0 includes:\n"
        "• Improved performance\n"
        "• New features\n"
        "• Bug fixes\n\n"
        "Would you like to update now?");

    dynamic_dialog->SetModality(DialogModality::Application);

    std::cout << "Updated title: " << dynamic_dialog->GetTitle() << std::endl;
    std::cout << "Opening updated dialog..." << std::endl;
    dynamic_dialog->Open();

    std::cout << "\n4. Demonstrating different modality types..." << std::endl;

    // Non-modal dialog (default)
    auto non_modal_dialog = std::make_shared<MessageDialog>(
        "Non-Modal Dialog",
        "This dialog does not block interaction.\n\n"
        "The application continues running and users can interact with other windows.");
    non_modal_dialog->SetModality(DialogModality::None);
    std::cout << "Modality: None (non-modal)" << std::endl;
    non_modal_dialog->Open();

    // Application modal dialog
    auto app_modal_dialog = std::make_shared<MessageDialog>(
        "Application Modal",
        "This dialog blocks interaction with all windows in the current application.");
    app_modal_dialog->SetModality(DialogModality::Application);
    std::cout << "Modality: Application" << std::endl;
    app_modal_dialog->Open();

    // Window modal dialog (behaves as Application on macOS)
    auto window_modal_dialog = std::make_shared<MessageDialog>(
        "Window Modal",
        "This dialog blocks interaction with a specific parent window.\n\n"
        "Note: On macOS, this behaves as Application.");
    window_modal_dialog->SetModality(DialogModality::Window);
    std::cout << "Modality: Window" << std::endl;
    window_modal_dialog->Open();

    std::cout << "\n=== MessageDialog Example Complete ===" << std::endl;
    std::cout << "This example demonstrated:" << std::endl;
    std::cout << "1. Creating MessageDialog instances" << std::endl;
    std::cout << "2. Setting title and message" << std::endl;
    std::cout << "3. Updating dialog content programmatically" << std::endl;
    std::cout << "4. Opening dialogs with different modality types (None, Application, Window)"
              << std::endl;
    std::cout << "5. Modal vs non-modal dialog behavior" << std::endl;

    std::cout << "\nExiting MessageDialog Example..." << std::endl;
    return 0;

  } catch (const std::exception& e) {
    std::cerr << "Error: " << e.what() << std::endl;
    return 1;
  }
}
