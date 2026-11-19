import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/signup_screen.dart';

void main() {
  testWidgets('LoginScreen renders email, password fields and demo buttons', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Sign In to Your Account'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Demo Professor (Prof. Aivhan)'), findsOneWidget);
    expect(find.text('Demo Student (Carlos Mendoza)'), findsOneWidget);
  });

  testWidgets('SignupScreen renders role selection and inputs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    expect(find.text('Create Your Account'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Instructor / Prof'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
