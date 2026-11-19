import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/student_classes_screen.dart';
import 'package:frontend/screens/student_dashboard_screen.dart';
import 'package:frontend/screens/student_settings_screen.dart';
import 'package:frontend/screens/student_groups_screen.dart';
import 'package:frontend/screens/widgets/student_sidebar.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  testWidgets('StudentDashboardScreen renders welcome header and metrics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: StudentDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back'), findsOneWidget);
    // Urgent deadline notification only appears when eventful (active activity with deadline < 24h)
    expect(
      find.textContaining('Urgent: Group Formation Deadline'),
      findsNothing,
    );
    expect(find.text('Enrolled Classes'), findsOneWidget);
  });

  testWidgets('StudentClassesScreen renders title and enroll button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: StudentClassesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('My Enrolled Classes'), findsOneWidget);
    expect(find.text('Enroll with Class Code'), findsWidgets);
  });

  testWidgets(
    'StudentSettingsScreen renders setup cards and technical skills',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: StudentSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('1. Personal & Academic Information'), findsOneWidget);
      expect(find.text('2. Technical Skills'), findsOneWidget);
      expect(find.text('3. Preferred Project Roles'), findsOneWidget);
      expect(find.text('4. Tools & Technologies'), findsOneWidget);
      expect(find.text('Save Profile'), findsOneWidget);
    },
  );

  testWidgets('Student welcome uses the registered first name', (tester) async {
    AuthService.currentUser = const AuthUser(
      name: 'Maria Santos',
      email: 'other.prefix@example.com',
      role: 'student',
    );
    addTearDown(() => AuthService.currentUser = null);
    await tester.pumpWidget(const MaterialApp(home: StudentDashboardScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back, Maria!'), findsOneWidget);
  });

  testWidgets('Settings opens for a saved section outside the preset list', (
    tester,
  ) async {
    AuthService.currentUser = const AuthUser(
      name: 'Maria Santos',
      email: 'maria@example.com',
      role: 'student',
      departmentOrSection: 'BSIT',
    );
    addTearDown(() => AuthService.currentUser = null);
    await tester.pumpWidget(const MaterialApp(home: StudentSettingsScreen()));
    expect(tester.takeException(), isNull);
    expect(find.text('My Profile'), findsOneWidget);
  });

  testWidgets('Groups uses the shared student sidebar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentGroupsScreen()));
    final sidebar = tester.widget<StudentSidebar>(find.byType(StudentSidebar));
    expect(sidebar.currentDestination, StudentNavDestination.groups);
  });
}
