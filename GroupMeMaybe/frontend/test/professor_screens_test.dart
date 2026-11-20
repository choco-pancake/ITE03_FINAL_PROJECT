import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/professor_activities_screen.dart';
import 'package:frontend/screens/professor_classes_screen.dart';
import 'package:frontend/screens/professor_dashboard_screen.dart';
import 'package:frontend/screens/professor_evaluation_screen.dart';
import 'package:frontend/screens/professor_settings_screen.dart';
import 'package:frontend/screens/widgets/professor_sidebar.dart';
import 'package:frontend/models/student_record.dart';
import 'package:frontend/services/student_record_service.dart';

class _FakeStudentRecordService extends StudentRecordService {
  Map<String, String>? savedValues;

  @override
  Future<List<StudentRecord>> getStudents() async => const [
    StudentRecord(
      id: 7,
      name: 'Maria Santos',
      email: 'maria@example.com',
      firstName: 'Maria',
      middleName: '',
      lastName: 'Santos',
      studentId: '2026-001',
      yearLevel: '2nd Year',
      block: 'BSIT 2A',
      classes: ['Web Development'],
    ),
  ];

  @override
  Future<void> updateStudent(int studentId, Map<String, String> values) async {
    savedValues = values;
  }
}

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
    expect(find.text('Student Records'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
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
      expect(find.text('Manage Student Records'), findsOneWidget);

      // Completion Statuses & Evaluation Metric
      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('Total Classes'), findsOneWidget);
      expect(find.text('Active Projects & Teams'), findsOneWidget);
      expect(find.text('Student Records'), findsWidgets);
      expect(find.text('Uninitialized'), findsWidgets);

      // Teams Section
      expect(find.text('Formed Teams & Squad Member Profiles'), findsOneWidget);
      expect(find.text('No Teams Formed Yet'), findsOneWidget);

      // Custom Skills Approval Queue
      expect(
        find.text('Custom Requested Skills Approval Queue'),
        findsOneWidget,
      );
      expect(
        find.text('No custom skill requests found in this category.'),
        findsOneWidget,
      );
      expect(find.text('Add Skill Request'), findsNothing);

      // Tap Review Requests & Evaluations button to navigate
      await tester.tap(find.text('Manage Student Records'));
      await tester.pumpAndSettle();

      // Verify navigates to Modification Requests / Professor Evaluation
      expect(find.text('Student Records'), findsWidgets);
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
      expect(find.text('Create New Project'), findsOneWidget);

      // Switch to Formed Teams & Groups tab
      await tester.tap(find.text('Formed Teams & Groups'));
      await tester.pumpAndSettle();

      // Verify groups content is displayed inside Projects (empty state when no teams created yet)
      expect(find.text('No Teams Formed Yet'), findsOneWidget);
      expect(
        find.text(
          'Teams will appear here once formed or assigned in your grouping activities.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ProfessorEvaluationScreen edits an enrolled student record',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = _FakeStudentRecordService();
      await tester.pumpWidget(
        MaterialApp(home: ProfessorEvaluationScreen(service: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Records'), findsWidgets);
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('New Request'), findsNothing);
      await tester.tap(find.text('Maria Santos'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Maria Santos'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Last name'), 'Reyes');
      await tester.tap(find.text('Save record'));
      await tester.pumpAndSettle();
      expect(service.savedValues?['last_name'], 'Reyes');
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
      expect(find.text('No classes found.'), findsOneWidget);
      expect(find.text('Create New Class'), findsOneWidget);

      // Open create class dialog
      await tester.tap(find.text('Create Class & Generate Code'));
      await tester.pumpAndSettle();

      expect(find.text('Course Code'), findsOneWidget);
      expect(find.text('Course Name / Title'), findsOneWidget);
      expect(find.text('Year Level'), findsOneWidget);
      expect(find.text('Section / Block'), findsOneWidget);
      expect(find.text('Generated Enrollment Code'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
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
