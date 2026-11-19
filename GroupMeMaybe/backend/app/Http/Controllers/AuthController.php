<?php

namespace App\Http\Controllers;

use App\Models\Profile;
use App\Services\GoogleTokenVerifier;
use Illuminate\Http\JsonResponse;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

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
            'department_or_section' => 'nullable|string|max:255',
            'preferred_role' => 'nullable|string|max:255',
            'skills' => 'nullable|array',
        ]);

        $role = $validated['role'] ?? 'student';

        // Check Faculty Authorization Code if registering as an instructor
        if ($role === 'professor') {
            $expectedCode = env('FACULTY_ACCESS_CODE', 'BSIT-FACULTY-2026');
            $providedCode = trim($validated['faculty_code'] ?? '');
            if ($providedCode !== $expectedCode) {
                return response()->json([
                    'message' => 'Invalid Faculty Authorization Code. Please contact the BSIT Department Chair for the instructor access key.',
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
                    'interests' => ['Web Development', 'Mobile Apps'],
                    'preferred_role' => $validated['preferred_role'] ?? 'Frontend Developer',
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
            'role' => 'required_if:intent,signup|nullable|string|in:student,professor',
            'department_or_section' => 'nullable|string|max:255',
            'preferred_role' => 'nullable|string|max:255',
        ]);

        $clientId = config('services.google.client_id');
        if (! is_string($clientId) || $clientId === '') {
            return response()->json(['message' => 'Google sign-in is not configured on the server.'], 503);
        }

        try {
            $payload = $verifier->verify($validated['id_token'], $clientId);
        } catch (\Throwable $exception) {
            return response()->json(['message' => 'Google verification is unavailable. Please try again.'], 503);
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
                $googleOwnsEmail = str_ends_with($email, '@gmail.com') || ! empty($payload['hd']);
                if (! $googleOwnsEmail) {
                    return response()->json([
                        'message' => 'Use password login for this existing account. Google cannot securely link this email.',
                    ], 409);
                }
                $user->google_sub = $subject;
                $user->save();
            }
        }

        if ($user === null && $validated['intent'] === 'login') {
            return response()->json(['message' => 'No account found. Please sign up with Google first.'], 404);
        }

        $created = false;
        if ($user === null) {
            $role = $validated['role'];
            $departmentOrSection = $role === 'professor'
                ? 'Department of Information Technology (BSIT)'
                : ($validated['department_or_section'] ?? 'BSIT');
            $googleName = trim((string) ($payload['name'] ?? ''));
            $user = User::create([
                'name' => $googleName !== '' ? $googleName : explode('@', $email)[0],
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
                    'interests' => ['Web Development', 'Mobile Apps'],
                    'preferred_role' => $validated['preferred_role'] ?? 'Frontend Developer',
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
                'department_or_section' => $user->department_or_section,
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

        if (!$user || !Hash::check($validated['password'], $user->password)) {
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
                'department_or_section' => $user->department_or_section,
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

        if (!$user) {
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
                'department_or_section' => $user->department_or_section,
            ],
        ]);
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
}
