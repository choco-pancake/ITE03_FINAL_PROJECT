import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scarcity_report.dart';
import 'package:frontend/screens/student_groups_screen.dart';

void main() {
  group('ScarcityReport Model Tests', () {
    test('ScarcityReport parses JSON correctly', () {
      final json = {
        'activity_id': 1,
        'activity_title': 'Final Capstone Project',
        'class_name': 'Web Development - BSIT 2A',
        'grouping_method': 'hybrid',
        'total_students': 30,
        'number_of_groups': 6,
        'group_capacity': 5,
        'skills_distribution': [
          {
            'skill': 'Frontend Development',
            'count': 18,
            'total_students': 30,
            'percentage': 60.0,
            'is_required': true,
            'is_scarce': false,
          },
          {
            'skill': 'Backend Development',
            'count': 5,
            'total_students': 30,
            'percentage': 16.7,
            'is_required': true,
            'is_scarce': true,
          },
        ],
        'scarce_skills': [
          {
            'skill': 'Backend Development',
            'count': 5,
            'needed': 6,
            'deficit': 1,
          }
        ],
        'has_scarcity': true,
        'unassigned_students_count': 6,
        'message': 'Scarce skills detected.',
      };

      final report = ScarcityReport.fromJson(json);

      expect(report.activityId, 1);
      expect(report.activityTitle, 'Final Capstone Project');
      expect(report.hasScarcity, isTrue);
      expect(report.skillsDistribution.length, 2);
      expect(report.skillsDistribution.first.skill, 'Frontend Development');
      expect(report.skillsDistribution.first.isScarce, isFalse);
      expect(report.scarceSkills.length, 1);
      expect(report.scarceSkills.first.skill, 'Backend Development');
      expect(report.scarceSkills.first.deficit, 1);
    });
  });

  group('StudentCandidate and Student Groups View Tests', () {
    test('StudentCandidate model stores details and state', () {
      final candidate = StudentCandidate(
        id: 1,
        name: 'Bea Cruz',
        block: 'BSIT 2A',
        avatarUrl: 'B',
        skills: ['Backend Development', 'Database Management'],
        interests: ['Web Development'],
        availability: 'Weekdays after 3 PM',
        commonHours: 5,
        compatibilityScore: 92.5,
        preferredRole: 'Backend Developer',
      );

      expect(candidate.name, 'Bea Cruz');
      expect(candidate.block, 'BSIT 2A');
      expect(candidate.compatibilityScore, 92.5);
      expect(candidate.isInvited, isFalse);

      candidate.isInvited = true;
      expect(candidate.isInvited, isTrue);
    });

    testWidgets('StudentGroupsScreen renders without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentGroupsScreen(),
        ),
      );

      // Loading state or initial render
      expect(find.byType(StudentGroupsScreen), findsOneWidget);
    });
  });
}
