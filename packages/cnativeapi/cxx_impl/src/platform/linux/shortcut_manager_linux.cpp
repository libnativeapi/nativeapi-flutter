#include <algorithm>
#include <atomic>
#include <cctype>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#include <X11/Xlib.h>
#include <X11/keysym.h>

#include "../../shortcut_manager.h"

namespace nativeapi {
namespace {

std::string ToLower(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](unsigned char ch) { return static_cast<char>(std::tolower(ch)); });
  return value;
}

std::vector<std::string> SplitAccelerator(const std::string& accelerator) {
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

bool ParseAcceleratorTokens(const std::string& accelerator,
                            std::vector<std::string>& modifiers,
                            std::string& key_token) {
  modifiers.clear();
  key_token.clear();

  auto parts = SplitAccelerator(accelerator);
  if (parts.empty()) {
    return false;
  }

  for (auto& part : parts) {
    std::string token = ToLower(part);
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

// Token -> X11 KeySym.
//
// Mirrors the token set in src/shortcut_manager.cpp's validator and the tables
// in the macOS/Windows backends, so the same accelerator string means the same
// key on every platform.
KeySym KeySymFromToken(const std::string& token) {
  static const std::unordered_map<std::string, KeySym> kKeySyms = {
      // Whitespace and editing.
      {"space", XK_space},
      {"tab", XK_Tab},
      {"enter", XK_Return},
      {"return", XK_Return},
      {"escape", XK_Escape},
      {"esc", XK_Escape},
      {"backspace", XK_BackSpace},
      {"delete", XK_Delete},
      {"forwarddelete", XK_Delete},
      {"insert", XK_Insert},
      {"help", XK_Help},

      // Navigation.
      {"home", XK_Home},
      {"end", XK_End},
      {"pageup", XK_Page_Up},
      {"pagedown", XK_Page_Down},
      {"up", XK_Up},
      {"down", XK_Down},
      {"left", XK_Left},
      {"right", XK_Right},

      // Punctuation, by name and by literal character.
      {"plus", XK_plus},
      {"equal", XK_equal},                {"=", XK_equal},
      {"minus", XK_minus},                {"-", XK_minus},
      {"comma", XK_comma},                {",", XK_comma},
      {"period", XK_period},              {".", XK_period},
      {"slash", XK_slash},                {"/", XK_slash},
      {"backslash", XK_backslash},        {"\\", XK_backslash},
      {"semicolon", XK_semicolon},        {";", XK_semicolon},
      {"quote", XK_apostrophe},           {"'", XK_apostrophe},
      {"leftbracket", XK_bracketleft},    {"[", XK_bracketleft},
      {"rightbracket", XK_bracketright},  {"]", XK_bracketright},
      {"grave", XK_grave}, {"backquote", XK_grave}, {"`", XK_grave},

      // Keypad.
      {"num0", XK_KP_0}, {"num1", XK_KP_1}, {"num2", XK_KP_2},
      {"num3", XK_KP_3}, {"num4", XK_KP_4}, {"num5", XK_KP_5},
      {"num6", XK_KP_6}, {"num7", XK_KP_7}, {"num8", XK_KP_8},
      {"num9", XK_KP_9},
      {"numdec", XK_KP_Decimal},
      {"numadd", XK_KP_Add},
      {"numsub", XK_KP_Subtract},
      {"nummult", XK_KP_Multiply},
      {"numdiv", XK_KP_Divide},
      {"numenter", XK_KP_Enter},
  };

  // Letters and digits resolve through Xlib's own name table.
  if (token.size() == 1) {
    char ch = token[0];
    if (std::isalpha(static_cast<unsigned char>(ch))) {
      return XStringToKeysym(std::string(1, static_cast<char>(std::toupper(ch))).c_str());
    }
    if (std::isdigit(static_cast<unsigned char>(ch))) {
      return XStringToKeysym(std::string(1, ch).c_str());
    }
  }

  // Function keys. XK_F1..XK_F24 are contiguous.
  if (token.size() > 1 && token[0] == 'f' &&
      token.find_first_not_of("0123456789", 1) == std::string::npos) {
    int fnum = std::stoi(token.substr(1));
    if (fnum >= 1 && fnum <= 24) {
      return XK_F1 + (fnum - 1);
    }
    return NoSymbol;
  }

  auto it = kKeySyms.find(token);
  return it == kKeySyms.end() ? NoSymbol : it->second;
}

bool ParseAcceleratorLinux(const std::string& accelerator,
                           unsigned int& modifiers,
                           KeyCode& keycode,
                           ::Display* display) {
  modifiers = 0;
  keycode = 0;

  std::vector<std::string> modifier_tokens;
  std::string key_token;
  if (!ParseAcceleratorTokens(accelerator, modifier_tokens, key_token)) {
    return false;
  }

  for (const auto& token : modifier_tokens) {
    if (token == "ctrl" || token == "control" || token == "cmdorctrl" ||
        token == "commandorcontrol") {
      modifiers |= ControlMask;
    } else if (token == "alt" || token == "option") {
      modifiers |= Mod1Mask;
    } else if (token == "shift") {
      modifiers |= ShiftMask;
    } else if (token == "cmd" || token == "command" || token == "super" || token == "meta") {
      modifiers |= Mod4Mask;
    }
  }

  KeySym keysym = KeySymFromToken(key_token);
  if (keysym == NoSymbol) {
    return false;
  }

  keycode = XKeysymToKeycode(display, keysym);
  return keycode != 0;
}

}  // namespace

class ShortcutManagerImpl final : public ShortcutManager::Impl {
 public:
  explicit ShortcutManagerImpl(ShortcutManager* manager) : manager_(manager) {
    XInitThreads();
    display_ = XOpenDisplay(nullptr);
    if (display_) {
      root_ = DefaultRootWindow(display_);
      exit_atom_ = XInternAtom(display_, "NATIVEAPI_SHORTCUT_EXIT", False);
    }
  }

  ~ShortcutManagerImpl() override {
    StopThread();
    if (display_) {
      XCloseDisplay(display_);
      display_ = nullptr;
    }
  }

  bool IsSupported() override { return display_ != nullptr; }

  bool RegisterShortcut(const std::shared_ptr<Shortcut>& shortcut) override {
    if (!display_) {
      return false;
    }

    unsigned int modifiers = 0;
    KeyCode keycode = 0;
    if (!ParseAcceleratorLinux(shortcut->GetAccelerator(), modifiers, keycode, display_)) {
      return false;
    }

    GrabKeyWithModifiers(keycode, modifiers);

    {
      std::lock_guard<std::mutex> lock(mutex_);
      GrabInfo info{keycode, modifiers};
      grabs_[shortcut->GetId()] = info;
      combo_to_shortcut_[ComposeKey(modifiers, keycode)] = shortcut->GetId();
    }

    EnsureThread();
    return true;
  }

  bool UnregisterShortcut(const std::shared_ptr<Shortcut>& shortcut) override {
    if (!display_) {
      return false;
    }

    GrabInfo info;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      auto it = grabs_.find(shortcut->GetId());
      if (it == grabs_.end()) {
        return false;
      }
      info = it->second;
      grabs_.erase(it);
      combo_to_shortcut_.erase(ComposeKey(info.modifiers, info.keycode));
    }

    UngrabKeyWithModifiers(info.keycode, info.modifiers);
    return true;
  }

  void SetupEventMonitoring() override { EnsureThread(); }

  void CleanupEventMonitoring() override {
    // Keep thread running while shortcuts may still be registered.
  }

 private:
  struct GrabInfo {
    KeyCode keycode;
    unsigned int modifiers;
  };

  void GrabKeyWithModifiers(KeyCode keycode, unsigned int modifiers) {
    const unsigned int extra_masks[] = {0, LockMask, Mod2Mask, LockMask | Mod2Mask};
    for (unsigned int mask : extra_masks) {
      XGrabKey(display_, keycode, modifiers | mask, root_, True, GrabModeAsync, GrabModeAsync);
    }
    XSync(display_, False);
  }

  void UngrabKeyWithModifiers(KeyCode keycode, unsigned int modifiers) {
    const unsigned int extra_masks[] = {0, LockMask, Mod2Mask, LockMask | Mod2Mask};
    for (unsigned int mask : extra_masks) {
      XUngrabKey(display_, keycode, modifiers | mask, root_);
    }
    XSync(display_, False);
  }

  uint32_t ComposeKey(unsigned int modifiers, KeyCode keycode) const {
    return (static_cast<uint32_t>(modifiers & 0xFFFF) << 16) | (keycode & 0xFFFF);
  }

  void EnsureThread() {
    if (running_.load() || !display_) {
      return;
    }

    running_.store(true);
    event_thread_ = std::thread([this]() { ThreadMain(); });
  }

  void StopThread() {
    if (!running_.load()) {
      return;
    }

    running_.store(false);
    SendExitMessage();
    if (event_thread_.joinable()) {
      event_thread_.join();
    }
  }

  void SendExitMessage() {
    if (!display_) {
      return;
    }

    XClientMessageEvent client_message = {};
    client_message.type = ClientMessage;
    client_message.message_type = exit_atom_;
    client_message.window = root_;
    client_message.format = 32;
    XSendEvent(display_, root_, False, 0, reinterpret_cast<XEvent*>(&client_message));
    XFlush(display_);
  }

  void ThreadMain() {
    if (!display_) {
      return;
    }

    XSelectInput(display_, root_, KeyPressMask);

    while (running_.load()) {
      XEvent event;
      XNextEvent(display_, &event);

      if (!running_.load()) {
        break;
      }

      if (event.type == ClientMessage) {
        if (event.xclient.message_type == exit_atom_) {
          break;
        }
      }

      if (event.type != KeyPress) {
        continue;
      }

      unsigned int normalized_mods = event.xkey.state & ~(LockMask | Mod2Mask);
      uint32_t combo = ComposeKey(normalized_mods, event.xkey.keycode);

      ShortcutId shortcut_id = 0;
      {
        std::lock_guard<std::mutex> lock(mutex_);
        auto it = combo_to_shortcut_.find(combo);
        if (it == combo_to_shortcut_.end()) {
          continue;
        }
        shortcut_id = it->second;
      }

      auto shortcut = manager_->Get(shortcut_id);
      if (!shortcut) {
        continue;
      }

      if (!manager_->IsEnabled() || !shortcut->IsEnabled()) {
        continue;
      }

      manager_->EmitShortcutActivated(shortcut_id, shortcut->GetAccelerator());
      shortcut->Invoke();
    }
  }

  ShortcutManager* manager_;
  // ::-qualified: nativeapi::Display/Window (via id_allocator.h) shadow the
  // X11 typedefs inside this namespace.
  ::Display* display_ = nullptr;
  ::Window root_ = 0;
  Atom exit_atom_ = None;

  std::mutex mutex_;
  std::unordered_map<ShortcutId, GrabInfo> grabs_;
  std::unordered_map<uint32_t, ShortcutId> combo_to_shortcut_;

  std::atomic<bool> running_{false};
  std::thread event_thread_;
};

ShortcutManager::ShortcutManager()
    : pimpl_(std::make_unique<ShortcutManagerImpl>(this)), next_shortcut_id_(1), enabled_(true) {}

ShortcutManager::~ShortcutManager() {
  UnregisterAll();
}

}  // namespace nativeapi
