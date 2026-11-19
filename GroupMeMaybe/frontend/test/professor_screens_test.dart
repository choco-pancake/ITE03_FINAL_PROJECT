import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/professor_activities_screen.dart';
import 'package:frontend/screens/professor_classes_screen.dart';
import 'package:frontend/screens/professor_dashboard_screen.dart';
import 'package:frontend/screens/professor_evaluation_screen.dart';
import 'package:frontend/screens/professor_settings_screen.dart';
import 'package:frontend/screens/widgets/professor_sidebar.dart';

void main() {
  testWidgets('ProfessorSidebar renders all 5 navigation destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfessorSidebar(
            currentDestination: ProfessorNavDestination.dashboard,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FACULTY PORTAL'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Classes'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Evaluation'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Prof. Aivhan'), findsOneWidget);
  });

  testWidgets(
    'ProfessorDashboardScreen renders completion statuses, teams, unassigned, and evaluation shortcut',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: ProfessorDashboardScreen()),
      );
      await tester.pumpAndSettle();

      // Welcome Header
      expect(find.textContaining('Welcome, Prof. Aivhan!'), findsOneWidget);
      expect(find.text('Review Requests & Evaluations'), findsOneWidget);

      // Completion Statuses & Evaluation Metric
      expect(find.text('Complete Profiles'), findsOneWidget);
      expect(find.text('Incomplete Profiles'), findsOneWidget);
      expect(find.text('Evaluation & Requests'), findsOneWidget);
      expect(find.text('Uninitialized'), findsWidgets);

      // Teams Section
      expect(find.text('Formed Teams & Squad Member Profiles'), findsOneWidget);
      expect(find.text('Alpha Squad'), findsWidgets);

      // Unassigned Students Section
      expect(
        find.text('Manage Unassigned Students (Past Deadline)'),
        findsOneWidget,
      );
      expect(find.text('Assign to Group'), findsWidgets);

      // Custom Skills Approval Queue
      expect(
        find.text('Custom Requested Skills Approval Queue'),
        findsOneWidget,
      );
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Approve'), findsWidgets);

      // Tap Review Requests & Evaluations button to navigate
      await tester.tap(find.text('Review Requests & Evaluations'));
      await tester.pumpAndSettle();

      // Verify navigates to Modification Requests / Professor Evaluation
      expect(find.text('Modification Requests'), findsOneWidget);
    },
  );

  testWidgets(
    'ProfessorActivitiesScreen renders Activities and Groups tabs with sidebar',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: ProfessorActivitiesScreen()),
      );
      await tester.pumpAndSettle();

      // Sidebar
      expect(find.text('Projects'), findsOneWidget);

      // Tabs
      expect(find.text('Activities & Milestones'), findsOneWidget);
      expect(find.text('Formed Teams & Groups'), findsOneWidget);

      // Initial tab content: Activities
      expect(find.text('+ Create Activity'), findsOneWidget);

      // Switch to Formed Teams & Groups tab
      await tester.tap(find.text('Formed Teams & Groups'));
      await tester.pumpAndSettle();

      // Verify groups content is displayed inside Projects
      expect(find.text('Alpha Squad'), findsOneWidget);
      expect(find.text('Carlos Mendoza'), findsOneWidget);
    },
  );

  testWidgets(
    'ProfessorEvaluationScreen renders with sidebar and modification requests',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: ProfessorEvaluationScreen()),
      );
      await tester.pumpAndSettle();

      // Sidebar
      expect(find.text('Evaluation'), findsOneWidget);

      // Main Content
      expect(find.text('Modification Requests'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Under review'), findsWidgets);
    },
  );

  testWidgets(
    'ProfessorClassesScreen renders course sections and class codes',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: ProfessorClassesScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Course Sections & Class Codes'), findsOneWidget);
      expect(find.text('Create Class & Generate Code'), findsOneWidget);
      expect(find.text('ITE 03 - Object Oriented Programming'), findsOneWidget);
      expect(find.text('OOP3A1'), findsOneWidget);
    },
  );

  testWidgets(
    'ProfessorSettingsScreen renders faculty details and toggle controls',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: ProfessorSettingsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Faculty Settings'), findsOneWidget);
      expect(find.text('Instructor Profile Details'), findsOneWidget);
      expect(find.text('Deadline Reminders'), findsOneWidget);
      expect(find.text('Save Settings'), findsOneWidget);
    },
  );
}
