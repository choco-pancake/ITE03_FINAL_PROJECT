import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/grouping_activity.dart';
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
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: StudentGroupsScreen(),
        ),
      );

      // Loading state or initial render
      expect(find.byType(StudentGroupsScreen), findsOneWidget);
    });

    test('GroupingActivity parses formed_teams JSON dynamically', () {
      final json = {
        'id': 5,
        'title': 'Automated Integration Testing Activity',
        'class_name': 'Web Development - BSIT 2A',
        'grouping_method': 'auto',
        'group_capacity': 5,
        'number_of_groups': 6,
        'required_skills': ['Software Testing and Quality Assurance', 'Backend Development'],
        'preferred_skills': ['Technical Documentation'],
        'min_proficiency_level': 'Intermediate',
        'min_common_hours': 4,
        'grouping_deadline': '2026-12-20T18:00:00.000000Z',
        'status': 'completed',
        'students_count': 30,
        'formed_teams': [
          {
            'name': 'Team Alpha Synthetix',
            'is_auto_assigned': true,
            'leader_email': 'alex.santos@student.edu',
            'members': [
              {
                'name': 'Alex Santos (You)',
                'email': 'alex.santos@student.edu',
                'role': 'Team Leader & Developer',
                'block': 'BSIT 2A',
                'avatar': 'A',
                'is_leader': true,
              },
              {
                'name': 'Dani Garcia',
                'email': 'dani.garcia@student.edu',
                'role': 'QA Specialist',
                'block': 'BSIT 2A',
                'avatar': 'D',
                'is_leader': false,
              },
            ],
          },
        ],
      };

      final activity = GroupingActivity.fromJson(json);

      expect(activity.id, 5);
      expect(activity.status, 'completed');
      expect(activity.formedTeams, isNotNull);
      expect(activity.formedTeams!.length, 1);

      final firstTeam = activity.formedTeams!.first as Map<String, dynamic>;
      expect(firstTeam['name'], 'Team Alpha Synthetix');
      expect(firstTeam['is_auto_assigned'], true);

      final members = firstTeam['members'] as List;
      expect(members.length, 2);
      expect(members[0]['name'], 'Alex Santos (You)');
      expect(members[0]['is_leader'], true);
    });
  });
}
