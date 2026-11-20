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

        foreach ($activities as $activity) {
            // Never auto-generate teams for student-made activities; only initialize legacy auto activities if completed/in progress
            if ($activity->grouping_method !== 'student_formed' && empty($activity->formed_teams) && in_array($activity->status, ['completed', 'grouping in progress'])) {
                $this->generateBalancedTeams($activity);
            }
        }

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
            'grouping_method' => 'nullable|string|in:auto,manual,hybrid',
            'group_capacity' => 'required|integer|min:2|max:50',
            'number_of_groups' => 'nullable|integer|min:1|max:100',
            'required_skills' => 'required|array|min:1',
            'required_skills.*' => 'string',
            'preferred_skills' => 'nullable|array',
            'preferred_skills.*' => 'string',
            'min_proficiency_level' => 'nullable|string|in:Beginner,Intermediate,Advanced',
            'min_common_hours' => 'nullable|integer|min:1|max:168',
            'grouping_deadline' => 'required|date',
            'student_modification_deadline' => 'nullable|date',
            'status' => 'nullable|string|in:draft,open,grouping in progress,completed',
            'students_count' => 'nullable|integer|min:0',
        ]);

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

        if (empty($validated['number_of_groups']) && !empty($validated['group_capacity'])) {
            $validated['number_of_groups'] = (int) ceil($validated['students_count'] / $validated['group_capacity']);
        }

        $activity = GroupingActivity::create($validated);
        $activity->load('academicClass');

        if ($activity->grouping_method !== 'student_formed' && $activity->status === 'completed' && empty($activity->formed_teams)) {
            $this->generateBalancedTeams($activity);
        }

        return response()->json($activity, 201);
    }

    /**
     * Display the specified grouping activity.
     */
    public function show(int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        if ($activity->grouping_method !== 'student_formed' && empty($activity->formed_teams) && in_array($activity->status, ['completed', 'grouping in progress'])) {
            $this->generateBalancedTeams($activity);
        }
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
                    'name' => $candidate->name,
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
                        'name' => $candidate->name,
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

        $authUser = $request->user();
        $leaderName = $validated['leader_name'] ?? ($authUser ? $authUser->name : 'Alex Santos');
        $leaderEmail = $validated['leader_email'] ?? ($authUser ? $authUser->email : 'alex.santos@student.edu');

        $rawRole = $validated['role'] ?? 'Team Leader & Developer';
        $role = (stripos($rawRole, 'leader') !== false) ? $rawRole : trim($rawRole) . ' (Leader)';

        $newTeam = [
            'name' => $validated['name'],
            'is_auto_assigned' => false,
            'leader_email' => $leaderEmail,
            'status' => 'Formed (1/' . ($activity->group_capacity ?? 5) . ')',
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
                    'status' => 'pending',
                    'is_pending' => true,
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
     * Join an existing team in an activity (Student self-service).
     */
    public function joinTeam(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);
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
        $studentName = $validated['student_name'] ?? ($authUser ? $authUser->name : 'Student User');
        $studentEmail = $validated['student_email'] ?? ($authUser ? $authUser->email : 'student@university.edu');
        $role = $validated['role'] ?? 'Developer';

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
                ];

                $team['members'] = $members;
                $found = true;

                // Notify squad leader of join request
                $leaderEmail = $team['leader_email'] ?? '';
                if ($leaderEmail) {
                    $leaderUser = \App\Models\User::where('email', $leaderEmail)->first();
                    if ($leaderUser) {
                        \App\Models\AppNotification::create([
                            'user_id' => $leaderUser->id,
                            'kind' => 'team_join_request',
                            'title' => 'New Join Request for ' . $team['name'],
                            'message' => "{$studentName} requested to join {$team['name']} as {$role}.",
                            'target' => 'groups',
                            'event_key' => 'join_req:' . $activity->id . ':' . $team['name'] . ':' . strtolower($studentEmail) . ':' . time(),
                        ]);
                    }
                }
                break;
            }
        }
        unset($team);

        if (!$found) {
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
        $activity = GroupingActivity::findOrFail($id);
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
                $members = $team['members'] ?? [];
                $updatedMembers = [];

                foreach ($members as $m) {
                    $mEmail = strtolower($m['email'] ?? '');
                    $mIsPending = ($m['status'] ?? '') === 'pending' || !empty($m['is_pending']);

                    if ($isBulkAccept && $mIsPending) {
                        $found = true;
                        $m['status'] = 'accepted';
                        $m['is_pending'] = false;
                        $updatedMembers[] = $m;
                        $this->notifyApplicantDecision($mEmail, $team['name'], 'accept', $activity->id);
                    } elseif ($isBulkDecline && $mIsPending) {
                        $found = true;
                        $this->notifyApplicantDecision($mEmail, $team['name'], 'decline', $activity->id);
                    } elseif (!$isBulkAccept && !$isBulkDecline && $mEmail === $studentEmail) {
                        $found = true;
                        if ($action === 'accept') {
                            $m['status'] = 'accepted';
                            $m['is_pending'] = false;
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
                break;
            }
        }
        unset($team);

        if (!$found) {
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
        $applicantUser = \App\Models\User::where('email', $email)->first();
        if ($applicantUser) {
            \App\Models\AppNotification::create([
                'user_id' => $applicantUser->id,
                'kind' => $action === 'accept' ? 'team_join_accepted' : 'team_join_declined',
                'title' => $action === 'accept' ? 'Join Request Accepted! 🎉' : 'Join Request Declined',
                'message' => $action === 'accept'
                    ? "Your request to join {$teamName} was accepted! You are now an official team member."
                    : "Your request to join {$teamName} was declined by the squad leader.",
                'target' => 'groups',
                'event_key' => 'join_res:' . $activityId . ':' . $teamName . ':' . strtolower($email) . ':' . time(),
            ]);
        }
    }

    /**
     * Calculate an accurate, dynamic balance score for a team based on skill coverage, capacity, and role diversity.
     */
    public function calculateTeamBalanceScore(GroupingActivity $activity, array $team): int
    {
        $members = $team['members'] ?? [];
        $officialMembers = array_filter($members, fn($m) => ($m['status'] ?? '') !== 'pending' && empty($m['is_pending']));
        $officialCount = count($officialMembers);
        $capacity = max(1, $activity->group_capacity ?? 5);

        if ($officialCount === 0) {
            return 0;
        }

        $requiredSkills = array_map('strtolower', $activity->required_skills ?? []);
        $totalRequired = max(1, count($requiredSkills));

        $teamEmails = array_map(fn($m) => strtolower($m['email'] ?? ''), $officialMembers);
        $profiles = \App\Models\Profile::whereIn(\DB::raw('LOWER(email)'), $teamEmails)->get();

        $coveredSkills = [];
        foreach ($profiles as $p) {
            foreach ($p->skills ?? [] as $sk) {
                $coveredSkills[strtolower($sk)] = true;
            }
        }
        foreach ($officialMembers as $m) {
            $mRole = strtolower($m['role'] ?? '');
            foreach ($requiredSkills as $req) {
                if (str_contains($mRole, $req) || str_contains($req, $mRole)) {
                    $coveredSkills[$req] = true;
                }
            }
        }

        $matchedCount = 0;
        foreach ($requiredSkills as $req) {
            if (!empty($coveredSkills[$req])) {
                $matchedCount++;
            }
        }

        // 60% skill coverage weight
        $skillScore = ($matchedCount / $totalRequired) * 60;

        // 20% team capacity fill weight
        $capacityRatio = min(1.0, $officialCount / $capacity);
        $capacityScore = $capacityRatio * 20;

        // 20% role diversity weight
        $roles = array_unique(array_map(fn($m) => strtolower(trim(preg_replace('/\(leader\)/i', '', $m['role'] ?? ''))), $officialMembers));
        $roleDiversity = min(1.0, count($roles) / max(1, $officialCount));
        $diversityScore = $roleDiversity * 20;

        return (int) round($skillScore + $capacityScore + $diversityScore);
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

        $targetTeam = $teams[$targetIndex];
        $targetTeam['status'] = 'Submitted for Evaluation';
        $targetTeam['submitted_at'] = now()->toIso8601String();

        // Calculate covered and scarce/missing skills
        $members = $targetTeam['members'] ?? [];
        $officialMembers = array_filter($members, fn($m) => ($m['status'] ?? '') !== 'pending' && empty($m['is_pending']));
        $teamEmails = array_map(fn($m) => strtolower($m['email'] ?? ''), $officialMembers);
        $profiles = \App\Models\Profile::whereIn(\DB::raw('LOWER(email)'), $teamEmails)->get();

        $coveredSkills = [];
        foreach ($profiles as $p) {
            foreach ($p->skills ?? [] as $sk) {
                $coveredSkills[strtolower($sk)] = true;
            }
        }
        foreach ($officialMembers as $m) {
            $mRole = strtolower($m['role'] ?? '');
            foreach ($activity->required_skills ?? [] as $req) {
                if (str_contains($mRole, strtolower($req)) || str_contains(strtolower($req), $mRole)) {
                    $coveredSkills[strtolower($req)] = true;
                }
            }
        }

        $covered = [];
        $scarce = [];
        foreach ($activity->required_skills ?? [] as $req) {
            if (!empty($coveredSkills[strtolower($req)])) {
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
                ? 'Your squad is missing ' . implode(', ', $scarce) . '. Consider recruiting members with these skills before final evaluation.'
                : 'Well-balanced squad! All required skills are covered.',
        ];

        $teams[$targetIndex] = $targetTeam;
        $activity->formed_teams = $teams;
        $activity->save();

        // Notify class professor if assigned
        $professorId = $activity->academicClass?->professor_id;
        if ($professorId) {
            \App\Models\AppNotification::create([
                'user_id' => $professorId,
                'kind' => 'team_submission',
                'title' => 'Squad Submitted for Evaluation: ' . $targetTeam['name'],
                'message' => "{$targetTeam['name']} in {$activity->title} has been submitted for evaluation.",
                'target' => 'evaluation',
                'event_key' => 'team_sub:' . $activity->id . ':' . $targetTeam['name'] . ':' . time(),
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

    /**
     * Generate balanced suggested groups automatically (Workflow Step 7).
     */
    public function generateBalancedTeams(GroupingActivity $activity): array
    {
        $profiles = \App\Models\Profile::all();
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

            if (!empty($groupMembers)) {
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
}
