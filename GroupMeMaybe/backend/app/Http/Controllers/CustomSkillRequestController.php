<?php

namespace App\Http\Controllers;

use App\Models\AppNotification;
use App\Models\CustomSkillRequest;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CustomSkillRequestController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = CustomSkillRequest::query();
        if ($request->user()->role !== 'professor') {
            $query->where('user_id', $request->user()->id);
        }

        return response()->json([
            'requests' => $query->latest()->get(),
            'approved_skills' => CustomSkillRequest::where('status', 'approved')->distinct()->pluck('skill_name'),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'student') {
            return response()->json(['message' => 'Only students can request a skill.'], 403);
        }
        $data = $request->validate([
            'skill_name' => 'required|string|max:255',
            'domain' => 'nullable|string|max:255',
        ]);
        $details = Profile::where('email', $user->email)->first()?->details ?? [];

        $skillRequest = DB::transaction(function () use ($user, $data, $details): CustomSkillRequest {
            $skillRequest = CustomSkillRequest::create([
                'user_id' => $user->id,
                'student_name' => $user->name,
                'student_id' => $details['student_id'] ?? null,
                'block' => $details['block'] ?? $user->department_or_section,
                'skill_name' => trim($data['skill_name']),
                'domain' => $data['domain'] ?? 'Custom Student Request',
                'status' => 'pending',
            ]);
            User::where('role', 'professor')->get()->each(function (User $professor) use ($skillRequest): void {
                if (($professor->notification_preferences['custom_skills'] ?? true) === false) {
                    return;
                }
                AppNotification::create([
                    'user_id' => $professor->id,
                    'event_key' => 'skill-request:'.$skillRequest->id,
                    'kind' => 'skill_request',
                    'title' => 'New custom skill request',
                    'message' => $skillRequest->student_name.' requested "'.$skillRequest->skill_name.'".',
                    'target' => 'skill_requests',
                ]);
            });

            return $skillRequest;
        });

        return response()->json($skillRequest, 201);
    }

    public function update(Request $request, CustomSkillRequest $skillRequest): JsonResponse
    {
        if ($request->user()->role !== 'professor') {
            return response()->json(['message' => 'Only professors can decide requests.'], 403);
        }
        $data = $request->validate([
            'status' => 'required|in:approved,rejected',
            'remarks' => 'nullable|string|max:1000',
        ]);
        if (in_array($skillRequest->status, ['approved', 'rejected'], true)) {
            return response()->json(['message' => 'This request has already been decided.'], 409);
        }

        DB::transaction(function () use ($skillRequest, $data): void {
            $skillRequest->update(['status' => $data['status'], 'remarks' => $data['remarks'] ?? null]);
            $student = User::find($skillRequest->user_id);
            if ($student === null) {
                return;
            }
            $profile = Profile::where('email', $student->email)->first();
            if ($profile !== null) {
                $skills = $profile->skills ?? [];
                if ($data['status'] === 'approved' && ! in_array($skillRequest->skill_name, $skills, true)) {
                    $skills[] = $skillRequest->skill_name;
                } elseif ($data['status'] === 'rejected') {
                    $skills = array_values(array_filter($skills, fn (string $skill): bool => $skill !== $skillRequest->skill_name));
                }
                $profile->update(['skills' => $skills]);
            }
            if (($student->notification_preferences['custom_skills'] ?? true) !== false) {
                AppNotification::create([
                    'user_id' => $student->id,
                    'event_key' => 'skill-decision:'.$skillRequest->id,
                    'kind' => 'skill_decision',
                    'title' => $data['status'] === 'approved' ? 'Skill approved' : 'Skill request declined',
                    'message' => 'Your request for "'.$skillRequest->skill_name.'" was '.$data['status'].'.',
                    'target' => 'profile',
                ]);
            }
        });

        return response()->json($skillRequest->fresh());
    }
}
