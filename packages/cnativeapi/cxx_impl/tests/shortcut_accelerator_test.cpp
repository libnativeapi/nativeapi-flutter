// Tests for ShortcutManager::IsValidAccelerator().
//
// This validator gates every Register() call, so anything it rejects is
// unreachable no matter what the platform backends support. It used to be
// narrower than the backends in ways that silently removed working keys:
// "Return", "Esc", "Control" and "Command" were all parsed by macOS, Windows
// and Linux but refused here, and no punctuation key could be expressed at all
// (so Cmd+Comma -- the standard Preferences shortcut -- was unrepresentable).
//
// The validator is pure, so these cases run identically on every platform.
// Whether a given accelerator can actually be grabbed is a platform and
// runtime question and is not asserted here.

#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>

#include "../src/shortcut_manager.h"

namespace {

using namespace nativeapi;

int g_failures = 0;

void Check(bool condition, const std::string& what) {
  if (!condition) {
    std::cerr << "FAIL: " << what << std::endl;
    ++g_failures;
  } else {
    std::cout << "  ok: " << what << std::endl;
  }
}

void ExpectValid(const std::string& accelerator) {
  Check(ShortcutManager::GetInstance().IsValidAccelerator(accelerator),
        "accepts \"" + accelerator + "\"");
}

void ExpectInvalid(const std::string& accelerator) {
  Check(!ShortcutManager::GetInstance().IsValidAccelerator(accelerator),
        "rejects \"" + accelerator + "\"");
}

// ---------------------------------------------------------------------------
// Modifiers
// ---------------------------------------------------------------------------

void TestModifierSpellings() {
  // Every spelling the platform parsers accept must pass validation too.
  for (const char* mod : {"Ctrl", "Control", "Alt", "Option", "Shift", "Cmd", "Command", "Super",
                          "Meta", "CmdOrCtrl", "CommandOrControl"}) {
    ExpectValid(std::string(mod) + "+A");
  }

  ExpectValid("Ctrl+Shift+Alt+Cmd+A");  // stacked
  ExpectValid("ctrl+shift+a");          // case-insensitive
  ExpectInvalid("Hyper+A");             // unknown modifier
}

// ---------------------------------------------------------------------------
// Keys
// ---------------------------------------------------------------------------

void TestLettersDigitsAndFunctionKeys() {
  ExpectValid("Ctrl+A");
  ExpectValid("Ctrl+z");
  ExpectValid("Ctrl+0");
  ExpectValid("Ctrl+9");

  ExpectValid("Ctrl+F1");
  ExpectValid("Ctrl+F9");
  ExpectValid("Ctrl+F10");
  ExpectValid("Ctrl+F12");
  ExpectValid("Ctrl+F24");
  ExpectInvalid("Ctrl+F0");
  ExpectInvalid("Ctrl+F25");
}

void TestNamedKeys() {
  for (const char* key : {"Space", "Tab", "Enter", "Return", "Escape", "Esc", "Backspace",
                          "Delete", "ForwardDelete", "Insert", "Help", "Home", "End", "PageUp",
                          "PageDown", "Up", "Down", "Left", "Right"}) {
    ExpectValid(std::string("Ctrl+") + key);
  }
}

void TestPunctuationKeys() {
  // By name...
  for (const char* key : {"Plus", "Minus", "Equal", "Comma", "Period", "Slash", "Backslash",
                          "Semicolon", "Quote", "LeftBracket", "RightBracket", "Grave",
                          "Backquote"}) {
    ExpectValid(std::string("Ctrl+") + key);
  }

  // ...and by the literal character each name stands for.
  for (const char* key : {",", ".", "/", "\\", ";", "'", "[", "]", "`", "=", "-"}) {
    ExpectValid(std::string("Ctrl+") + key);
  }

  // The motivating case: Preferences on macOS.
  ExpectValid("Cmd+Comma");
  ExpectValid("Cmd+,");
}

void TestKeypadKeys() {
  for (const char* key : {"Num0", "Num5", "Num9", "NumDec", "NumAdd", "NumSub", "NumMult",
                          "NumDiv", "NumEnter"}) {
    ExpectValid(std::string("Ctrl+") + key);
  }
}

// ---------------------------------------------------------------------------
// Malformed input
// ---------------------------------------------------------------------------

void TestMalformedAccelerators() {
  ExpectInvalid("");
  ExpectInvalid("Ctrl+");        // modifier with no key
  ExpectInvalid("Ctrl++");       // '+' is spelled "Plus"
  ExpectInvalid("Invalid");      // unknown key name
  ExpectInvalid("Ctrl+A+B");     // two keys
  ExpectInvalid("Ctrl Shift A");  // wrong separator
}

}  // namespace

int main() {
  std::cout << "shortcut_accelerator_test" << std::endl;

  TestModifierSpellings();
  TestLettersDigitsAndFunctionKeys();
  TestNamedKeys();
  TestPunctuationKeys();
  TestKeypadKeys();
  TestMalformedAccelerators();

  if (g_failures > 0) {
    std::cerr << g_failures << " check(s) failed" << std::endl;
    return EXIT_FAILURE;
  }
  std::cout << "all checks passed" << std::endl;
  return EXIT_SUCCESS;
}
