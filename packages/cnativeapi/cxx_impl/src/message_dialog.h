#pragma once

#include <memory>
#include <string>
#include "dialog.h"

namespace nativeapi {

/**
 * @class MessageDialog
 * @brief Dialog for displaying messages and simple prompts.
 *
 * MessageDialog is used to display information, warnings, errors, or
 * questions to the user. It can be shown modally or non-modally.
 *
 * This class inherits from Dialog and provides message-specific
 * functionality such as message text.
 *
 * @note This class uses the PIMPL idiom to hide platform-specific
 * implementation details.
 *
 * @example
 * ```cpp
 * // Simple message dialog
 * auto dialog = std::make_shared<MessageDialog>(
 *     "Update Available",
 *     "A new version is available. Would you like to update?");
 * dialog->SetModality(DialogModality::Application);
 * dialog->Open();
 * ```
 */
class MessageDialog : public Dialog {
 public:
  /**
   * @brief Create a message dialog with title and message.
   *
   * @param title Dialog title
   * @param message Dialog message
   *
   * @example
   * ```cpp
   * auto dialog = std::make_shared<MessageDialog>(
   *     "Update Available",
   *     "A new version is available. Would you like to update?");
   * dialog->SetModality(DialogModality::Application);
   * dialog->Open();
   * ```
   */
  MessageDialog(const std::string& title, const std::string& message);

  /**
   * @brief Destructor.
   */
  virtual ~MessageDialog();

  /**
   * @brief Set the dialog title.
   *
   * @param title The dialog title
   */
  void SetTitle(const std::string& title);

  /**
   * @brief Get the dialog title.
   *
   * @return The current title
   */
  std::string GetTitle() const;

  /**
   * @brief Set the dialog message.
   *
   * @param message The dialog message
   */
  void SetMessage(const std::string& message);

  /**
   * @brief Get the dialog message.
   *
   * @return The current message
   */
  std::string GetMessage() const;

  /**
   * @brief Get the current modality setting of the dialog.
   *
   * @return The current DialogModality setting
   */
  DialogModality GetModality() const override;

  /**
   * @brief Set the modality of the dialog.
   *
   * @param modality The modality type to set
   */
  void SetModality(DialogModality modality) override;

  /**
   * @brief Open the dialog.
   *
   * Displays the dialog according to the current modality setting.
   *
   * @return true if the dialog was successfully opened, false otherwise
   */
  bool Open() override;

  /**
   * @brief Close the dialog programmatically.
   *
   * Dismisses the dialog as if the user had closed it.
   *
   * @return true if the dialog was successfully closed, false otherwise
   */
  bool Close() override;

 private:
  /**
   * @brief Private implementation class.
   */
  class Impl;

  /**
   * @brief Pointer to platform-specific implementation.
   *
   * @note This is separate from Dialog::pimpl_ to allow for
   * message-dialog-specific implementation details.
   */
  std::unique_ptr<Impl> pimpl_;

  /**
   * @brief Current modality setting.
   */
  DialogModality modality_ = DialogModality::None;
};

}  // namespace nativeapi
