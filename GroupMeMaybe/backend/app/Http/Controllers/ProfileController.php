<?php

namespace App\Http\Controllers;

use App\Models\Profile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProfileController extends Controller
{
    public function mine(Request $request): JsonResponse
    {
        $profile = Profile::where('email', $request->user()->email)->first();

        return $profile
            ? response()->json($profile)
            : response()->json(['message' => 'Profile not found.'], 404);
    }

    public function saveMine(Request $request): JsonResponse
    {
        // Auto-extract first_name, middle_name, and last_name from name if not provided
        if ((! $request->filled('first_name') || ! $request->filled('last_name')) && $request->filled('name')) {
            $parts = preg_split('/\s+/', trim((string) $request->input('name')));
            $request->merge([
                'first_name' => $request->input('first_name') ?: ($parts[0] ?? $request->user()->first_name ?? 'Student'),
                'last_name' => $request->input('last_name') ?: (count($parts) > 1 ? end($parts) : ($request->user()->last_name ?? 'User')),
                'middle_name' => $request->input('middle_name') ?: (count($parts) > 2 ? implode(' ', array_slice($parts, 1, count($parts) - 2)) : ($request->user()->middle_name ?? null)),
            ]);
        }

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'first_name' => 'nullable|string|max:255',
            'middle_name' => 'nullable|string|max:255',
            'last_name' => 'nullable|string|max:255',
            'skills' => 'nullable|array',
            'skills.*' => 'string|max:255',
            'interests' => 'nullable|array',
            'interests.*' => 'string|max:255',
            'preferred_role' => 'nullable|string|max:255',
            'availability' => 'nullable|string|max:255',
            'details' => 'nullable|array',
            'details.student_id' => 'nullable|string|max:100',
            'details.year_level' => 'nullable|string|max:30',
            'details.block' => 'nullable|string|max:100',
            'details.roles' => 'nullable|array',
            'details.tools' => 'nullable|array',
            'details.available_days' => 'nullable|array',
            'details.meeting_start' => 'nullable|string|max:30',
            'details.meeting_end' => 'nullable|string|max:30',
            'details.collaboration_mode' => 'nullable|string|max:50',
            'details.experience' => 'nullable|string|max:5000',
            'details.is_complete' => 'nullable|boolean',
        ]);

        $data['skills'] = $data['skills'] ?? [];
        $data['interests'] = $data['interests'] ?? [];
        $data['preferred_role'] = $data['preferred_role'] ?? 'Frontend developer';
        $data['availability'] = $data['availability'] ?? ($data['details']['block'] ?? 'General');
        $data['details'] = $data['details'] ?? [];

        $user = $request->user();
        if ($user->role !== 'student') {
            return response()->json(['message' => 'Only students can save student profiles.'], 403);
        }

        $profile = DB::transaction(function () use ($user, $data): Profile {
            $user->update([
                'name' => $data['name'],
                'first_name' => $data['first_name'] ?? $user->first_name,
                'middle_name' => $data['middle_name'] ?? $user->middle_name,
                'last_name' => $data['last_name'] ?? $user->last_name,
                'department_or_section' => $data['details']['block'] ?? $user->department_or_section,
            ]);

            return Profile::updateOrCreate(['email' => $user->email], $data);
        });

        return response()->json($profile);
    }

    // READ all
    public function index()
    {
        return response()->json(Profile::all());
    }

    // CREATE
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:profiles,email',
            'skills' => 'required|array',
            'interests' => 'nullable|array',
            'preferred_role' => 'required|string',
            'availability' => 'required|string',
        ]);

        $profile = Profile::create($data);

        return response()->json($profile, 201);
    }

    // READ one
    public function show(Profile $profile)
    {
        return response()->json($profile);
    }

    // UPDATE
    public function update(Request $request, Profile $profile)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:profiles,email,'.$profile->id,
            'skills' => 'sometimes|array',
            'interests' => 'nullable|array',
            'preferred_role' => 'sometimes|string',
            'availability' => 'sometimes|string',
        ]);

        $profile->update($data);

        return response()->json($profile);
    }

    // DELETE
    public function destroy(Profile $profile)
    {
        $profile->delete();

        return response()->json(null, 204);
    }
}
