import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/signup_screen.dart';
import 'package:frontend/screens/widgets/landing_top_bar.dart';
import 'package:frontend/screens/widgets/student_sidebar.dart';

void main() {
  testWidgets(
    'LoginScreen renders email, password, google auth, and no demo buttons or topbar signup',
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

      // Verify quick demo buttons and topbar back arrow/signup are removed
      expect(find.text('Demo Professor (Prof. Aivhan)'), findsNothing);
      expect(find.text('Demo Student (Carlos Mendoza)'), findsNothing);
      expect(find.text('OR QUICK DEMO LOGIN'), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(
        find.descendant(
          of: find.byType(LandingTopBar),
          matching: find.text('Sign Up'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'SignupScreen renders role selection, split name fields, year/section dropdowns, and instructor faculty code',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Instructor / Prof'), findsOneWidget);

      // Split name fields
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Middle Name (Optional)'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Full Name'), findsNothing);

      // Student Year Level and Section dropdowns
      expect(find.text('Year Level'), findsOneWidget);
      expect(find.text('Class Section / Block'), findsOneWidget);
      expect(find.text('Preferred Project Role'), findsOneWidget);

      expect(find.text('Create Student Account'), findsOneWidget);
      expect(find.text('Sign up with Google'), findsOneWidget);

      // Faculty code should not be visible for student
      expect(find.text('Faculty Authorization Code'), findsNothing);

      // Top-left arrow should not exist
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      // Topbar should not have a Sign Up button
      expect(
        find.descendant(
          of: find.byType(LandingTopBar),
          matching: find.text('Sign Up'),
        ),
        findsNothing,
      );

      // Switch to Instructor
      await tester.tap(find.text('Instructor / Prof'));
      await tester.pumpAndSettle();

      // Instructor should have Faculty Authorization Code
      expect(find.text('Faculty Authorization Code'), findsOneWidget);
      expect(find.text('Create Instructor Account'), findsOneWidget);

      // Student-specific fields should be hidden for Instructor
      expect(find.text('Year Level'), findsNothing);
      expect(find.text('Class Section / Block'), findsNothing);
      expect(find.text('Preferred Project Role'), findsNothing);
    },
  );

  testWidgets(
    'StudentSidebar renders STUDENT PORTAL badge and opens confirmation modal on log out',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudentSidebar(
              currentDestination: StudentNavDestination.dashboard,
            ),
          ),
        ),
      );

      expect(find.text('STUDENT PORTAL'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Classes'), findsOneWidget);
      expect(find.text('Groups (Teams)'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Find the logout icon button
      final logoutBtn = find.byTooltip('Sign Out');
      expect(logoutBtn, findsOneWidget);

      // Tap Sign Out icon
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Verify confirmation modal appears
      expect(find.text('Confirm Sign Out'), findsOneWidget);
      expect(
        find.text('Are you sure you want to log out of GroupMeMaybe?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // Tap Cancel to dismiss
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Sign Out'), findsNothing);
    },
  );
}
