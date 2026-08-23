#include <iostream>
#include <memory>

#include "nativeapi.h"

using namespace nativeapi;

int main() {
  std::cout << "Application Example" << std::endl;

  // Get the Application singleton
  auto& app = Application::GetInstance();

  std::cout << "Application initialized automatically" << std::endl;
  std::cout << "Single instance: " << (app.IsSingleInstance() ? "Yes" : "No") << std::endl;

  // Add event listeners
  auto started_listener =
      app.AddListener<ApplicationStartedEvent>([](const ApplicationStartedEvent& event) {
        std::cout << "Application started event received" << std::endl;
      });

  auto quit_listener = app.AddListener<ApplicationQuitRequestedEvent>(
      [](const ApplicationQuitRequestedEvent& event) {
        std::cout << "Application quit requested event received" << std::endl;
      });

  auto activated_listener =
      app.AddListener<ApplicationActivatedEvent>([](const ApplicationActivatedEvent& event) {
        std::cout << "Application activated event received" << std::endl;
      });

  auto deactivated_listener =
      app.AddListener<ApplicationDeactivatedEvent>([](const ApplicationDeactivatedEvent& event) {
        std::cout << "Application deactivated event received" << std::endl;
      });

  // Create a simple window (automatically registered)
  auto& window_manager = WindowManager::GetInstance();

  auto window = std::make_shared<Window>();
  window->SetTitle("Application Example Window");

  if (!window) {
    std::cerr << "Failed to create window" << std::endl;
    return 1;
  }

  // Set as primary window
  app.SetPrimaryWindow(window);

  std::cout << "Window created successfully" << std::endl;
  std::cout << "Window ID: " << window->GetId() << std::endl;

  // Show the window
  window->Show();

  std::cout << "Starting application event loop..." << std::endl;
  std::cout << "Press Ctrl+C to quit" << std::endl;

  // Run the application
  int exit_code = app.Run();

  std::cout << "Application exited with code: " << exit_code << std::endl;

  // Clean up listeners
  app.RemoveListener(started_listener);
  app.RemoveListener(quit_listener);
  app.RemoveListener(activated_listener);
  app.RemoveListener(deactivated_listener);

  return exit_code;
}
