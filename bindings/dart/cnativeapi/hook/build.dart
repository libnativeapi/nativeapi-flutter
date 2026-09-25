// Builds the nativeapi core, C ABI included, into the shared library that the
// `@Native` functions in lib/src/bindings_generated.dart resolve against.
//
// The source lists mirror core/src/CMakeLists.txt; keep the two in step.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }
    final targetOS = input.config.code.targetOS;
    final core = _locateCore(input.packageRoot);
    final src = core.resolve('src/');

    final platformDir = switch (targetOS) {
      OS.android => 'android',
      OS.iOS => 'ios',
      OS.linux => 'linux',
      OS.macOS => 'macos',
      OS.windows => 'windows',
      _ => throw UnsupportedError('cnativeapi does not support $targetOS'),
    };
    final apple = targetOS == OS.iOS || targetOS == OS.macOS;

    final sources = [
      ..._list(src, '', '.cpp'),
      ..._list(src, 'foundation/', '.cpp'),
      ..._list(src, 'capi/', '.cpp'),
      ..._list(src, 'platform/$platformDir/', apple ? '.mm' : '.cpp').where(
        // The WinUI 3 backend is opt-in in core's CMake build and needs the
        // Windows App SDK; the Win32 implementations stand in for it.
        (path) => !RegExp(
          r'(menu_winui3|message_dialog_winui3|window_winui3|winui3_runtime|view_winui3)_windows\.cpp$',
        ).hasMatch(path),
      ),
    ];

    final flags = <String>[];
    final libraries = <String>[];
    final libraryDirectories = <String>[];
    var frameworks = <String>[];
    switch (targetOS) {
      case OS.macOS:
        flags.addAll(_objectiveCpp);
        frameworks = [
          'Cocoa',
          'QuartzCore',
          'Carbon',
          'CoreGraphics',
          'ApplicationServices',
          'ServiceManagement',
        ];
      case OS.iOS:
        flags.addAll(_objectiveCpp);
        frameworks = ['UIKit', 'Foundation', 'CoreGraphics'];
      case OS.linux:
        flags.addAll(await _pkgConfig(['--cflags', ..._linuxPackages]));
        // Libraries go after the sources, where --as-needed keeps them.
        for (final flag in await _pkgConfig(['--libs', ..._linuxPackages])) {
          if (flag.startsWith('-l')) {
            libraries.add(flag.substring(2));
          } else if (flag.startsWith('-L')) {
            libraryDirectories.add(flag.substring(2));
          } else {
            flags.add(flag);
          }
        }
        flags.add('-pthread');
      case OS.android:
        libraries.addAll(['log', 'android']);
      case OS.windows:
        flags.addAll(['/EHsc', '/utf-8']);
        libraries.addAll([
          'user32',
          'shell32',
          'ole32',
          'uuid',
          'comctl32',
          'dwmapi',
          'gdiplus',
          'crypt32',
          'advapi32',
          'version',
          'gdi32',
        ]);
    }

    final builder = CBuilder.library(
      name: 'cnativeapi',
      assetName: 'cnativeapi.dart',
      sources: sources,
      includes: [src.toFilePath()],
      frameworks: frameworks,
      libraries: libraries,
      libraryDirectories: libraryDirectories,
      flags: flags,
      language: Language.cpp,
      std: 'c++17',
    );
    await builder.run(
      input: input,
      output: output,
      logger: Logger('')
        ..level = Level.ALL
        ..onRecord.listen((record) => print(record.message)),
    );
  });
}

/// Compiles every source as Objective-C++ under ARC. The flags come after the
/// `-x c++` that [Language.cpp] adds, so they win.
const _objectiveCpp = [
  '-x',
  'objective-c++',
  '-fobjc-arc',
  '-DOBJC_OLD_DISPATCH_PROTOTYPES=0',
];

const _linuxPackages = ['gtk+-3.0', 'x11', 'xi'];

/// The core sources: a published package carries a copy in cxx_impl/ (vendored
/// by the release workflow); inside the workspace repository the package
/// builds the checkout's core/ directly.
Uri _locateCore(Uri packageRoot) {
  for (final candidate in [
    packageRoot.resolve('cxx_impl/'),
    packageRoot.resolve('../../../core/'),
  ]) {
    if (File.fromUri(candidate.resolve('src/CMakeLists.txt')).existsSync()) {
      return candidate;
    }
  }
  throw StateError(
    'nativeapi core sources not found next to ${packageRoot.toFilePath()}; '
    'run `git submodule update --init core` in the repository',
  );
}

/// The files directly in [dir] (relative to [src]) ending in [extension],
/// sorted so the build is reproducible.
List<String> _list(Uri src, String dir, String extension) {
  final directory = Directory.fromUri(src.resolve(dir));
  return [
    for (final entity in directory.listSync())
      if (entity is File && entity.path.endsWith(extension)) entity.path,
  ]..sort();
}

Future<List<String>> _pkgConfig(List<String> args) async {
  final result = await Process.run('pkg-config', args);
  if (result.exitCode != 0) {
    throw StateError(
      'pkg-config ${args.join(' ')} failed; install the GTK 3, X11 and Xi '
      'development packages.\n${result.stderr}',
    );
  }
  return (result.stdout as String)
      .split(RegExp(r'\s+'))
      .where((flag) => flag.isNotEmpty)
      .toList();
}
