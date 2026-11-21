<?php

namespace App\Http\Controllers;

use App\Models\AcademicClass;
use App\Models\GroupingActivity;
use App\Models\ProjectSubmission;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ProjectSubmissionController extends Controller
{
    public function classStatuses(Request $request, int $id): JsonResponse
    {
        $class = AcademicClass::with('activities.projectSubmissions')->findOrFail($id);
        if (! $this->canViewClass($request, $class)) {
            return response()->json(['message' => 'You cannot view this class.'], 403);
        }

        $statuses = [];
        foreach ($class->activities as $activity) {
            $submissions = $activity->projectSubmissions;
            if ($request->user()->role === 'professor') {
                $submittedCount = $submissions->count();
                $gradedCount = $submissions->whereNotNull('grade')->count();
                $statuses[$activity->id] = [
                    'submitted_group_count' => $submittedCount,
                    'graded_group_count' => $gradedCount,
                    'graded' => $submittedCount > 0 && $submittedCount === $gradedCount,
                ];

                continue;
            }

            $team = $this->memberTeam($activity, $request->user()->email);
            $submission = $team === null ? null : $submissions->firstWhere('team_name', $team['name']);
            $deadline = $activity->project_submission_deadline ?? $activity->grouping_deadline;
            $statuses[$activity->id] = [
                'team_name' => $team['name'] ?? null,
                'submitted' => $submission !== null,
                'graded' => $submission?->grade !== null,
                'grade' => $submission?->grade,
                'submission_id' => $submission?->id,
                'file_name' => $submission?->file_name,
                'submitted_at' => $submission?->submitted_at,
                'feedback' => $submission?->feedback,
                'can_submit' => $team !== null
                    && strcasecmp($team['leader_email'] ?? '', $request->user()->email) === 0
                    && now()->lessThanOrEqualTo($deadline),
            ];
        }

        return response()->json((object) $statuses);
    }

    public function index(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        if (! $this->canViewClass($request, $activity->academicClass)) {
            return response()->json(['message' => 'You cannot view this project.'], 403);
        }
        $query = $activity->projectSubmissions()->latest('submitted_at');
        if ($request->user()->role === 'student') {
            $team = $this->memberTeam($activity, $request->user()->email);
            if ($team === null) {
                return response()->json([]);
            }
            $query->where('team_name', $team['name']);
        }

        return response()->json($query->get());
    }

    public function store(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        $user = $request->user();
        if ($user->role !== 'student' || ! $this->canViewClass($request, $activity->academicClass)) {
            return response()->json(['message' => 'Only an enrolled team leader can submit this project.'], 403);
        }
        $validated = $request->validate([
            'team_name' => 'required|string|max:255',
            'file' => 'required|file|mimes:pdf,docx,txt,zip|max:10240',
        ]);
        $deadline = $activity->project_submission_deadline ?? $activity->grouping_deadline;
        if (now()->greaterThan($deadline)) {
            return response()->json(['message' => 'The project submission deadline has passed.'], 422);
        }
        $team = $this->memberTeam($activity, $user->email);
        if ($team === null || $team['name'] !== $validated['team_name']
            || strcasecmp($team['leader_email'] ?? '', $user->email) !== 0) {
            return response()->json(['message' => 'Only the approved team leader can submit this project.'], 403);
        }

        $file = $request->file('file');
        $path = $file->store('project-submissions', 'local');
        $existing = $activity->projectSubmissions()->where('team_name', $team['name'])->first();
        $submission = $activity->projectSubmissions()->updateOrCreate(
            ['team_name' => $team['name']],
            [
                'submitted_by' => $user->id,
                'file_path' => $path,
                'file_name' => $file->getClientOriginalName(),
                'submitted_at' => now(),
            ],
        );
        if ($existing !== null) {
            Storage::disk('local')->delete($existing->file_path);
        }

        return response()->json($submission, $existing === null ? 201 : 200);
    }

    public function download(Request $request, ProjectSubmission $submission): JsonResponse|StreamedResponse
    {
        $submission->load('activity.academicClass');
        $activity = $submission->activity;
        if (! $this->canViewClass($request, $activity->academicClass)
            || ($request->user()->role === 'student'
                && ($this->memberTeam($activity, $request->user()->email)['name'] ?? null) !== $submission->team_name)) {
            return response()->json(['message' => 'You cannot download this submission.'], 403);
        }
        if (! Storage::disk('local')->exists($submission->file_path)) {
            return response()->json(['message' => 'The submission file is unavailable.'], 404);
        }

        return Storage::disk('local')->download($submission->file_path, $submission->file_name);
    }

    public function grade(Request $request, ProjectSubmission $submission): JsonResponse
    {
        $submission->load('activity.academicClass');
        $class = $submission->activity->academicClass;
        if ($request->user()->role !== 'professor' || $class?->professor_id !== $request->user()->id) {
            return response()->json(['message' => 'Only the class professor can grade this submission.'], 403);
        }
        $deadline = $submission->activity->project_submission_deadline ?? $submission->activity->grouping_deadline;
        if (now()->lessThanOrEqualTo($deadline)) {
            return response()->json(['message' => 'Project grades can be recorded after the deadline.'], 422);
        }
        $validated = $request->validate([
            'grade' => 'required|numeric|between:0,100',
            'feedback' => 'nullable|string|max:5000',
        ]);
        $submission->update([
            'grade' => $validated['grade'],
            'feedback' => $validated['feedback'] ?? null,
            'graded_by' => $request->user()->id,
            'graded_at' => now(),
        ]);

        return response()->json($submission);
    }

    private function canViewClass(Request $request, ?AcademicClass $class): bool
    {
        if ($class === null) {
            return false;
        }
        $user = $request->user();
        if ($user->role === 'professor') {
            return $class->professor_id === $user->id;
        }

        return $user->role === 'student' && $class->students()->whereKey($user->id)->exists();
    }

    private function memberTeam(GroupingActivity $activity, string $email): ?array
    {
        foreach ($activity->formed_teams ?? [] as $team) {
            foreach ($team['members'] ?? [] as $member) {
                if (strcasecmp($member['email'] ?? '', $email) === 0
                    && ($member['status'] ?? '') !== 'pending' && empty($member['is_pending'])) {
                    return $team;
                }
            }
        }

        return null;
    }
}
