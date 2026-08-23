#pragma once

#include <string>

namespace nativeapi {

/**
 * @enum DialogModality
 * @brief Dialog modality types.
 *
 * Defines how the dialog blocks user interaction.
 */
enum class DialogModality {
  /**
   * @brief None - Non-modal dialog.
   *
   * The dialog does not block user interaction. The application continues
   * to run and users can interact with other windows while the dialog is open.
   */
  None,

  /**
   * @brief Application - Blocks the current application.
   *
   * Blocks interaction with all windows in the current application,
   * but allows interaction with other applications.
   */
  Application,

  /**
   * @brief Window - Blocks the parent window (requires parent window handle).
   *
   * Blocks interaction with a specific parent window.
   * Requires a parent window handle to be provided.
   */
  Window
};

/**
 * @class Dialog
 * @brief Base class for all dialog types.
 *
 * This abstract class provides the common interface for all dialog types
 * in the system. Specific dialog types (MessageDialog, FileDialog, etc.)
 * inherit from this class and implement their specific behavior.
 *
 * The Dialog class provides:
 * - Modal and non-modal display modes
 * - Modal state management
 *
 * @note This is an abstract base class. Use specific dialog types like
 * MessageDialog, FileDialog, etc., to create actual dialogs.
 *
 * @example
 * ```cpp
 * // Create a message dialog (see MessageDialog for details)
 * auto message_dialog = std::make_shared<MessageDialog>(
 *     "Title", "Message", MessageDialogType::Info);
 *
 * // Set modal mode and open
 * message_dialog->SetModality(DialogModality::Application);
 * message_dialog->Open();
 * ```
 */
class Dialog {
 public:
  /**
   * @brief Virtual destructor.
   *
   * Ensures proper cleanup of derived classes and platform-specific resources.
   */
  virtual ~Dialog();

  /**
   * @brief Get the current modality setting of the dialog.
   *
   * @return The current DialogModality setting
   */
  virtual DialogModality GetModality() const = 0;

  /**
   * @brief Set the modality of the dialog.
   *
   * The modality determines how the dialog blocks user interaction:
   * - None: Non-modal dialog, does not block user interaction
   * - Application: Blocks interaction with all windows in the current application
   * - Window: Blocks interaction with a specific parent window (requires parent handle)
   *
   * @param modality The modality type to set
   *
   * @note This setting affects the behavior when Open() is called.
   *       The modality should be set before opening the dialog.
   *
   * @example
   * ```cpp
   * dialog->SetModality(DialogModality::Application);  // Make it application modal
   * dialog->Open();                                    // Open as modal dialog
   * ```
   */
  virtual void SetModality(DialogModality modality) = 0;

  /**
   * @brief Open the dialog according to its modality setting.
   *
   * The dialog behavior depends on the current modality:
   * - None: Opens non-modally, does not block the calling thread
   * - Application/Window: Opens modally, blocks until the user dismisses the dialog
   *
   * @return true if the dialog was successfully opened, false otherwise
   *
   * @example
   * ```cpp
   * // Non-modal dialog
   * dialog->SetModality(DialogModality::None);
   * dialog->Open();
   * // Application continues running...
   *
   * // Modal dialog
   * dialog->SetModality(DialogModality::Application);
   * dialog->Open();
   * // Blocks until user dismisses dialog
   * ```
   */
  virtual bool Open();

  /**
   * @brief Close the dialog programmatically.
   *
   * Dismisses the dialog as if the user had closed it.
   *
   * @return true if the dialog was successfully closed, false otherwise
   */
  virtual bool Close();
};

}  // namespace nativeapi
