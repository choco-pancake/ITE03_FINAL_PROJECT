<?php

namespace Tests\Feature;

use App\Models\AcademicClass;
use App\Models\GroupingActivity;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationFlowTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_skill_request_notifies_professor_and_decision_notifies_student(): void
    {
        $student = User::factory()->create(['role' => 'student', 'name' => 'Maria Santos']);
        $professor = User::factory()->create(['role' => 'professor']);

        Sanctum::actingAs($student);
        $skillRequest = $this->postJson('/api/custom-skill-requests', [
            'skill_name' => 'Rust', 'domain' => 'Programming',
        ])->assertCreated()->json();
        $this->getJson('/api/notifications')->assertJsonPath('unread_count', 0);
        $this->patchJson('/api/custom-skill-requests/'.$skillRequest['id'], ['status' => 'approved'])->assertForbidden();

        Sanctum::actingAs($professor);
        $this->getJson('/api/notifications')->assertJsonPath('unread_count', 1)
            ->assertJsonPath('notifications.0.kind', 'skill_request');
        $this->patchJson('/api/custom-skill-requests/'.$skillRequest['id'], ['status' => 'approved'])->assertOk()
            ->assertJsonPath('status', 'approved');
        $this->patchJson('/api/custom-skill-requests/'.$skillRequest['id'], ['status' => 'rejected'])->assertStatus(409);

        Sanctum::actingAs($student);
        $notification = $this->getJson('/api/notifications')->assertJsonPath('unread_count', 1)
            ->assertJsonPath('notifications.0.kind', 'skill_decision')->json('notifications.0');
        $this->patchJson('/api/notifications/'.$notification['id'].'/read')->assertOk();
        $this->getJson('/api/notifications')->assertJsonPath('unread_count', 0);
    }

    public function test_deadline_notifications_only_target_matching_section_and_respect_preference(): void
    {
        $student = User::factory()->create(['role' => 'student', 'department_or_section' => '21-ITEM-03']);
        $professor = User::factory()->create(['role' => 'professor']);
        $matching = AcademicClass::create(['name' => 'Programming', 'section' => '21-ITEM-03', 'class_code' => 'PRG1', 'professor_id' => $professor->id]);
        $matching->students()->attach($student->id);
        $other = AcademicClass::create(['name' => 'Networks', 'section' => '21-CSE-01', 'class_code' => 'NET1', 'professor_id' => $professor->id]);
        foreach ([$matching, $other] as $class) {
            GroupingActivity::create([
                'academic_class_id' => $class->id,
                'class_name' => $class->name.' - '.$class->section,
                'title' => $class->name.' project',
                'required_skills' => [],
                'grouping_deadline' => now()->addHours(12),
            ]);
        }

        Sanctum::actingAs($student);
        $this->getJson('/api/notifications')->assertJsonPath('unread_count', 1);
        $this->getJson('/api/notifications')->assertJsonCount(1, 'notifications');
        $this->putJson('/api/notification-preferences', ['group_activity' => false])->assertJsonPath('group_activity', false);
        $this->getJson('/api/notification-preferences')->assertJsonPath('group_activity', false);
        $this->assertDatabaseCount('app_notifications', 1);
    }
}
