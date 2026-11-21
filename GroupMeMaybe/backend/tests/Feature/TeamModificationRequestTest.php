<?php

namespace Tests\Feature;

use App\Models\AcademicClass;
use App\Models\GroupingActivity;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class TeamModificationRequestTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_leader_requests_member_change_and_professor_approves_swap(): void
    {
        $professor = User::factory()->create(['role' => 'professor', 'email' => 'prof@univ.edu']);
        $class = AcademicClass::create([
            'name' => 'Web Systems',
            'section' => 'BSIT 2A',
            'class_code' => 'WEB201',
            'professor_id' => $professor->id,
            'students_count' => 15,
        ]);

        $leader = User::factory()->create(['role' => 'student', 'email' => 'leader@univ.edu', 'name' => 'Maria Leader']);
        $outgoing = User::factory()->create(['role' => 'student', 'email' => 'outgoing@univ.edu', 'name' => 'Bob Outgoing']);
        $incoming = User::factory()->create(['role' => 'student', 'email' => 'incoming@univ.edu', 'name' => 'Charlie Incoming']);
        $class->students()->attach([$leader->id, $outgoing->id, $incoming->id]);
        Profile::create([
            'name' => $incoming->name, 'email' => $incoming->email,
            'skills' => [], 'preferred_role' => 'Developer',
            'availability' => 'Weekdays', 'details' => ['is_complete' => true],
        ]);

        $activity = GroupingActivity::create([
            'title' => 'Web App Project',
            'academic_class_id' => $class->id,
            'class_name' => 'Web Systems',
            'required_skills' => ['React', 'Laravel'],
            'group_capacity' => 4,
            'number_of_groups' => 2,
            'grouping_method' => 'student_formed',
            'grouping_deadline' => now()->addDays(7),
            'status' => 'active',
            'formed_teams' => [
                [
                    'name' => 'Code Ninjas',
                    'leader_email' => 'leader@univ.edu',
                    'leader_name' => 'Maria Leader',
                    'status' => 'Submitted for Evaluation',
                    'submitted_at' => now()->toIso8601String(),
                    'balance_score' => 70,
                    'members' => [
                        [
                            'name' => 'Maria Leader',
                            'email' => 'leader@univ.edu',
                            'role' => 'Project Manager (Leader)',
                            'status' => 'accepted',
                            'is_leader' => true,
                            'skills' => ['Laravel'],
                        ],
                        [
                            'name' => 'Bob Outgoing',
                            'email' => 'outgoing@univ.edu',
                            'role' => 'Frontend Developer',
                            'status' => 'accepted',
                            'is_leader' => false,
                            'skills' => ['HTML'],
                        ],
                    ],
                ],
            ],
        ]);

        // 1. Leader requests member change
        $responseRequest = $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/request-member-change", [
            'team_name' => 'Code Ninjas',
            'outgoing_student_email' => 'outgoing@univ.edu',
            'outgoing_student_name' => 'Bob Outgoing',
            'incoming_student_email' => 'incoming@univ.edu',
            'incoming_student_name' => 'Charlie Incoming',
            'reason' => 'Schedule conflict and complementary React skills needed',
        ]);
        $responseRequest->assertOk();
        $this->assertTrue($responseRequest->json('success'));

        $reqId = $responseRequest->json('request.id');
        $this->assertNotNull($reqId);

        // Verify outgoing member marked as under_review
        $activity->refresh();
        $this->assertEquals('under_review', $activity->formed_teams[0]['members'][1]['status']);

        // 2. Professor lists modification requests
        $responseList = $this->actingAs($professor)->getJson('/api/modification-requests');
        $responseList->assertOk();
        $this->assertCount(1, $responseList->json('requests'));
        $this->assertEquals('Bob Outgoing', $responseList->json('requests.0.outgoing_student_name'));
        $this->assertEquals('Charlie Incoming', $responseList->json('requests.0.incoming_student_name'));

        // 3. Professor approves swap
        $responseDecision = $this->actingAs($professor)->postJson("/api/modification-requests/{$reqId}/decision", [
            'decision' => 'approved',
            'notes' => 'Approved change based on schedule availability',
        ]);
        $responseDecision->assertOk();

        // Verify incoming student replaced outgoing student in team
        $activity->refresh();
        $team = $activity->formed_teams[0];
        $this->assertEquals('Approved', $team['status']);
        $this->assertEquals('Charlie Incoming', $team['members'][1]['name']);
        $this->assertEquals('incoming@univ.edu', $team['members'][1]['email']);
        $this->assertEquals('Frontend Developer', $team['members'][1]['role']);
    }
}
