import 'package:nativeapi/src/foundation/event.dart';
import 'package:nativeapi/src/foundation/geometry.dart';

/// Base class for all window-related events.
abstract class WindowEvent extends Event {
  /// The ID of the window that triggered this event.
  final int windowId;

  WindowEvent(this.windowId);
}

/// Event emitted when a window is created.
class WindowCreatedEvent extends WindowEvent {
  WindowCreatedEvent(super.windowId);

  @override
  String get typeName => 'WindowCreatedEvent';
}

/// Event emitted when a window is closed.
class WindowClosedEvent extends WindowEvent {
  WindowClosedEvent(super.windowId);

  @override
  String get typeName => 'WindowClosedEvent';
}

/// Event emitted when a window receives focus.
class WindowFocusedEvent extends WindowEvent {
  WindowFocusedEvent(super.windowId);

  @override
  String get typeName => 'WindowFocusedEvent';
}

/// Event emitted when a window loses focus.
class WindowBlurredEvent extends WindowEvent {
  WindowBlurredEvent(super.windowId);

  @override
  String get typeName => 'WindowBlurredEvent';
}

/// Event emitted when a window is minimized.
class WindowMinimizedEvent extends WindowEvent {
  WindowMinimizedEvent(super.windowId);

  @override
  String get typeName => 'WindowMinimizedEvent';
}

/// Event emitted when a window is maximized.
class WindowMaximizedEvent extends WindowEvent {
  WindowMaximizedEvent(super.windowId);

  @override
  String get typeName => 'WindowMaximizedEvent';
}

/// Event emitted when a window is restored from minimized or maximized state.
class WindowRestoredEvent extends WindowEvent {
  WindowRestoredEvent(super.windowId);

  @override
  String get typeName => 'WindowRestoredEvent';
}

/// Event emitted when a window is moved.
class WindowMovedEvent extends WindowEvent {
  /// The new position of the window.
  final Offset position;

  WindowMovedEvent(super.windowId, this.position);

  @override
  String get typeName => 'WindowMovedEvent';
}

/// Event emitted when a window is resized.
class WindowResizedEvent extends WindowEvent {
  /// The new size of the window.
  final Size size;

  WindowResizedEvent(super.windowId, this.size);

  @override
  String get typeName => 'WindowResizedEvent';
}
