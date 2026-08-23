#pragma once

#include <functional>
#include <memory>
#include <string>

#include "foundation/event_emitter.h"
#include "foundation/keyboard.h"

namespace nativeapi {

class KeyboardMonitor : public EventEmitter<KeyboardEvent> {
 public:
  KeyboardMonitor();
  virtual ~KeyboardMonitor();

  // Start the keyboard monitor
  void Start();

  // Stop the keyboard monitor
  void Stop();

  // Check if the keyboard monitor is monitoring
  bool IsMonitoring() const;

  // Get access to the event emitter for internal use
  EventEmitter<KeyboardEvent>& GetInternalEventEmitter();

 private:
  class Impl;
  std::unique_ptr<Impl> impl_;

  friend class Impl;
};

}  // namespace nativeapi
