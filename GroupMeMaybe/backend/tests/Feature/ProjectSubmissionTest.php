<?php

namespace Tests\Feature;

use App\Models\AcademicClass;
use App\Models\GroupingActivity;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProjectSubmissionTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_class_with_no_projects_returns_empty_status_object(): void
    {
        $professor = User::factory()->create(['role' => 'professor']);
        $class = AcademicClass::create([
            'name' => 'Empty Class', 'class_code' => 'EMPTY1', 'professor_id' => $professor->id,
        ]);

        $response = $this->actingAs($professor)
            ->getJson("/api/classes/{$class->id}/project-statuses")
            ->assertOk();
        $this->assertSame('{}', $response->getContent());
    }

    public function test_roster_submission_filters_and_grading_permissions(): void
    {
        Storage::fake('local');
        $professor = User::factory()->create(['role' => 'professor']);
        $leader = User::factory()->create(['role' => 'student']);
        $member = User::factory()->create(['role' => 'student']);
        $outsider = User::factory()->create(['role' => 'student']);
        $class = AcademicClass::create([
            'name' => 'Systems', 'section' => '21-ITEM-03',
            'class_code' => 'SYS100', 'professor_id' => $professor->id,
        ]);
        $class->students()->attach([$leader->id, $member->id]);
        Profile::create([
            'name' => $leader->name, 'email' => $leader->email,
            'skills' => ['PHP'], 'preferred_role' => 'Backend Developer',
            'availability' => 'Weekdays', 'details' => ['block' => '21-ITEM-03'],
        ]);
        $activity = GroupingActivity::create([
            'title' => 'Project', 'class_name' => 'Systems - 21-ITEM-03',
            'academic_class_id' => $class->id, 'required_skills' => ['PHP'],
            'grouping_deadline' => now()->addDay(),
            'project_submission_deadline' => now()->addDays(2),
            'formed_teams' => [[
                'name' => 'Team A', 'leader_email' => $leader->email,
                'members' => [
                    ['email' => $leader->email, 'status' => 'accepted', 'is_leader' => true],
                    ['email' => $member->email, 'status' => 'accepted', 'is_leader' => false],
                ],
            ]],
        ]);

        $this->actingAs($leader)->getJson("/api/classes/{$class->id}/students")
            ->assertOk()->assertJsonCount(2);
        $this->actingAs($leader)->deleteJson("/api/classes/{$class->id}/students/{$leader->id}")
            ->assertForbidden();
        $this->actingAs($member)->post("/api/activities/{$activity->id}/project-submissions", [
            'team_name' => 'Team A',
            'file' => UploadedFile::fake()->create('report.pdf', 10, 'application/pdf'),
        ])->assertForbidden();
        $this->actingAs($leader)->post("/api/activities/{$activity->id}/project-submissions", [
            'team_name' => 'Team A',
            'file' => UploadedFile::fake()->create('report.pdf', 10, 'application/pdf'),
        ])->assertCreated()->assertJsonPath('file_name', 'report.pdf');
        $this->actingAs($member)->getJson("/api/classes/{$class->id}/project-statuses")
            ->assertJsonPath((string) $activity->id.'.submitted', true);
        $this->actingAs($professor)->getJson("/api/classes/{$class->id}/project-statuses")
            ->assertJsonPath((string) $activity->id.'.graded', false);
        $submission = $activity->projectSubmissions()->firstOrFail();
        $firstPath = $submission->file_path;
        $this->actingAs($member)->get("/api/project-submissions/{$submission->id}/file")->assertOk();
        $this->actingAs($professor)->get("/api/project-submissions/{$submission->id}/file")->assertOk();
        $this->actingAs($outsider)->get("/api/project-submissions/{$submission->id}/file")->assertForbidden();
        $this->actingAs($leader)->withHeaders(['Accept' => 'application/json'])
            ->post("/api/activities/{$activity->id}/project-submissions", [
                'team_name' => 'Team A',
                'file' => UploadedFile::fake()->create('script.exe', 10, 'application/octet-stream'),
            ])->assertUnprocessable()->assertJsonValidationErrors('file');
        $this->actingAs($leader)->post("/api/activities/{$activity->id}/project-submissions", [
            'team_name' => 'Team A',
            'file' => UploadedFile::fake()->create('revised.pdf', 10, 'application/pdf'),
        ])->assertOk()->assertJsonPath('file_name', 'revised.pdf');
        Storage::disk('local')->assertMissing($firstPath);
        Storage::disk('local')->assertExists($submission->fresh()->file_path);
        $this->actingAs($professor)->patchJson("/api/project-submissions/{$submission->id}/grade", [
            'grade' => 92,
        ])->assertUnprocessable();

        $this->travel(3)->days();
        $this->actingAs($leader)->post("/api/activities/{$activity->id}/project-submissions", [
            'team_name' => 'Team A',
            'file' => UploadedFile::fake()->create('late.pdf', 10, 'application/pdf'),
        ])->assertUnprocessable();
        $this->actingAs($professor)->patchJson("/api/project-submissions/{$submission->id}/grade", [
            'grade' => 92.5, 'feedback' => 'Good work',
        ])->assertOk()->assertJsonPath('feedback', 'Good work');
        $this->actingAs($professor)->getJson("/api/classes/{$class->id}/project-statuses")
            ->assertJsonPath((string) $activity->id.'.graded', true);
        $this->actingAs($member)->getJson("/api/classes/{$class->id}/project-statuses")
            ->assertJsonPath((string) $activity->id.'.graded', true);
        $this->actingAs($professor)->patchJson("/api/project-submissions/{$submission->id}/grade", [
            'grade' => 95,
        ])->assertOk()->assertJsonPath('grade', '95.00');
        $submittedPath = $submission->fresh()->file_path;
        $this->actingAs($professor)->deleteJson("/api/activities/{$activity->id}")->assertOk();
        Storage::disk('local')->assertMissing($submittedPath);
    }
}
