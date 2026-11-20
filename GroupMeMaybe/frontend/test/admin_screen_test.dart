import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/widgets/admin_sidebar.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  test('AdminOverview model parses json properly', () {
    final json = {
      'total_faculty': 5,
      'total_students': 60,
      'total_classes': 4,
      'total_activities': 8,
      'active_faculty_code': 'BSIT-FACULTY-2026',
      'semester': '1st Semester',
      'academic_year': '2026-2027',
      'semester_mode': 'auto',
      'manual_semester': '1st Semester',
      'manual_academic_year': '2026-2027',
    };

    final overview = AdminOverview.fromJson(json);
    expect(overview.totalFaculty, 5);
    expect(overview.totalStudents, 60);
    expect(overview.totalClasses, 4);
    expect(overview.totalActivities, 8);
    expect(overview.activeFacultyCode, 'BSIT-FACULTY-2026');
    expect(overview.semester, '1st Semester');
    expect(overview.academicYear, '2026-2027');
    expect(overview.semesterMode, 'auto');
  });

  test('AuthUser detects admin role', () {
    final adminUser = AuthUser(
      name: 'Dean Eleanor Vance',
      email: 'admin@university.edu',
      role: 'admin',
    );
    expect(adminUser.isAdmin, isTrue);
    expect(adminUser.isProfessor, isFalse);
    expect(adminUser.isStudent, isFalse);

    final profUser = AuthUser(
      name: 'Prof. Aivhan',
      email: 'prof@university.edu',
      role: 'professor',
    );
    expect(profUser.isAdmin, isFalse);
    expect(profUser.isProfessor, isTrue);
    expect(profUser.isStudent, isFalse);

    final studentUser = AuthUser(
      name: 'Carlos Mendoza',
      email: 'carlos@student.edu',
      role: 'student',
    );
    expect(studentUser.isAdmin, isFalse);
    expect(studentUser.isProfessor, isFalse);
    expect(studentUser.isStudent, isTrue);
  });

  testWidgets('AdminSidebar renders all destinations and ADMIN PORTAL badge',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminSidebar(
            currentDestination: AdminNavDestination.overview,
          ),
        ),
      ),
    );

    expect(find.text('GroupMeMaybe'), findsOneWidget);
    expect(find.text('ADMIN PORTAL'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Faculty & Codes'), findsOneWidget);
    expect(find.text('Academic Terms'), findsOneWidget);
    expect(find.text('Students Directory'), findsOneWidget);
  });
}
