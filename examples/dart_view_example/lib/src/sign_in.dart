// A sign-in form: validation as you type, Enter to move on and to submit, a
// masked field that can be revealed, and a fake round trip on a Dart timer
// during which the form is disabled.

import 'dart:async';

import 'package:nativeapi/nativeapi.dart';

import 'event_log.dart';
import 'ui.dart';

final class SignInSection {
  SignInSection({required this.onSignedIn, required this.onSignedOut}) {
    _username = field(
      'signIn.username',
      placeholder: 'Username',
      onChanged: (_) => _validate(),
      onSubmitted: () => _password.focus(),
    );
    _password = field(
      'signIn.password',
      placeholder: 'Password (6+ characters)',
      secure: true,
      onChanged: (_) => _validate(),
      onSubmitted: () {
        if (_submit.isEnabled) _signIn();
      },
    );
    _reveal = button(
      'signIn.reveal',
      'Show',
      _toggleReveal,
      tooltip: 'Show or mask the password',
    );
    _clear = button('signIn.clear', 'Clear', _reset);
    _submit = button('signIn.submit', 'Sign in', () {
      if (_signedInAs != null) {
        _signOut();
      } else {
        _signIn();
      }
    });
    _status = label(
      'signIn.status',
      'Try any name; "admin" is locked.',
      color: muted,
    );

    view = section(
      'signIn',
      'Sign in',
      column(
        'signIn.body',
        spacing: 8,
        children: [
          _username,
          row(
            'signIn.passwordRow',
            spacing: 8,
            children: [
              _password
                ..flex = 1
                ..alignment = ViewAlignment.center,
              _reveal,
            ],
          ),
          row(
            'signIn.actions',
            spacing: 8,
            children: [_status..flex = 1, _clear, _submit],
          ),
        ],
      ),
    );
    _status.alignment = ViewAlignment.center;
    _validate();
  }

  final void Function(String user) onSignedIn;
  final void Function() onSignedOut;

  late final View view;
  late final TextField _username;
  late final TextField _password;
  late final Button _reveal;
  late final Button _clear;
  late final Button _submit;
  late final Label _status;

  Timer? _pending;
  String? _signedInAs;

  String get _user => (_username.text ?? '').trim();
  String get _pass => _password.text ?? '';

  void focus() => _username.focus();

  /// Fills the form, as a user would, and submits it.
  void signInAs(String user, String password) {
    if (_signedInAs != null || _pending != null) return;
    _username.text = user;
    _password.text = password;
    _validate();
    _signIn();
  }

  void _validate() {
    final busy = _pending != null;
    final signedIn = _signedInAs != null;
    _submit.isEnabled =
        !busy && (signedIn || (_user.isNotEmpty && _pass.isNotEmpty));
    _clear.isEnabled = !busy && !signedIn;
    _username.isEnabled = !busy && !signedIn;
    _password.isEnabled = !busy && !signedIn;
    _reveal.isEnabled = !busy && !signedIn;
  }

  void _toggleReveal() {
    _password.isSecure = !_password.isSecure;
    _reveal.text = _password.isSecure ? 'Show' : 'Hide';
    _password.focus();
  }

  void _reset() {
    _username.text = '';
    _password.text = '';
    _setStatus('Cleared.', muted);
    _validate();
    _username.focus();
  }

  void _signIn() {
    final user = _user;
    _setStatus('Signing in as $user…', muted);
    _submit.text = 'Wait…';
    eventLog.note('signIn', 'request for "$user"');
    _pending = Timer(const Duration(milliseconds: 900), () {
      _pending = null;
      _submit.text = 'Sign in';
      if (user.toLowerCase() == 'admin') {
        _fail('The admin account is locked.');
      } else if (_pass.length < 6) {
        _fail('Password needs at least 6 characters.');
      } else {
        _signedInAs = user;
        _submit.text = 'Sign out';
        _setStatus('Welcome, $user.', success);
        eventLog.note('signIn', 'signed in as "$user"');
        onSignedIn(user);
      }
      _validate();
    });
    _validate();
  }

  void _fail(String reason) {
    _setStatus(reason, danger);
    eventLog.note('signIn', 'refused: $reason');
    _validate();
    _password.focus();
  }

  void _signOut() {
    eventLog.note('signIn', 'signed out "$_signedInAs"');
    _signedInAs = null;
    _submit.text = 'Sign in';
    _password.text = '';
    _setStatus('Signed out.', muted);
    _validate();
    onSignedOut();
    _username.focus();
  }

  void _setStatus(String text, Color color) {
    _status
      ..text = text
      ..textColor = color;
  }
}
