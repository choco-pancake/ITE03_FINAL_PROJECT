import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/activity_summary.dart';
import 'package:frontend/models/grouping_activity.dart';
import 'package:frontend/screens/widgets/activity_card.dart';
import 'package:frontend/screens/widgets/summary_cards_row.dart';

void main() {
  group('Aivhan Module - GroupingActivity Model Tests', () {
    test('GroupingActivity model serialization and deserialization', () {
      final json = {
        'id': 1,
        'academic_class_id': 2,
        'class_name': 'Web Development - BSIT 2A',
        'title': 'Final Project',
        'description': 'Full-stack web application capstone',
        'grouping_method': 'hybrid',
        'group_capacity': 5,
        'number_of_groups': 6,
        'required_skills': ['Frontend Development', 'Backend Development'],
        'preferred_skills': ['UI/UX Design'],
        'min_proficiency_level': 'Intermediate',
        'min_common_hours': 5,
        'grouping_deadline': '2026-12-15T23:59:00.000',
        'student_modification_deadline': '2026-12-18T23:59:00.000',
        'status': 'open',
        'students_count': 30,
      };

      final activity = GroupingActivity.fromJson(json);

      expect(activity.id, 1);
      expect(activity.title, 'Final Project');
      expect(activity.className, 'Web Development - BSIT 2A');
      expect(activity.groupingMethod, 'hybrid');
      expect(activity.groupCapacity, 5);
      expect(activity.numberOfGroups, 6);
      expect(activity.requiredSkills, contains('Frontend Development'));
      expect(activity.preferredSkills, contains('UI/UX Design'));
      expect(activity.status, 'open');
      expect(activity.studentsCount, 30);

      final outJson = activity.toJson();
      expect(outJson['title'], 'Final Project');
      expect(outJson['grouping_method'], 'hybrid');
      expect(outJson['group_capacity'], 5);
    });

    test('ActivitySummary model parsing', () {
      final json = {
        'total': 10,
        'active': 4,
        'upcoming': 5,
        'completed': 3,
        'draft': 1,
      };

      final summary = ActivitySummary.fromJson(json);
      expect(summary.total, 10);
      expect(summary.active, 4);
      expect(summary.upcoming, 5);
      expect(summary.completed, 3);
      expect(summary.draft, 1);
    });
  });

  group('Aivhan Module - Widgets Tests', () {
    testWidgets('ActivityCard renders activity details and action buttons',
        (tester) async {
      bool viewDetailsCalled = false;
      bool editCalled = false;
      bool deleteCalled = false;

      final testActivity = GroupingActivity(
        id: 42,
        className: 'Mobile Development - BSCS 3B',
        title: 'Cross-Platform Sprint',
        groupingMethod: 'auto',
        groupCapacity: 4,
        numberOfGroups: 7,
        requiredSkills: ['Mobile App Development', 'UI/UX Design'],
        preferredSkills: ['Testing'],
        groupingDeadline: DateTime(2026, 12, 1),
        status: 'open',
        studentsCount: 28,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: testActivity,
              onViewDetails: () => viewDetailsCalled = true,
              onEdit: () => editCalled = true,
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Cross-Platform Sprint'), findsOneWidget);
      expect(find.text('Mobile Development - BSCS 3B'), findsOneWidget);
      expect(find.text('AUTO'), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('Mobile App Development'), findsOneWidget);

      // Tap View Details
      await tester.tap(find.text('View Details'));
      expect(viewDetailsCalled, isTrue);

      // Tap Edit
      await tester.tap(find.text('Edit'));
      expect(editCalled, isTrue);

      // Tap Delete
      await tester.tap(find.text('Delete'));
      expect(deleteCalled, isTrue);
    });

    testWidgets('SummaryCardsRow renders counts and invokes filter callback',
        (tester) async {
      String? selectedFilter;

      const summary = ActivitySummary(
        total: 12,
        active: 6,
        upcoming: 4,
        completed: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCardsRow(
              summary: summary,
              selectedFilter: 'all',
              onSelectFilter: (key) => selectedFilter = key,
            ),
          ),
        ),
      );

      expect(find.text('Total Activities'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Active Activities'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Upcoming Activities'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Completed Activities'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Tap on Active Activities card
      await tester.tap(find.text('Active Activities'));
      expect(selectedFilter, 'active');
    });
  });
}
