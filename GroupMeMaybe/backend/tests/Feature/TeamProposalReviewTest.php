<?php

namespace Tests\Feature;

use App\Models\AcademicClass;
use App\Models\AppNotification;
use App\Models\GroupingActivity;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class TeamProposalReviewTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_professor_can_approve_team_proposal(): void
    {
        $professor = User::factory()->create(['role' => 'professor', 'email' => 'prof1@univ.edu']);
        $class = AcademicClass::create([
            'name' => 'Data Structures',
            'section' => 'BSCS 2A',
            'class_code' => 'DS101',
            'professor_id' => $professor->id,
            'students_count' => 10,
        ]);

        $student1 = User::factory()->create(['role' => 'student', 'email' => 's1@univ.edu', 'name' => 'Student One']);
        $student2 = User::factory()->create(['role' => 'student', 'email' => 's2@univ.edu', 'name' => 'Student Two']);

        $activity = GroupingActivity::create([
            'title' => 'Tree Project',
            'academic_class_id' => $class->id,
            'class_name' => 'Data Structures',
            'required_skills' => ['C++', 'Algorithms'],
            'group_capacity' => 2,
            'grouping_method' => 'student_formed',
            'grouping_deadline' => now()->addDays(7),
            'status' => 'active',
            'formed_teams' => [
                [
                    'name' => 'Alpha Team',
                    'leader_email' => 's1@univ.edu',
                    'status' => 'Submitted for Evaluation',
                    'balance_score' => 85,
                    'members' => [
                        ['name' => 'Student One', 'email' => 's1@univ.edu', 'status' => 'accepted'],
                        ['name' => 'Student Two', 'email' => 's2@univ.edu', 'status' => 'accepted'],
                    ],
                ],
            ],
        ]);

        $response = $this->actingAs($professor)->postJson("/api/activities/{$activity->id}/teams/review", [
            'team_name' => 'Alpha Team',
            'decision' => 'approved',
            'professor_notes' => 'Great squad composition, approved!',
        ]);

        $response->assertStatus(200);
        $this->assertEquals('Approved', $response->json('team.status'));
        $this->assertEquals('Great squad composition, approved!', $response->json('team.professor_notes'));

        // Notification created for members
        $this->assertDatabaseHas('app_notifications', [
            'user_id' => $student1->id,
            'kind' => 'team_approved',
        ]);
        $this->assertDatabaseHas('app_notifications', [
            'user_id' => $student2->id,
            'kind' => 'team_approved',
        ]);
    }

    public function test_professor_can_decline_team_proposal_with_scarcity_notes(): void
    {
        $professor = User::factory()->create(['role' => 'professor', 'email' => 'prof2@univ.edu']);
        $class = AcademicClass::create([
            'name' => 'Mobile Dev',
            'section' => 'BSIT 3B',
            'class_code' => 'MOB301',
            'professor_id' => $professor->id,
            'students_count' => 10,
        ]);

        $student = User::factory()->create(['role' => 'student', 'email' => 'lead@univ.edu', 'name' => 'Lead Student']);

        $activity = GroupingActivity::create([
            'title' => 'Flutter App',
            'academic_class_id' => $class->id,
            'class_name' => 'Mobile Dev',
            'required_skills' => ['Flutter', 'UI/UX Design'],
            'group_capacity' => 2,
            'grouping_method' => 'student_formed',
            'grouping_deadline' => now()->addDays(7),
            'status' => 'active',
            'formed_teams' => [
                [
                    'name' => 'Beta Team',
                    'leader_email' => 'lead@univ.edu',
                    'status' => 'Submitted for Evaluation',
                    'scarcity_report' => [
                        'is_scarce' => true,
                        'scarce_skills' => ['UI/UX Design'],
                    ],
                    'members' => [
                        ['name' => 'Lead Student', 'email' => 'lead@univ.edu', 'status' => 'accepted'],
                    ],
                ],
            ],
        ]);

        $response = $this->actingAs($professor)->postJson("/api/activities/{$activity->id}/teams/review", [
            'team_name' => 'Beta Team',
            'decision' => 'declined',
            'professor_notes' => 'Please recruit a teammate with UI/UX Design skill.',
        ]);

        $response->assertStatus(200);
        $this->assertEquals('Declined', $response->json('team.status'));
        $this->assertEquals('Please recruit a teammate with UI/UX Design skill.', $response->json('team.professor_notes'));

        $this->assertDatabaseHas('app_notifications', [
            'user_id' => $student->id,
            'kind' => 'team_declined',
        ]);
    }

    public function test_non_professor_cannot_review_team_proposal(): void
    {
        $professor = User::factory()->create(['role' => 'professor', 'email' => 'owner@univ.edu']);
        $otherProf = User::factory()->create(['role' => 'professor', 'email' => 'other@univ.edu']);
        $student = User::factory()->create(['role' => 'student', 'email' => 'student@univ.edu']);

        $class = AcademicClass::create([
            'name' => 'Networks',
            'section' => 'BSCS 3A',
            'class_code' => 'NET301',
            'professor_id' => $professor->id,
            'students_count' => 10,
        ]);

        $activity = GroupingActivity::create([
            'title' => 'Routing Project',
            'academic_class_id' => $class->id,
            'class_name' => 'Networks',
            'required_skills' => ['Cisco'],
            'group_capacity' => 2,
            'grouping_method' => 'student_formed',
            'grouping_deadline' => now()->addDays(7),
            'status' => 'active',
            'formed_teams' => [
                [
                    'name' => 'Gamma Team',
                    'leader_email' => 'student@univ.edu',
                    'status' => 'Submitted for Evaluation',
                    'members' => [],
                ],
            ],
        ]);

        // Student cannot review
        $res1 = $this->actingAs($student)->postJson("/api/activities/{$activity->id}/teams/review", [
            'team_name' => 'Gamma Team',
            'decision' => 'approved',
        ]);
        $res1->assertStatus(403);

        // Different professor cannot review
        $res2 = $this->actingAs($otherProf)->postJson("/api/activities/{$activity->id}/teams/review", [
            'team_name' => 'Gamma Team',
            'decision' => 'approved',
        ]);
        $res2->assertStatus(403);
    }
}
