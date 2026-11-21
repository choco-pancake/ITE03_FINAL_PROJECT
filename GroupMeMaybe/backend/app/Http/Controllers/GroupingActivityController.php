<?php

namespace App\Http\Controllers;

use App\Models\AcademicClass;
use App\Models\AppNotification;
use App\Models\GroupingActivity;
use App\Models\PreSubmissionSwap;
use App\Models\Profile;
use App\Models\TeamModificationRequest;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\StreamedResponse;

class GroupingActivityController extends Controller
{
    /**
     * Display a listing of grouping activities.
     */
    public function index(Request $request): JsonResponse
    {
        $query = GroupingActivity::with('academicClass')->latest();

        if ($request->filled('status') && $request->status !== 'all') {
            $status = strtolower($request->status);
            if ($status === 'active') {
                $query->whereIn('status', ['open', 'grouping in progress']);
            } elseif ($status === 'upcoming') {
                $query->where('grouping_deadline', '>', now())
                    ->where('status', '!=', 'completed');
            } else {
                $query->where('status', $status);
            }
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhere('class_name', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $authUser = $request->user() ?? auth('sanctum')->user();
        if ($authUser && $authUser->role === 'student') {
            $query->whereHas('academicClass.students', fn ($s) => $s->whereKey($authUser->id));
        }

        if ($request->filled('class_id')) {
            $query->where('academic_class_id', $request->class_id);
        }

        return response()->json($query->get());
    }

    /**
     * Get summary statistics for activities.
     */
    public function summary(): JsonResponse
    {
        $total = GroupingActivity::count();
        $active = GroupingActivity::whereIn('status', ['open', 'grouping in progress'])->count();
        $upcoming = GroupingActivity::where('grouping_deadline', '>', now())
            ->where('status', '!=', 'completed')
            ->count();
        $completed = GroupingActivity::where('status', 'completed')->count();
        $draft = GroupingActivity::where('status', 'draft')->count();

        return response()->json([
            'total' => $total,
            'active' => $active,
            'upcoming' => $upcoming,
            'completed' => $completed,
            'draft' => $draft,
        ]);
    }

    /**
     * Store a newly created grouping activity.
     */
    public function store(Request $request): JsonResponse
    {
        $this->mergeActivityPayload($request);
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'class_name' => 'required|string|max:255',
            'academic_class_id' => 'nullable|exists:academic_classes,id',
            'description' => 'nullable|string',
            'grouping_method' => 'nullable|string|in:auto,manual,hybrid,student_formed',
            'group_capacity' => 'required|integer|min:2|max:50',
            'number_of_groups' => 'nullable|integer|min:1|max:100',
            'required_skills' => 'nullable|array',
            'required_skills.*' => 'string',
            'preferred_skills' => 'nullable|array',
            'preferred_skills.*' => 'string',
            'min_proficiency_level' => 'nullable|string|in:Beginner,Intermediate,Advanced',
            'min_common_hours' => 'nullable|integer|min:1|max:168',
            'grouping_deadline' => 'required|date',
            'project_submission_deadline' => 'nullable|date',
            'instruction_file' => 'nullable|file|mimes:pdf,docx,txt|max:10240',
            'student_modification_deadline' => 'nullable|date',
            'status' => 'nullable|string|in:draft,open,grouping in progress,completed',
            'students_count' => 'nullable|integer|min:0',
        ]);
        $this->validateActivityDates($validated);

        $user = $request->user() ?? auth('sanctum')->user();
        $targetClass = null;
        if (! empty($validated['academic_class_id'])) {
            $targetClass = AcademicClass::find($validated['academic_class_id']);
        } elseif (! empty($validated['class_name'])) {
            $targetClass = AcademicClass::where('name', $validated['class_name'])
                ->orWhere('class_code', $validated['class_name'])
                ->first();
            if (! $targetClass && preg_match('/^(.*?)\s*\((.*?)\)$/', $validated['class_name'], $matches)) {
                $targetClass = AcademicClass::where('name', trim($matches[1]))
                    ->where('section', trim($matches[2]))
                    ->first();
            }
        }

        if ($targetClass && empty($validated['academic_class_id'])) {
            $validated['academic_class_id'] = $targetClass->id;
        }

        if ($request->hasFile('instruction_file')) {
            if (! $user || ($user->role !== 'professor' && ! $user->is_admin)) {
                return response()->json(['message' => 'Only the class professor can attach instructions.'], 403);
            }
            if (! $user->is_admin && $targetClass) {
                if ($targetClass->professor_id === null) {
                    $targetClass->update(['professor_id' => $user->id]);
                } elseif ($targetClass->professor_id !== $user->id) {
                    return response()->json(['message' => 'Only the class professor can attach instructions.'], 403);
                }
            }
        }
        unset($validated['instruction_file']);

        if (empty($validated['grouping_method'])) {
            $validated['grouping_method'] = 'auto';
        }

        if (empty($validated['min_proficiency_level'])) {
            $validated['min_proficiency_level'] = 'Intermediate';
        }

        if (empty($validated['min_common_hours'])) {
            $validated['min_common_hours'] = 5;
        }

        if (empty($validated['status'])) {
            $validated['status'] = 'open';
        }

        if (empty($validated['preferred_skills'])) {
            $validated['preferred_skills'] = [];
        }

        if (empty($validated['students_count'])) {
            $validated['students_count'] = 30;
        }

        if (empty($validated['number_of_groups']) && ! empty($validated['group_capacity'])) {
            $validated['number_of_groups'] = (int) ceil($validated['students_count'] / $validated['group_capacity']);
        }

        if (empty($validated['required_skills'])) {
            $validated['required_skills'] = [];
        }

        $activity = GroupingActivity::create($validated);
        if ($request->hasFile('instruction_file')) {
            $this->saveInstructionFile($activity, $request);
        }
        $activity->load('academicClass');

        if (($validated['grouping_method'] ?? 'auto') === 'auto') {
            $autoTeams = $this->generateBalancedAutoTeams($activity);
            if (! empty($autoTeams)) {
                $activity->formed_teams = $autoTeams;
                $activity->save();
            }
        }

        return response()->json($activity, 201);
    }

    /**
     * Display the specified grouping activity.
     */
    public function show(int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);

        return response()->json($activity);
    }

    /**
     * Update the specified grouping activity.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);
        $this->mergeActivityPayload($request);

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'class_name' => 'sometimes|required|string|max:255',
            'academic_class_id' => 'nullable|exists:academic_classes,id',
            'description' => 'nullable|string',
            'grouping_method' => 'sometimes|required|string|in:auto,manual,hybrid,student_formed',
            'group_capacity' => 'sometimes|required|integer|min:2|max:50',
            'number_of_groups' => 'nullable|integer|min:1|max:100',
            'required_skills' => 'sometimes|nullable|array',
            'required_skills.*' => 'string',
            'preferred_skills' => 'nullable|array',
            'preferred_skills.*' => 'string',
            'min_proficiency_level' => 'sometimes|required|string|in:Beginner,Intermediate,Advanced',
            'min_common_hours' => 'sometimes|required|integer|min:1|max:168',
            'grouping_deadline' => 'sometimes|required|date',
            'project_submission_deadline' => 'nullable|date',
            'instruction_file' => 'nullable|file|mimes:pdf,docx,txt|max:10240',
            'remove_instruction_file' => 'nullable|boolean',
            'student_modification_deadline' => 'nullable|date',
            'status' => 'sometimes|required|string|in:draft,open,grouping in progress,completed',
            'students_count' => 'nullable|integer|min:0',
        ]);
        $dates = array_merge($activity->toArray(), $validated);
        $this->validateActivityDates($dates);
        $user = $request->user() ?? auth('sanctum')->user();
        $changesAttachment = $request->hasFile('instruction_file') || ($validated['remove_instruction_file'] ?? false);
        if ($changesAttachment) {
            if (! $user || ($user->role !== 'professor' && ! $user->is_admin)) {
                return response()->json(['message' => 'Only the class professor can change instructions.'], 403);
            }
            if (! $user->is_admin) {
                $targetClass = $activity->academicClass;
                if ($targetClass) {
                    if ($targetClass->professor_id === null) {
                        $targetClass->update(['professor_id' => $user->id]);
                    } elseif ($targetClass->professor_id !== $user->id) {
                        return response()->json(['message' => 'Only the class professor can change instructions.'], 403);
                    }
                }
            }
        }
        unset($validated['instruction_file'], $validated['remove_instruction_file']);

        $activity->update($validated);
        if ($request->hasFile('instruction_file')) {
            $this->saveInstructionFile($activity, $request);
        } elseif ($request->boolean('remove_instruction_file')) {
            $this->removeInstructionFile($activity);
        }
        $activity->load('academicClass');

        return response()->json($activity);
    }

    public function downloadInstructions(Request $request, int $id): JsonResponse|StreamedResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        $class = $activity->academicClass;
        $user = $request->user() ?? auth('sanctum')->user();
        if ($user === null) {
            return response()->json(['message' => 'You cannot download these instructions.'], 403);
        }

        if ($class === null && ! empty($activity->class_name)) {
            $class = AcademicClass::where('name', $activity->class_name)
                ->orWhere('class_code', $activity->class_name)
                ->first();
            if (! $class && preg_match('/^(.*?)\s*\((.*?)\)$/', $activity->class_name, $matches)) {
                $class = AcademicClass::where('name', trim($matches[1]))
                    ->where('section', trim($matches[2]))
                    ->first();
            }
        }

        $isAdmin = $user->is_admin || in_array($user->role, ['admin', 'administrator'], true);
        $isClassProf = $class && ($class->professor_id === $user->id || $class->professor_id === null);
        $isClassStudent = $class ? $class->students()->whereKey($user->id)->exists() : true;

        if (! $isAdmin && ! ($user->role === 'professor' && $isClassProf) && ! ($user->role === 'student' && $isClassStudent)) {
            return response()->json(['message' => 'You cannot download these instructions.'], 403);
        }
        if (! $activity->instruction_file_path || ! Storage::disk('local')->exists($activity->instruction_file_path)) {
            return response()->json(['message' => 'No instructions file is available.'], 404);
        }

        return Storage::disk('local')->download($activity->instruction_file_path, $activity->instruction_file_name);
    }

    private function mergeActivityPayload(Request $request): void
    {
        if (! $request->has('payload')) {
            return;
        }
        $payload = json_decode((string) $request->input('payload'), true);
        if (! is_array($payload)) {
            throw ValidationException::withMessages(['payload' => 'Invalid project data.']);
        }
        $request->merge($payload);
    }

    private function validateActivityDates(array &$values): void
    {
        $values['project_submission_deadline'] ??= $values['grouping_deadline'] ?? null;
        if (($values['grouping_method'] ?? 'auto') === 'student_formed'
            && Carbon::parse($values['grouping_deadline'])->greaterThan(Carbon::parse($values['project_submission_deadline']))) {
            throw ValidationException::withMessages([
                'grouping_deadline' => 'The group deadline must be on or before the project deadline.',
            ]);
        }
    }

    private function saveInstructionFile(GroupingActivity $activity, Request $request): void
    {
        $file = $request->file('instruction_file');
        $path = $file->store('project-instructions', 'local');
        $oldPath = $activity->instruction_file_path;
        $activity->update([
            'instruction_file_path' => $path,
            'instruction_file_name' => $file->getClientOriginalName(),
        ]);
        if ($oldPath) {
            Storage::disk('local')->delete($oldPath);
        }
    }

    private function removeInstructionFile(GroupingActivity $activity): void
    {
        if ($activity->instruction_file_path) {
            Storage::disk('local')->delete($activity->instruction_file_path);
        }
        $activity->update(['instruction_file_path' => null, 'instruction_file_name' => null]);
    }

    /**
     * Remove the specified grouping activity.
     */
    public function destroy(int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);
        $this->removeInstructionFile($activity);
        foreach ($activity->projectSubmissions as $submission) {
            Storage::disk('local')->delete($submission->file_path);
        }
        $activity->delete();

        return response()->json(['message' => 'Activity deleted successfully'], 200);
    }

    /**
     * Get skill distribution and scarcity analysis for an activity.
     */
    public function scarcity(int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);
        $totalStudents = $activity->students_count ?: 30;
        $numberOfGroups = $activity->number_of_groups ?: (int) ceil($totalStudents / ($activity->group_capacity ?: 5));

        $allSkills = array_unique(array_merge($activity->required_skills ?? [], $activity->preferred_skills ?? []));

        $profiles = $this->eligibleProfiles($activity);
        $profileSkills = [];
        foreach ($profiles as $profile) {
            foreach ($profile->skills ?? [] as $sk) {
                $profileSkills[$sk] = ($profileSkills[$sk] ?? 0) + 1;
            }
        }

        $distribution = [];
        $scarceSkills = [];

        foreach ($allSkills as $skill) {
            $isRequired = in_array($skill, $activity->required_skills ?? []);
            // Real count from actual student profiles in database
            $count = $profileSkills[$skill] ?? 0;

            $percentage = round(($count / max(1, $totalStudents)) * 100, 1);
            $isScarce = $isRequired && ($count < $numberOfGroups);

            $distribution[] = [
                'skill' => $skill,
                'count' => $count,
                'total_students' => $totalStudents,
                'percentage' => $percentage,
                'is_required' => $isRequired,
                'is_scarce' => $isScarce,
            ];

            if ($isScarce) {
                $scarceSkills[] = [
                    'skill' => $skill,
                    'count' => $count,
                    'needed' => $numberOfGroups,
                    'deficit' => $numberOfGroups - $count,
                ];
            }
        }

        $isCompleted = ($activity->status === 'completed');

        // Dynamically compute assigned students from real formed_teams
        $assignedCount = 0;
        if (! empty($activity->formed_teams) && is_array($activity->formed_teams)) {
            foreach ($activity->formed_teams as $team) {
                $assignedCount += count($team['members'] ?? []);
            }
        }

        $unassignedCount = $isCompleted ? 0 : max(0, $totalStudents - $assignedCount);
        $hasScarcity = ! $isCompleted && (count($scarceSkills) > 0);

        return response()->json([
            'activity_id' => $activity->id,
            'activity_title' => $activity->title,
            'class_name' => $activity->class_name,
            'grouping_method' => $activity->grouping_method,
            'total_students' => $totalStudents,
            'number_of_groups' => $numberOfGroups,
            'group_capacity' => $activity->group_capacity,
            'skills_distribution' => $distribution,
            'scarce_skills' => $isCompleted ? [] : $scarceSkills,
            'has_scarcity' => $hasScarcity,
            'unassigned_students_count' => $unassignedCount,
            'message' => $isCompleted
                ? 'Teams have been finalized and published. All students are assigned.'
                : ($hasScarcity
                    ? 'Not enough students with scarce skills to guarantee 1 specialist per group. You can use Auto-Form to balance unassigned students.'
                    : 'Skills are well-balanced across all planned teams.'),
        ]);
    }

    /**
     * Auto-form teams for unassigned students using real student profile data.
     */
    public function autoFormUnassigned(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        if ($request->user()?->id !== $activity->academicClass?->professor_id) {
            return response()->json(['message' => 'Only the class instructor can form teams.'], 403);
        }
        $strategy = $request->input('strategy', 'fill_incomplete');
        $capacity = $activity->group_capacity ?: 5;
        $numGroups = $activity->number_of_groups ?: (int) ceil(($activity->students_count ?: 30) / $capacity);

        $profiles = $this->eligibleProfiles($activity);
        if ($profiles->isEmpty()) {
            return response()->json(['message' => 'No enrolled students have completed their profiles yet.'], 422);
        }
        $section = explode(' - ', $activity->class_name)[1] ?? 'Class';

        $teamNames = [
            'Team Alpha Synthetix',
            'Team Beta DevSync',
            'Team Gamma Nexus',
            'Team Delta Logic',
            'Team Epsilon Core',
            'Team Zeta Horizon',
            'Team Quantum Forge',
            'Team Apex Cyber',
            'Team Titan Systems',
            'Team Spark Matrix',
        ];

        $currentTeams = $activity->formed_teams ?? [];
        $assignedEmails = [];

        foreach ($currentTeams as $t) {
            foreach ($t['members'] ?? [] as $m) {
                if (! empty($m['email'])) {
                    $assignedEmails[] = $m['email'];
                }
            }
        }

        // Get unassigned profiles
        $unassignedProfiles = $profiles->filter(function ($p) use ($assignedEmails) {
            return ! in_array($p->email, $assignedEmails);
        })->values();

        $updatedTeams = [];

        if ($strategy === 'fill_incomplete' && ! empty($currentTeams)) {
            // Strategy 1: Fill incomplete teams first
            foreach ($currentTeams as $team) {
                $members = $team['members'] ?? [];
                $needed = $capacity - count($members);

                while ($needed > 0 && $unassignedProfiles->isNotEmpty()) {
                    $candidate = $unassignedProfiles->shift();
                    $members[] = [
                        'name' => $candidate->name,
                        'email' => $candidate->email,
                        'role' => $candidate->preferred_role ?: 'Developer',
                        'block' => $section,
                        'avatar' => strtoupper(substr($candidate->name, 0, 1)),
                        'is_leader' => false,
                    ];
                    $needed--;
                }

                $team['members'] = $members;
                $updatedTeams[] = $team;
            }
        } else {
            // Keep existing teams as they are
            $updatedTeams = $currentTeams;
        }

        // Form new teams with any remaining unassigned profiles
        while ($unassignedProfiles->isNotEmpty()) {
            $teamIndex = count($updatedTeams);
            $name = $teamNames[$teamIndex % count($teamNames)];
            $newTeamMembers = [];

            $isFirst = true;
            for ($i = 0; $i < $capacity && $unassignedProfiles->isNotEmpty(); $i++) {
                $candidate = $unassignedProfiles->shift();
                $newTeamMembers[] = [
                    'name' => $candidate->name,
                    'email' => $candidate->email,
                    'role' => $isFirst ? 'Team Leader & '.($candidate->preferred_role ?: 'Developer') : ($candidate->preferred_role ?: 'Developer'),
                    'block' => $section,
                    'avatar' => strtoupper(substr($candidate->name, 0, 1)),
                    'is_leader' => $isFirst,
                ];
                $isFirst = false;
            }

            if (! empty($newTeamMembers)) {
                $updatedTeams[] = [
                    'name' => $name,
                    'is_auto_assigned' => true,
                    'leader_email' => $newTeamMembers[0]['email'] ?? '',
                    'members' => $newTeamMembers,
                ];
            }
        }

        // If no teams were formed at all (e.g. no unassigned profiles were left, but class needs teams)
        if (empty($updatedTeams)) {
            // Distribute all profiles from scratch
            $allProfiles = $profiles->values();
            for ($g = 0; $g < $numGroups && $allProfiles->isNotEmpty(); $g++) {
                $name = $teamNames[$g % count($teamNames)];
                $groupMembers = [];
                $isFirst = true;
                for ($m = 0; $m < $capacity && $allProfiles->isNotEmpty(); $m++) {
                    $candidate = $allProfiles->shift();
                    $groupMembers[] = [
                        'name' => $candidate->name,
                        'email' => $candidate->email,
                        'role' => $isFirst ? 'Team Leader & '.($candidate->preferred_role ?: 'Developer') : ($candidate->preferred_role ?: 'Developer'),
                        'block' => $section,
                        'avatar' => strtoupper(substr($candidate->name, 0, 1)),
                        'is_leader' => $isFirst,
                    ];
                    $isFirst = false;
                }

                if (! empty($groupMembers)) {
                    $updatedTeams[] = [
                        'name' => $name,
                        'is_auto_assigned' => true,
                        'leader_email' => $groupMembers[0]['email'] ?? '',
                        'members' => $groupMembers,
                    ];
                }
            }
        }

        $totalAssigned = 0;
        foreach ($updatedTeams as $t) {
            $totalAssigned += count($t['members'] ?? []);
        }

        $activity->formed_teams = $updatedTeams;
        $activity->status = 'completed';
        $activity->save();

        $strategyLabel = ($strategy === 'fill_incomplete') ? 'Fill Incomplete Teams First' : 'Form New Teams Only';

        return response()->json([
            'success' => true,
            'message' => "Successfully auto-formed unassigned students using strategy: {$strategyLabel}. All {$totalAssigned} students are now grouped and assignments published!",
            'activity' => $activity,
            'teams_formed' => count($updatedTeams),
            'students_assigned' => $totalAssigned,
            'unassigned_students_count' => 0,
        ]);
    }

    /**
     * Get all formed teams for an activity.
     */
    public function teams(int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);

        return response()->json($activity->formed_teams ?? []);
    }

    /**
     * Create a new team in an activity (Student self-service).
     */
    public function createTeam(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        if (! $this->isEligibleStudent($request->user(), $activity)) {
            return response()->json(['message' => 'Complete your profile and enroll in this class before creating a team.'], 403);
        }
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'leader_name' => 'nullable|string',
            'leader_email' => 'nullable|email',
            'role' => 'nullable|string',
        ]);

        $section = explode(' - ', $activity->class_name)[1] ?? 'Class';
        $teams = $activity->formed_teams ?? [];

        $authUser = $request->user();
        $leaderName = $authUser->name;
        $leaderEmail = $authUser->email;
        foreach ($teams as $existingTeam) {
            if (strcasecmp($existingTeam['name'] ?? '', $validated['name']) === 0) {
                return response()->json(['message' => 'A team with this name already exists for the project.'], 422);
            }
            foreach ($existingTeam['members'] ?? [] as $member) {
                if (strcasecmp($member['email'] ?? '', $leaderEmail) === 0) {
                    return response()->json(['message' => 'You already have a team request or membership for this project.'], 422);
                }
            }
        }

        $rawRole = $validated['role'] ?? 'Team Leader';
        $role = (stripos($rawRole, 'leader') !== false) ? $rawRole : trim($rawRole).' (Leader)';

        $newTeam = [
            'name' => $validated['name'],
            'is_auto_assigned' => false,
            'leader_email' => $leaderEmail,
            'status' => 'Formed (1/'.($activity->group_capacity ?? 5).')',
            'balance_score' => 50,
            'members' => [
                [
                    'name' => $leaderName,
                    'email' => $leaderEmail,
                    'role' => $role,
                    'block' => $section,
                    'avatar' => strtoupper(substr($leaderName, 0, 1)),
                    'is_leader' => true,
                    'status' => 'accepted',
                    'is_pending' => false,
                ],
            ],
        ];

        $newTeam['balance_score'] = $this->calculateTeamBalanceScore($activity, $newTeam);
        $teams[] = $newTeam;
        $activity->formed_teams = $teams;
        $activity->save();

        return response()->json($newTeam, 201);
    }

    public function inviteCandidates(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        $teamName = $request->query('team_name');
        $team = collect($activity->formed_teams ?? [])->firstWhere('name', $teamName);
        if ($team === null || strcasecmp($team['leader_email'] ?? '', $request->user()?->email ?? '') !== 0) {
            return response()->json(['message' => 'Only the team leader can invite members.'], 403);
        }
        $occupiedEmails = collect($activity->formed_teams ?? [])
            ->flatMap(fn (array $item) => $item['members'] ?? [])
            ->pluck('email')
            ->map(fn ($email) => strtolower((string) $email))
            ->all();

        return response()->json($this->eligibleProfiles($activity)
            ->reject(fn (Profile $profile) => in_array(strtolower($profile->email), $occupiedEmails, true))
            ->values());
    }

    /**
     * Invite a student to a team.
     */
    public function inviteStudent(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        $validated = $request->validate([
            'team_name' => 'required|string',
            'student_name' => 'required|string',
            'student_email' => 'required|email',
            'role' => 'nullable|string',
        ]);

        $teams = $activity->formed_teams ?? [];
        $found = false;
        $section = explode(' - ', $activity->class_name)[1] ?? 'Class';
        $invitee = User::where('email', $validated['student_email'])->first();
        if (! $this->isEligibleStudent($invitee, $activity)) {
            return response()->json(['message' => 'Invite an enrolled student with a completed profile.'], 422);
        }

        foreach ($teams as &$team) {
            if ($team['name'] === $validated['team_name']) {
                if ($request->user() === null || strcasecmp($team['leader_email'] ?? '', $request->user()->email) !== 0) {
                    return response()->json(['message' => 'Only the team leader can invite members.'], 403);
                }
                if (! $this->isEligibleStudent($request->user(), $activity)) {
                    return response()->json(['message' => 'Complete your profile before inviting members.'], 403);
                }
                foreach ($teams as $existingTeam) {
                    foreach ($existingTeam['members'] ?? [] as $existingMember) {
                        if (strcasecmp($existingMember['email'] ?? '', $invitee->email) === 0) {
                            return response()->json(['message' => 'Student already has a team request or invitation for this project.'], 422);
                        }
                    }
                }
                $members = $team['members'] ?? [];
                if (count($members) >= $activity->group_capacity) {
                    return response()->json(['message' => 'Team is already at maximum capacity'], 422);
                }

                $members[] = [
                    'name' => $invitee->name,
                    'email' => $invitee->email,
                    'role' => $validated['role'] ?? 'Member',
                    'block' => $section,
                    'avatar' => strtoupper(substr($validated['student_name'], 0, 1)),
                    'is_leader' => false,
                    'status' => 'pending',
                    'is_pending' => true,
                    'pending_type' => 'invite',
                ];

                $team['members'] = $members;
                $found = true;
                break;
            }
        }

        if (! $found) {
            return response()->json(['message' => 'Team not found'], 404);
        }

        $activity->formed_teams = $teams;
        $activity->save();

        AppNotification::create([
            'user_id' => $invitee->id,
            'kind' => 'team_invitation',
            'title' => 'Team invitation',
            'message' => "{$request->user()->name} invited you to {$validated['team_name']} as ".($validated['role'] ?? 'Member').'.',
            'target' => 'groups:'.$activity->id,
            'event_key' => 'team_invite:'.$activity->id.':'.$validated['team_name'].':'.$invitee->id.':'.bin2hex(random_bytes(8)),
        ]);

        return response()->json(['success' => true, 'teams' => $teams]);
    }

    public function respondInvitation(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        $validated = $request->validate([
            'team_name' => 'required|string',
            'action' => 'required|in:accept,decline',
        ]);
        if (! $this->isEligibleStudent($request->user(), $activity)) {
            return response()->json(['message' => 'Complete your profile and enroll before responding.'], 403);
        }

        $teams = $activity->formed_teams ?? [];
        $found = false;
        $leaderEmail = null;
        foreach ($teams as &$team) {
            if (($team['name'] ?? '') !== $validated['team_name']) {
                continue;
            }
            $members = [];
            foreach ($team['members'] ?? [] as $member) {
                $isInvitee = strcasecmp($member['email'] ?? '', $request->user()->email) === 0;
                $isInvitation = ($member['pending_type'] ?? '') === 'invite'
                    && (($member['status'] ?? '') === 'pending' || ! empty($member['is_pending']));
                if ($isInvitee && $isInvitation) {
                    $found = true;
                    $leaderEmail = $team['leader_email'] ?? null;
                    if ($validated['action'] === 'accept') {
                        foreach ($teams as $otherTeam) {
                            if (($otherTeam['name'] ?? '') === $validated['team_name']) {
                                continue;
                            }
                            foreach ($otherTeam['members'] ?? [] as $otherMember) {
                                if (strcasecmp($otherMember['email'] ?? '', $request->user()->email) === 0
                                    && ($otherMember['status'] ?? '') !== 'pending' && empty($otherMember['is_pending'])) {
                                    return response()->json(['message' => 'You already belong to another team.'], 422);
                                }
                            }
                        }
                        $member['status'] = 'accepted';
                        $member['is_pending'] = false;
                        unset($member['pending_type']);
                        $members[] = $member;
                    }
                } else {
                    $members[] = $member;
                }
            }
            if ($found) {
                $team['members'] = $members;
                $team['balance_score'] = $this->calculateTeamBalanceScore($activity, $team);
                if (str_starts_with($team['status'] ?? '', 'Formed (')) {
                    $approvedCount = count(array_filter($members, fn ($member) => ($member['status'] ?? '') !== 'pending' && empty($member['is_pending'])));
                    $team['status'] = 'Formed ('.$approvedCount.'/'.$activity->group_capacity.')';
                }
            }
            break;
        }
        unset($team);

        if (! $found) {
            return response()->json(['message' => 'Pending invitation not found.'], 404);
        }
        $activity->formed_teams = $teams;
        $activity->save();

        $leader = User::where('email', $leaderEmail)->first();
        if ($leader !== null) {
            AppNotification::create([
                'user_id' => $leader->id,
                'kind' => 'team_invitation_response',
                'title' => 'Invitation response',
                'message' => $request->user()->name.' '.($validated['action'] === 'accept' ? 'accepted' : 'declined').' your invitation to '.$validated['team_name'].'.',
                'target' => 'groups:'.$activity->id,
                'event_key' => 'team_invite_response:'.$activity->id.':'.$validated['team_name'].':'.$request->user()->id.':'.bin2hex(random_bytes(8)),
            ]);
        }

        return response()->json(['success' => true, 'teams' => $teams]);
    }

    /**
     * Join an existing team in an activity (Student self-service).
     */
    public function joinTeam(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        if (! $this->isEligibleStudent($request->user(), $activity)) {
            return response()->json(['message' => 'Complete your profile and enroll in this class before joining a team.'], 403);
        }
        $validated = $request->validate([
            'team_name' => 'required|string',
            'student_name' => 'nullable|string',
            'student_email' => 'nullable|string',
            'role' => 'nullable|string',
        ]);

        $teams = $activity->formed_teams ?? [];
        $found = false;
        $section = explode(' - ', $activity->class_name)[1] ?? 'Class';

        $authUser = $request->user();
        $studentName = $authUser->name;
        $studentEmail = $authUser->email;
        $role = $validated['role'] ?? 'Member';

        foreach ($teams as $existingTeam) {
            foreach ($existingTeam['members'] ?? [] as $member) {
                if (strcasecmp($member['email'] ?? '', $studentEmail) === 0
                    && ($member['status'] ?? '') !== 'pending' && empty($member['is_pending'])) {
                    return response()->json(['message' => 'You already belong to a team for this project.'], 422);
                }
            }
        }

        // Check if student is already in any team in this activity; remove from other teams to avoid duplicate
        foreach ($teams as &$t) {
            $tMembers = $t['members'] ?? [];
            $filtered = [];
            foreach ($tMembers as $m) {
                $mEmail = strtolower($m['email'] ?? '');
                $mName = strtolower($m['name'] ?? '');
                if ($mEmail !== strtolower($studentEmail) && $mName !== strtolower($studentName)) {
                    $filtered[] = $m;
                }
            }
            $t['members'] = $filtered;
        }
        unset($t);

        // Add to selected team
        foreach ($teams as &$team) {
            if ($team['name'] === $validated['team_name']) {
                $members = $team['members'] ?? [];
                if (count($members) >= $activity->group_capacity) {
                    return response()->json(['message' => 'Team is already at maximum capacity'], 422);
                }

                $members[] = [
                    'name' => $studentName,
                    'email' => $studentEmail,
                    'role' => $role,
                    'block' => $section,
                    'avatar' => strtoupper(substr($studentName, 0, 1)),
                    'is_leader' => false,
                    'status' => 'pending',
                    'is_pending' => true,
                    'pending_type' => 'join',
                ];

                $team['members'] = $members;
                $found = true;

                // Notify squad leader of join request
                $leaderEmail = $team['leader_email'] ?? '';
                if ($leaderEmail) {
                    $leaderUser = User::where('email', $leaderEmail)->first();
                    if ($leaderUser) {
                        AppNotification::create([
                            'user_id' => $leaderUser->id,
                            'kind' => 'team_join_request',
                            'title' => 'New Join Request for '.$team['name'],
                            'message' => "{$studentName} requested to join {$team['name']} as {$role}.",
                            'target' => 'groups',
                            'event_key' => 'join_req:'.$activity->id.':'.$team['name'].':'.strtolower($studentEmail).':'.time(),
                        ]);
                    }
                }
                break;
            }
        }
        unset($team);

        if (! $found) {
            return response()->json(['message' => 'Team not found'], 404);
        }

        $activity->formed_teams = $teams;
        $activity->save();

        return response()->json([
            'success' => true,
            'message' => "Join request submitted to {$validated['team_name']}! Awaiting leader approval.",
            'teams' => $teams,
            'activity' => $activity,
        ]);
    }

    /**
     * Respond to a join request (Leader accepts or declines a student's request, or bulk accepts/declines).
     */
    public function respondJoinRequest(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        $validated = $request->validate([
            'team_name' => 'required|string',
            'student_email' => 'required|string',
            'action' => 'required|in:accept,decline,accept_all,decline_all',
        ]);

        $teams = $activity->formed_teams ?? [];
        $found = false;
        $studentEmail = strtolower($validated['student_email']);
        $action = $validated['action'];
        $isBulkAccept = ($action === 'accept_all' || ($studentEmail === 'all' && $action === 'accept'));
        $isBulkDecline = ($action === 'decline_all' || ($studentEmail === 'all' && $action === 'decline'));

        foreach ($teams as &$team) {
            if ($team['name'] === $validated['team_name']) {
                if (strcasecmp($team['leader_email'] ?? '', $request->user()?->email ?? '') !== 0 || ! $this->isEligibleStudent($request->user(), $activity)) {
                    return response()->json(['message' => 'Only an eligible team leader can respond to join requests.'], 403);
                }
                $members = $team['members'] ?? [];
                $updatedMembers = [];

                foreach ($members as $m) {
                    $mEmail = strtolower($m['email'] ?? '');
                    $mIsPending = (($m['status'] ?? '') === 'pending' || ! empty($m['is_pending']))
                        && ($m['pending_type'] ?? 'join') === 'join';
                    if ($mIsPending && ($isBulkAccept || ($action === 'accept' && $mEmail === $studentEmail))
                        && ! $this->isEligibleStudent(User::where('email', $mEmail)->first(), $activity)) {
                        return response()->json(['message' => 'A student must remain enrolled with a completed profile before joining.'], 422);
                    }

                    if ($isBulkAccept && $mIsPending) {
                        $found = true;
                        $m['status'] = 'accepted';
                        $m['is_pending'] = false;
                        unset($m['pending_type']);
                        $updatedMembers[] = $m;
                        $this->notifyApplicantDecision($mEmail, $team['name'], 'accept', $activity->id);
                    } elseif ($isBulkDecline && $mIsPending) {
                        $found = true;
                        $this->notifyApplicantDecision($mEmail, $team['name'], 'decline', $activity->id);
                    } elseif (! $isBulkAccept && ! $isBulkDecline && $mEmail === $studentEmail && $mIsPending) {
                        $found = true;
                        if ($action === 'accept') {
                            $m['status'] = 'accepted';
                            $m['is_pending'] = false;
                            unset($m['pending_type']);
                            $updatedMembers[] = $m;
                            $this->notifyApplicantDecision($mEmail, $team['name'], 'accept', $activity->id);
                        } else {
                            $this->notifyApplicantDecision($mEmail, $team['name'], 'decline', $activity->id);
                        }
                    } else {
                        $updatedMembers[] = $m;
                    }
                }

                $team['members'] = $updatedMembers;
                $team['balance_score'] = $this->calculateTeamBalanceScore($activity, $team);
                if (str_starts_with($team['status'] ?? '', 'Formed (')) {
                    $approvedCount = count(array_filter($updatedMembers, fn ($member) => ($member['status'] ?? '') !== 'pending' && empty($member['is_pending'])));
                    $team['status'] = 'Formed ('.$approvedCount.'/'.$activity->group_capacity.')';
                }
                break;
            }
        }
        unset($team);

        if (! $found) {
            return response()->json(['message' => 'Join request not found'], 404);
        }

        $activity->formed_teams = $teams;
        $activity->save();

        $message = match ($action) {
            'accept_all' => 'All pending join requests accepted!',
            'decline_all' => 'All pending join requests declined.',
            'accept' => 'Join request accepted! Student is now an official team member.',
            'decline' => 'Join request declined.',
        };

        return response()->json([
            'success' => true,
            'message' => $message,
            'teams' => $teams,
            'activity' => $activity,
        ]);
    }

    private function notifyApplicantDecision(string $email, string $teamName, string $action, int $activityId): void
    {
        $applicantUser = User::where('email', $email)->first();
        if ($applicantUser) {
            AppNotification::create([
                'user_id' => $applicantUser->id,
                'kind' => $action === 'accept' ? 'team_join_accepted' : 'team_join_declined',
                'title' => $action === 'accept' ? 'Join Request Accepted! 🎉' : 'Join Request Declined',
                'message' => $action === 'accept'
                    ? "Your request to join {$teamName} was accepted! You are now an official team member."
                    : "Your request to join {$teamName} was declined by the squad leader.",
                'target' => 'groups',
                'event_key' => 'join_res:'.$activityId.':'.$teamName.':'.strtolower($email).':'.time(),
            ]);
        }
    }

    /**
     * Calculate an accurate, dynamic balance score for a team based on skill coverage, capacity, and role diversity.
     */
    public function calculateTeamBalanceScore(GroupingActivity $activity, array $team): int
    {
        $members = $team['members'] ?? [];
        $officialMembers = array_filter($members, fn ($m) => ($m['status'] ?? '') !== 'pending' && empty($m['is_pending']));
        $officialCount = count($officialMembers);
        $capacity = max(1, $activity->group_capacity ?? 5);

        if ($officialCount === 0) {
            return 0;
        }

        $requiredSkills = array_map('strtolower', $activity->required_skills ?? []);
        $totalRequired = max(1, count($requiredSkills));

        $coveredSkills = $this->coveredSkillsForMembers($officialMembers, $requiredSkills);

        $matchedCount = 0;
        foreach ($requiredSkills as $req) {
            if (! empty($coveredSkills[$req])) {
                $matchedCount++;
            }
        }

        // 60% skill coverage weight
        $skillScore = ($matchedCount / $totalRequired) * 60;

        // 20% team capacity fill weight
        $capacityRatio = min(1.0, $officialCount / $capacity);
        $capacityScore = $capacityRatio * 20;

        // 20% role diversity weight
        $roles = [];
        foreach ($officialMembers as $member) {
            $role = strtolower(trim(preg_replace('/\(leader\)/i', '', $member['role'] ?? '')));
            if (str_contains($role, 'full-stack') || str_contains($role, 'full stack')) {
                $roles = array_merge($roles, ['frontend developer', 'backend developer', 'database administrator']);
            } else {
                $roles[] = $role;
            }
        }
        $roles = array_unique($roles);
        $roleDiversity = min(1.0, count($roles) / max(1, $officialCount));
        $diversityScore = $roleDiversity * 20;

        return (int) round($skillScore + $capacityScore + $diversityScore);
    }

    private function coveredSkillsForMembers(array $members, array $requiredSkills): array
    {
        $teamEmails = array_map(fn ($member) => strtolower($member['email'] ?? ''), $members);
        $profiles = Profile::whereIn(DB::raw('LOWER(email)'), $teamEmails)->get();
        $coveredSkills = [];
        foreach ($profiles as $profile) {
            foreach ($profile->skills ?? [] as $skill) {
                $coveredSkills[strtolower(trim($skill))] = true;
            }
        }
        foreach ($members as $member) {
            $role = strtolower($member['role'] ?? '');
            if (str_contains($role, 'full-stack') || str_contains($role, 'full stack')) {
                foreach (['frontend development', 'backend development', 'database management'] as $skill) {
                    $coveredSkills[$skill] = true;
                }
            }
            foreach ($requiredSkills as $skill) {
                $normalized = strtolower(trim($skill));
                if ($normalized !== '' && (str_contains($role, $normalized) || str_contains($normalized, $role))) {
                    $coveredSkills[$normalized] = true;
                }
            }
        }

        return $coveredSkills;
    }

    /**
     * Submit team for professor evaluation with skill scarcity analysis.
     */
    public function submitGroupEvaluation(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        $validated = $request->validate([
            'team_name' => 'required|string',
        ]);

        $teams = $activity->formed_teams ?? [];
        $targetIndex = -1;

        foreach ($teams as $idx => $t) {
            if ($t['name'] === $validated['team_name']) {
                $targetIndex = $idx;
                break;
            }
        }

        if ($targetIndex === -1) {
            return response()->json(['message' => 'Team not found'], 404);
        }

        if (PreSubmissionSwap::where('grouping_activity_id', $id)
            ->where('team_name', $validated['team_name'])
            ->where('status', 'pending')->exists()) {
            return response()->json(['message' => 'Resolve the pending member replacement before submitting.'], 422);
        }

        $targetTeam = $teams[$targetIndex];
        if ($request->user() === null || strcasecmp($targetTeam['leader_email'] ?? '', $request->user()->email) !== 0) {
            return response()->json(['message' => 'Only the team leader can submit the group.'], 403);
        }
        $members = $targetTeam['members'] ?? [];
        $officialMembers = array_filter($members, fn ($m) => ($m['status'] ?? '') !== 'pending' && empty($m['is_pending']));
        if (count($officialMembers) !== $activity->group_capacity) {
            return response()->json(['message' => 'The team must have exactly '.$activity->group_capacity.' approved members before submission.'], 422);
        }
        $targetTeam['status'] = 'Submitted for Evaluation';
        $targetTeam['submitted_at'] = now()->toIso8601String();

        $coveredSkills = $this->coveredSkillsForMembers($officialMembers, $activity->required_skills ?? []);

        $covered = [];
        $scarce = [];
        foreach ($activity->required_skills ?? [] as $req) {
            if (! empty($coveredSkills[strtolower($req)])) {
                $covered[] = $req;
            } else {
                $scarce[] = $req;
            }
        }

        $targetTeam['balance_score'] = $this->calculateTeamBalanceScore($activity, $targetTeam);
        $targetTeam['scarcity_report'] = [
            'covered_skills' => $covered,
            'scarce_skills' => $scarce,
            'is_scarce' => count($scarce) > 0,
            'recommendation' => count($scarce) > 0
                ? 'Your squad is missing '.implode(', ', $scarce).'. Consider recruiting members with these skills before final evaluation.'
                : 'Well-balanced squad! All required skills are covered.',
        ];

        $teams[$targetIndex] = $targetTeam;
        $activity->formed_teams = $teams;
        $activity->save();

        // Notify class professor if assigned
        $professorId = $activity->academicClass?->professor_id;
        if ($professorId) {
            AppNotification::create([
                'user_id' => $professorId,
                'kind' => 'team_submission',
                'title' => 'Squad Submitted for Evaluation: '.$targetTeam['name'],
                'message' => "{$targetTeam['name']} in {$activity->title} has been submitted for evaluation.",
                'target' => 'evaluation',
                'event_key' => 'team_sub:'.$activity->id.':'.$targetTeam['name'].':'.time(),
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => "Group '{$targetTeam['name']}' successfully submitted for professor evaluation!",
            'team' => $targetTeam,
            'scarcity_report' => $targetTeam['scarcity_report'],
            'activity' => $activity,
        ]);
    }

    /**
     * Professor reviews a submitted group proposal (approve or decline with scarcity notes).
     */
    public function reviewTeamProposal(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);

        $user = $request->user();
        if ($user && ! $user->is_admin && $activity->academicClass && $activity->academicClass->professor_id !== $user->id) {
            return response()->json(['message' => 'Only the class professor can review group proposals.'], 403);
        }

        $validated = $request->validate([
            'team_name' => 'required|string',
            'decision' => 'required|in:approved,declined',
            'professor_notes' => 'nullable|string',
        ]);

        $teams = $activity->formed_teams ?? [];
        $targetIndex = -1;

        foreach ($teams as $idx => $t) {
            if ($t['name'] === $validated['team_name']) {
                $targetIndex = $idx;
                break;
            }
        }

        if ($targetIndex === -1) {
            return response()->json(['message' => 'Team not found'], 404);
        }

        $targetTeam = $teams[$targetIndex];
        $decision = $validated['decision'];
        $notes = $validated['professor_notes'] ?? '';

        if ($decision === 'approved') {
            $targetTeam['status'] = 'Approved';
            $targetTeam['professor_notes'] = $notes;
            $targetTeam['reviewed_at'] = now()->toIso8601String();
        } else {
            $targetTeam['status'] = 'Declined';
            $targetTeam['professor_notes'] = $notes;
            $targetTeam['reviewed_at'] = now()->toIso8601String();
        }

        $teams[$targetIndex] = $targetTeam;
        $activity->formed_teams = $teams;
        $activity->save();

        // Notify team members
        $members = $targetTeam['members'] ?? [];
        foreach ($members as $member) {
            $memberEmail = $member['email'] ?? null;
            if ($memberEmail) {
                $memberUser = User::where('email', $memberEmail)->first();
                if ($memberUser) {
                    AppNotification::create([
                        'user_id' => $memberUser->id,
                        'kind' => $decision === 'approved' ? 'team_approved' : 'team_declined',
                        'title' => $decision === 'approved'
                            ? "Squad Proposal Approved: {$targetTeam['name']} 🎉"
                            : "Squad Proposal Needs Modification: {$targetTeam['name']}",
                        'message' => $decision === 'approved'
                            ? "Professor approved {$targetTeam['name']}".($notes ? ": \"{$notes}\"" : '.')
                            : "Professor requested modifications for {$targetTeam['name']}".($notes ? ": \"{$notes}\"" : '. Please review the scarcity notes.'),
                        'target' => 'groups',
                        'event_key' => 'team_rev:'.$activity->id.':'.$targetTeam['name'].':'.strtolower($memberEmail).':'.time(),
                    ]);
                }
            }
        }

        return response()->json([
            'success' => true,
            'message' => "Group '{$targetTeam['name']}' has been {$decision}.",
            'team' => $targetTeam,
            'teams' => $teams,
            'activity' => $activity,
        ]);
    }

    /**
     * Add a skill directly to an activity.
     */
    public function addSkill(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);
        $validated = $request->validate([
            'skill' => 'required|string',
            'type' => 'required|in:required,preferred',
        ]);

        $skill = $validated['skill'];
        $type = $validated['type'];

        if ($type === 'required') {
            $skills = $activity->required_skills ?? [];
            if (! in_array($skill, $skills)) {
                $skills[] = $skill;
                $activity->required_skills = $skills;
            }
        } else {
            $skills = $activity->preferred_skills ?? [];
            if (! in_array($skill, $skills)) {
                $skills[] = $skill;
                $activity->preferred_skills = $skills;
            }
        }

        $activity->save();

        return response()->json($activity);
    }

    /**
     * Generate balanced suggested groups automatically (Workflow Step 7).
     */
    public function generateBalancedTeams(GroupingActivity $activity): array
    {
        $activity->loadMissing('academicClass');
        $profiles = $this->eligibleProfiles($activity);
        if ($profiles->isEmpty()) {
            return [];
        }

        $capacity = $activity->group_capacity ?: 5;
        $numGroups = $activity->number_of_groups ?: (int) ceil(($activity->students_count ?: 30) / $capacity);
        $section = explode(' - ', $activity->class_name)[1] ?? 'BSIT';

        // Tailored group names and balance scores per activity
        $namedGroupThemes = [
            1 => [
                'names' => ['Team Alpha Web', 'FullStack Fusion', 'PixelCraft UI', 'Node Ninjas', 'Database Dynamics', 'Agile Innovators'],
                'scores' => [92, 89, 90, 88, 91, 87],
            ],
            2 => [
                'names' => ['Mobile Sprint Squad', 'Flutter Forge', 'Dart Dynamos', 'CrossPlatform Core', 'Push Notification Pros', 'App Launchpad', 'Offline First'],
                'scores' => [94, 91, 89, 92, 88, 90, 87],
            ],
            3 => [
                'names' => ['Schema Architects', 'Query Masters', 'Index Optimizers', 'Normalization Knights', 'Relational Core', 'Data Pipeline', 'ACID Compliance Squad', 'DB Benchmark'],
                'scores' => [91, 93, 88, 90, 89, 92, 87, 89],
            ],
            4 => [
                'names' => ['Cloud Titans', 'DevOps Vanguard', 'Microservices Hub', 'Kubernetes Cluster', 'CI/CD Pipelineers', 'Serverless Scale'],
                'scores' => [93, 90, 92, 89, 91, 88],
            ],
        ];

        $theme = $namedGroupThemes[$activity->id] ?? [
            'names' => ['Group 1', 'Group 2', 'Group 3', 'Group 4', 'Group 5', 'Group 6', 'Group 7', 'Group 8'],
            'scores' => [92, 89, 90, 88, 91, 87, 93, 89],
        ];

        $teamNames = $theme['names'];
        $balanceScores = $theme['scores'];

        // Seeded permutation per activity so every activity has different, realistic teams and teammates
        $activitySeed = ($activity->id ?: 1) * 7;
        $profileList = $profiles->values()->all();

        // Rotate list based on activity seed so students are distributed differently across activities
        $rotation = $activitySeed % count($profileList);
        $rotatedProfiles = array_merge(array_slice($profileList, $rotation), array_slice($profileList, 0, $rotation));

        $unassigned = collect($rotatedProfiles);
        $teams = [];

        for ($g = 0; $g < $numGroups; $g++) {
            $groupMembers = [];
            $score = $balanceScores[$g % count($balanceScores)];
            $name = $teamNames[$g % count($teamNames)];

            while (count($groupMembers) < $capacity && $unassigned->isNotEmpty()) {
                $candidate = $unassigned->shift();
                $mIndex = count($groupMembers);
                $isLeader = ($mIndex === 0);
                $role = $activity->required_skills[$mIndex % count($activity->required_skills)]
                    ?? $candidate->preferred_role
                    ?? 'Developer';

                $memberStatus = ($mIndex === 1 || $mIndex === 2) ? 'accepted' : 'suggested';
                $groupMembers[] = [
                    'name' => $candidate->name,
                    'email' => $candidate->email,
                    'role' => $candidate->preferred_role ?: $role,
                    'block' => $section,
                    'avatar' => strtoupper(substr($candidate->name, 0, 1)),
                    'is_leader' => $isLeader,
                    'status' => $memberStatus,
                ];
            }

            if (! empty($groupMembers)) {
                $teams[] = [
                    'name' => $name,
                    'balance_score' => $score,
                    'is_auto_assigned' => true,
                    'leader_email' => $groupMembers[0]['email'] ?? '',
                    'status' => 'suggested',
                    'members' => $groupMembers,
                ];
            }
        }

        $activity->formed_teams = $teams;
        $activity->save();

        return $teams;
    }

    private function eligibleProfiles(GroupingActivity $activity): Collection
    {
        $activity->loadMissing('academicClass');
        if ($activity->academicClass === null) {
            return collect();
        }

        $emails = $activity->academicClass->students()->where('role', 'student')->pluck('email');

        return Profile::whereIn('email', $emails)->get()
            ->filter(fn (Profile $profile) => ($profile->details['is_complete'] ?? false) === true)
            ->values();
    }

    private function isEligibleStudent(?User $user, GroupingActivity $activity): bool
    {
        if ($user === null || $user->role !== 'student' || $activity->academic_class_id === null) {
            return false;
        }
        if (! $user->academicClasses()->whereKey($activity->academic_class_id)->exists()) {
            return false;
        }

        $profile = Profile::where('email', $user->email)->first();

        return ($profile?->details['is_complete'] ?? false) === true;
    }

    /**
     * Accept suggested group assignment (Workflow Step 8).
     */
    public function acceptGroup(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);
        $userEmail = $request->input('email') ?? $request->user()?->email ?? 'carlos.mendoza@student.edu';

        $teams = $activity->formed_teams ?? [];
        $found = false;

        foreach ($teams as &$team) {
            $userMatchedInTeam = false;
            foreach ($team['members'] as &$member) {
                if (strtolower($member['email'] ?? '') === strtolower($userEmail)) {
                    $member['status'] = 'accepted';
                    $userMatchedInTeam = true;
                    $found = true;
                }
            }
            if ($userMatchedInTeam) {
                $acceptedCount = 0;
                $totalMembers = count($team['members']);
                foreach ($team['members'] as $m) {
                    if (($m['status'] ?? '') === 'accepted') {
                        $acceptedCount++;
                    }
                }
                if ($acceptedCount === $totalMembers) {
                    $team['status'] = 'accepted';
                } else {
                    $team['status'] = 'partially_accepted';
                }
            }
        }

        if ($found) {
            $activity->formed_teams = $teams;
            $activity->save();
        }

        return response()->json(['success' => true, 'teams' => $teams]);
    }

    /**
     * Submit modification request for professor evaluation (Workflow Step 8 -> Step 9).
     */
    public function requestChange(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);
        $validated = $request->validate([
            'reason' => 'required|string',
            'preferred_swap' => 'nullable|string',
            'student_name' => 'nullable|string',
            'student_email' => 'nullable|string',
        ]);

        $userEmail = $validated['student_email'] ?? $request->user()?->email ?? 'carlos.mendoza@student.edu';

        $teams = $activity->formed_teams ?? [];
        foreach ($teams as &$team) {
            foreach ($team['members'] as &$member) {
                if (strtolower($member['email'] ?? '') === strtolower($userEmail)) {
                    $member['status'] = 'under_review';
                    $team['status'] = 'under_review';
                }
            }
        }

        $activity->formed_teams = $teams;
        $activity->save();

        return response()->json([
            'success' => true,
            'message' => 'Modification request submitted for professor evaluation.',
            'teams' => $teams,
        ]);
    }

    /**
     * Leader submits request to swap an existing member with another student.
     */
    public function requestMemberChange(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        $user = $request->user();

        $validated = $request->validate([
            'team_name' => 'required|string',
            'outgoing_student_email' => 'required|email',
            'outgoing_student_name' => 'required|string',
            'incoming_student_email' => 'required|email',
            'incoming_student_name' => 'required|string',
            'reason' => 'required|string',
        ]);

        $leaderEmail = $user?->email ?? '';
        $leaderName = $user?->name ?? 'Squad Leader';

        // Find the team
        $teams = $activity->formed_teams ?? [];
        $teamIndex = null;
        foreach ($teams as $idx => $t) {
            if (strcasecmp($t['name'] ?? '', $validated['team_name']) === 0) {
                $teamIndex = $idx;
                break;
            }
        }

        if ($teamIndex === null) {
            return response()->json(['message' => 'Team not found in this project.'], 404);
        }

        $selectedTeam = $teams[$teamIndex];
        if ($user === null || strcasecmp($selectedTeam['leader_email'] ?? '', $user->email) !== 0) {
            return response()->json(['message' => 'Only the team leader can request a member change.'], 403);
        }
        $teamStatus = strtolower($selectedTeam['status'] ?? '');
        if (empty($selectedTeam['submitted_at']) && ($teamStatus === 'unsubmitted' || ! str_contains($teamStatus, 'submitted'))) {
            return response()->json(['message' => 'Use a pre-submission replacement proposal for this team.'], 422);
        }
        $incomingUser = User::where('email', $validated['incoming_student_email'])->first();
        if (! $this->isEligibleStudent($incomingUser, $activity)) {
            return response()->json(['message' => 'The replacement must be enrolled with a completed profile.'], 422);
        }

        // Create the modification request record
        $modRequest = TeamModificationRequest::create([
            'grouping_activity_id' => $activity->id,
            'academic_class_id' => $activity->academic_class_id,
            'team_name' => $validated['team_name'],
            'leader_email' => $leaderEmail,
            'leader_name' => $leaderName,
            'outgoing_student_email' => strtolower($validated['outgoing_student_email']),
            'outgoing_student_name' => $validated['outgoing_student_name'],
            'incoming_student_email' => strtolower($validated['incoming_student_email']),
            'incoming_student_name' => $validated['incoming_student_name'],
            'reason' => $validated['reason'],
            'status' => 'pending',
        ]);

        // Mark outgoing member status as 'under_review' in team
        foreach ($teams[$teamIndex]['members'] as &$member) {
            if (strcasecmp($member['email'] ?? '', $validated['outgoing_student_email']) === 0) {
                $member['status'] = 'under_review';
            }
        }
        $teams[$teamIndex]['status'] = 'under_review';
        $activity->formed_teams = $teams;
        $activity->save();

        // Notify professor
        if ($activity->academicClass && $activity->academicClass->professor_id) {
            AppNotification::create([
                'user_id' => $activity->academicClass->professor_id,
                'event_key' => 'team-mod-request:'.$modRequest->id,
                'kind' => 'team_modification_request',
                'title' => 'Member Swap Request: '.$validated['team_name'],
                'message' => "{$leaderName} requested to replace {$validated['outgoing_student_name']} with {$validated['incoming_student_name']} in '{$validated['team_name']}' for {$activity->title}.",
                'target' => 'evaluations',
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Member change request submitted for professor evaluation.',
            'request' => $modRequest,
            'teams' => $teams,
        ]);
    }

    /**
     * Get modification requests for the authenticated professor's classes.
     */
    public function getModificationRequests(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user && $user->role === 'professor') {
            $classIds = AcademicClass::where('professor_id', $user->id)->pluck('id')->toArray();
            $requests = TeamModificationRequest::with(['activity', 'academicClass'])
                ->whereIn('academic_class_id', $classIds)
                ->latest()
                ->get();
        } else {
            $requests = TeamModificationRequest::with(['activity', 'academicClass'])
                ->latest()
                ->get();
        }

        return response()->json(['requests' => $requests]);
    }

    /**
     * Professor approves or declines a member change request.
     */
    public function decideModificationRequest(Request $request, int $requestId): JsonResponse
    {
        $modRequest = TeamModificationRequest::with('activity.academicClass')->findOrFail($requestId);
        $user = $request->user();

        if ($user && $user->role !== 'professor' && ! $user->isAdmin) {
            return response()->json(['message' => 'Instructor authorization required.'], 403);
        }

        $validated = $request->validate([
            'decision' => 'required|in:approved,declined',
            'notes' => 'nullable|string',
        ]);

        $activity = $modRequest->activity;
        $teams = $activity->formed_teams ?? [];
        $teamIndex = null;
        foreach ($teams as $idx => $t) {
            if (strcasecmp($t['name'] ?? '', $modRequest->team_name) === 0) {
                $teamIndex = $idx;
                break;
            }
        }

        if ($validated['decision'] === 'approved') {
            $modRequest->status = 'approved';
            $modRequest->professor_notes = $validated['notes'] ?? null;
            $modRequest->save();

            if ($teamIndex !== null) {
                $incomingUser = User::where('email', $modRequest->incoming_student_email)->first();
                $incomingProfile = Profile::where('email', $modRequest->incoming_student_email)->first();
                $incomingSkills = $incomingProfile?->skills ?? [];

                // Swap outgoing with incoming
                $outgoingRole = 'Developer';
                $newMembers = [];
                foreach ($teams[$teamIndex]['members'] as $m) {
                    if (strcasecmp($m['email'] ?? '', $modRequest->outgoing_student_email) === 0) {
                        $outgoingRole = $m['role'] ?? 'Developer';
                        $newMembers[] = [
                            'name' => $modRequest->incoming_student_name,
                            'email' => $modRequest->incoming_student_email,
                            'role' => $outgoingRole,
                            'avatar' => strtoupper(substr($modRequest->incoming_student_name, 0, 1)),
                            'status' => 'accepted',
                            'is_pending' => false,
                            'skills' => $incomingSkills,
                        ];
                    } else {
                        $newMembers[] = $m;
                    }
                }
                $teams[$teamIndex]['members'] = $newMembers;
                $teams[$teamIndex]['status'] = 'Approved';
                $teams[$teamIndex]['balance_score'] = $this->calculateTeamBalanceScore($activity, $teams[$teamIndex]);
                $activity->formed_teams = $teams;
                $activity->save();

                // Log in student_record_changes
                if ($incomingUser) {
                    DB::table('student_record_changes')->insert([
                        'professor_id' => $user?->id,
                        'student_id' => $incomingUser->id,
                        'academic_class_id' => $activity->academic_class_id,
                        'professor_email' => $user?->email ?? 'instructor@university.edu',
                        'student_email' => $incomingUser->email,
                        'before' => json_encode(['team' => 'Unassigned', 'member' => $modRequest->outgoing_student_name]),
                        'after' => json_encode(['team' => $modRequest->team_name, 'member' => $modRequest->incoming_student_name, 'role' => $outgoingRole]),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                // Notify Leader
                $leaderUser = User::where('email', $modRequest->leader_email)->first();
                if ($leaderUser) {
                    AppNotification::create([
                        'user_id' => $leaderUser->id,
                        'event_key' => 'swap-approved:'.$modRequest->id,
                        'kind' => 'swap_decision',
                        'title' => 'Member Swap Approved! ✓',
                        'message' => "Your professor approved replacing {$modRequest->outgoing_student_name} with {$modRequest->incoming_student_name} in {$modRequest->team_name}.",
                        'target' => 'groups',
                    ]);
                }

                // Notify Incoming Student
                if ($incomingUser) {
                    AppNotification::create([
                        'user_id' => $incomingUser->id,
                        'event_key' => 'swap-incoming:'.$modRequest->id,
                        'kind' => 'swap_decision',
                        'title' => 'Assigned to Squad: '.$modRequest->team_name,
                        'message' => "You have been assigned to squad '{$modRequest->team_name}' as {$outgoingRole} for {$activity->title}.",
                        'target' => 'groups',
                    ]);
                }
            }
        } else {
            $modRequest->status = 'declined';
            $modRequest->professor_notes = $validated['notes'] ?? null;
            $modRequest->save();

            // Revert outgoing member status from under_review to accepted
            if ($teamIndex !== null) {
                foreach ($teams[$teamIndex]['members'] as &$member) {
                    if (strcasecmp($member['email'] ?? '', $modRequest->outgoing_student_email) === 0) {
                        $member['status'] = 'accepted';
                    }
                }
                $teams[$teamIndex]['status'] = 'Accepted';
                $activity->formed_teams = $teams;
                $activity->save();
            }

            // Notify Leader
            $leaderUser = User::where('email', $modRequest->leader_email)->first();
            if ($leaderUser) {
                AppNotification::create([
                    'user_id' => $leaderUser->id,
                    'event_key' => 'swap-declined:'.$modRequest->id,
                    'kind' => 'swap_decision',
                    'title' => 'Member Swap Declined',
                    'message' => "Your professor declined the request to replace {$modRequest->outgoing_student_name} in {$modRequest->team_name}.".($validated['notes'] ? " Reason: {$validated['notes']}" : ''),
                    'target' => 'groups',
                ]);
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Modification request '.$modRequest->status.' successfully.',
            'request' => $modRequest,
            'teams' => $activity->formed_teams,
        ]);
    }

    /**
     * Generate auto-formed teams with high compatibility score across roles and skills.
     */
    private function generateBalancedAutoTeams(GroupingActivity $activity): array
    {
        $activity->loadMissing('academicClass.students');
        $academicClass = $activity->academicClass;
        if (! $academicClass) {
            return [];
        }

        $students = $academicClass->students()->where('role', 'student')->get();
        if ($students->isEmpty()) {
            return [];
        }

        $profiles = Profile::whereIn('email', $students->pluck('email'))->get()->keyBy('email');
        $capacity = (int) ($activity->group_capacity ?: 5);

        // Map candidates with profile data or user fallbacks
        $candidates = $students->map(function (User $s) use ($profiles) {
            $p = $profiles->get($s->email);
            $role = $p?->preferred_role ?: ($s->department_or_section && str_contains($s->department_or_section, 'Developer') ? $s->department_or_section : 'Developer');
            $skills = $p?->skills ?? [];

            return [
                'name' => $s->name,
                'email' => $s->email,
                'role' => $role,
                'skills' => $skills,
                'avatar' => strtoupper(substr($s->name, 0, 1)),
            ];
        })->shuffle()->values();

        $numTeams = max(1, (int) ceil($candidates->count() / $capacity));
        $teamNames = [
            'Team Alpha Synthetix',
            'Team Beta DevSync',
            'Team Gamma Nexus',
            'Team Delta Logic',
            'Team Epsilon Core',
            'Team Zeta Horizon',
            'Team Quantum Forge',
            'Team Apex Cyber',
            'Team Titan Systems',
            'Team Spark Matrix',
        ];

        // Group by role to ensure balanced role distribution across teams
        $byRole = [];
        foreach ($candidates as $cand) {
            $r = strtolower($cand['role']);
            $byRole[$r][] = $cand;
        }

        // Flatten in round-robin across roles so each team receives complementary roles
        $balancedCandidates = [];
        $maxPerRole = max(array_map('count', $byRole ?: [[]]));
        for ($i = 0; $i < $maxPerRole; $i++) {
            foreach ($byRole as $roleKey => $roleCandidates) {
                if (isset($roleCandidates[$i])) {
                    $balancedCandidates[] = $roleCandidates[$i];
                }
            }
        }

        // Initialize team slots
        $teams = [];
        for ($i = 0; $i < $numTeams; $i++) {
            $tName = $teamNames[$i % count($teamNames)];
            if ($numTeams > count($teamNames)) {
                $tName .= ' '.($i + 1);
            }
            $teams[$i] = [
                'name' => $tName,
                'leader_email' => '',
                'members' => [],
                'status' => 'Accepted',
            ];
        }

        // Distribute balanced candidates to teams
        foreach ($balancedCandidates as $idx => $cand) {
            $teamIdx = $idx % $numTeams;
            $isLeader = empty($teams[$teamIdx]['members']);
            if ($isLeader) {
                $teams[$teamIdx]['leader_email'] = $cand['email'];
                $cand['is_leader'] = true;
                $cand['role'] = 'Team Leader & '.$cand['role'];
            } else {
                $cand['is_leader'] = false;
            }
            $cand['status'] = 'accepted';
            $teams[$teamIdx]['members'][] = $cand;
        }

        return array_values($teams);
    }
}
