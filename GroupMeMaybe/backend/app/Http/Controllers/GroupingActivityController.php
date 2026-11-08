<?php

namespace App\Http\Controllers;

use App\Models\GroupingActivity;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

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

        if ($request->filled('class_id')) {
            $query->where('academic_class_id', $request->class_id);
        }

        $activities = $query->get();

        return response()->json($activities);
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
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'class_name' => 'required|string|max:255',
            'academic_class_id' => 'nullable|exists:academic_classes,id',
            'description' => 'nullable|string',
            'grouping_method' => 'required|string|in:auto,manual,hybrid',
            'group_capacity' => 'required|integer|min:2|max:50',
            'number_of_groups' => 'nullable|integer|min:1|max:100',
            'required_skills' => 'required|array|min:1',
            'required_skills.*' => 'string',
            'preferred_skills' => 'nullable|array',
            'preferred_skills.*' => 'string',
            'min_proficiency_level' => 'required|string|in:Beginner,Intermediate,Advanced',
            'min_common_hours' => 'required|integer|min:1|max:168',
            'grouping_deadline' => 'required|date',
            'student_modification_deadline' => 'nullable|date',
            'status' => 'nullable|string|in:draft,open,grouping in progress,completed',
            'students_count' => 'nullable|integer|min:0',
        ]);

        if (empty($validated['status'])) {
            $validated['status'] = 'open';
        }

        if (empty($validated['preferred_skills'])) {
            $validated['preferred_skills'] = [];
        }

        if (empty($validated['students_count'])) {
            $validated['students_count'] = 30;
        }

        if (empty($validated['number_of_groups']) && !empty($validated['group_capacity'])) {
            $validated['number_of_groups'] = (int) ceil($validated['students_count'] / $validated['group_capacity']);
        }

        $activity = GroupingActivity::create($validated);
        $activity->load('academicClass');

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

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'class_name' => 'sometimes|required|string|max:255',
            'academic_class_id' => 'nullable|exists:academic_classes,id',
            'description' => 'nullable|string',
            'grouping_method' => 'sometimes|required|string|in:auto,manual,hybrid',
            'group_capacity' => 'sometimes|required|integer|min:2|max:50',
            'number_of_groups' => 'nullable|integer|min:1|max:100',
            'required_skills' => 'sometimes|required|array|min:1',
            'required_skills.*' => 'string',
            'preferred_skills' => 'nullable|array',
            'preferred_skills.*' => 'string',
            'min_proficiency_level' => 'sometimes|required|string|in:Beginner,Intermediate,Advanced',
            'min_common_hours' => 'sometimes|required|integer|min:1|max:168',
            'grouping_deadline' => 'sometimes|required|date',
            'student_modification_deadline' => 'nullable|date',
            'status' => 'sometimes|required|string|in:draft,open,grouping in progress,completed',
            'students_count' => 'nullable|integer|min:0',
        ]);

        $activity->update($validated);
        $activity->load('academicClass');

        return response()->json($activity);
    }

    /**
     * Remove the specified grouping activity.
     */
    public function destroy(int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);
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

        $profiles = \App\Models\Profile::all();
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
        if (!empty($activity->formed_teams) && is_array($activity->formed_teams)) {
            foreach ($activity->formed_teams as $team) {
                $assignedCount += count($team['members'] ?? []);
            }
        }

        $unassignedCount = $isCompleted ? 0 : max(0, $totalStudents - $assignedCount);
        $hasScarcity = !$isCompleted && (count($scarceSkills) > 0);

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
        $activity = GroupingActivity::findOrFail($id);
        $strategy = $request->input('strategy', 'fill_incomplete');
        $capacity = $activity->group_capacity ?: 5;
        $numGroups = $activity->number_of_groups ?: (int) ceil(($activity->students_count ?: 30) / $capacity);

        $profiles = \App\Models\Profile::all();
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
                if (!empty($m['email'])) {
                    $assignedEmails[] = $m['email'];
                }
            }
        }

        // Get unassigned profiles
        $unassignedProfiles = $profiles->filter(function ($p) use ($assignedEmails) {
            return !in_array($p->email, $assignedEmails);
        })->values();

        $updatedTeams = [];

        if ($strategy === 'fill_incomplete' && !empty($currentTeams)) {
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
                    'name' => ($candidate->email === 'alex.santos@student.edu') ? 'Alex Santos (You)' : $candidate->name,
                    'email' => $candidate->email,
                    'role' => $isFirst ? 'Team Leader & ' . ($candidate->preferred_role ?: 'Developer') : ($candidate->preferred_role ?: 'Developer'),
                    'block' => $section,
                    'avatar' => strtoupper(substr($candidate->name, 0, 1)),
                    'is_leader' => $isFirst,
                ];
                $isFirst = false;
            }

            if (!empty($newTeamMembers)) {
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
                        'name' => ($candidate->email === 'alex.santos@student.edu') ? 'Alex Santos (You)' : $candidate->name,
                        'email' => $candidate->email,
                        'role' => $isFirst ? 'Team Leader & ' . ($candidate->preferred_role ?: 'Developer') : ($candidate->preferred_role ?: 'Developer'),
                        'block' => $section,
                        'avatar' => strtoupper(substr($candidate->name, 0, 1)),
                        'is_leader' => $isFirst,
                    ];
                    $isFirst = false;
                }

                if (!empty($groupMembers)) {
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
        $activity = GroupingActivity::findOrFail($id);
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'leader_name' => 'nullable|string',
            'leader_email' => 'nullable|email',
            'role' => 'nullable|string',
        ]);

        $section = explode(' - ', $activity->class_name)[1] ?? 'Class';
        $teams = $activity->formed_teams ?? [];

        $leaderName = $validated['leader_name'] ?? 'Alex Santos (You)';
        $leaderEmail = $validated['leader_email'] ?? 'alex.santos@student.edu';

        $newTeam = [
            'name' => $validated['name'],
            'is_auto_assigned' => false,
            'leader_email' => $leaderEmail,
            'members' => [
                [
                    'name' => $leaderName,
                    'email' => $leaderEmail,
                    'role' => 'Team Leader & ' . ($validated['role'] ?? 'Developer'),
                    'block' => $section,
                    'avatar' => strtoupper(substr($leaderName, 0, 1)),
                    'is_leader' => true,
                ],
            ],
        ];

        $teams[] = $newTeam;
        $activity->formed_teams = $teams;
        $activity->save();

        return response()->json($newTeam, 201);
    }

    /**
     * Invite a student to a team.
     */
    public function inviteStudent(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);
        $validated = $request->validate([
            'team_name' => 'required|string',
            'student_name' => 'required|string',
            'student_email' => 'nullable|string',
            'role' => 'nullable|string',
        ]);

        $teams = $activity->formed_teams ?? [];
        $found = false;
        $section = explode(' - ', $activity->class_name)[1] ?? 'Class';

        foreach ($teams as &$team) {
            if ($team['name'] === $validated['team_name']) {
                $members = $team['members'] ?? [];
                if (count($members) >= $activity->group_capacity) {
                    return response()->json(['message' => 'Team is already at maximum capacity'], 422);
                }

                $members[] = [
                    'name' => $validated['student_name'],
                    'email' => $validated['student_email'] ?? strtolower(str_replace(' ', '.', $validated['student_name'])) . '@student.edu',
                    'role' => $validated['role'] ?? 'Developer',
                    'block' => $section,
                    'avatar' => strtoupper(substr($validated['student_name'], 0, 1)),
                    'is_leader' => false,
                ];

                $team['members'] = $members;
                $found = true;
                break;
            }
        }

        if (!$found) {
            return response()->json(['message' => 'Team not found'], 404);
        }

        $activity->formed_teams = $teams;
        $activity->save();

        return response()->json(['success' => true, 'teams' => $teams]);
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
            if (!in_array($skill, $skills)) {
                $skills[] = $skill;
                $activity->required_skills = $skills;
            }
        } else {
            $skills = $activity->preferred_skills ?? [];
            if (!in_array($skill, $skills)) {
                $skills[] = $skill;
                $activity->preferred_skills = $skills;
            }
        }

        $activity->save();

        return response()->json($activity);
    }
}
