<?php

namespace App\Http\Controllers;

use App\Models\Profile;
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
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email',
            'password' => 'required|string|min:6',
            'role' => 'nullable|string|in:student,professor',
            'department_or_section' => 'nullable|string|max:255',
            'preferred_role' => 'nullable|string|max:255',
            'skills' => 'nullable|array',
        ]);

        $role = $validated['role'] ?? 'student';

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => $role,
            'department_or_section' => $validated['department_or_section'] ?? null,
        ]);

        // If the user registered as a student, create or link a student Profile
        if ($role === 'student') {
            Profile::firstOrCreate(
                ['email' => $user->email],
                [
                    'name' => $user->name,
                    'skills' => $validated['skills'] ?? ['Frontend Development', 'UI/UX Design'],
                    'interests' => ['Web Development', 'Mobile Apps'],
                    'preferred_role' => $validated['preferred_role'] ?? 'Frontend Developer',
                    'availability' => 'Weekdays after 3PM',
                ]
            );
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registration successful',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'department_or_section' => $user->department_or_section,
            ],
            'token' => $token,
        ], 201);
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
