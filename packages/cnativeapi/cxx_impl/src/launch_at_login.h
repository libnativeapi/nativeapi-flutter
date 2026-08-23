#pragma once

#include <memory>
#include <string>
#include <vector>

namespace nativeapi {

/**
 * @brief Manage launching the application at user login (cross-platform).
 *
 * LaunchAtLogin provides a unified API to enable or disable starting your application
 * automatically when the user logs in. The actual mechanism is platform-specific,
 * but this class abstracts away those differences.
 *
 * Platform implementations:
 * - Windows: HKCU\Software\Microsoft\Windows\CurrentVersion\Run registry key
 * - macOS: ServiceManagement SMAppService for the main app or bundled login item helpers
 * - Linux (XDG): ~/.config/autostart/[app_id].desktop
 * - Android/iOS/OHOS: Not supported (returns false from IsSupported/operations)
 *
 * Notes:
 * - This API is intended for desktop environments. On mobile platforms this API is
 *   typically unsupported by design. Methods will fail gracefully.
 * - You can let the implementation determine the current executable path, or call
 *   SetProgram() to customize the target binary and arguments recorded in the OS where the
 *   platform supports arbitrary launch commands. On macOS, SMAppService can only register
 *   the main app or a bundled helper, so custom executable paths and arguments are not
 *   supported.
 * - Some platforms may require application-specific permissions or entitlements
 *   (e.g., sandbox restrictions on macOS). In such cases, operations may fail.
 *
 * Typical usage:
 * @code
 * using namespace nativeapi;
 *
 * if (LaunchAtLogin::IsSupported()) {
 *   LaunchAtLogin launch_at_login("com.example.myapp", "MyApp");
 *   // Optionally override the program and arguments where supported:
 *   launch_at_login.SetProgram("/usr/local/bin/myapp", {"--minimized"});
 *
 *   launch_at_login.Enable();
 *   bool enabled = launch_at_login.IsEnabled(); // should be true
 * }
 * @endcode
 */
class LaunchAtLogin {
 public:
  /**
   * @brief Check whether launch-at-login is supported on this platform.
   *
   * @return true if supported; false for unsupported platforms (e.g., mobile).
   */
  static bool IsSupported();

  /**
   * @brief Construct a LaunchAtLogin manager with default identifier and display name.
   *
   * The default identifier and display name are implementation-defined. Typically,
   * the identifier is derived from the current process/bundle information, and the
   * display name is derived from the application or executable name.
   */
  LaunchAtLogin();

  /**
   * @brief Construct a LaunchAtLogin manager with a custom identifier.
   *
   * @param id A stable, unique identifier for your app.
   *           Examples:
   *           - Windows: used as the registry value name, e.g., "MyApp"
   *           - macOS: bundle identifier for a bundled LoginItem helper, e.g.,
   *             "com.example.myapp.Helper"; the default constructor registers the main app
   *           - Linux: used as the .desktop file name (without extension), e.g., "myapp"
   *
   * Recommendation: Use a reverse-DNS identifier when possible, e.g., "com.example.myapp".
   */
  explicit LaunchAtLogin(const std::string& id);

  /**
   * @brief Construct a LaunchAtLogin manager with a custom identifier and display name.
   *
   * @param id           Stable, unique identifier (see above).
   * @param display_name Human-readable name shown in OS surfaces where applicable.
   */
  LaunchAtLogin(const std::string& id, const std::string& display_name);

  virtual ~LaunchAtLogin();

  /**
   * @brief Get the unique identifier associated with this LaunchAtLogin instance.
   *
   * @return The identifier string.
   */
  std::string GetId() const;

  /**
   * @brief Get the human-readable display name used where applicable.
   *
   * @return The display name string.
   */
  std::string GetDisplayName() const;

  /**
   * @brief Set a human-readable display name used where applicable.
   *
   * Some platforms surface a name in their UI (e.g., Linux .desktop Name).
   *
   * @param display_name The human-readable name.
   * @return true if the value was stored locally; does not change OS registration until Enable().
   */
  bool SetDisplayName(const std::string& display_name);

  /**
   * @brief Set the program (executable) path and optional arguments used to launch at login.
   *
   * If not set, implementations will try to use the current process executable path.
   * On platforms that require a single string (e.g., Windows registry), arguments will
   * be encoded appropriately (quoted when needed). On Linux, arguments are stored in
   * the .desktop Exec line. On macOS, SMAppService does not support arbitrary
   * executable paths or arguments for main-app login items.
   *
   * @param executable_path Absolute path to the executable to run on login.
   * @param arguments       Optional arguments; order is preserved.
   * @return true if stored locally; does not change OS registration until Enable().
   */
  bool SetProgram(const std::string& executable_path,
                  const std::vector<std::string>& arguments = {});

  /**
   * @brief Get the currently configured executable path used to launch at login.
   *
   * This returns the locally configured value (not necessarily what is stored in the OS).
   * If never set explicitly and cannot be resolved from the current process, it may be empty.
   *
   * @return Executable path string (may be empty).
   */
  std::string GetExecutablePath() const;

  /**
   * @brief Get the currently configured arguments used to launch at login.
   *
   * This returns the locally configured value (not necessarily what is stored in the OS).
   *
   * @return Vector of arguments (may be empty).
   */
  std::vector<std::string> GetArguments() const;

  /**
   * @brief Enable launch-at-login for the configured program and arguments.
   *
   * If no program was explicitly set via SetProgram(), the implementation will attempt
   * to resolve the current executable path and use that as the program to start.
   *
   * @return true on success; false on error or when unsupported.
   */
  bool Enable();

  /**
   * @brief Disable launch-at-login.
   *
   * @return true on success; false on error or when unsupported.
   */
  bool Disable();

  /**
   * @brief Query whether launch-at-login is currently enabled for this manager's identifier.
   *
   * This checks the platform-specific mechanism to determine whether the app (program path
   * and arguments currently configured) is registered to start at user login.
   *
   * @return true if currently enabled; false otherwise.
   */
  bool IsEnabled() const;

  // Prevent copying and moving
  LaunchAtLogin(const LaunchAtLogin&) = delete;
  LaunchAtLogin& operator=(const LaunchAtLogin&) = delete;
  LaunchAtLogin(LaunchAtLogin&&) = delete;
  LaunchAtLogin& operator=(LaunchAtLogin&&) = delete;

 private:
  class Impl;
  std::unique_ptr<Impl> pimpl_;
};

}  // namespace nativeapi
