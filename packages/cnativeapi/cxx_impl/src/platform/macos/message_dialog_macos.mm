#import <Cocoa/Cocoa.h>
#include "../../dialog.h"
#include "../../message_dialog.h"

namespace nativeapi {

// Private implementation class for MessageDialog
class MessageDialog::Impl {
 public:
  Impl(const std::string& title, const std::string& message)
      : title_(title), message_(message), ns_alert_(nil), is_open_(false) {
    // Create NSAlert instance
    ns_alert_ = [[NSAlert alloc] init];

    // Set default values
    [ns_alert_ setMessageText:[NSString stringWithUTF8String:title.c_str()]];
    [ns_alert_ setInformativeText:[NSString stringWithUTF8String:message.c_str()]];

    // Set default alert style to informational
    [ns_alert_ setAlertStyle:NSAlertStyleInformational];
  }

  ~Impl() {
    if (ns_alert_) {
      ns_alert_ = nil;
    }
  }

  void SetTitle(const std::string& title) {
    title_ = title;
    if (ns_alert_) {
      [ns_alert_ setMessageText:[NSString stringWithUTF8String:title.c_str()]];
    }
  }

  std::string GetTitle() const { return title_; }

  void SetMessage(const std::string& message) {
    message_ = message;
    if (ns_alert_) {
      [ns_alert_ setInformativeText:[NSString stringWithUTF8String:message.c_str()]];
    }
  }

  std::string GetMessage() const { return message_; }

  bool Open(DialogModality modality) {
    if (!ns_alert_) {
      return false;
    }

    // Ensure we're on the main thread for UI operations
    if (![NSThread isMainThread]) {
      __block bool result = false;
      dispatch_sync(dispatch_get_main_queue(), ^{
        result = OpenOnMainThread(modality);
      });
      return result;
    }

    return OpenOnMainThread(modality);
  }

  bool OpenOnMainThread(DialogModality modality) {
    if (!ns_alert_) {
      return false;
    }

    // Configure alert style based on modality
    // Note: macOS doesn't have true system modal dialogs in modern versions
    // Application is the standard modal behavior
    // Window behaves as Application on macOS
    switch (modality) {
      case DialogModality::None:
        // Non-modal: show as sheet or window that doesn't block
        // For NSAlert, we can use beginSheetModalForWindow:completionHandler:
        // However, NSAlert doesn't have a direct non-modal display method
        // We'll use runModal with a workaround, or implement as sheet
        // For now, treat None as non-blocking modal (temporary solution)
        is_open_ = true;
        @autoreleasepool {
          // Note: NSAlert doesn't have a true non-modal mode
          // This is a limitation of NSAlert API
          // Consider using NSPanel or custom window for true non-modal dialogs
          [ns_alert_ runModal];
        }
        is_open_ = false;
        break;
      case DialogModality::Application:
      case DialogModality::Window:
        // Both use application modal behavior on macOS
        // Run the alert modally - this blocks until the user dismisses the dialog
        is_open_ = true;
        @autoreleasepool {
          [ns_alert_ runModal];
        }
        // After runModal returns, the dialog has been dismissed
        is_open_ = false;
        break;
    }

    return true;
  }

  bool Close() {
    if (!ns_alert_ || !is_open_) {
      return false;
    }

    // NSAlert doesn't have a direct close method
    // We need to stop the modal session if it's running
    // For sheet-based dialogs, we can dismiss the sheet
    // Note: This is a limitation of NSAlert API
    // In practice, the user must dismiss the dialog manually

    is_open_ = false;
    return true;
  }

  bool IsOpen() const { return is_open_; }

 private:
  std::string title_;
  std::string message_;
  NSAlert* ns_alert_;
  bool is_open_;
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
