<?php

namespace Tests\Feature;

use App\Models\AcademicClass;
use App\Models\AppNotification;
use App\Models\GroupingActivity;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class GroupingActivityJoinTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_student_formed_grouping_method_can_be_created_and_updated(): void
    {
        $payload = [
            'title' => 'Class Project',
            'class_name' => 'Mobile Development',
            'grouping_method' => 'student_formed',
            'group_capacity' => 4,
            'required_skills' => ['Mobile App Development'],
            'grouping_deadline' => now()->addDays(7)->toIso8601String(),
        ];

        $created = $this->postJson('/api/activities', $payload)->assertCreated();
        $created->assertJsonPath('grouping_method', 'student_formed');

        $this->putJson('/api/activities/'.$created->json('id'), [
            'grouping_method' => 'auto',
        ])->assertOk()->assertJsonPath('grouping_method', 'auto');

        $this->putJson('/api/activities/'.$created->json('id'), [
            'grouping_method' => 'student_formed',
        ])->assertOk()->assertJsonPath('grouping_method', 'student_formed');
    }

    public function test_invitation_requires_student_approval_and_full_team_before_submission(): void
    {
        $professor = User::factory()->create(['role' => 'professor']);
        $leader = User::factory()->create(['role' => 'student']);
        $invitee = User::factory()->create(['role' => 'student']);
        $applicant = User::factory()->create(['role' => 'student']);
        $class = AcademicClass::create(['name' => 'Web Systems', 'class_code' => 'WEB302', 'professor_id' => $professor->id]);
        $class->students()->attach([$leader->id, $invitee->id, $applicant->id]);
        foreach ([$leader, $invitee, $applicant] as $student) {
            Profile::create([
                'name' => $student->name,
                'email' => $student->email,
                'skills' => [],
                'preferred_role' => 'Frontend developer',
                'availability' => 'Weekdays',
                'details' => ['is_complete' => true],
            ]);
        }
        $activity = GroupingActivity::create([
            'title' => 'Web Project',
            'academic_class_id' => $class->id,
            'class_name' => 'Web Systems',
            'required_skills' => ['Frontend Development', 'Backend Development', 'Database Management'],
            'group_capacity' => 3,
            'grouping_method' => 'student_formed',
            'grouping_deadline' => now()->addDays(7),
            'formed_teams' => [],
        ]);
        $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams", [
            'name' => 'Team Alpha', 'role' => 'Full-stack developer',
        ])->assertCreated();
        $this->assertGreaterThanOrEqual(80, $activity->fresh()->formed_teams[0]['balance_score']);
        $this->actingAs($leader)->getJson("/api/activities/{$activity->id}/teams/invite-candidates?team_name=Team%20Alpha")
            ->assertOk()->assertJsonCount(2);
        $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/submit-evaluation", ['team_name' => 'Team Alpha'])->assertUnprocessable();

        $invite = ['team_name' => 'Team Alpha', 'student_name' => $invitee->name, 'student_email' => $invitee->email, 'role' => 'Backend developer'];
        $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/invite", $invite)->assertOk();
        $this->actingAs($leader)->getJson("/api/activities/{$activity->id}/teams/invite-candidates?team_name=Team%20Alpha")
            ->assertOk()->assertJsonCount(1);
        $this->assertSame('invite', $activity->fresh()->formed_teams[0]['members'][1]['pending_type']);
        $this->assertSame('pending', $activity->fresh()->formed_teams[0]['members'][1]['status']);
        $this->assertTrue(AppNotification::where('user_id', $invitee->id)->where('kind', 'team_invitation')->exists());
        $this->assertSame('groups:'.$activity->id, AppNotification::where('user_id', $invitee->id)->where('kind', 'team_invitation')->first()->target);
        $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/respond-join", [
            'team_name' => 'Team Alpha', 'student_email' => $invitee->email, 'action' => 'accept',
        ])->assertNotFound();
        $this->actingAs($applicant)->postJson("/api/activities/{$activity->id}/teams/respond-invite", [
            'team_name' => 'Team Alpha', 'action' => 'accept',
        ])->assertNotFound();
        $this->actingAs($invitee)->postJson("/api/activities/{$activity->id}/teams/respond-invite", [
            'team_name' => 'Team Alpha', 'action' => 'decline',
        ])->assertOk();
        $this->assertCount(1, $activity->fresh()->formed_teams[0]['members']);

        $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/invite", $invite)->assertOk();
        $this->actingAs($invitee)->postJson("/api/activities/{$activity->id}/teams/respond-invite", [
            'team_name' => 'Team Alpha', 'action' => 'accept',
        ])->assertOk();
        $this->assertCount(2, $activity->fresh()->formed_teams[0]['members']);
        $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/submit-evaluation", ['team_name' => 'Team Alpha'])->assertUnprocessable();

        $this->actingAs($applicant)->postJson("/api/activities/{$activity->id}/teams/join", ['team_name' => 'Team Alpha'])->assertOk();
        $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/respond-join", [
            'team_name' => 'Team Alpha', 'student_email' => $applicant->email, 'action' => 'accept',
        ])->assertOk();
        $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/submit-evaluation", ['team_name' => 'Team Alpha'])
            ->assertOk()
            ->assertJsonPath('scarcity_report.covered_skills', ['Frontend Development', 'Backend Development', 'Database Management']);
    }

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
        $leader = User::factory()->create(['role' => 'student', 'name' => 'Juan Leader', 'email' => 'juan@student.edu']);
        $pedro = User::factory()->create(['role' => 'student', 'name' => 'Pedro Applicant', 'email' => 'pedro@student.edu']);
        $maria = User::factory()->create(['role' => 'student', 'name' => 'Maria Applicant', 'email' => 'maria@student.edu']);
        $class->students()->attach([$leader->id, $pedro->id, $maria->id]);
        foreach ([$leader, $pedro, $maria] as $student) {
            Profile::create([
                'name' => $student->name,
                'email' => $student->email,
                'skills' => [],
                'preferred_role' => 'Developer',
                'availability' => 'Weekdays',
                'details' => ['is_complete' => true],
            ]);
        }

        $activity = GroupingActivity::create([
            'title' => 'Final Capstone Project',
            'academic_class_id' => $class->id,
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
        $responseCreate = $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams", [
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

        $incomplete = User::factory()->create(['role' => 'student', 'email' => 'incomplete@student.edu']);
        $class->students()->attach($incomplete->id);
        Profile::create([
            'name' => $incomplete->name,
            'email' => $incomplete->email,
            'skills' => [],
            'preferred_role' => 'Developer',
            'availability' => 'Weekdays',
            'details' => ['is_complete' => false],
        ]);
        $this->actingAs($incomplete)->postJson("/api/activities/{$activity->id}/teams/join", [
            'team_name' => 'Team Alpha',
        ])->assertForbidden();
        $this->assertCount(1, $activity->fresh()->formed_teams[0]['members']);

        // 2. Another student requests to join
        $responseJoin = $this->actingAs($pedro)->postJson("/api/activities/{$activity->id}/teams/join", [
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
        $responseAccept = $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/respond-join", [
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
        $this->actingAs($maria)->postJson("/api/activities/{$activity->id}/teams/join", [
            'team_name' => 'Team Alpha',
            'student_name' => 'Maria Applicant',
            'student_email' => 'maria@student.edu',
            'role' => 'UI / UX designer',
        ])->assertOk();

        $activity->refresh();
        $this->assertCount(3, $activity->formed_teams[0]['members']);

        $responseDecline = $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/respond-join", [
            'team_name' => 'Team Alpha',
            'student_email' => 'maria@student.edu',
            'action' => 'decline',
        ]);
        $responseDecline->assertOk();

        $activity->refresh();
        $this->assertCount(2, $activity->formed_teams[0]['members']);
        $emails = array_column($activity->formed_teams[0]['members'], 'email');
        $this->assertNotContains('maria@student.edu', $emails);

        $autoActivity = GroupingActivity::create([
            'title' => 'Automatic Team Project',
            'academic_class_id' => $class->id,
            'class_name' => 'Mobile Development',
            'required_skills' => ['Flutter'],
            'group_capacity' => 4,
            'number_of_groups' => 1,
            'grouping_method' => 'auto',
            'grouping_deadline' => now()->addDays(7),
            'status' => 'completed',
            'formed_teams' => [],
        ]);
        $this->getJson("/api/activities/{$autoActivity->id}")->assertJsonPath('formed_teams', []);
        $this->assertSame([], $autoActivity->fresh()->formed_teams);
        $this->actingAs($professor)->postJson("/api/activities/{$autoActivity->id}/auto-form", [
            'strategy' => 'new_groups',
        ])->assertOk();
        $autoMembers = collect($autoActivity->fresh()->formed_teams)->flatMap(fn (array $team) => $team['members']);
        $this->assertCount(3, $autoMembers);
        $this->assertNotContains('incomplete@student.edu', $autoMembers->pluck('email'));
    }
}
