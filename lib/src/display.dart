import 'dart:ui';

class Display {
  // Basic identification

  /// Unique identifier for the display
  final String id;

  /// Human-readable display name
  final String name;

  // Physical properties

  /// Display position in virtual desktop coordinates
  final Offset position;

  /// Full display size in logical pixels
  final Size size;

  /// Available work area (excluding taskbars, docks, etc.)
  final Rect workArea;

  /// Display scaling factor (1.0 = 100%, 2.0 = 200%, etc.)
  final double scaleFactor;

  // Additional properties

  /// Whether this is the primary display
  final bool isPrimary;

  Display({
    required this.id,
    required this.name,
    required this.position,
    required this.size,
    required this.workArea,
    required this.scaleFactor,
    this.isPrimary = false,
  });

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is Display) {
      return id == other.id;
    }
    return false;
  }
}
