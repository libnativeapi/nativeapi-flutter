import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';

class AccessibilityManager with CNativeApiBindingsMixin {
  void enable() {
    bindings.native_accessibility_manager_enable();
  }

  bool get isEnabled {
    return bindings.native_accessibility_manager_is_enabled();
  }
}
