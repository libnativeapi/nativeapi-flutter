#include <atomic>
#include <chrono>
#include <iostream>
#include <memory>
#include <string>
#include <thread>

#include "../../keyboard_monitor.h"

// Import X11 headers after including the header to avoid conflicts
// We'll need to undefine None to avoid conflicts with our enum
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/XInput2.h>
#include <X11/keysym.h>

// Handle the None conflict from X11
#ifdef None
#undef None
#endif

namespace nativeapi {

class KeyboardMonitor::Impl {
 public:
  Impl(KeyboardMonitor* monitor) : monitor_(monitor), display_(nullptr), monitoring_(false) {}

  Display* display_;
  std::atomic<bool> monitoring_;
  std::thread monitoring_thread_;
  KeyboardMonitor* monitor_;
  int xi_opcode_;

  void MonitoringLoop();
  void InitializeXInput();
  void CleanupXInput();
  uint32_t GetModifierState();
};

KeyboardMonitor::KeyboardMonitor() : impl_(std::make_unique<Impl>(this)) {}

KeyboardMonitor::~KeyboardMonitor() {
  Stop();
}

void KeyboardMonitor::Impl::InitializeXInput() {
  display_ = XOpenDisplay(nullptr);
  if (!display_) {
    std::cerr << "Failed to open X display" << std::endl;
    return;
  }

  // Check for XInput extension
  int event, error;
  if (!XQueryExtension(display_, "XInputExtension", &xi_opcode_, &event, &error)) {
    std::cerr << "XInput extension not available" << std::endl;
    XCloseDisplay(display_);
    display_ = nullptr;
    return;
  }

  // Check XInput version
  int major = 2, minor = 0;
  if (XIQueryVersion(display_, &major, &minor) != Success) {
    std::cerr << "XInput 2.0 not available" << std::endl;
    XCloseDisplay(display_);
    display_ = nullptr;
    return;
  }

  // Select for keyboard events on root window
  XIEventMask eventmask;
  unsigned char mask[XIMaskLen(XI_LASTEVENT)] = {0};

  eventmask.deviceid = XIAllMasterDevices;
  eventmask.mask_len = sizeof(mask);
  eventmask.mask = mask;

  XISetMask(mask, XI_KeyPress);
  XISetMask(mask, XI_KeyRelease);

  Window root = DefaultRootWindow(display_);
  if (XISelectEvents(display_, root, &eventmask, 1) != Success) {
    std::cerr << "Failed to select XI events" << std::endl;
    XCloseDisplay(display_);
    display_ = nullptr;
    return;
  }
}

void KeyboardMonitor::Impl::CleanupXInput() {
  if (display_) {
    XCloseDisplay(display_);
    display_ = nullptr;
  }
}

uint32_t KeyboardMonitor::Impl::GetModifierState() {
  uint32_t modifier_keys = static_cast<uint32_t>(ModifierKey::None);

  if (!display_)
    return modifier_keys;

  // Query current keyboard state
  char keys[32];
  XQueryKeymap(display_, keys);

  // Check for common modifier keycodes
  // These keycodes may vary by system, but are common defaults
  int shift_keycode = XKeysymToKeycode(display_, XK_Shift_L);
  int ctrl_keycode = XKeysymToKeycode(display_, XK_Control_L);
  int alt_keycode = XKeysymToKeycode(display_, XK_Alt_L);
  int meta_keycode = XKeysymToKeycode(display_, XK_Super_L);
  int caps_keycode = XKeysymToKeycode(display_, XK_Caps_Lock);
  int num_keycode = XKeysymToKeycode(display_, XK_Num_Lock);
  int scroll_keycode = XKeysymToKeycode(display_, XK_Scroll_Lock);

  // Check if keys are pressed
  if (shift_keycode && (keys[shift_keycode / 8] & (1 << (shift_keycode % 8)))) {
    modifier_keys |= static_cast<uint32_t>(ModifierKey::Shift);
  }
  if (ctrl_keycode && (keys[ctrl_keycode / 8] & (1 << (ctrl_keycode % 8)))) {
    modifier_keys |= static_cast<uint32_t>(ModifierKey::Ctrl);
  }
  if (alt_keycode && (keys[alt_keycode / 8] & (1 << (alt_keycode % 8)))) {
    modifier_keys |= static_cast<uint32_t>(ModifierKey::Alt);
  }
  if (meta_keycode && (keys[meta_keycode / 8] & (1 << (meta_keycode % 8)))) {
    modifier_keys |= static_cast<uint32_t>(ModifierKey::Meta);
  }
  if (caps_keycode && (keys[caps_keycode / 8] & (1 << (caps_keycode % 8)))) {
    modifier_keys |= static_cast<uint32_t>(ModifierKey::CapsLock);
  }
  if (num_keycode && (keys[num_keycode / 8] & (1 << (num_keycode % 8)))) {
    modifier_keys |= static_cast<uint32_t>(ModifierKey::NumLock);
  }
  if (scroll_keycode && (keys[scroll_keycode / 8] & (1 << (scroll_keycode % 8)))) {
    modifier_keys |= static_cast<uint32_t>(ModifierKey::ScrollLock);
  }

  return modifier_keys;
}

void KeyboardMonitor::Impl::MonitoringLoop() {
  if (!display_)
    return;

  while (monitoring_) {
    // Check for pending events
    while (XPending(display_) && monitoring_) {
      XEvent event;
      XNextEvent(display_, &event);

      // Handle XI2 events
      if (event.xcookie.type == GenericEvent && event.xcookie.extension == xi_opcode_) {
        if (XGetEventData(display_, &event.xcookie)) {
          XIDeviceEvent* xi_event = (XIDeviceEvent*)event.xcookie.data;

          if (xi_event->evtype == XI_KeyPress) {
            KeyPressedEvent key_event(xi_event->detail);
            monitor_->Emit(key_event);

            ModifierKeysChangedEvent modifier_event(GetModifierState());
            monitor_->Emit(modifier_event);
          } else if (xi_event->evtype == XI_KeyRelease) {
            KeyReleasedEvent key_event(xi_event->detail);
            monitor_->Emit(key_event);

            ModifierKeysChangedEvent modifier_event(GetModifierState());
            monitor_->Emit(modifier_event);
          }

          XFreeEventData(display_, &event.xcookie);
        }
      }
    }

    // Small sleep to prevent excessive CPU usage
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
}

void KeyboardMonitor::Start() {
  if (impl_->monitoring_) {
    return;  // Already started
  }

  impl_->InitializeXInput();
  if (!impl_->display_) {
    std::cerr << "Failed to initialize X11 display for keyboard monitoring" << std::endl;
    return;
  }

  impl_->monitoring_ = true;
  impl_->monitoring_thread_ = std::thread(&KeyboardMonitor::Impl::MonitoringLoop, impl_.get());

  std::cout << "Keyboard monitor started successfully" << std::endl;
}

void KeyboardMonitor::Stop() {
  if (!impl_->monitoring_) {
    return;  // Already stopped
  }

  impl_->monitoring_ = false;

  // Wait for monitoring thread to finish
  if (impl_->monitoring_thread_.joinable()) {
    impl_->monitoring_thread_.join();
  }

  impl_->CleanupXInput();

  std::cout << "Keyboard monitor stopped successfully" << std::endl;
}

bool KeyboardMonitor::IsMonitoring() const {
  return impl_->monitoring_;
}

}  // namespace nativeapi
