<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\GoogleTokenVerifier;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class GoogleAuthTest extends TestCase
{
    use LazilyRefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config()->set('services.google.client_id', 'test-client-id');
    }

    private function mockGoogleAccount(array $overrides = []): void
    {
        $this->mock(GoogleTokenVerifier::class)
            ->shouldReceive('verify')
            ->once()
            ->with('signed-token', 'test-client-id')
            ->andReturn(array_merge([
                'sub' => 'google-sub-123',
                'email' => 'maria@gmail.com',
                'email_verified' => true,
                'name' => 'Maria Santos',
            ], $overrides));
    }

    public function test_google_signup_uses_verified_identity_and_creates_a_student_profile(): void
    {
        $this->mockGoogleAccount();

        $this->postJson('/api/google-auth', [
            'id_token' => 'signed-token',
            'intent' => 'signup',
            'role' => 'student',
            'name' => 'Spoofed Name',
            'email' => 'spoofed@example.com',
            'department_or_section' => 'BSIT 2A',
        ])->assertCreated()
            ->assertJsonPath('user.name', 'Maria Santos')
            ->assertJsonPath('user.email', 'maria@gmail.com')
            ->assertJsonPath('user.role', 'student');

        $this->assertDatabaseHas('users', [
            'email' => 'maria@gmail.com',
            'google_sub' => 'google-sub-123',
        ]);
        $this->assertDatabaseHas('profiles', ['email' => 'maria@gmail.com']);
    }

    public function test_google_login_requires_an_existing_account(): void
    {
        $this->mockGoogleAccount();

        $this->postJson('/api/google-auth', [
            'id_token' => 'signed-token',
            'intent' => 'login',
        ])->assertNotFound()
            ->assertJsonPath('message', 'No account found. Please sign up with Google first.');

        $this->assertDatabaseMissing('users', ['google_sub' => 'google-sub-123']);
    }

    public function test_google_login_keeps_the_existing_role(): void
    {
        User::factory()->create([
            'email' => 'maria@gmail.com',
            'role' => 'professor',
            'google_sub' => 'google-sub-123',
        ]);
        $this->mockGoogleAccount();

        $this->postJson('/api/google-auth', [
            'id_token' => 'signed-token',
            'intent' => 'login',
            'role' => 'student',
        ])->assertOk()
            ->assertJsonPath('user.role', 'professor');
    }

    public function test_unverified_google_email_is_rejected(): void
    {
        $this->mockGoogleAccount(['email_verified' => false]);

        $this->postJson('/api/google-auth', [
            'id_token' => 'signed-token',
            'intent' => 'signup',
            'role' => 'student',
        ])->assertUnauthorized();

        $this->assertDatabaseCount('users', 0);
    }

    public function test_google_cannot_link_an_existing_external_email_without_password_proof(): void
    {
        User::factory()->create(['email' => 'maria@example.com']);
        $this->mockGoogleAccount(['email' => 'maria@example.com']);

        $this->postJson('/api/google-auth', [
            'id_token' => 'signed-token',
            'intent' => 'login',
        ])->assertStatus(409);

        $this->assertDatabaseMissing('users', ['google_sub' => 'google-sub-123']);
    }

    public function test_missing_google_client_id_returns_configuration_error(): void
    {
        config()->set('services.google.client_id', null);

        $this->postJson('/api/google-auth', [
            'id_token' => 'signed-token',
            'intent' => 'signup',
            'role' => 'student',
        ])->assertStatus(503)
            ->assertJsonPath('message', 'Google sign-in is not configured on the server.');
    }
}
