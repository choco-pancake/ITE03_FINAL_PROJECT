<?php

namespace Tests\Feature;

use App\Models\AcademicClass;
use App\Models\AppNotification;
use App\Models\GroupingActivity;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProjectInstructionsAndUnenrollmentTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_project_dates_and_private_instruction_file(): void
    {
        Storage::fake('local');
        $professor = User::factory()->create(['role' => 'professor']);
        $student = User::factory()->create(['role' => 'student']);
        $outsider = User::factory()->create(['role' => 'student']);
        $class = AcademicClass::create([
            'name' => 'Systems', 'class_code' => 'SYS100', 'professor_id' => $professor->id,
        ]);
        $class->students()->attach($student->id);
        $payload = [
            'title' => 'Project', 'class_name' => 'Systems',
            'academic_class_id' => $class->id, 'grouping_method' => 'student_formed',
            'group_capacity' => 2, 'required_skills' => ['PHP'],
            'grouping_deadline' => now()->addDays(5)->toDateTimeString(),
            'project_submission_deadline' => now()->addDays(10)->toDateTimeString(),
        ];
        $this->actingAs($student)->post('/api/activities', [
            'payload' => json_encode($payload),
            'instruction_file' => UploadedFile::fake()->create('guide.pdf', 10, 'application/pdf'),
        ])->assertForbidden();
        $this->assertDatabaseCount('grouping_activities', 0);
        $this->actingAs($professor)->withHeaders(['Accept' => 'application/json'])->post('/api/activities', [
            'payload' => json_encode($payload),
            'instruction_file' => UploadedFile::fake()->create('script.exe', 10, 'application/octet-stream'),
        ])->assertUnprocessable()->assertJsonValidationErrors('instruction_file');
        $this->actingAs($professor)->post('/api/activities', [
            'payload' => json_encode($payload),
            'instruction_file' => UploadedFile::fake()->create('guide.pdf', 10, 'application/pdf'),
        ])->assertCreated()->assertJsonPath('instruction_file_name', 'guide.pdf');
        $activity = GroupingActivity::firstOrFail();
        Storage::disk('local')->assertExists($activity->instruction_file_path);
        $this->actingAs($student)->get("/api/activities/{$activity->id}/instructions")->assertOk();
        $this->actingAs($outsider)->get("/api/activities/{$activity->id}/instructions")->assertForbidden();
        $oldPath = $activity->instruction_file_path;
        $this->actingAs($professor)->post("/api/activities/{$activity->id}", [
            '_method' => 'PUT',
            'payload' => json_encode($payload),
            'instruction_file' => UploadedFile::fake()->create('updated.pdf', 10, 'application/pdf'),
        ])->assertOk()->assertJsonPath('instruction_file_name', 'updated.pdf');
        Storage::disk('local')->assertMissing($oldPath);
        Storage::disk('local')->assertExists($activity->fresh()->instruction_file_path);
        $replacementPath = $activity->fresh()->instruction_file_path;
        $this->actingAs($professor)->putJson("/api/activities/{$activity->id}", [
            'remove_instruction_file' => true,
        ])->assertOk()->assertJsonPath('instruction_file_name', null);
        Storage::disk('local')->assertMissing($replacementPath);
        $payload['grouping_deadline'] = now()->addDays(12)->toDateTimeString();
        $this->actingAs($professor)->putJson("/api/activities/{$activity->id}", $payload)
            ->assertUnprocessable();
    }

    public function test_professor_can_attach_instructions_via_bearer_token(): void
    {
        Storage::fake('local');
        $professor = User::factory()->create(['role' => 'professor']);
        $token = $professor->createToken('test')->plainTextToken;
        $class = AcademicClass::create([
            'name' => 'Web Development', 'class_code' => 'WEB101', 'professor_id' => $professor->id,
        ]);
        $payload = [
            'title' => 'Bearer Token Project', 'class_name' => 'Web Development',
            'academic_class_id' => $class->id, 'grouping_method' => 'auto',
            'group_capacity' => 3, 'required_skills' => ['Flutter'],
            'grouping_deadline' => now()->addDays(5)->toDateTimeString(),
            'project_submission_deadline' => now()->addDays(10)->toDateTimeString(),
        ];

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->post('/api/activities', [
            'payload' => json_encode($payload),
            'instruction_file' => UploadedFile::fake()->create('project_guide.pdf', 15, 'application/pdf'),
        ]);

        $response->assertCreated()->assertJsonPath('instruction_file_name', 'project_guide.pdf');
        $activity = GroupingActivity::where('title', 'Bearer Token Project')->firstOrFail();
        Storage::disk('local')->assertExists($activity->instruction_file_path);
    }

    public function test_unenrollment_removes_only_selected_class_membership_and_team_entries(): void
    {
        $professor = User::factory()->create(['role' => 'professor']);
        $student = User::factory()->create(['role' => 'student']);
        $member = User::factory()->create(['role' => 'student']);
        $otherClass = AcademicClass::create([
            'name' => 'Other', 'class_code' => 'OTH100', 'professor_id' => $professor->id,
        ]);
        $class = AcademicClass::create([
            'name' => 'Systems', 'class_code' => 'SYS100', 'professor_id' => $professor->id,
        ]);
        $class->students()->attach([$student->id, $member->id]);
        $otherClass->students()->attach($student->id);
        $activity = GroupingActivity::create([
            'title' => 'Project', 'class_name' => 'Systems',
            'academic_class_id' => $class->id, 'grouping_method' => 'student_formed',
            'group_capacity' => 3, 'required_skills' => [], 'grouping_deadline' => now()->addDays(5),
            'formed_teams' => [[
                'name' => 'Team A', 'leader_email' => $student->email,
                'status' => 'Formed (2/3)',
                'members' => [
                    ['email' => $student->email, 'status' => 'accepted', 'is_leader' => true],
                    ['email' => $member->email, 'status' => 'accepted', 'is_leader' => false],
                ],
            ]],
        ]);
        AppNotification::create([
            'user_id' => $student->id,
            'event_key' => 'project_deadline:'.$activity->id.':123',
            'kind' => 'project_deadline',
            'title' => 'Project deadline',
            'message' => 'Project is due.',
            'target' => 'classes',
        ]);
        $this->actingAs($member)->deleteJson("/api/classes/{$class->id}/students/{$student->id}")
            ->assertForbidden();
        $this->actingAs($professor)->deleteJson("/api/classes/{$class->id}/students/{$student->id}")
            ->assertOk();
        $this->assertFalse($class->students()->whereKey($student->id)->exists());
        $this->assertTrue($otherClass->students()->whereKey($student->id)->exists());
        $this->assertSame(1, $class->fresh()->student_count);
        $this->assertSame($member->email, $activity->fresh()->formed_teams[0]['leader_email']);
        $this->assertCount(1, $activity->fresh()->formed_teams[0]['members']);
        $this->assertDatabaseMissing('app_notifications', [
            'user_id' => $student->id,
            'event_key' => 'project_deadline:'.$activity->id.':123',
        ]);
        $this->actingAs($student)->deleteJson("/api/classes/{$otherClass->id}/students/{$student->id}")
            ->assertForbidden();
        $this->assertSame(1, $otherClass->students()->count());
    }
}
