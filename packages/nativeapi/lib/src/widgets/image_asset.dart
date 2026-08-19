import 'dart:io';

import 'package:path/path.dart' as path;

import '../image.dart';

/// Loading an [Image] from a Flutter asset.
///
/// Hand-written rather than generated: the C++ API only knows about files and
/// base64, and where Flutter puts a bundled asset on disk is a Flutter fact
/// with no counterpart in the header.
extension ImageAsset on Image {
  /// Loads a bundled asset by its `pubspec.yaml` name.
  ///
  /// ```dart
  /// final appIcon = ImageAsset.fromAsset('assets/icons/app_icon.png');
  /// if (appIcon != null) {
  ///   trayIcon.setIcon(appIcon);
  /// }
  /// ```
  ///
  /// The asset has to be declared in pubspec.yaml:
  /// ```yaml
  /// flutter:
  ///   assets:
  ///     - assets/icons/
  /// ```
  static Image? fromAsset(String name) {
    final executablePath = Platform.resolvedExecutable;

    // Where most platforms put the bundle.
    var assetPath = path.joinAll([
      path.dirname(executablePath),
      'data/flutter_assets',
      name,
    ]);

    // macOS keeps them inside the app bundle's framework resources instead.
    if (Platform.isMacOS) {
      assetPath = path.join(
        path.dirname(path.dirname(executablePath)),
        'Frameworks',
        'App.framework',
        'Resources',
        'flutter_assets',
        name,
      );
    }

    return Image.fromFile(assetPath);
  }
}
