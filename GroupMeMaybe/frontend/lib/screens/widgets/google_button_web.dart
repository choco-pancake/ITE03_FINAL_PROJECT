import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget renderButton({required bool signup}) => google_web.renderButton(
  configuration: google_web.GSIButtonConfiguration(
    text: signup
        ? google_web.GSIButtonText.signupWith
        : google_web.GSIButtonText.continueWith,
    size: google_web.GSIButtonSize.large,
    minimumWidth: 320,
  ),
);
