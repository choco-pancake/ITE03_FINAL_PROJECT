<?php

namespace Tests\Feature;

use App\Models\AcademicClass;
use App\Models\GroupingActivity;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class GroupingActivityJoinTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_student_joins_team_as_pending_and_leader_accepts_or_declines(): void
    {
        $professor = User::factory()->create(['role' => 'professor']);
        $class = AcademicClass::create([
            'name' => 'Mobile Development',
            'section' => 'BSIT 3A',
            'class_code' => 'MOB101',
            'professor_id' => $professor->id,
            'students_count' => 10,
        ]);

        $activity = GroupingActivity::create([
            'title' => 'Final Capstone Project',
            'class_name' => 'Mobile Development',
            'required_skills' => ['Flutter', 'PHP'],
            'group_capacity' => 4,
            'number_of_groups' => 3,
            'grouping_method' => 'student_formed',
            'grouping_deadline' => now()->addDays(7),
            'status' => 'active',
            'formed_teams' => [],
        ]);

        // 0. Verify newly created student_formed activity starts empty and is NOT auto-populated on get
        $responseIndex = $this->getJson('/api/activities');
        $responseIndex->assertOk();
        $this->assertEmpty($responseIndex->json()[0]['formed_teams'] ?? []);

        $responseShow = $this->getJson("/api/activities/{$activity->id}");
        $responseShow->assertOk();
        $this->assertEmpty($responseShow->json()['formed_teams'] ?? []);

        // 1. Leader creates a team
        $responseCreate = $this->postJson("/api/activities/{$activity->id}/teams", [
            'name' => 'Team Alpha',
            'role' => 'Project leader / team leader',
            'leader_name' => 'Juan Leader',
            'leader_email' => 'juan@student.edu',
        ]);
        $responseCreate->assertStatus(201);

        $activity->refresh();
        $this->assertCount(1, $activity->formed_teams);
        $this->assertEquals('juan@student.edu', $activity->formed_teams[0]['leader_email']);
        $this->assertEquals('accepted', $activity->formed_teams[0]['members'][0]['status']);
        $this->assertFalse($activity->formed_teams[0]['members'][0]['is_pending']);

        // 2. Another student requests to join
        $responseJoin = $this->postJson("/api/activities/{$activity->id}/teams/join", [
            'team_name' => 'Team Alpha',
            'student_name' => 'Pedro Applicant',
            'student_email' => 'pedro@student.edu',
            'role' => 'Backend developer',
        ]);
        $responseJoin->assertOk();
        $responseJoin->assertJsonPath('success', true);

        $activity->refresh();
        $team = $activity->formed_teams[0];
        $this->assertCount(2, $team['members']);
        $applicant = $team['members'][1];
        $this->assertEquals('pedro@student.edu', $applicant['email']);
        $this->assertEquals('pending', $applicant['status']);
        $this->assertTrue($applicant['is_pending']);

        // 3. Leader accepts Pedro
        $responseAccept = $this->postJson("/api/activities/{$activity->id}/teams/respond-join", [
            'team_name' => 'Team Alpha',
            'student_email' => 'pedro@student.edu',
            'action' => 'accept',
        ]);
        $responseAccept->assertOk();

        $activity->refresh();
        $acceptedApplicant = $activity->formed_teams[0]['members'][1];
        $this->assertEquals('accepted', $acceptedApplicant['status']);
        $this->assertFalse($acceptedApplicant['is_pending']);

        // 4. Another student requests to join, and leader declines
        $this->postJson("/api/activities/{$activity->id}/teams/join", [
            'team_name' => 'Team Alpha',
            'student_name' => 'Maria Applicant',
            'student_email' => 'maria@student.edu',
            'role' => 'UI / UX designer',
        ])->assertOk();

        $activity->refresh();
        $this->assertCount(3, $activity->formed_teams[0]['members']);

        $responseDecline = $this->postJson("/api/activities/{$activity->id}/teams/respond-join", [
            'team_name' => 'Team Alpha',
            'student_email' => 'maria@student.edu',
            'action' => 'decline',
        ]);
        $responseDecline->assertOk();

        $activity->refresh();
        $this->assertCount(2, $activity->formed_teams[0]['members']);
        $emails = array_column($activity->formed_teams[0]['members'], 'email');
        $this->assertNotContains('maria@student.edu', $emails);
    }
}
