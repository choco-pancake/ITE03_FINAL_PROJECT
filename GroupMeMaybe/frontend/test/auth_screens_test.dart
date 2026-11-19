import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/signup_screen.dart';

void main() {
  testWidgets(
    'LoginScreen renders email, password, google auth, and no demo buttons',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.text('Sign In to Your Account'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // Verify quick demo buttons and topbar back arrow are removed
      expect(find.text('Demo Professor (Prof. Aivhan)'), findsNothing);
      expect(find.text('Demo Student (Carlos Mendoza)'), findsNothing);
      expect(find.text('OR QUICK DEMO LOGIN'), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    },
  );

  testWidgets(
    'SignupScreen renders role selection, google auth, and no back arrow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Instructor / Prof'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign up with Google'), findsOneWidget);

      // Student has Class Section / Block
      expect(find.text('Class Section / Block'), findsOneWidget);
      expect(find.text('Department / College'), findsNothing);

      // Top-left arrow should not exist
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      // Switch to Instructor
      await tester.tap(find.text('Instructor / Prof'));
      await tester.pumpAndSettle();

      // Instructor should NOT have Department / College field (locked to BSIT)
      expect(find.text('Department / College'), findsNothing);
      expect(find.text('Class Section / Block'), findsNothing);
    },
  );
}
