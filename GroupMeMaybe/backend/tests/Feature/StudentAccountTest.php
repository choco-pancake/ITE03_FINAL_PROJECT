<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\GoogleTokenVerifier;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StudentAccountTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_student_profile_saves_all_details_and_updates_account_identity(): void
    {
        $user = User::factory()->create(['role' => 'student', 'email' => 'maria@example.com']);
        Sanctum::actingAs($user);

        $details = [
            'student_id' => '2026-1001',
            'year_level' => '2nd Year',
            'block' => '21-ITEM-03',
            'roles' => ['Backend developer', 'QA / software tester'],
            'tools' => ['Laravel', 'MySQL'],
            'available_days' => ['Mon', 'Wed'],
            'meeting_start' => '07:00 AM',
            'meeting_end' => '09:00 AM',
            'collaboration_mode' => 'Hybrid',
            'experience' => 'Built a class project.',
            'is_complete' => true,
        ];

        $this->putJson('/api/profile', [
            'name' => 'Maria Santos',
            'email' => 'spoofed@example.com',
            'first_name' => 'Maria',
            'last_name' => 'Santos',
            'skills' => ['Backend development'],
            'interests' => ['Web development'],
            'preferred_role' => 'Backend developer',
            'availability' => '21-ITEM-03 | 07:00 AM - 09:00 AM',
            'details' => $details,
        ])->assertOk()->assertJsonPath('details.block', '21-ITEM-03');

        $this->getJson('/api/profile')->assertOk()
            ->assertJsonPath('details.student_id', '2026-1001')
            ->assertJsonPath('email', 'maria@example.com');
        $this->assertDatabaseHas('users', ['id' => $user->id, 'department_or_section' => '21-ITEM-03']);
    }

    public function test_password_change_requires_current_password(): void
    {
        $user = User::factory()->create(['password' => Hash::make('old-password')]);
        Sanctum::actingAs($user);

        $this->postJson('/api/account/password', [
            'current_password' => 'wrong',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertForbidden();

        $this->postJson('/api/account/password', [
            'current_password' => 'old-password',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertOk();

        $this->assertTrue(Hash::check('new-password', $user->fresh()->password));
    }

    public function test_account_deletion_removes_user_and_profile(): void
    {
        $user = User::factory()->create(['role' => 'student', 'password' => Hash::make('old-password')]);
        Sanctum::actingAs($user);
        $this->putJson('/api/profile', [
            'name' => 'Maria Santos', 'first_name' => 'Maria', 'last_name' => 'Santos',
            'skills' => [], 'interests' => [], 'preferred_role' => 'Developer',
            'availability' => '21-ITEM-03', 'details' => ['block' => '21-ITEM-03'],
        ])->assertOk();

        $this->deleteJson('/api/account', ['current_password' => 'old-password'])->assertOk();
        $this->assertDatabaseMissing('users', ['id' => $user->id]);
        $this->assertDatabaseMissing('profiles', ['email' => $user->email]);
    }

    public function test_google_linked_account_can_set_password_after_verification(): void
    {
        $user = User::factory()->create([
            'google_sub' => 'google-sub-123',
            'password' => Hash::make('unknown-random-password'),
        ]);
        Sanctum::actingAs($user);
        config()->set('services.google.client_id', 'test-client-id');
        $this->mock(GoogleTokenVerifier::class)
            ->shouldReceive('verify')
            ->once()
            ->with('signed-token', 'test-client-id')
            ->andReturn(['sub' => 'google-sub-123', 'email_verified' => true]);

        $this->postJson('/api/account/password', [
            'id_token' => 'signed-token',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertOk();

        $this->assertTrue(Hash::check('new-password', $user->fresh()->password));
    }
}
