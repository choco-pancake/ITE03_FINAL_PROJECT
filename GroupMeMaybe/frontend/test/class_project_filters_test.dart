import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/academic_class.dart';
import 'package:frontend/models/grouping_activity.dart';
import 'package:frontend/screens/professor_class_detail_screen.dart';
import 'package:frontend/screens/student_classes_screen.dart';
import 'package:frontend/services/activity_service.dart';

class _ClassService extends ActivityService {
  _ClassService({required this.professor});

  final bool professor;
  final academicClass = AcademicClass(
    id: 1, name: 'Systems', section: '21-ITEM-03', classCode: 'SYS123',
    studentCount: 1, activitiesCount: 2,
  );

  List<GroupingActivity> get projects => [
    GroupingActivity(
      id: 1, academicClassId: 1, className: academicClass.displayName,
      title: 'Submitted Project', groupingMethod: 'student_formed',
      requiredSkills: const ['PHP'], groupingDeadline: DateTime(2027, 2, 1),
    ),
    GroupingActivity(
      id: 2, academicClassId: 1, className: academicClass.displayName,
      title: 'Unsubmitted Project', groupingMethod: 'auto',
      requiredSkills: const ['Dart'], groupingDeadline: DateTime(2027, 2, 1),
    ),
  ];

  @override
  Future<List<AcademicClass>> getClasses() async => [academicClass];

  @override
  Future<List<Map<String, dynamic>>> getClassStudents(int classId) async => [
    {'id': 7, 'name': 'Maria Santos', 'student_id': '21-1234-567', 'preferred_role': 'Frontend Developer'},
  ];

  @override
  Future<List<GroupingActivity>> getActivities({
    String? status, String? search, int? classId,
  }) async => projects;

  @override
  Future<Map<int, Map<String, dynamic>>> getProjectStatuses(int classId) async =>
      professor
          ? {
              1: {'submitted_group_count': 1, 'graded_group_count': 1, 'graded': true},
              2: {'submitted_group_count': 0, 'graded_group_count': 0, 'graded': false},
            }
          : {
              1: {'submitted': true, 'graded': true, 'grade': '95.00',
                  'team_name': 'Team A', 'file_name': 'report.pdf', 'can_submit': false},
              2: {'submitted': false, 'graded': false, 'can_submit': false},
            };
}

void main() {
  testWidgets('student class filters projects by submission and grade', (tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      home: StudentClassesScreen(service: _ClassService(professor: false)),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Systems').first);
    await tester.pumpAndSettle();
    expect(find.text('Enrolled Classmates'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('Submitted Project'), findsOneWidget);
    expect(find.text('Unsubmitted Project'), findsOneWidget);
    expect(find.byTooltip('Unenroll from class'), findsNothing);
    await tester.tap(find.text('Incomplete'));
    await tester.pumpAndSettle();
    expect(find.text('Submitted Project'), findsNothing);
    expect(find.text('Unsubmitted Project'), findsOneWidget);
  });

  testWidgets('professor class shows roster and graded project filter', (tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final service = _ClassService(professor: true);
    await tester.pumpWidget(MaterialApp(
      home: ProfessorClassDetailScreen(academicClass: service.academicClass, service: service),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('Submitted Project'), findsOneWidget);
    expect(find.text('Unsubmitted Project'), findsOneWidget);
    await tester.tap(find.text('Graded'));
    await tester.pumpAndSettle();
    expect(find.text('Submitted Project'), findsOneWidget);
    expect(find.text('Unsubmitted Project'), findsNothing);
  });
}
