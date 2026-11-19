import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/landing_screen.dart';

void main() {
  const studentRoles = [
    'Project Leader / Team Leader',
    'Frontend Developer',
    'Backend Developer',
    'UI / UX Designer',
    'QA / Software Tester',
  ];

  const professorCapabilities = [
    'Project Creation',
    'Skills Verification',
    'Class Enrollment',
    'Group Management',
    'Request Modification Approval',
  ];

  testWidgets(
    'shows the student roles and professor capabilities without checks',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

      for (final role in studentRoles) {
        expect(find.text(role), findsOneWidget);
      }
      for (final capability in professorCapabilities) {
        expect(find.text(capability), findsOneWidget);
      }

      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.text('Join as Student'), findsOneWidget);
      expect(find.text('Launch Team Match'), findsOneWidget);

      // Verify top right of topbar only has Log In, not redundant Sign Up
      expect(find.text('Log In'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsNothing);

      // Tap Launch Team Match and verify it navigates to Instructor Sign Up
      await tester.tap(find.text('Launch Team Match'));
      await tester.pumpAndSettle();

      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('Instructor / Prof'), findsOneWidget);
      // Department field should be removed for instructor
      expect(find.text('Department / College'), findsNothing);
    },
  );
}
