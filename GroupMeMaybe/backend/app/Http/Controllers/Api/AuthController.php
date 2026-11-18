<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'student_id' => 'required|string',
            'role' => 'nullable|string|in:student,professor',
            'block' => 'nullable|string',
        ]);

        $role = $validated['role'] ?? 'student';
        $userId = ($role === 'professor' ? 'prof-' : 'stud-') . time();

        $user = User::create([
            'id' => $userId,
            'first_name' => $validated['first_name'],
            'last_name' => $validated['last_name'],
            'name' => "{$validated['first_name']} {$validated['last_name']}",
            'email' => strtolower($validated['email']),
            'password' => Hash::make($validated['password']),
            'student_id' => $validated['student_id'],
            'role' => $role,
            'block' => $validated['block'] ?? 'BSIT 2A',
            'profile_status' => $role === 'professor' ? 'complete' : 'uninitialized',
            'proficiency_rating' => 'intermediate',
            'weekly_common_hours' => 10,
            'technical_skills' => [],
            'preferred_roles' => [],
            'interests' => [],
            'available_days' => ['Monday', 'Wednesday', 'Friday'],
        ]);

        return response()->json([
            'message' => 'Registration successful.',
            'user' => $user,
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', strtolower($request->email))->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Invalid email or password credentials.',
            ], 401);
        }

        return response()->json([
            'message' => 'Login successful.',
            'user' => $user,
        ]);
    }

    public function me(Request $request)
    {
        $userId = $request->header('X-User-Id');
        $user = $userId ? User::find($userId) : User::where('email', 'alex.santos@university.edu')->first();

        if (!$user) {
            $user = User::first();
        }

        return response()->json([
            'user' => $user,
        ]);
    }
}
