// Paints the header's avatar in memory and encodes it as a PNG data URI, so
// that ImageView has something to show without shipping an image file.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nativeapi/nativeapi.dart';

/// A round badge: a diagonal gradient from [hue] to [hue] + 60 with a light
/// ring and a highlight, transparent outside the circle. [seed] moves the
/// highlight, so that every "New avatar" looks a little different.
Image? paintAvatar({required double hue, int seed = 0, int size = 128}) {
  final random = math.Random(seed);
  final glowX = 0.25 + random.nextDouble() * 0.5;
  final glowY = 0.2 + random.nextDouble() * 0.4;
  final twist = random.nextDouble() * 60 - 30;

  final rgba = Uint8List(size * size * 4);
  final center = (size - 1) / 2;
  final radius = size / 2 - 1;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x - center, dy = y - center;
      final distance = math.sqrt(dx * dx + dy * dy);
      // One pixel of anti-aliasing on the rim.
      final coverage = (radius - distance + 0.5).clamp(0.0, 1.0);
      if (coverage == 0) continue;

      final t = (x + y) / (2 * size);
      var rgb = _hsv(hue + twist + 60 * t, 0.62, 0.95 - 0.25 * t);

      final ring = 1 - (distance - radius * 0.86).abs() / (radius * 0.05);
      if (ring > 0) rgb = _mix(rgb, (1, 1, 1), 0.45 * ring);

      final hx = x - size * glowX, hy = y - size * glowY;
      final glow = 1 - math.sqrt(hx * hx + hy * hy) / (radius * 0.6);
      if (glow > 0) rgb = _mix(rgb, (1, 1, 1), 0.4 * glow * glow);

      final i = (y * size + x) * 4;
      rgba[i] = (rgb.$1 * 255).round();
      rgba[i + 1] = (rgb.$2 * 255).round();
      rgba[i + 2] = (rgb.$3 * 255).round();
      rgba[i + 3] = (coverage * 255).round();
    }
  }
  final png = _encodePng(rgba, size, size);
  return Image.fromBase64('data:image/png;base64,${base64Encode(png)}');
}

typedef _Rgb = (double, double, double);

_Rgb _hsv(double hue, double s, double v) {
  final h = (hue % 360) / 60;
  final c = v * s;
  final x = c * (1 - (h % 2 - 1).abs());
  final m = v - c;
  final (r, g, b) = switch (h.floor()) {
    0 => (c, x, 0.0),
    1 => (x, c, 0.0),
    2 => (0.0, c, x),
    3 => (0.0, x, c),
    4 => (x, 0.0, c),
    _ => (c, 0.0, x),
  };
  return (r + m, g + m, b + m);
}

_Rgb _mix(_Rgb a, _Rgb b, double t) => (
  a.$1 + (b.$1 - a.$1) * t,
  a.$2 + (b.$2 - a.$2) * t,
  a.$3 + (b.$3 - a.$3) * t,
);

// --- A minimal PNG encoder: 8-bit RGBA, no interlacing, no filtering --------

Uint8List _encodePng(Uint8List rgba, int width, int height) {
  final raw = BytesBuilder(copy: false);
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // filter type: none
    raw.add(Uint8List.sublistView(rgba, y * width * 4, (y + 1) * width * 4));
  }
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 6); // colour type: RGBA

  final png = BytesBuilder(copy: false)
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  _chunk(png, 'IHDR', header.buffer.asUint8List());
  _chunk(png, 'IDAT', Uint8List.fromList(zlib.encode(raw.takeBytes())));
  _chunk(png, 'IEND', Uint8List(0));
  return png.takeBytes();
}

void _chunk(BytesBuilder out, String type, Uint8List data) {
  final typeBytes = ascii.encode(type);
  out
    ..add(_uint32(data.length))
    ..add(typeBytes)
    ..add(data)
    ..add(_uint32(_crc32([...typeBytes, ...data])));
}

Uint8List _uint32(int value) =>
    (ByteData(4)..setUint32(0, value)).buffer.asUint8List();

final List<int> _crcTable = List.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
  }
  return c;
});

/// CRC-32 as PNG uses it: over a chunk's type followed by its data.
int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >>> 8);
  }
  return crc ^ 0xFFFFFFFF;
}
