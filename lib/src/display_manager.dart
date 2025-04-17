import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:nativeapi/src/display_listener.dart';
import 'package:nativeapi/src/event_listener_mixin.dart';
import 'package:nativeapi/src/nativeapi_bindings_generated.dart';

import 'display.dart';
import 'nativeapi_bindings.dart';

class DisplayManager with EventListenerMixin<DisplayListener> {
  DisplayManager._();

  static final DisplayManager instance = DisplayManager._();

  NativeApiBindings get _bindings => nativeApiBindings;

  late final ffi.NativeCallable<DisplayAddedCallbackFunction>
      _addedCallbackCallable;
  late final ffi.NativeCallable<DisplayRemovedCallbackFunction>
      _removedCallbackCallable;

  DisplayManager() {
    _addedCallbackCallable =
        ffi.NativeCallable<DisplayAddedCallbackFunction>.listener(
            _onDisplayAdded);
    _removedCallbackCallable =
        ffi.NativeCallable<DisplayRemovedCallbackFunction>.listener(
            _onDisplayRemoved);

    _bindings.display_manager_on_display_added(
        _addedCallbackCallable.nativeFunction);
    _bindings.display_manager_on_display_removed(
        _removedCallbackCallable.nativeFunction);
  }

  void _onDisplayAdded(NativeDisplay display) {
    print('onDisplayAdded: ${display.dartify()}');
    notifyListeners((l) => l.onDisplayAdded(display.dartify()));
  }

  void _onDisplayRemoved(NativeDisplay display) {
    print('onDisplayRemoved: ${display.dartify()}');
    notifyListeners((l) => l.onDisplayRemoved(display.dartify()));
  }

  /// Get all displays.
  ///
  /// Returns a list of all displays.
  List<Display> getAll() {
    return _bindings.display_manager_get_all().dartify();
  }

  /// Get the primary display.
  ///
  /// Returns the primary display.
  Display getPrimary() {
    return _bindings.display_manager_get_primary().dartify();
  }

  /// Get the cursor position.
  ///
  /// Returns the cursor position in the primary display.
  Offset getCursorPosition() {
    return _bindings.display_manager_get_cursor_position().dartify();
  }

  @override
  void addListener(DisplayListener listener) {
    super.addListener(listener);
    if (hasListeners) _bindings.display_manager_start_listening();
  }

  @override
  void removeListener(DisplayListener listener) {
    super.removeListener(listener);
    if (!hasListeners) _bindings.display_manager_stop_listening();
  }
}

extension on NativeDisplay {
  Display dartify() {
    String id, name;
    try {
      id = this.id.cast<Utf8>().toDartString();
    } catch (e) {
      id = '';
    }
    try {
      name = this.name.cast<Utf8>().toDartString();
    } catch (e) {
      name = '';
    }

    return Display(
      id: id,
      name: name,
      size: Size(width, height),
      scaleFactor: scaleFactor,
    );
  }
}

extension on NativeDisplayList {
  List<Display> dartify() {
    return List.generate(count, (index) => displays[index].dartify());
  }
}

extension on NativePoint {
  Offset dartify() {
    return Offset(x, y);
  }
}
