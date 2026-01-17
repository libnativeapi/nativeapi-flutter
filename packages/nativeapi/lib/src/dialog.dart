import 'package:cnativeapi/cnativeapi.dart';

/// Dialog modality types.
///
/// Defines how the dialog blocks user interaction.
enum DialogModality {
  /// None - Non-modal dialog.
  ///
  /// The dialog does not block user interaction. The application continues
  /// to run and users can interact with other windows while the dialog is open.
  none,

  /// Application - Blocks the current application.
  ///
  /// Blocks interaction with all windows in the current application,
  /// but allows interaction with other applications.
  application,

  /// Window - Blocks the parent window (requires parent window handle).
  ///
  /// Blocks interaction with a specific parent window.
  /// Requires a parent window handle to be provided.
  window;

  /// Converts this [DialogModality] to its native representation.
  native_dialog_modality_t toNative() {
    switch (this) {
      case DialogModality.none:
        return native_dialog_modality_t.NATIVE_DIALOG_MODALITY_NONE;
      case DialogModality.application:
        return native_dialog_modality_t.NATIVE_DIALOG_MODALITY_APPLICATION;
      case DialogModality.window:
        return native_dialog_modality_t.NATIVE_DIALOG_MODALITY_WINDOW;
    }
  }

  /// Converts a native [native_dialog_modality_t] to [DialogModality].
  static DialogModality fromNative(native_dialog_modality_t nativeType) {
    switch (nativeType) {
      case native_dialog_modality_t.NATIVE_DIALOG_MODALITY_NONE:
        return DialogModality.none;
      case native_dialog_modality_t.NATIVE_DIALOG_MODALITY_APPLICATION:
        return DialogModality.application;
      case native_dialog_modality_t.NATIVE_DIALOG_MODALITY_WINDOW:
        return DialogModality.window;
    }
  }
}

/// Base class for all dialog types.
///
/// This abstract class provides the common interface for all dialog types
/// in the system. Specific dialog types (MessageDialog, FileDialog, etc.)
/// inherit from this class and implement their specific behavior.
///
/// The Dialog class provides:
/// - Modal and non-modal display modes
/// - Modal state management
///
/// Example:
/// ```dart
/// // Create a message dialog (see MessageDialog for details)
/// final messageDialog = MessageDialog(
///   'Title',
///   'Message',
/// );
///
/// // Set modal mode and open
/// messageDialog.modality = DialogModality.application;
/// messageDialog.open();
/// ```
abstract class Dialog {
  /// Gets the current modality setting of the dialog.
  ///
  /// Returns the current [DialogModality] setting.
  DialogModality get modality;

  /// Sets the modality of the dialog.
  ///
  /// The modality determines how the dialog blocks user interaction:
  /// - [DialogModality.none]: Non-modal dialog, does not block user interaction
  /// - [DialogModality.application]: Blocks interaction with all windows in the current application
  /// - [DialogModality.window]: Blocks interaction with a specific parent window (requires parent handle)
  ///
  /// This setting affects the behavior when [open] is called.
  /// The modality should be set before opening the dialog.
  ///
  /// Example:
  /// ```dart
  /// dialog.modality = DialogModality.application;  // Make it application modal
  /// dialog.open();                                 // Open as modal dialog
  /// ```
  set modality(DialogModality value);

  /// Opens the dialog according to its modality setting.
  ///
  /// The dialog behavior depends on the current modality:
  /// - [DialogModality.none]: Opens non-modally, does not block the calling thread
  /// - [DialogModality.application]/[DialogModality.window]: Opens modally, blocks until the user dismisses the dialog
  ///
  /// Returns `true` if the dialog was successfully opened, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// // Non-modal dialog
  /// dialog.modality = DialogModality.none;
  /// dialog.open();
  /// // Application continues running...
  ///
  /// // Modal dialog
  /// dialog.modality = DialogModality.application;
  /// dialog.open();
  /// // Blocks until user dismisses dialog
  /// ```
  bool open();

  /// Closes the dialog programmatically.
  ///
  /// Dismisses the dialog as if the user had closed it.
  ///
  /// Returns `true` if the dialog was successfully closed, `false` otherwise.
  bool close();
}
