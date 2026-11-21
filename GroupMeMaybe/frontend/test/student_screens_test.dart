import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/student_classes_screen.dart';
import 'package:frontend/screens/student_dashboard_screen.dart';
import 'package:frontend/screens/student_settings_screen.dart';
import 'package:frontend/screens/student_groups_screen.dart';
import 'package:frontend/screens/widgets/student_sidebar.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/models/class_sections.dart';
import 'package:frontend/models/profile.dart';

void main() {
  test('year levels use the requested class sections', () {
    expect(ClassSections.byYear['1st Year'], [
      '11-ITEM-01',
      '11-ITEM-02',
      '11-ITEN-01',
      '11-ITEN-02',
      '11-ITEN-03',
      '11-ITEW-01',
      '11-ITEW-02',
      '11-ITEW-03',
      '11-CSE-01',
      '11-CSE-02',
    ]);
    expect(ClassSections.byYear['2nd Year'], [
      '21-ITEM-01',
      '21-ITEM-02',
      '21-ITEN-01',
      '21-ITEN-02',
      '21-ITEN-03',
      '21-ITEW-01',
      '21-ITEW-02',
      '21-ITEW-03',
      '21-ITEW-04',
      '21-CSE-01',
    ]);
    expect(ClassSections.byYear['3rd Year'], [
      '31-ITE-01',
      '31-ITE-02',
      '31-ITE-03',
      '31-ITE-04',
      '31-ITE-05',
      '31-ITE-06',
      '31-ITE-07',
      '31-ITE-08',
      '31-ITE-09',
      '31-CSE-01',
    ]);
    expect(ClassSections.byYear['4th Year'], [
      '41-ITE-01',
      '41-ITE-02',
      '41-ITE-03',
      '41-ITE-04',
      '41-ITE-05',
      '41-CSE-01',
    ]);
  });

  test('profile details survive JSON serialization', () {
    final profile = Profile(
      name: 'Maria Santos',
      email: 'maria@example.com',
      skills: ['Flutter'],
      preferredRole: 'Frontend developer',
      availability: '21-ITEM-03',
      details: {
        'year_level': '2nd Year',
        'block': '21-ITEM-03',
        'available_days': ['Mon'],
      },
    );
    expect(Profile.fromJson(profile.toJson()).details, profile.details);
  });

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

  testWidgets('dashboard welcome stays aligned with Settings at different heights', (
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
    final shortTop = tester.getTopLeft(find.textContaining('Welcome back')).dy;

    tester.view.physicalSize = const Size(1280, 1400);
    await tester.pumpAndSettle();
    final tallTop = tester.getTopLeft(find.textContaining('Welcome back')).dy;
    expect(tallTop, closeTo(shortTop, 2));

    await tester.pumpWidget(const MaterialApp(home: StudentSettingsScreen()));
    await tester.pumpAndSettle();
    final settingsTop = tester.getTopLeft(find.text('Settings').last).dy;
    expect(tallTop, closeTo(settingsTop, 16));
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

  testWidgets('StudentClassesScreen validates class code on enrollment', (
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

    await tester.tap(find.text('Enroll with Class Code').first);
    await tester.pumpAndSettle();

    expect(find.text('Enroll Now'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'INVALID-CODE');
    await tester.tap(find.text('Enroll Now'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not found'), findsOneWidget);
  });

  testWidgets('StudentGroupsScreen accepts initialClassId and initialClassName', (
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
        home: StudentGroupsScreen(
          initialClassId: 1,
          initialClassName: 'Web Development - BSIT 2A',
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(StudentGroupsScreen), findsOneWidget);
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

      expect(find.widgetWithText(ChoiceChip, 'My Profile'), findsOneWidget);
      expect(find.text('Account & Security'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      // Profile view mode is rendered by default
      expect(find.text('1. Personal & Academic Information'), findsOneWidget);
      expect(find.text('2. Technical Skills'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Save Profile'), findsOneWidget);
    },
  );

  testWidgets('new student profile shows academic placeholders without skill search', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: StudentSettingsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Select year level'), findsOneWidget);
    expect(find.text('Select block'), findsOneWidget);
    expect(find.text('Search technical skills...'), findsNothing);
  });

  testWidgets('project role choices follow selected technical skills', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: StudentSettingsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    final skill = find.text('Frontend Development').last;
    await tester.ensureVisible(skill);
    await tester.tap(skill);
    await tester.pumpAndSettle();

    final firstRole = find.byKey(const ValueKey('1st Priority (Primary Role):null'));
    await tester.ensureVisible(firstRole);
    await tester.tap(firstRole);
    await tester.pumpAndSettle();
    expect(find.text('Frontend developer'), findsOneWidget);
    expect(find.text('Backend developer'), findsNothing);
  });

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
    expect(find.widgetWithText(ChoiceChip, 'My Profile'), findsOneWidget);
  });

  testWidgets('Groups uses the shared student sidebar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentGroupsScreen()));
    final sidebar = tester.widget<StudentSidebar>(find.byType(StudentSidebar));
    expect(sidebar.currentDestination, StudentNavDestination.groups);
  });
}
