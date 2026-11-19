import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_button_stub.dart'
    if (dart.library.js_interop) 'google_button_web.dart'
    as google_button;

/// Google's web button provides the account picker and a signed ID token.
class GoogleAuthButton extends StatefulWidget {
  const GoogleAuthButton({
    super.key,
    required this.onIdToken,
    required this.onError,
    this.signup = false,
    this.isBusy = false,
  });

  final Future<void> Function(String idToken) onIdToken;
  final ValueChanged<String> onError;
  final bool signup;
  final bool isBusy;

  @override
  State<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<GoogleAuthButton> {
  static const _clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static Future<void>? _initialization;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && _clientId.isNotEmpty) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    try {
      _initialization ??= GoogleSignIn.instance.initialize(clientId: _clientId);
      await _initialization;
      if (!mounted) return;
      _subscription = GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            final token = event.user.authentication.idToken;
            if (token == null || token.isEmpty) {
              widget.onError(
                'Google did not return an ID token. Please try again.',
              );
            } else {
              widget.onIdToken(token);
            }
          }
        },
        onError: (Object error) =>
            widget.onError('Google sign-in failed: $error'),
      );
      setState(() => _ready = true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Google sign-in could not start: $error');
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Text('Google sign-in is available in the web app.');
    }
    if (_clientId.isEmpty) {
      return const Text(
        'Google sign-in is not configured. Set GOOGLE_CLIENT_ID to enable it.',
        textAlign: TextAlign.center,
      );
    }
    if (_error != null) return Text(_error!, textAlign: TextAlign.center);
    if (!_ready) return const Center(child: CircularProgressIndicator());

    return IgnorePointer(
      ignoring: widget.isBusy,
      child: Center(child: google_button.renderButton(signup: widget.signup)),
    );
  }
}
