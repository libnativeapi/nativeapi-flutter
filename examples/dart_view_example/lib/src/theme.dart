// The workbench's accent colour, which the footer cycles through and every
// section repaints itself with.

import 'package:nativeapi/nativeapi.dart';

final class Accent {
  const Accent(this.name, this.color, this.hue);

  final String name;
  final Color color;

  /// Hue in degrees, for the generated avatar.
  final double hue;
}

const accents = [
  Accent('Indigo', Color(r: 88, g: 86, b: 214, a: 255), 243),
  Accent('Teal', Color(r: 0, g: 150, b: 160, a: 255), 184),
  Accent('Orange', Color(r: 230, g: 120, b: 20, a: 255), 28),
  Accent('Pink', Color(r: 214, g: 51, b: 132, a: 255), 330),
  Accent('Green', Color(r: 52, g: 150, b: 72, a: 255), 132),
];

final class Theme {
  var _index = 0;
  final _listeners = <void Function(Accent)>[];

  Accent get accent => accents[_index];

  /// Calls [listener] now and whenever the accent changes.
  void bind(void Function(Accent accent) listener) {
    _listeners.add(listener);
    listener(accent);
  }

  void next() {
    _index = (_index + 1) % accents.length;
    for (final listener in _listeners) {
      listener(accent);
    }
  }
}

final theme = Theme();
