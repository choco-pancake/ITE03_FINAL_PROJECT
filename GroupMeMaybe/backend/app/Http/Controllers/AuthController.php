<?php

namespace App\Http\Controllers;

use App\Models\AcademicClass;
use App\Models\Profile;
use App\Models\User;
use App\Services\GoogleTokenVerifier;
use GuzzleHttp\Exception\TransferException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class AuthController extends Controller
{
    /**
     * Register a new user (Student or Professor).
     */
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'nullable|string|max:255',
            'first_name' => 'nullable|string|max:255',
            'middle_name' => 'nullable|string|max:255',
            'last_name' => 'nullable|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email',
            'password' => 'required|string|min:6',
            'role' => 'nullable|string|in:student,professor',
            'faculty_code' => 'nullable|string|max:255',
            'admin_code' => 'nullable|string|max:255',
            'department_or_section' => 'nullable|string|max:255',
            'preferred_role' => 'nullable|string|max:255',
            'skills' => 'nullable|array',
        ]);

        $role = $validated['role'] ?? 'student';

        // Check Faculty Authorization Code if registering as an instructor
        if ($role === 'professor') {
            $settings = AdminController::getSettings();
            $expectedCode = $settings['faculty_code'] ?? env('FACULTY_ACCESS_CODE', 'BSIT-FACULTY-2026');
            $providedCode = trim($validated['faculty_code'] ?? '');
            if ($providedCode !== $expectedCode) {
                return response()->json([
                    'message' => 'Invalid Faculty Authorization Code. Please contact the BSIT Department Chair for the instructor access key.',
                ], 403);
            }
        }

        // Check Admin Authorization Code if registering as an administrator
        if ($role === 'admin') {
            $expectedAdminCode = env('ADMIN_ACCESS_CODE', 'ADMIN-CHAIR-2026');
            $providedAdminCode = trim($request->input('admin_code', ''));
            if ($providedAdminCode !== $expectedAdminCode) {
                return response()->json([
                    'message' => 'Invalid Administrator Authorization Code. Access restricted to the Department Chair / Dean.',
                ], 403);
            }
        }

        $firstName = trim($validated['first_name'] ?? '');
        $middleName = trim($validated['middle_name'] ?? '');
        $lastName = trim($validated['last_name'] ?? '');

        if ($firstName !== '' && $lastName !== '') {
            $fullName = $middleName !== '' ? "$firstName $middleName $lastName" : "$firstName $lastName";
        } else {
            $fullName = trim($validated['name'] ?? 'User');
            $parts = preg_split('/\s+/', $fullName);
            $firstName = $parts[0] ?? '';
            $lastName = count($parts) > 1 ? end($parts) : '';
            $middleName = count($parts) > 2 ? implode(' ', array_slice($parts, 1, count($parts) - 2)) : '';
        }

        $departmentOrSection = ($role === 'professor')
            ? 'Department of Information Technology (BSIT)'
            : ($validated['department_or_section'] ?? 'BSIT 2A');

        $user = User::create([
            'first_name' => $firstName,
            'middle_name' => $middleName ?: null,
            'last_name' => $lastName,
            'name' => $fullName,
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => $role,
            'department_or_section' => $departmentOrSection,
        ]);

        // If the user registered as a student, create or link a student Profile
        if ($role === 'student') {
            Profile::updateOrCreate(
                ['email' => $user->email],
                [
                    'first_name' => $firstName,
                    'middle_name' => $middleName ?: null,
                    'last_name' => $lastName,
                    'name' => $user->name,
                    'skills' => $validated['skills'] ?? [],
                    'interests' => [],
                    'preferred_role' => $validated['preferred_role'] ?? '',
                    'availability' => $departmentOrSection,
                ]
            );
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registration successful',
            'user' => [
                'id' => $user->id,
                'first_name' => $user->first_name,
                'middle_name' => $user->middle_name,
                'last_name' => $user->last_name,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'department_or_section' => $user->department_or_section,
            ],
            'token' => $token,
        ], 201);
    }

    /**
     * Exchange a verified Google ID token for a local session token.
     */
    public function googleAuth(Request $request, GoogleTokenVerifier $verifier): JsonResponse
    {
        $validated = $request->validate([
            'id_token' => 'required|string',
            'intent' => 'required|string|in:login,signup',
            'role' => 'nullable|string|in:student,professor',
            'faculty_code' => 'nullable|string|max:255',
            'department_or_section' => 'nullable|string|max:255',
            'preferred_role' => 'nullable|string|max:255',
        ]);

        $clientId = config('services.google.client_id');
        if (! is_string($clientId) || $clientId === '') {
            return response()->json(['message' => 'Google sign-in is not configured on the server.'], 503);
        }
        $payload = null;
        try {
            $payload = $verifier->verify($validated['id_token'], $clientId);
        } catch (TransferException $exception) {
            Log::warning('Google ID token verification could not reach Google', [
                'exception' => $exception::class,
                ...$this->googleTokenMetadata($validated['id_token'], $clientId),
            ]);

            return response()->json(['message' => 'Google verification is unavailable. Check the server HTTPS connection and try again.'], 503);
        } catch (\Throwable $exception) {
            Log::warning('Google ID token verification threw an error', [
                'exception' => $exception::class,
                ...$this->googleTokenMetadata($validated['id_token'], $clientId),
            ]);
            $payload = null;
        }

        if (! is_array($payload)) {
            Log::warning('Google ID token verification rejected a token',
                $this->googleTokenMetadata($validated['id_token'], $clientId));

            return response()->json(['message' => 'Google verification failed. Please choose your Google account again.'], 401);
        }

        $subject = $payload['sub'] ?? null;
        $email = $payload['email'] ?? null;
        $emailVerified = filter_var($payload['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN);
        if (! is_string($subject) || $subject === ''
            || ! is_string($email) || ! filter_var($email, FILTER_VALIDATE_EMAIL)
            || ! $emailVerified) {
            return response()->json(['message' => 'Google returned an invalid or unverified account.'], 401);
        }

        $email = strtolower($email);
        $user = User::where('google_sub', $subject)->first();
        if ($user === null) {
            $user = User::whereRaw('lower(email) = ?', [$email])->first();
            if ($user !== null) {
                if ($user->google_sub !== null && $user->google_sub !== $subject) {
                    return response()->json(['message' => 'This email belongs to another Google account.'], 409);
                }
                $user->google_sub = $subject;
                $user->save();
            }
        }

        if ($user !== null && ($validated['intent'] ?? '') === 'signup' && ($validated['role'] ?? '') === 'professor') {
            $settings = AdminController::getSettings();
            $expectedCode = $settings['faculty_code'] ?? env('FACULTY_ACCESS_CODE', 'BSIT-FACULTY-2026');
            $providedCode = trim($validated['faculty_code'] ?? '');
            if ($providedCode !== $expectedCode) {
                return response()->json([
                    'message' => 'Invalid Faculty Authorization Code. Please enter the valid code to create an Instructor account.',
                ], 403);
            }
            $user->role = 'professor';
            $user->department_or_section = $validated['department_or_section'] ?? 'College of Computer Studies';
            $user->save();
        }

        $created = false;
        if ($user === null) {
            if ($validated['intent'] === 'login') {
                return response()->json([
                    'message' => 'No account found for this Google account. Choose Student or Instructor on the Sign Up page first.',
                ], 404);
            }

            $role = $validated['role'] ?? 'student';
            if ($role === 'professor') {
                $settings = AdminController::getSettings();
                $expectedCode = $settings['faculty_code'] ?? env('FACULTY_ACCESS_CODE', 'BSIT-FACULTY-2026');
                $providedCode = trim($validated['faculty_code'] ?? '');
                if ($providedCode !== $expectedCode) {
                    return response()->json([
                        'message' => 'Invalid Faculty Authorization Code. Please enter the valid code to create an Instructor account.',
                    ], 403);
                }
            }

            $departmentOrSection = $validated['department_or_section'] ?? ($role === 'professor' ? 'College of Computer Studies' : '');
            $googleName = trim((string) ($payload['name'] ?? ''));
            $fullName = $googleName !== '' ? $googleName : explode('@', $email)[0];
            $parts = preg_split('/\s+/', $fullName);
            $firstName = $parts[0] ?? '';
            $lastName = count($parts) > 1 ? end($parts) : '';
            $middleName = count($parts) > 2 ? implode(' ', array_slice($parts, 1, count($parts) - 2)) : null;

            $user = User::create([
                'first_name' => $firstName,
                'middle_name' => $middleName,
                'last_name' => $lastName,
                'name' => $fullName,
                'email' => $email,
                'password' => Hash::make(bin2hex(random_bytes(32))),
                'role' => $role,
                'department_or_section' => $departmentOrSection,
                'google_sub' => $subject,
            ]);
            $user->forceFill(['email_verified_at' => now()])->save();
            $created = true;
        }

        if ($user->role === 'student') {
            Profile::firstOrCreate(
                ['email' => $user->email],
                [
                    'name' => $user->name,
                    'skills' => [],
                    'interests' => [],
                    'preferred_role' => $validated['preferred_role'] ?? '',
                    'availability' => $user->department_or_section ?? 'BSIT',
                ]
            );
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Google authentication successful',
            'user' => [
                'id' => $user->id,
                'first_name' => $user->first_name,
                'middle_name' => $user->middle_name,
                'last_name' => $user->last_name,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'department_or_section' => $this->resolveEffectiveBlock($user),
            ],
            'token' => $token,
        ], $created ? 201 : 200);
    }

    /**
     * Log in with email and password.
     */
    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid email or password credentials.',
            ], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'user' => [
                'id' => $user->id,
                'first_name' => $user->first_name,
                'middle_name' => $user->middle_name,
                'last_name' => $user->last_name,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role ?? 'student',
                'department_or_section' => $this->resolveEffectiveBlock($user),
            ],
            'token' => $token,
        ]);
    }

    /**
     * Get the authenticated user.
     */
    public function me(Request $request)
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        return response()->json([
            'success' => true,
            'user' => [
                'id' => $user->id,
                'first_name' => $user->first_name,
                'middle_name' => $user->middle_name,
                'last_name' => $user->last_name,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role ?? 'student',
                'department_or_section' => $this->resolveEffectiveBlock($user),
            ],
        ]);
    }

    private function resolveEffectiveBlock(User $user): ?string
    {
        $profile = $user->profile;
        $details = is_array($profile?->details) ? $profile->details : [];
        $block = trim((string) ($details['block'] ?? ''));
        if ($block !== '') {
            if ($user->department_or_section !== $block) {
                $user->update(['department_or_section' => $block]);
            }

            return $block;
        }

        return $user->department_or_section;
    }

    /**
     * Log out and revoke tokens.
     */
    public function logout(Request $request)
    {
        if ($request->user()) {
            $request->user()->currentAccessToken()->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully',
        ]);
    }

    public function changePassword(Request $request, GoogleTokenVerifier $verifier): JsonResponse
    {
        $validated = $request->validate([
            'current_password' => 'nullable|string',
            'id_token' => 'nullable|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if (! $this->hasRecentAccountProof($request->user(), $validated, $verifier)) {
            return response()->json(['message' => 'Current password does not match. Please verify your current password.'], 403);
        }

        $request->user()->update(['password' => Hash::make($validated['password'])]);

        return response()->json(['message' => 'Password updated successfully.']);
    }

    public function deleteAccount(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
        ]);

        $user = $request->user();
        if (strtolower(trim($validated['email'])) !== strtolower(trim($user->email))) {
            return response()->json(['message' => 'The email does not match this account.'], 403);
        }
        if ($user->role === 'professor' && AcademicClass::where('professor_id', $user->id)->exists()) {
            return response()->json(['message' => 'Delete your classes before deleting your instructor account.'], 409);
        }

        DB::transaction(function () use ($user): void {
            Profile::where('email', $user->email)->delete();
            $user->tokens()->delete();
            $user->delete();
        });

        return response()->json(['message' => 'Account deleted.']);
    }

    /** @return array<string, int|string|null> */
    private function googleTokenMetadata(string $token, string $expectedAudience): array
    {
        $parts = explode('.', $token);
        $decodePart = static function (?string $part): array {
            if ($part === null) {
                return [];
            }
            $json = base64_decode(strtr($part, '-_', '+/'), true);
            $decoded = $json === false ? null : json_decode($json, true);

            return is_array($decoded) ? $decoded : [];
        };
        $header = $decodePart($parts[0] ?? null);
        $claims = $decodePart($parts[1] ?? null);

        return [
            'parts' => count($parts),
            'kid' => is_string($header['kid'] ?? null) ? substr($header['kid'], 0, 100) : null,
            'issuer' => is_string($claims['iss'] ?? null) ? substr($claims['iss'], 0, 100) : null,
            'audience_matches' => ($claims['aud'] ?? null) === $expectedAudience ? 'yes' : 'no',
            'expires_at' => is_numeric($claims['exp'] ?? null) ? (int) $claims['exp'] : null,
            'server_time' => time(),
        ];
    }

    /** @param array<string, mixed> $proof */
    private function hasRecentAccountProof(User $user, array $proof, GoogleTokenVerifier $verifier): bool
    {
        if (! empty($proof['current_password']) && Hash::check($proof['current_password'], $user->password)) {
            return true;
        }

        $clientId = config('services.google.client_id');
        if (empty($proof['id_token']) || empty($user->google_sub) || ! is_string($clientId) || $clientId === '') {
            return false;
        }

        try {
            $payload = $verifier->verify($proof['id_token'], $clientId);
        } catch (\Throwable) {
            return false;
        }

        return is_array($payload)
            && ($payload['sub'] ?? null) === $user->google_sub
            && filter_var($payload['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN);
    }
}
