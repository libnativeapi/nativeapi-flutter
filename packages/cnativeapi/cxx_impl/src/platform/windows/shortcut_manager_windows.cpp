#include <algorithm>
#include <atomic>
#include <cctype>
#include <condition_variable>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#include <windows.h>

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


// Token -> Windows virtual-key code.
//
// Mirrors the token set in src/shortcut_manager.cpp's validator and the tables
// in the macOS/Linux backends, so the same accelerator string means the same
// key on every platform.
bool LookupWindowsKeyCode(const std::string& token, UINT& vk) {
  static const std::unordered_map<std::string, UINT> kKeyCodes = {
      // Whitespace and editing.
      {"space", VK_SPACE},
      {"tab", VK_TAB},
      {"enter", VK_RETURN},
      {"return", VK_RETURN},
      {"escape", VK_ESCAPE},
      {"esc", VK_ESCAPE},
      {"backspace", VK_BACK},
      {"delete", VK_DELETE},
      {"forwarddelete", VK_DELETE},
      {"insert", VK_INSERT},
      {"help", VK_HELP},

      // Navigation.
      {"home", VK_HOME},
      {"end", VK_END},
      {"pageup", VK_PRIOR},
      {"pagedown", VK_NEXT},
      {"up", VK_UP},
      {"down", VK_DOWN},
      {"left", VK_LEFT},
      {"right", VK_RIGHT},

      // Punctuation, by name and by literal character.
      {"plus", VK_OEM_PLUS},
      {"equal", VK_OEM_PLUS},            {"=", VK_OEM_PLUS},
      {"minus", VK_OEM_MINUS},           {"-", VK_OEM_MINUS},
      {"comma", VK_OEM_COMMA},           {",", VK_OEM_COMMA},
      {"period", VK_OEM_PERIOD},         {".", VK_OEM_PERIOD},
      {"slash", VK_OEM_2},               {"/", VK_OEM_2},
      {"backslash", VK_OEM_5},           {"\\", VK_OEM_5},
      {"semicolon", VK_OEM_1},           {";", VK_OEM_1},
      {"quote", VK_OEM_7},               {"'", VK_OEM_7},
      {"leftbracket", VK_OEM_4},         {"[", VK_OEM_4},
      {"rightbracket", VK_OEM_6},        {"]", VK_OEM_6},
      {"grave", VK_OEM_3}, {"backquote", VK_OEM_3}, {"`", VK_OEM_3},

      // Keypad.
      {"num0", VK_NUMPAD0}, {"num1", VK_NUMPAD1}, {"num2", VK_NUMPAD2},
      {"num3", VK_NUMPAD3}, {"num4", VK_NUMPAD4}, {"num5", VK_NUMPAD5},
      {"num6", VK_NUMPAD6}, {"num7", VK_NUMPAD7}, {"num8", VK_NUMPAD8},
      {"num9", VK_NUMPAD9},
      {"numdec", VK_DECIMAL},
      {"numadd", VK_ADD},
      {"numsub", VK_SUBTRACT},
      {"nummult", VK_MULTIPLY},
      {"numdiv", VK_DIVIDE},
      // Windows has no separate numpad-Enter virtual key; it reports VK_RETURN.
      {"numenter", VK_RETURN},
  };

  // Letters and digits map to their ASCII value as a virtual-key code.
  if (token.size() == 1) {
    unsigned char ch = static_cast<unsigned char>(token[0]);
    if (std::isalpha(ch)) {
      vk = static_cast<UINT>(std::toupper(ch));
      return true;
    }
    if (std::isdigit(ch)) {
      vk = static_cast<UINT>(ch);
      return true;
    }
  }

  // Function keys. VK_F1..VK_F24 are contiguous, unlike the Carbon equivalents.
  if (token.size() > 1 && token[0] == 'f' &&
      token.find_first_not_of("0123456789", 1) == std::string::npos) {
    int fnum = std::stoi(token.substr(1));
    if (fnum >= 1 && fnum <= 24) {
      vk = VK_F1 + (fnum - 1);
      return true;
    }
    return false;
  }

  auto it = kKeyCodes.find(token);
  if (it == kKeyCodes.end()) {
    return false;
  }
  vk = it->second;
  return true;
}

bool ParseAcceleratorWindows(const std::string& accelerator, UINT& modifiers, UINT& vk) {
  modifiers = 0;
  vk = 0;

  std::vector<std::string> modifier_tokens;
  std::string key_token;
  if (!ParseAcceleratorTokens(accelerator, modifier_tokens, key_token)) {
    return false;
  }

  for (const auto& token : modifier_tokens) {
    if (token == "ctrl" || token == "control" || token == "cmdorctrl" ||
        token == "commandorcontrol") {
      modifiers |= MOD_CONTROL;
    } else if (token == "alt" || token == "option") {
      modifiers |= MOD_ALT;
    } else if (token == "shift") {
      modifiers |= MOD_SHIFT;
    } else if (token == "cmd" || token == "command" || token == "super" ||
               token == "meta") {
      modifiers |= MOD_WIN;
    }
  }

  modifiers |= MOD_NOREPEAT;

  return LookupWindowsKeyCode(key_token, vk);
}


}  // namespace

class ShortcutManagerImpl final : public ShortcutManager::Impl {
 public:
  explicit ShortcutManagerImpl(ShortcutManager* manager) : manager_(manager), running_(false) {}

  ~ShortcutManagerImpl() override { StopThread(); }

  bool IsSupported() override { return true; }

  bool RegisterShortcut(const std::shared_ptr<Shortcut>& shortcut) override {
    EnsureThread();

    UINT modifiers = 0;
    UINT vk = 0;
    if (!ParseAcceleratorWindows(shortcut->GetAccelerator(), modifiers, vk)) {
      return false;
    }

    int hotkey_id = 0;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      hotkey_id = next_hotkey_id_++;
    }
    if (!RegisterHotKey(hwnd_, hotkey_id, modifiers, vk)) {
      return false;
    }

    {
      std::lock_guard<std::mutex> lock(mutex_);
      shortcut_to_hotkey_[shortcut->GetId()] = hotkey_id;
      hotkey_to_shortcut_[hotkey_id] = shortcut->GetId();
    }

    return true;
  }

  bool UnregisterShortcut(const std::shared_ptr<Shortcut>& shortcut) override {
    int hotkey_id = 0;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      auto it = shortcut_to_hotkey_.find(shortcut->GetId());
      if (it == shortcut_to_hotkey_.end()) {
        return false;
      }
      hotkey_id = it->second;
      shortcut_to_hotkey_.erase(it);
      hotkey_to_shortcut_.erase(hotkey_id);
    }

    UnregisterHotKey(hwnd_, hotkey_id);
    return true;
  }

  void SetupEventMonitoring() override { EnsureThread(); }

  void CleanupEventMonitoring() override {
    // Keep thread alive while shortcuts might still be registered.
  }

 private:
  static LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
    if (msg == WM_NCCREATE) {
      auto* create_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
      SetWindowLongPtr(hwnd, GWLP_USERDATA,
                       reinterpret_cast<LONG_PTR>(create_struct->lpCreateParams));
      return DefWindowProc(hwnd, msg, wparam, lparam);
    }

    auto* self =
        reinterpret_cast<ShortcutManagerImpl*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
    if (!self) {
      return DefWindowProc(hwnd, msg, wparam, lparam);
    }

    switch (msg) {
      case WM_HOTKEY:
        self->HandleHotKey(static_cast<int>(wparam));
        return 0;
      case WM_CLOSE:
        DestroyWindow(hwnd);
        return 0;
      case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
      default:
        return DefWindowProc(hwnd, msg, wparam, lparam);
    }
  }

  void HandleHotKey(int hotkey_id) {
    ShortcutId shortcut_id = 0;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      auto it = hotkey_to_shortcut_.find(hotkey_id);
      if (it == hotkey_to_shortcut_.end()) {
        return;
      }
      shortcut_id = it->second;
    }

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

  void EnsureThread() {
    if (running_.load()) {
      std::unique_lock<std::mutex> lock(thread_mutex_);
      thread_cv_.wait(lock, [this]() { return hwnd_ready_; });
      return;
    }

    running_.store(true);
    thread_ = std::thread([this]() { ThreadMain(); });

    std::unique_lock<std::mutex> lock(thread_mutex_);
    thread_cv_.wait(lock, [this]() { return hwnd_ready_; });
  }

  void ThreadMain() {
    const wchar_t* class_name = L"NativeApiShortcutManager";

    WNDCLASSW wc = {};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = GetModuleHandle(nullptr);
    wc.lpszClassName = class_name;
    RegisterClassW(&wc);

    HWND hwnd = CreateWindowExW(0, class_name, L"", 0, 0, 0, 0, 0, HWND_MESSAGE, nullptr,
                                wc.hInstance, this);

    {
      std::lock_guard<std::mutex> lock(thread_mutex_);
      hwnd_ = hwnd;
      hwnd_ready_ = true;
    }
    thread_cv_.notify_all();

    MSG msg;
    while (GetMessage(&msg, nullptr, 0, 0) > 0) {
      TranslateMessage(&msg);
      DispatchMessage(&msg);
    }
  }

  void StopThread() {
    if (!running_.load()) {
      return;
    }

    running_.store(false);
    if (hwnd_) {
      PostMessage(hwnd_, WM_CLOSE, 0, 0);
    }
    if (thread_.joinable()) {
      thread_.join();
    }
    hwnd_ = nullptr;
    hwnd_ready_ = false;
  }

  ShortcutManager* manager_;
  std::mutex mutex_;
  std::unordered_map<ShortcutId, int> shortcut_to_hotkey_;
  std::unordered_map<int, ShortcutId> hotkey_to_shortcut_;
  int next_hotkey_id_ = 1;

  std::atomic<bool> running_;
  std::thread thread_;
  std::mutex thread_mutex_;
  std::condition_variable thread_cv_;
  HWND hwnd_ = nullptr;
  bool hwnd_ready_ = false;
};

ShortcutManager::ShortcutManager()
    : pimpl_(std::make_unique<ShortcutManagerImpl>(this)), next_shortcut_id_(1), enabled_(true) {}

ShortcutManager::~ShortcutManager() {
  UnregisterAll();
}

}  // namespace nativeapi
