#include "../../dialog.h"
#include "../../message_dialog.h"

#include <gtk/gtk.h>

namespace nativeapi {

// Private implementation class for MessageDialog
class MessageDialog::Impl {
 public:
  Impl(const std::string& title, const std::string& message)
      : title_(title), message_(message), dialog_(nullptr), is_open_(false) {
    // Ensure GTK is initialized
    if (!gdk_display_get_default()) {
      gtk_init_check(nullptr, nullptr);
    }
  }

  ~Impl() {
    if (dialog_) {
      gtk_widget_destroy(dialog_);
      dialog_ = nullptr;
    }
  }

  void SetTitle(const std::string& title) {
    title_ = title;
    // Title will be applied when dialog is opened
  }

  std::string GetTitle() const { return title_; }

  void SetMessage(const std::string& message) {
    message_ = message;
    // Message will be applied when dialog is opened
  }

  std::string GetMessage() const { return message_; }

  bool Open(DialogModality modality) {
    // Ensure GTK is initialized
    if (!gdk_display_get_default()) {
      if (!gtk_init_check(nullptr, nullptr)) {
        return false;
      }
    }

    // For modal dialogs, always create a new dialog since gtk_dialog_run destroys it
    // For non-modal dialogs, close existing dialog if open before creating new one
    // This ensures title and message are always up to date
    if (dialog_ && GTK_IS_WIDGET(dialog_)) {
      // Destroy old dialog if exists
      gtk_widget_destroy(dialog_);
      dialog_ = nullptr;
      is_open_ = false;
    }

    // Create a new message dialog
    dialog_ = gtk_message_dialog_new(
        nullptr,           // No parent window
        GTK_DIALOG_MODAL,  // Default to modal (will be overridden for non-modal)
        GTK_MESSAGE_INFO,  // Message type
        GTK_BUTTONS_OK,    // Buttons
        "%s",              // Format string
        message_.c_str());

    if (!dialog_) {
      return false;
    }

    // Set title
    gtk_window_set_title(GTK_WINDOW(dialog_), title_.c_str());

    // Connect destroy signal to track when dialog is closed by user
    g_signal_connect(dialog_, "response", G_CALLBACK(OnResponse), this);
    g_signal_connect(dialog_, "destroy", G_CALLBACK(OnDestroy), this);

    // Handle modality
    switch (modality) {
      case DialogModality::None:
        // Non-modal: show the dialog without blocking
        gtk_window_set_modal(GTK_WINDOW(dialog_), FALSE);
        gtk_widget_show(dialog_);
        is_open_ = true;
        break;

      case DialogModality::Application:
      case DialogModality::Window:
        // Modal: block until user responds
        gtk_window_set_modal(GTK_WINDOW(dialog_), TRUE);
        is_open_ = true;

        // Run the dialog modally - this blocks until user responds
        // Note: gtk_dialog_run automatically destroys the dialog when done
        gtk_dialog_run(GTK_DIALOG(dialog_));

        // After gtk_dialog_run returns, the dialog has been dismissed and destroyed
        // The OnDestroy callback will set dialog_ to nullptr
        is_open_ = false;
        break;
    }

    return true;
  }

  bool Close() {
    if (!dialog_ || !is_open_) {
      return false;
    }

    // Close the dialog programmatically
    gtk_dialog_response(GTK_DIALOG(dialog_), GTK_RESPONSE_CLOSE);

    // If it's a modal dialog, we need to destroy it manually
    // (gtk_dialog_run already destroyed it)
    if (dialog_) {
      gtk_widget_destroy(dialog_);
      dialog_ = nullptr;
    }

    is_open_ = false;
    return true;
  }

 private:
  std::string title_;
  std::string message_;
  GtkWidget* dialog_;
  bool is_open_;

  static void OnResponse(GtkDialog* dialog, gint response_id, gpointer user_data) {
    Impl* impl = static_cast<Impl*>(user_data);

    // Mark as closed
    impl->is_open_ = false;

    // For non-modal dialogs, destroy the dialog when user responds
    if (!gtk_window_get_modal(GTK_WINDOW(dialog))) {
      gtk_widget_destroy(GTK_WIDGET(dialog));
      impl->dialog_ = nullptr;
    }
  }

  static void OnDestroy(GtkWidget* widget, gpointer user_data) {
    Impl* impl = static_cast<Impl*>(user_data);

    // Clear the dialog pointer when it's destroyed
    if (impl->dialog_ == widget) {
      impl->dialog_ = nullptr;
      impl->is_open_ = false;
    }
  }
};

// MessageDialog implementation
MessageDialog::MessageDialog(const std::string& title, const std::string& message)
    : pimpl_(std::make_unique<Impl>(title, message)) {
  // Set default modality to None (non-modal)
  SetModality(DialogModality::None);
}

MessageDialog::~MessageDialog() = default;

void MessageDialog::SetTitle(const std::string& title) {
  pimpl_->SetTitle(title);
}

std::string MessageDialog::GetTitle() const {
  return pimpl_->GetTitle();
}

void MessageDialog::SetMessage(const std::string& message) {
  pimpl_->SetMessage(message);
}

std::string MessageDialog::GetMessage() const {
  return pimpl_->GetMessage();
}

DialogModality MessageDialog::GetModality() const {
  return modality_;
}

void MessageDialog::SetModality(DialogModality modality) {
  modality_ = modality;
}

bool MessageDialog::Open() {
  DialogModality modality = GetModality();
  return pimpl_->Open(modality);
}

bool MessageDialog::Close() {
  return pimpl_->Close();
}

}  // namespace nativeapi
