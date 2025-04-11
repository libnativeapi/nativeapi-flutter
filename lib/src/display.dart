import 'dart:ui';

class Display {
  final String id;
  final String name;
  final Size size;
  final double scaleFactor;

  Display({
    required this.id,
    required this.name,
    required this.size,
    required this.scaleFactor,
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
