#include <windows.h>
#include <iostream>
#include <string>

#include "../../foundation/keyboard.h"
#include "../../keyboard_monitor.h"

namespace nativeapi {

class KeyboardMonitor::Impl {
 public:
  Impl(KeyboardMonitor* monitor) : monitor_(monitor), hook_(nullptr) {}

  HHOOK hook_;
  KeyboardMonitor* monitor_;
};

KeyboardMonitor::KeyboardMonitor() : impl_(std::make_unique<Impl>(this)) {}

KeyboardMonitor::~KeyboardMonitor() {
  Stop();
}

// Global pointer to current keyboard monitor instance
static KeyboardMonitor* g_current_monitor = nullptr;

// Low-level keyboard hook procedure
static LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode >= 0) {
    KBDLLHOOKSTRUCT* pKeyboard = reinterpret_cast<KBDLLHOOKSTRUCT*>(lParam);

    // Get the KeyboardMonitor instance from global variable
    if (!g_current_monitor) {
      return CallNextHookEx(nullptr, nCode, wParam, lParam);
    }

    auto& emitter = g_current_monitor->GetInternalEventEmitter();

    if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
      KeyPressedEvent key_event(pKeyboard->vkCode);
      emitter.Emit(key_event);
    } else if (wParam == WM_KEYUP || wParam == WM_SYSKEYUP) {
      KeyReleasedEvent key_event(pKeyboard->vkCode);
      emitter.Emit(key_event);
    }

    // Check for modifier key changes
    uint32_t modifier_keys = static_cast<uint32_t>(ModifierKey::None);

    if (GetAsyncKeyState(VK_SHIFT) & 0x8000) {
      modifier_keys |= static_cast<uint32_t>(ModifierKey::Shift);
    }
    if (GetAsyncKeyState(VK_CONTROL) & 0x8000) {
      modifier_keys |= static_cast<uint32_t>(ModifierKey::Ctrl);
    }
    if (GetAsyncKeyState(VK_MENU) & 0x8000) {
      modifier_keys |= static_cast<uint32_t>(ModifierKey::Alt);
    }
    if (GetAsyncKeyState(VK_LWIN) & 0x8000 || GetAsyncKeyState(VK_RWIN) & 0x8000) {
      modifier_keys |= static_cast<uint32_t>(ModifierKey::Meta);
    }
    if (GetAsyncKeyState(VK_CAPITAL) & 0x0001) {
      modifier_keys |= static_cast<uint32_t>(ModifierKey::CapsLock);
    }
    if (GetAsyncKeyState(VK_NUMLOCK) & 0x0001) {
      modifier_keys |= static_cast<uint32_t>(ModifierKey::NumLock);
    }
    if (GetAsyncKeyState(VK_SCROLL) & 0x0001) {
      modifier_keys |= static_cast<uint32_t>(ModifierKey::ScrollLock);
    }

    static uint32_t last_modifier_keys = 0;
    if (modifier_keys != last_modifier_keys) {
      ModifierKeysChangedEvent modifier_event(modifier_keys);
      emitter.Emit(modifier_event);
      last_modifier_keys = modifier_keys;
    }
  }

  return CallNextHookEx(nullptr, nCode, wParam, lParam);
}

void KeyboardMonitor::Start() {
  if (impl_->hook_ != nullptr) {
    return;  // Already started
  }

  // Set up the global reference for the hook procedure
  g_current_monitor = this;

  // Install low-level keyboard hook
  impl_->hook_ =
      SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc, GetModuleHandle(nullptr), 0);

  if (impl_->hook_ == nullptr) {
    std::cerr << "Failed to install keyboard hook. Error: " << GetLastError() << std::endl;
    return;
  }
}

void KeyboardMonitor::Stop() {
  if (impl_->hook_ == nullptr) {
    return;  // Already stopped
  }

  // Clear the global reference
  g_current_monitor = nullptr;

  // Uninstall the hook
  if (UnhookWindowsHookEx(impl_->hook_)) {
    impl_->hook_ = nullptr;
  } else {
    std::cerr << "Failed to uninstall keyboard hook. Error: " << GetLastError() << std::endl;
  }
}

bool KeyboardMonitor::IsMonitoring() const {
  return impl_->hook_ != nullptr;
}

EventEmitter<KeyboardEvent>& KeyboardMonitor::GetInternalEventEmitter() {
  return *this;
}

}  // namespace nativeapi
