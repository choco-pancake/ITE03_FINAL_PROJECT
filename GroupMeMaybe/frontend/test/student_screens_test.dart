import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/student_classes_screen.dart';
import 'package:frontend/screens/student_dashboard_screen.dart';
import 'package:frontend/screens/student_settings_screen.dart';

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
    expect(
      find.textContaining('Urgent: Group Formation Deadline'),
      findsOneWidget,
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
}
