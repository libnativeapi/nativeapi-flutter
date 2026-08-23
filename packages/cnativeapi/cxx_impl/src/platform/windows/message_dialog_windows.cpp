// clang-format off
#include <windows.h>
#include <windowsx.h>
// clang-format on

// Undefine Windows API macros that conflict with our method names
#ifdef GetMessage
#undef GetMessage
#endif

#include <memory>
#include <string>

#include "../../dialog.h"
#include "../../message_dialog.h"
#include "string_utils_windows.h"

namespace nativeapi {

// Private implementation class for MessageDialog using Win32 MessageBox
class MessageDialog::Impl {
 public:
  Impl(const std::string& title, const std::string& message) : title_(title), message_(message) {}

  ~Impl() = default;

  void SetTitle(const std::string& title) { title_ = title; }

  std::string GetTitle() const { return title_; }

  void SetMessage(const std::string& message) { message_ = message; }

  std::string GetMessage() const { return message_; }

  bool Open(DialogModality modality) {
    std::wstring wtitle = StringToWString(title_);
    std::wstring wmessage = StringToWString(message_);

    UINT uType = MB_OK | MB_ICONINFORMATION;

    // Set modality
    if (modality == DialogModality::Application) {
      uType |= MB_APPLMODAL;
    } else if (modality == DialogModality::Window) {
      uType |= MB_SYSTEMMODAL;  // Use system modal as approximation
    }

    int result = MessageBoxW(nullptr, wmessage.c_str(), wtitle.c_str(), uType);
    return result != 0;
  }

  bool Close() {
    // MessageBox doesn't support programmatic closing
    return false;
  }

 private:
  std::string title_;
  std::string message_;
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
