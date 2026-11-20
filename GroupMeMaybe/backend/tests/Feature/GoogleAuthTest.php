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

    public function test_google_login_creates_student_account_when_missing(): void
    {
        $this->mockGoogleAccount();

        $this->postJson('/api/google-auth', [
            'id_token' => 'signed-token',
            'intent' => 'login',
        ])->assertCreated()
            ->assertJsonPath('user.role', 'student');

        $this->assertDatabaseHas('users', ['google_sub' => 'google-sub-123']);
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

    public function test_google_links_an_existing_account_with_verified_email(): void
    {
        User::factory()->create(['email' => 'maria@example.com']);
        $this->mockGoogleAccount(['email' => 'maria@example.com']);

        $this->postJson('/api/google-auth', [
            'id_token' => 'signed-token',
            'intent' => 'login',
        ])->assertOk();

        $this->assertDatabaseHas('users', ['google_sub' => 'google-sub-123']);
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

    public function test_email_text_cannot_bypass_google_token_verification(): void
    {
        $this->mock(GoogleTokenVerifier::class)
            ->shouldReceive('verify')
            ->once()
            ->andReturn(null);

        $this->postJson('/api/google-auth', [
            'id_token' => 'maria@gmail.com',
            'intent' => 'login',
        ])->assertUnauthorized();

        $this->assertDatabaseCount('users', 0);
    }
}
