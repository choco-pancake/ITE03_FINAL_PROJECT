<?php

namespace App\Http\Controllers;

use App\Models\AcademicClass;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AcademicClassController extends Controller
{
    /**
     * Display a listing of classes.
     */
    public function index(Request $request): JsonResponse
    {
        $query = AcademicClass::query()->withCount('activities');
        if ($request->user()->role === 'professor') {
            $query->where('professor_id', $request->user()->id);
        } elseif ($request->user()->role === 'student') {
            $query->whereHas('students', fn ($students) => $students->whereKey($request->user()->id));
        }

        $classes = $query->get();

        return response()->json($classes);
    }

    /**
     * Store a newly created class.
     */
    public function store(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'professor') {
            return response()->json(['message' => 'Only instructors can create classes.'], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'section' => 'nullable|string|max:50',
            'class_code' => 'required|string|unique:academic_classes,class_code',
            'description' => 'nullable|string',
        ]);

        $class = AcademicClass::create([
            ...$validated,
            'professor_id' => $request->user()->id,
            'student_count' => 0,
        ]);

        return response()->json($class, 201);
    }

    /**
     * Display the specified class.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $class = AcademicClass::with(['activities', 'students.profile'])->findOrFail($id);
        if (! $this->canView($request, $class)) {
            return response()->json(['message' => 'You cannot view this class.'], 403);
        }

        return response()->json($class);
    }

    /**
     * Retrieve students enrolled in the specified class.
     */
    public function students(Request $request, int $id): JsonResponse
    {
        $class = AcademicClass::findOrFail($id);
        if (! $this->canView($request, $class)) {
            return response()->json(['message' => 'You cannot view this class.'], 403);
        }

        $students = $class->students()->with('profile')->get()->map(function ($s) use ($class) {
            $details = is_array($s->profile?->details) ? $s->profile->details : [];
            $block = trim((string) ($details['block'] ?? ''));
            if ($block === '' && ! empty($class->section)) {
                $block = trim((string) $class->section);
            }
            if ($block === '') {
                $block = trim((string) ($s->department_or_section ?? ''));
            }

            return [
                'id' => $s->id,
                'name' => $s->name,
                'email' => $s->email,
                'student_id' => $details['student_id'] ?? '',
                'block' => $block,
                'year_level' => $details['year_level'] ?? '',
                'preferred_role' => $s->profile?->preferred_role ?? 'Developer',
                'skills' => $s->profile?->skills ?? [],
            ];
        });

        return response()->json($students);
    }

    /**
     * Update the specified class.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $class = AcademicClass::findOrFail($id);
        if ($request->user()->role !== 'professor' || $class->professor_id !== $request->user()->id) {
            return response()->json(['message' => 'Only the class instructor can edit this class.'], 403);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'section' => 'nullable|string|max:50',
            'class_code' => 'sometimes|string|unique:academic_classes,class_code,'.$id,
            'description' => 'nullable|string',
        ]);

        $class->update($validated);

        return response()->json($class);
    }

    /**
     * Remove the specified class.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $class = AcademicClass::findOrFail($id);
        if ($request->user()->role !== 'professor' || $class->professor_id !== $request->user()->id) {
            return response()->json(['message' => 'Only the class instructor can delete this class.'], 403);
        }

        $class->delete();

        return response()->json(null, 204);
    }

    public function enroll(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'student') {
            return response()->json(['message' => 'Only students can enroll in classes.'], 403);
        }

        $validated = $request->validate(['class_code' => 'required|string|max:255']);
        $rawCode = trim($validated['class_code']);
        $upperCode = strtoupper($rawCode);

        $class = AcademicClass::where('class_code', $upperCode)
            ->orWhere('class_code', $rawCode)
            ->orWhereRaw('UPPER(TRIM(class_code)) = ?', [$upperCode])
            ->first();

        if ($class === null) {
            return response()->json([
                'message' => "Class code \"{$rawCode}\" not found. Please verify the code with your instructor.",
            ], 404);
        }

        DB::transaction(function () use ($class, $request): void {
            $lockedClass = AcademicClass::whereKey($class->id)->lockForUpdate()->firstOrFail();
            $lockedClass->students()->syncWithoutDetaching([$request->user()->id]);
            $lockedClass->update(['student_count' => $lockedClass->students()->count()]);
        });

        return response()->json($class->refresh());
    }

    public function unenroll(Request $request, int $id, int $studentId): JsonResponse
    {
        $class = AcademicClass::findOrFail($id);
        $student = User::where('role', 'student')->findOrFail($studentId);
        $actor = $request->user();
        if ($actor->role !== 'professor' || $class->professor_id !== $actor->id) {
            return response()->json(['message' => 'You cannot unenroll this student.'], 403);
        }
        if (! $class->students()->whereKey($student->id)->exists()) {
            return response()->json(['message' => 'Student is not enrolled in this class.'], 404);
        }

        DB::transaction(function () use ($class, $student): void {
            $lockedClass = AcademicClass::whereKey($class->id)->lockForUpdate()->firstOrFail();
            $lockedClass->students()->detach($student->id);
            $lockedClass->update(['student_count' => $lockedClass->students()->count()]);

            foreach ($lockedClass->activities()->lockForUpdate()->get() as $activity) {
                $teams = [];
                foreach ($activity->formed_teams ?? [] as $team) {
                    $members = array_values(array_filter($team['members'] ?? [],
                        fn (array $member): bool => strcasecmp($member['email'] ?? '', $student->email) !== 0));
                    if ($members === []) {
                        continue;
                    }
                    if (strcasecmp($team['leader_email'] ?? '', $student->email) === 0) {
                        $newLeader = collect($members)->first(fn (array $member): bool => ($member['status'] ?? '') !== 'pending' && empty($member['is_pending']));
                        if ($newLeader === null) {
                            continue;
                        }
                        $team['leader_email'] = $newLeader['email'];
                        foreach ($members as &$member) {
                            $member['is_leader'] = strcasecmp($member['email'] ?? '', $newLeader['email']) === 0;
                        }
                        unset($member);
                    }
                    $team['members'] = $members;
                    if (str_starts_with($team['status'] ?? '', 'Formed (')) {
                        $approved = count(array_filter($members,
                            fn (array $member): bool => ($member['status'] ?? '') !== 'pending' && empty($member['is_pending'])));
                        $team['status'] = 'Formed ('.$approved.'/'.$activity->group_capacity.')';
                    }
                    $teams[] = $team;
                }
                $activity->update(['formed_teams' => $teams]);
                DB::table('pre_submission_swaps')
                    ->where('grouping_activity_id', $activity->id)
                    ->where('status', 'pending')
                    ->where(fn ($query) => $query->where('outgoing_email', $student->email)
                        ->orWhere('incoming_email', $student->email)
                        ->orWhere('leader_email', $student->email))
                    ->delete();
                DB::table('team_modification_requests')
                    ->where('grouping_activity_id', $activity->id)
                    ->where('status', 'pending')
                    ->where(fn ($query) => $query->where('outgoing_student_email', $student->email)
                        ->orWhere('incoming_student_email', $student->email)
                        ->orWhere('leader_email', $student->email))
                    ->delete();
                DB::table('app_notifications')
                    ->where('user_id', $student->id)
                    ->where('kind', 'team_invitation')
                    ->where('event_key', 'like', 'team_invite:'.$activity->id.':%')
                    ->delete();
                DB::table('app_notifications')
                    ->where('kind', 'team_join_request')
                    ->where('event_key', 'like', 'join_req:'.$activity->id.':%:'.strtolower($student->email).':%')
                    ->delete();
                DB::table('app_notifications')
                    ->where('user_id', $student->id)
                    ->where(fn ($query) => $query
                        ->where('event_key', 'like', 'group_deadline:'.$activity->id.':%')
                        ->orWhere('event_key', 'like', 'project_deadline:'.$activity->id.':%')
                        ->orWhere('event_key', 'like', 'deadline:'.$activity->id.':%'))
                    ->delete();
            }
        });

        return response()->json(['message' => 'Student unenrolled from this class.']);
    }

    private function canView(Request $request, AcademicClass $class): bool
    {
        if ($request->user()->role === 'admin') {
            return true;
        }
        if ($request->user()->role === 'professor') {
            return $class->professor_id === $request->user()->id;
        }

        return $request->user()->role === 'student'
            && $class->students()->whereKey($request->user()->id)->exists();
    }
}
