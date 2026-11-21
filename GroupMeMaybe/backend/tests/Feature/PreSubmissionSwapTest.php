<?php

namespace Tests\Feature;

use App\Models\AcademicClass;
use App\Models\GroupingActivity;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class PreSubmissionSwapTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_both_students_must_approve_before_roster_changes_and_submission_is_blocked(): void
    {
        $professor = User::factory()->create(['role' => 'professor']);
        $leader = User::factory()->create(['role' => 'student']);
        $outgoing = User::factory()->create(['role' => 'student']);
        $incoming = User::factory()->create(['role' => 'student']);
        $class = AcademicClass::create(['name' => 'Web Systems', 'class_code' => 'WEB201', 'professor_id' => $professor->id]);
        $class->students()->attach([$leader->id, $outgoing->id, $incoming->id]);
        foreach ([$leader, $outgoing, $incoming] as $student) {
            Profile::create([
                'name' => $student->name, 'email' => $student->email,
                'skills' => [], 'preferred_role' => 'Developer',
                'availability' => 'Weekdays', 'details' => ['is_complete' => true],
            ]);
        }
        $activity = GroupingActivity::create([
            'title' => 'Web App Project', 'academic_class_id' => $class->id, 'class_name' => 'Web Systems',
            'required_skills' => ['React'], 'group_capacity' => 2, 'number_of_groups' => 2,
            'grouping_method' => 'student_formed', 'grouping_deadline' => now()->addDays(7), 'status' => 'active',
            'formed_teams' => [[
                'name' => 'Code Ninjas', 'leader_email' => $leader->email, 'status' => 'Unsubmitted',
                'members' => [
                    ['name' => $leader->name, 'email' => $leader->email, 'role' => 'Leader', 'is_leader' => true, 'status' => 'accepted'],
                    ['name' => $outgoing->name, 'email' => $outgoing->email, 'role' => 'Developer', 'is_leader' => false, 'status' => 'accepted'],
                ],
            ]],
        ]);

        $proposal = $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/pre-submission-swaps", [
            'team_name' => 'Code Ninjas', 'outgoing_email' => $outgoing->email,
            'incoming_email' => $incoming->email, 'reason' => 'Availability changed',
        ])->assertCreated();
        $id = $proposal->json('swap.id');
        $this->actingAs($leader)->getJson('/api/pre-submission-swaps')->assertOk()->assertJsonCount(1, 'swaps');
        $this->assertSame($outgoing->email, $activity->fresh()->formed_teams[0]['members'][1]['email']);
        $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/submit-evaluation", ['team_name' => 'Code Ninjas'])->assertUnprocessable();
        $this->actingAs($professor)->postJson("/api/pre-submission-swaps/{$id}/decision", ['decision' => 'approve'])->assertForbidden();
        $this->actingAs($incoming)->postJson("/api/pre-submission-swaps/{$id}/decision", ['decision' => 'approve'])->assertOk();
        $this->assertSame($outgoing->email, $activity->fresh()->formed_teams[0]['members'][1]['email']);
        $this->actingAs($outgoing)->postJson("/api/pre-submission-swaps/{$id}/decision", ['decision' => 'approve'])->assertOk();
        $this->assertSame($incoming->email, $activity->fresh()->formed_teams[0]['members'][1]['email']);

        $reverse = [
            'team_name' => 'Code Ninjas', 'outgoing_email' => $incoming->email,
            'incoming_email' => $outgoing->email, 'reason' => 'Review the new roster',
        ];
        $declined = $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/pre-submission-swaps", $reverse)->assertCreated();
        $this->actingAs($outgoing)->postJson('/api/pre-submission-swaps/'.$declined->json('swap.id').'/decision', ['decision' => 'decline'])->assertOk();
        $this->assertSame($incoming->email, $activity->fresh()->formed_teams[0]['members'][1]['email']);
        $cancelled = $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/pre-submission-swaps", $reverse)->assertCreated();
        $this->actingAs($leader)->postJson('/api/pre-submission-swaps/'.$cancelled->json('swap.id').'/decision', ['decision' => 'cancel'])->assertOk();
        $this->actingAs($leader)->postJson("/api/activities/{$activity->id}/teams/submit-evaluation", ['team_name' => 'Code Ninjas'])->assertOk();
    }
}
