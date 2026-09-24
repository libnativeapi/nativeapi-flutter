// Lists the connected displays. A plain Dart program: run it with
// `dart run example/nativeapi_example.dart`.

import 'package:nativeapi/nativeapi.dart';

void main() {
  for (final display in DisplayManager.instance.getAll()) {
    final size = display.size;
    print(
      '${display.name ?? '(unnamed)'}: '
      '${size.width}x${size.height} @${display.scaleFactor}x',
    );
  }
}
