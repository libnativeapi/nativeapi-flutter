#include <algorithm>
#include <cctype>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#import <Carbon/Carbon.h>

#include "../../shortcut_manager.h"

namespace nativeapi {
namespace {

// Four-char signature tagging every hotkey this library owns, so the shared
// Carbon handler can ignore hotkeys registered by the host application.
constexpr FourCharCode kHotKeySignature = 'ntap';

std::string ShortcutToLower(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](unsigned char ch) { return static_cast<char>(std::tolower(ch)); });
  return value;
}

std::vector<std::string> SplitShortcutAccelerator(const std::string& accelerator) {
  std::vector<std::string> parts;
  std::string current;
  for (char ch : accelerator) {
    if (ch == '+') {
      if (!current.empty()) {
        parts.push_back(current);
        current.clear();
      }
    } else if (!std::isspace(static_cast<unsigned char>(ch))) {
      current.push_back(ch);
    }
  }
  if (!current.empty()) {
    parts.push_back(current);
  }
  return parts;
}

bool ParseShortcutAcceleratorTokens(const std::string& accelerator,
                                    std::vector<std::string>& modifiers,
                                    std::string& key_token) {
  modifiers.clear();
  key_token.clear();

  auto parts = SplitShortcutAccelerator(accelerator);
  if (parts.empty()) {
    return false;
  }

  for (auto& part : parts) {
    std::string token = ShortcutToLower(part);
    if (token == "ctrl" || token == "control" || token == "alt" || token == "option" ||
        token == "shift" || token == "cmd" || token == "command" || token == "super" ||
        token == "meta" || token == "cmdorctrl" || token == "commandorcontrol") {
      modifiers.push_back(token);
    } else {
      if (!key_token.empty()) {
        return false;
      }
      key_token = token;
    }
  }

  return !key_token.empty();
}

// Token -> Carbon virtual key code.
//
// Carbon's kVK_* constants are positional (they describe where the key sits on
// an ANSI board, not what it prints), and they are non-contiguous — so this has
// to be an explicit table rather than arithmetic on a base value. The coverage
// mirrors soffes/HotKey's Key enum: letters, digits, F1-F20, navigation,
// punctuation and the keypad.
bool LookupShortcutKeyCode(const std::string& token, UInt32& keycode) {
  static const std::unordered_map<std::string, UInt32> kKeyCodes = {
      // Letters.
      {"a", kVK_ANSI_A}, {"b", kVK_ANSI_B}, {"c", kVK_ANSI_C}, {"d", kVK_ANSI_D},
      {"e", kVK_ANSI_E}, {"f", kVK_ANSI_F}, {"g", kVK_ANSI_G}, {"h", kVK_ANSI_H},
      {"i", kVK_ANSI_I}, {"j", kVK_ANSI_J}, {"k", kVK_ANSI_K}, {"l", kVK_ANSI_L},
      {"m", kVK_ANSI_M}, {"n", kVK_ANSI_N}, {"o", kVK_ANSI_O}, {"p", kVK_ANSI_P},
      {"q", kVK_ANSI_Q}, {"r", kVK_ANSI_R}, {"s", kVK_ANSI_S}, {"t", kVK_ANSI_T},
      {"u", kVK_ANSI_U}, {"v", kVK_ANSI_V}, {"w", kVK_ANSI_W}, {"x", kVK_ANSI_X},
      {"y", kVK_ANSI_Y}, {"z", kVK_ANSI_Z},

      // Digits.
      {"0", kVK_ANSI_0}, {"1", kVK_ANSI_1}, {"2", kVK_ANSI_2}, {"3", kVK_ANSI_3},
      {"4", kVK_ANSI_4}, {"5", kVK_ANSI_5}, {"6", kVK_ANSI_6}, {"7", kVK_ANSI_7},
      {"8", kVK_ANSI_8}, {"9", kVK_ANSI_9},

      // Function keys.
      {"f1", kVK_F1},   {"f2", kVK_F2},   {"f3", kVK_F3},   {"f4", kVK_F4},
      {"f5", kVK_F5},   {"f6", kVK_F6},   {"f7", kVK_F7},   {"f8", kVK_F8},
      {"f9", kVK_F9},   {"f10", kVK_F10}, {"f11", kVK_F11}, {"f12", kVK_F12},
      {"f13", kVK_F13}, {"f14", kVK_F14}, {"f15", kVK_F15}, {"f16", kVK_F16},
      {"f17", kVK_F17}, {"f18", kVK_F18}, {"f19", kVK_F19}, {"f20", kVK_F20},

      // Whitespace and editing.
      {"space", kVK_Space},
      {"tab", kVK_Tab},
      {"enter", kVK_Return},
      {"return", kVK_Return},
      {"escape", kVK_Escape},
      {"esc", kVK_Escape},
      {"backspace", kVK_Delete},
      {"delete", kVK_ForwardDelete},
      {"forwarddelete", kVK_ForwardDelete},
      {"insert", kVK_Help},
      {"help", kVK_Help},

      // Navigation.
      {"home", kVK_Home},
      {"end", kVK_End},
      {"pageup", kVK_PageUp},
      {"pagedown", kVK_PageDown},
      {"up", kVK_UpArrow},
      {"down", kVK_DownArrow},
      {"left", kVK_LeftArrow},
      {"right", kVK_RightArrow},

      // Punctuation, by name and by literal character.
      {"plus", kVK_ANSI_Equal},
      {"equal", kVK_ANSI_Equal},        {"=", kVK_ANSI_Equal},
      {"minus", kVK_ANSI_Minus},        {"-", kVK_ANSI_Minus},
      {"comma", kVK_ANSI_Comma},        {",", kVK_ANSI_Comma},
      {"period", kVK_ANSI_Period},      {".", kVK_ANSI_Period},
      {"slash", kVK_ANSI_Slash},        {"/", kVK_ANSI_Slash},
      {"backslash", kVK_ANSI_Backslash},{"\\", kVK_ANSI_Backslash},
      {"semicolon", kVK_ANSI_Semicolon},{";", kVK_ANSI_Semicolon},
      {"quote", kVK_ANSI_Quote},        {"'", kVK_ANSI_Quote},
      {"leftbracket", kVK_ANSI_LeftBracket},   {"[", kVK_ANSI_LeftBracket},
      {"rightbracket", kVK_ANSI_RightBracket}, {"]", kVK_ANSI_RightBracket},
      {"grave", kVK_ANSI_Grave},        {"backquote", kVK_ANSI_Grave}, {"`", kVK_ANSI_Grave},

      // Keypad.
      {"num0", kVK_ANSI_Keypad0}, {"num1", kVK_ANSI_Keypad1}, {"num2", kVK_ANSI_Keypad2},
      {"num3", kVK_ANSI_Keypad3}, {"num4", kVK_ANSI_Keypad4}, {"num5", kVK_ANSI_Keypad5},
      {"num6", kVK_ANSI_Keypad6}, {"num7", kVK_ANSI_Keypad7}, {"num8", kVK_ANSI_Keypad8},
      {"num9", kVK_ANSI_Keypad9},
      {"numdec", kVK_ANSI_KeypadDecimal},
      {"numadd", kVK_ANSI_KeypadPlus},
      {"numsub", kVK_ANSI_KeypadMinus},
      {"nummult", kVK_ANSI_KeypadMultiply},
      {"numdiv", kVK_ANSI_KeypadDivide},
      {"numenter", kVK_ANSI_KeypadEnter},
  };

  auto it = kKeyCodes.find(token);
  if (it == kKeyCodes.end()) {
    return false;
  }
  keycode = it->second;
  return true;
}

bool ParseMacShortcutAccelerator(const std::string& accelerator,
                                 UInt32& modifiers,
                                 UInt32& keycode) {
  modifiers = 0;
  keycode = 0;

  std::vector<std::string> modifier_tokens;
  std::string key_token;
  if (!ParseShortcutAcceleratorTokens(accelerator, modifier_tokens, key_token)) {
    return false;
  }

  for (const auto& token : modifier_tokens) {
    if (token == "ctrl" || token == "control") {
      modifiers |= controlKey;
    } else if (token == "alt" || token == "option") {
      modifiers |= optionKey;
    } else if (token == "shift") {
      modifiers |= shiftKey;
    } else {
      // cmd / command / meta / super / cmdorctrl all mean Command on macOS.
      modifiers |= cmdKey;
    }
  }

  return LookupShortcutKeyCode(key_token, keycode);
}

}  // namespace

/**
 * @brief macOS global shortcuts, built on Carbon's RegisterEventHotKey.
 *
 * Modelled on soffes/HotKey: one process-wide Carbon event handler, one
 * RegisterEventHotKey call per shortcut, and an EventHotKeyID whose signature
 * identifies hotkeys this library owns.
 *
 * @note Carbon delivers hotkeys into the *main thread's* event queue, so
 *       something must pump that queue. A Cocoa app gets this from
 *       `[NSApp run]`; a program without one calls RunMainThreadLoopFor()
 *       (see PlatformRunMainThreadLoopFor in dispatcher_macos.mm, which
 *       services the Carbon queue as well as the GCD main queue). Nothing
 *       is delivered while no one pumps — an earlier revision of this file
 *       tried to pump from a private background thread, which cannot work:
 *       ReceiveNextEvent() drains the *calling* thread's queue, and hotkey
 *       events are never posted to a worker thread's queue.
 */
class ShortcutManagerImpl final : public ShortcutManager::Impl {
 public:
  explicit ShortcutManagerImpl(ShortcutManager* manager) : manager_(manager) {}

  ~ShortcutManagerImpl() override {
    std::lock_guard<std::mutex> lock(mutex_);
    for (const auto& [id, hotkey] : hotkeys_) {
      UnregisterEventHotKey(hotkey);
    }
    hotkeys_.clear();

    if (handler_) {
      RemoveEventHandler(handler_);
      handler_ = nullptr;
    }
  }

  bool IsSupported() override { return true; }

  bool RegisterShortcut(const std::shared_ptr<Shortcut>& shortcut) override {
    UInt32 modifiers = 0;
    UInt32 keycode = 0;
    if (!ParseMacShortcutAccelerator(shortcut->GetAccelerator(), modifiers, keycode)) {
      return false;
    }

    EnsureHandler();

    EventHotKeyID hotkey_id;
    hotkey_id.signature = kHotKeySignature;
    hotkey_id.id = static_cast<UInt32>(shortcut->GetId());

    EventHotKeyRef hotkey_ref = nullptr;
    // GetApplicationEventTarget() rather than soffes/HotKey's
    // GetEventDispatcherTarget(): the dispatcher target is per-thread, and this
    // library documents Register() as callable from any thread. The application
    // target is process-wide, and the main thread's dispatcher propagates to it,
    // so delivery works under both a Cocoa run loop and RunMainThreadLoopFor().
    OSStatus status = RegisterEventHotKey(keycode, modifiers, hotkey_id,
                                          GetApplicationEventTarget(), 0, &hotkey_ref);
    if (status != noErr || !hotkey_ref) {
      return false;
    }

    std::lock_guard<std::mutex> lock(mutex_);
    hotkeys_[shortcut->GetId()] = hotkey_ref;
    return true;
  }

  bool UnregisterShortcut(const std::shared_ptr<Shortcut>& shortcut) override {
    EventHotKeyRef hotkey_ref = nullptr;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      auto it = hotkeys_.find(shortcut->GetId());
      if (it == hotkeys_.end()) {
        return false;
      }
      hotkey_ref = it->second;
      hotkeys_.erase(it);
    }

    UnregisterEventHotKey(hotkey_ref);
    return true;
  }

  void SetupEventMonitoring() override { EnsureHandler(); }

  void CleanupEventMonitoring() override {
    // The handler is shared with the shortcuts themselves, which outlive any
    // individual event listener; it is torn down in the destructor instead.
  }

 private:
  static OSStatus HotKeyHandler(EventHandlerCallRef next_handler, EventRef event, void* user_data) {
    auto* self = static_cast<ShortcutManagerImpl*>(user_data);
    if (!self) {
      return eventNotHandledErr;
    }

    EventHotKeyID hotkey_id;
    OSStatus status = GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, nullptr,
                                        sizeof(EventHotKeyID), nullptr, &hotkey_id);
    if (status != noErr) {
      return eventNotHandledErr;
    }

    // Leave hotkeys owned by the host application to the host's own handlers.
    if (hotkey_id.signature != kHotKeySignature) {
      return eventNotHandledErr;
    }

    self->HandleHotKey(static_cast<ShortcutId>(hotkey_id.id));
    return noErr;
  }

  void EnsureHandler() {
    std::lock_guard<std::mutex> lock(handler_mutex_);
    if (handler_) {
      return;
    }

    EventTypeSpec event_type;
    event_type.eventClass = kEventClassKeyboard;
    event_type.eventKind = kEventHotKeyPressed;

    InstallEventHandler(GetApplicationEventTarget(), HotKeyHandler, 1, &event_type, this,
                        &handler_);
  }

  void HandleHotKey(ShortcutId shortcut_id) {
    auto shortcut = manager_->Get(shortcut_id);
    if (!shortcut) {
      return;
    }

    if (!manager_->IsEnabled() || !shortcut->IsEnabled()) {
      return;
    }

    manager_->EmitShortcutActivated(shortcut_id, shortcut->GetAccelerator());
    shortcut->Invoke();
  }

  ShortcutManager* manager_;

  std::mutex mutex_;
  std::unordered_map<ShortcutId, EventHotKeyRef> hotkeys_;

  std::mutex handler_mutex_;
  EventHandlerRef handler_ = nullptr;
};

ShortcutManager::ShortcutManager()
    : pimpl_(std::make_unique<ShortcutManagerImpl>(this)), next_shortcut_id_(1), enabled_(true) {}

ShortcutManager::~ShortcutManager() {
  UnregisterAll();
}

}  // namespace nativeapi
