<?php

namespace Tests\Feature;

use App\Models\AcademicClass;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StudentRecordAccessTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function makeProfile(User $student): Profile
    {
        return Profile::create([
            'name' => $student->name,
            'email' => $student->email,
            'first_name' => 'Maria',
            'middle_name' => null,
            'last_name' => 'Santos',
            'skills' => ['Flutter'],
            'preferred_role' => 'Developer',
            'availability' => 'BSIT 2A',
            'details' => [
                'student_id' => '2026-001',
                'year_level' => '2nd Year',
                'block' => 'BSIT 2A',
                'is_complete' => true,
            ],
        ]);
    }

    public function test_class_enrollment_is_saved_and_only_owner_sees_the_student(): void
    {
        $professor = User::factory()->create(['role' => 'professor']);
        $otherProfessor = User::factory()->create(['role' => 'professor']);
        $student = User::factory()->create(['role' => 'student']);

        Sanctum::actingAs($student);
        $this->postJson('/api/classes', ['name' => 'Web Development', 'class_code' => 'WEB123'])->assertForbidden();

        Sanctum::actingAs($professor);
        $class = $this->postJson('/api/classes', [
            'name' => 'Web Development',
            'section' => 'BSIT 2A',
            'class_code' => 'WEB123',
        ])->assertCreated()->assertJsonPath('professor_id', $professor->id)->json();

        Sanctum::actingAs($student);
        $this->postJson('/api/classes/enroll', ['class_code' => 'missing'])->assertNotFound();
        $this->postJson('/api/classes/enroll', ['class_code' => 'web123'])->assertOk()->assertJsonPath('student_count', 1);
        $this->postJson('/api/classes/enroll', ['class_code' => 'WEB123'])->assertOk()->assertJsonPath('student_count', 1);
        $this->getJson('/api/classes')->assertJsonCount(1);
        $this->assertDatabaseHas('academic_class_enrollments', [
            'academic_class_id' => $class['id'],
            'student_id' => $student->id,
        ]);

        Sanctum::actingAs($professor);
        $this->getJson('/api/professor/students')->assertOk()->assertJsonPath('students.0.id', $student->id);
        $this->deleteJson('/api/account', ['email' => $professor->email])->assertStatus(409);

        Sanctum::actingAs($otherProfessor);
        $this->getJson('/api/professor/students')->assertOk()->assertJsonCount(0, 'students');
        $this->deleteJson('/api/classes/'.$class['id'])->assertForbidden();
    }

    public function test_professor_record_edit_is_unavailable_and_students_cannot_change_completed_identity(): void
    {
        $professor = User::factory()->create(['role' => 'professor']);
        $otherProfessor = User::factory()->create(['role' => 'professor']);
        $student = User::factory()->create([
            'role' => 'student',
            'first_name' => 'Maria',
            'last_name' => 'Santos',
            'name' => 'Maria Santos',
            'department_or_section' => 'BSIT 2A',
        ]);
        $this->makeProfile($student);
        $class = AcademicClass::create([
            'professor_id' => $professor->id,
            'name' => 'Web Development',
            'class_code' => 'WEB123',
            'student_count' => 0,
        ]);
        $class->students()->attach($student->id);
        $payload = [
            'first_name' => 'Maria',
            'middle_name' => 'A',
            'last_name' => 'Reyes',
            'student_id' => '2026-002',
            'year_level' => '3rd Year',
            'block' => 'BSIT 3A',
        ];

        Sanctum::actingAs($student);
        $this->patchJson('/api/professor/students/'.$student->id.'/record', $payload)->assertNotFound();
        $this->putJson('/api/profile', [
            'name' => 'Maria Reyes',
            'first_name' => 'Maria',
            'last_name' => 'Reyes',
            'details' => ['student_id' => '2026-001', 'year_level' => '2nd Year', 'block' => 'BSIT 2A', 'is_complete' => true],
        ])->assertForbidden();

        Sanctum::actingAs($otherProfessor);
        $this->patchJson('/api/professor/students/'.$student->id.'/record', $payload)->assertNotFound();

        Sanctum::actingAs($professor);
        $this->patchJson('/api/professor/students/'.$student->id.'/record', $payload)->assertNotFound();
        $this->assertDatabaseHas('users', ['id' => $student->id, 'name' => 'Maria Santos']);
        $this->assertDatabaseCount('student_record_changes', 0);

        Sanctum::actingAs($student);
        $this->putJson('/api/profile', [
            'name' => 'Maria Santos',
            'first_name' => 'Maria',
            'last_name' => 'Santos',
            'skills' => ['Flutter', 'Laravel'],
            'details' => ['student_id' => '2026-001', 'year_level' => '2nd Year', 'block' => 'BSIT 2A', 'is_complete' => true],
        ])->assertOk();
        $this->putJson('/api/profile', [
            'name' => 'Maria Santos',
            'details' => ['student_id' => '2026-001', 'year_level' => '2nd Year', 'block' => 'BSIT 2A', 'is_complete' => false],
        ])->assertForbidden();
    }
}
