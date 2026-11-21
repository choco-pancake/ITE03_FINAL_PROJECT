<?php

namespace App\Http\Controllers;

use App\Models\AppNotification;
use App\Models\GroupingActivity;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user->role === 'student' && ($user->notification_preferences['group_activity'] ?? true)) {
            $this->addUpcomingDeadlines($user);
        }
        $query = AppNotification::where('user_id', $user->id);

        return response()->json([
            'notifications' => (clone $query)->latest()->limit(50)->get(),
            'unread_count' => (clone $query)->whereNull('read_at')->count(),
        ]);
    }

    public function markRead(Request $request, AppNotification $notification): JsonResponse
    {
        if ($notification->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Notification not found.'], 404);
        }
        if ($notification->read_at === null) {
            $notification->update(['read_at' => now()]);
        }

        return response()->json($notification);
    }

    public function preferences(Request $request): JsonResponse
    {
        return response()->json([
            'group_activity' => $request->user()->notification_preferences['group_activity'] ?? true,
            'custom_skills' => $request->user()->notification_preferences['custom_skills'] ?? true,
        ]);
    }

    public function updatePreferences(Request $request): JsonResponse
    {
        $data = $request->validate([
            'group_activity' => 'sometimes|boolean',
            'custom_skills' => 'sometimes|boolean',
        ]);
        $user = $request->user();
        $user->update(['notification_preferences' => array_merge($user->notification_preferences ?? [], $data)]);

        return $this->preferences($request);
    }

    private function addUpcomingDeadlines(User $user): void
    {
        $block = trim((string) $user->department_or_section);
        $activities = GroupingActivity::with('academicClass')
            ->where('status', 'open')
            ->where(function ($query): void {
                $query->whereBetween('grouping_deadline', [now(), now()->addHours(24)])
                    ->orWhereBetween('project_submission_deadline', [now(), now()->addHours(24)]);
            })
            ->get();

        foreach ($activities as $activity) {
            $section = $activity->academicClass?->section
                ?? (explode(' - ', $activity->class_name)[1] ?? '');
            if ($activity->academicClass !== null
                ? ! $activity->academicClass->students()->whereKey($user->id)->exists()
                : ($block === '' || strcasecmp(trim((string) $section), $block) !== 0)) {
                continue;
            }
            if ($activity->grouping_method === 'student_formed'
                && $activity->grouping_deadline->between(now(), now()->addHours(24))) {
                AppNotification::firstOrCreate(
                    ['user_id' => $user->id, 'event_key' => 'group_deadline:'.$activity->id.':'.$activity->grouping_deadline->timestamp],
                    [
                        'kind' => 'group_deadline',
                        'title' => 'Group submission deadline approaching',
                        'message' => '"'.$activity->title.'" groups are due within 24 hours.',
                        'target' => 'groups',
                    ]
                );
            }
            $projectDeadline = $activity->project_submission_deadline ?? $activity->grouping_deadline;
            if ($projectDeadline->between(now(), now()->addHours(24))) {
                AppNotification::firstOrCreate(
                    ['user_id' => $user->id, 'event_key' => 'project_deadline:'.$activity->id.':'.$projectDeadline->timestamp],
                    [
                        'kind' => 'project_deadline',
                        'title' => 'Project submission deadline approaching',
                        'message' => '"'.$activity->title.'" project is due within 24 hours.',
                        'target' => 'classes',
                    ]
                );
            }
        }
    }
}
