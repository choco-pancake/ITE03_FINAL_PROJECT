import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/professor_activities_screen.dart';
import 'package:frontend/screens/professor_classes_screen.dart';
import 'package:frontend/screens/professor_dashboard_screen.dart';
import 'package:frontend/screens/professor_evaluation_screen.dart';
import 'package:frontend/screens/professor_settings_screen.dart';
import 'package:frontend/screens/widgets/professor_sidebar.dart';
import 'package:frontend/screens/widgets/activity_form_dialog.dart';
import 'package:frontend/screens/widgets/student_profile_dialog.dart';
import 'package:frontend/models/student_record.dart';
import 'package:frontend/services/student_record_service.dart';

class _FakeStudentRecordService extends StudentRecordService {
  int? unenrolledId;

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
      classEnrollments: [{'id': 1, 'name': 'Web Development', 'section': 'BSIT 2A'}],
    ),
  ];

  @override
  Future<void> unenrollStudent(int classId, int studentId) async {
    unenrolledId = studentId;
  }
}

void main() {
  testWidgets('activity form shares skill options and validates MM-DD-YYYY', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ActivityFormDialog(onSaved: () {}),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, 'Frontend Development'), findsNWidgets(2));
    final frontendChip = find.widgetWithText(FilterChip, 'Frontend Development').first;
    await tester.ensureVisible(frontendChip);
    await tester.tap(frontendChip);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'Frontend Development'), findsOneWidget);

    final deadlineField = find.byType(TextFormField).last;
    expect(find.text('MM-DD-YYYY'), findsOneWidget);
    final deadlineDecoration = tester.widget<InputDecorator>(
      find.ancestor(of: find.text('MM-DD-YYYY'), matching: find.byType(InputDecorator)).first,
    );
    expect(deadlineDecoration.decoration.hintStyle?.color, const Color(0xFF94A3B8));
    await tester.ensureVisible(deadlineField);
    await tester.enterText(deadlineField, '02-30-2027');
    expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
    await tester.pump();
    expect(find.text('Enter a date as MM-DD-YYYY'), findsOneWidget);

    await tester.ensureVisible(find.text('Student-Made'));
    await tester.tap(find.text('Student-Made'));
    await tester.pumpAndSettle();
    expect(find.text('Group Submission Deadline'), findsOneWidget);
    expect(find.text('Project Submission Deadline'), findsOneWidget);
    expect(find.text('MM-DD-YYYY'), findsNWidgets(2));
  });

  testWidgets('ProfessorSidebar renders all 4 navigation destinations', (
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
    expect(find.text('Projects'), findsNothing);
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

      // Sidebar (Projects is removed from sidebar; Classes is the active destination)
      expect(find.text('Classes'), findsOneWidget);
      expect(find.text('Projects'), findsNothing);

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
    'ProfessorEvaluationScreen can only unenroll an enrolled student',
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
      expect(find.text('BSIT 2A'), findsOneWidget);
      // Tapping the block card opens the students in that block
      await tester.tap(find.text('BSIT 2A'));
      await tester.pumpAndSettle();

      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('New Request'), findsNothing);
      // Tapping the student opens their profile dialog
      await tester.tap(find.text('Maria Santos'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentProfileDialog), findsOneWidget);
      // Close the profile dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Edit Student Record'), findsNothing);
      await tester.tap(find.byTooltip('Unenroll from class'));
      await tester.pumpAndSettle();
      expect(find.text('Unenroll student?'), findsOneWidget);
      await tester.tap(find.text('Unenroll'));
      await tester.pumpAndSettle();
      expect(service.unenrolledId, 7);
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
