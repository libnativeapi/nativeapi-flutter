import 'package:nativeapi/src/ffi/bindings_generated.dart';
import 'ffi/bindings.dart';

class AccessibilityManager {
  AccessibilityManager._();

  static final AccessibilityManager instance = AccessibilityManager._();

  NativeApiBindings get _bindings => nativeApiBindings;

  /// Enable the accessibility permission.
  void enable() {
    _bindings.native_accessibility_manager_enable();
  }

  /// Whether the accessibility permission is enabled.
  bool isEnabled() {
    return _bindings.native_accessibility_manager_is_enabled();
  }
}
