import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:cnativeapi/cnativeapi.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/native_handle_wrapper.dart';
import 'package:nativeapi/src/foundation/geometry.dart';
import 'package:path/path.dart' as path;

/// A cross-platform image class for handling images across different platforms.
///
/// This class provides a unified interface for working with images and supports
/// multiple initialization methods including file paths, base64-encoded data,
/// and system icons.
///
/// Features:
/// - Load images from file paths
/// - Load images from base64-encoded strings
/// - Platform-specific system icon support
/// - Automatic format detection and conversion
/// - Memory-efficient internal representation
///
/// All Image instances must be created using static factory methods
/// (fromFile, fromBase64, fromSystemIcon).
///
/// Example:
/// ```dart
/// // Create image from file path
/// final image1 = Image.fromFile('/path/to/icon.png');
///
/// // Create image from base64 string
/// final image2 = Image.fromBase64('data:image/png;base64,iVBORw0KGgo...');
///
/// // Create image from system icon
/// final image3 = Image.fromSystemIcon('folder');
///
/// // Use with TrayIcon
/// trayIcon.icon = image1;
///
/// // Use with MenuItem
/// menuItem.icon = image2;
///
/// // Get image dimensions
/// final size = image1.size;
/// if (size.width > 0 && size.height > 0) {
///   print('Image size: ${size.width}x${size.height}');
/// }
///
/// // Get image format for debugging
/// final format = image1.format;
/// print('Image format: $format');
/// ```
class Image
    with CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_image_t> {
  late final native_image_t _nativeHandle;

  /// Constructor for internal use
  Image(this._nativeHandle);

  /// Create an image from a Flutter asset.
  ///
  /// Loads an image from the Flutter assets bundle. This method automatically
  /// resolves the correct asset path based on the current platform.
  ///
  /// The asset path is constructed differently for each platform:
  /// - macOS: Located in App.framework/Resources/flutter_assets/
  /// - Other platforms: Located in data/flutter_assets/ relative to executable
  ///
  /// Returns null if the asset file is not found or loading failed.
  ///
  /// Example:
  /// ```dart
  /// // Load an image asset (assumes assets/icons/app_icon.png exists)
  /// final appIcon = Image.fromAsset('assets/icons/app_icon.png');
  /// if (appIcon != null) {
  ///   trayIcon.icon = appIcon;
  /// }
  ///
  /// // Load a simple asset
  /// final logo = Image.fromAsset('images/logo.svg');
  /// ```
  ///
  /// Note: The asset must be included in your pubspec.yaml file:
  /// ```yaml
  /// flutter:
  ///   assets:
  ///     - assets/icons/
  ///     - images/
  /// ```
  static Image? fromAsset(String name) {
    // Get the path to the current executable
    String executablePath = Platform.resolvedExecutable;

    // Default asset path for most platforms (Windows, Linux)
    String assetPath = path.joinAll([
      path.dirname(executablePath),
      'data/flutter_assets',
      name,
    ]);

    // macOS has a different bundle structure
    if (Platform.isMacOS) {
      // On macOS, assets are located in the app bundle's framework resources
      assetPath = path.join(
        path.dirname(path.dirname(executablePath)),
        'Frameworks',
        'App.framework',
        'Resources',
        'flutter_assets',
        name,
      );
    }

    // Load the image from the resolved asset path
    return fromFile(assetPath);
  }

  /// Create an image from a file path.
  ///
  /// Loads an image from the specified file path on disk. The image format
  /// is automatically detected based on the file contents.
  ///
  /// Returns null if loading failed.
  ///
  /// Supported formats depend on the platform:
  /// - macOS: PNG, JPEG, GIF, TIFF, BMP, ICO, PDF
  /// - Windows: PNG, JPEG, BMP, GIF, TIFF, ICO
  /// - Linux: PNG, JPEG, BMP, GIF, SVG, XPM (depends on system libraries)
  static Image? fromFile(String filePath) {
    final filePathPtr = filePath.toNativeUtf8().cast<Char>();
    final handle = cnativeApiBindings.native_image_from_file(filePathPtr);
    ffi.calloc.free(filePathPtr);

    if (handle == nullptr) {
      return null;
    }

    return Image(handle);
  }

  /// Create an image from base64-encoded data.
  ///
  /// Decodes and loads an image from a base64-encoded string. The string
  /// can optionally include a data URI prefix (e.g., "data:image/png;base64,").
  ///
  /// Returns null if decoding failed.
  ///
  /// The image format is automatically detected from the decoded data.
  static Image? fromBase64(String base64Data) {
    final base64DataPtr = base64Data.toNativeUtf8().cast<Char>();
    final handle = cnativeApiBindings.native_image_from_base64(base64DataPtr);
    ffi.calloc.free(base64DataPtr);

    if (handle == nullptr) {
      return null;
    }

    return Image(handle);
  }

  /// Get the size of the image in pixels.
  ///
  /// Returns a Size object with width and height, or Size.zero if invalid.
  Size get size {
    final nativeSize = bindings.native_image_get_size(_nativeHandle);
    return Size(nativeSize.width, nativeSize.height);
  }

  /// Get the image format string for debugging purposes.
  ///
  /// Returns the image format (e.g., "PNG", "JPEG", "GIF"), or null if unknown.
  String? get format {
    final formatPtr = bindings.native_image_get_format(_nativeHandle);
    if (formatPtr == nullptr) {
      return null;
    }

    final format = formatPtr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(formatPtr);
    return format;
  }

  /// Convert the image to base64-encoded PNG data.
  ///
  /// Returns base64-encoded PNG data with data URI prefix, or null on error.
  String? toBase64() {
    final base64Ptr = bindings.native_image_to_base64(_nativeHandle);
    if (base64Ptr == nullptr) {
      return null;
    }

    final base64 = base64Ptr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(base64Ptr);
    return base64;
  }

  /// Save the image to a file.
  ///
  /// Returns true if saved successfully, false otherwise.
  bool saveToFile(String filePath) {
    final filePathPtr = filePath.toNativeUtf8().cast<Char>();
    final result = bindings.native_image_save_to_file(
      _nativeHandle,
      filePathPtr,
    );
    ffi.calloc.free(filePathPtr);
    return result;
  }

  @override
  native_image_t get nativeHandle => _nativeHandle;

  @override
  void dispose() {
    bindings.native_image_destroy(_nativeHandle);
  }
}
