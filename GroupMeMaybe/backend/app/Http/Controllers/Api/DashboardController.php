<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use App\Models\CustomSkillRequest;
use App\Models\Team;
use App\Models\User;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function getStudentDashboard(Request $request)
    {
        $userId = $request->header('X-User-Id');
        $student = $userId ? User::find($userId) : User::where('email', 'alex.santos@university.edu')->first();

        if (!$student) {
            $student = User::where('role', 'student')->first();
        }

        $myTeam = null;
        if ($student) {
            $myTeam = Team::with('members')
                ->whereHas('members', fn ($q) => $q->where('user_id', $student->id))
                ->first();
        }

        $activities = Activity::with('teams.members')->where('status', 'open')->get();

        return response()->json([
            'student' => $student,
            'my_team' => $myTeam,
            'open_activities_count' => $activities->count(),
            'activities' => $activities,
        ]);
    }

    public function getProfessorDashboard(Request $request)
    {
        $students = User::where('role', 'student')->get();
        $teams = Team::with('members')->get();
        $pendingSkills = CustomSkillRequest::where('status', 'pending')->get();

        $completeCount = $students->where('profile_status', 'complete')->count();
        $incompleteCount = $students->where('profile_status', 'incomplete')->count();
        $uninitializedCount = $students->where('profile_status', 'uninitialized')->count();

        // Calculate unassigned students
        $assignedUserIds = [];
        foreach ($teams as $t) {
            foreach ($t->members as $m) {
                $assignedUserIds[] = $m->user_id;
            }
        }
        $unassignedStudents = $students->whereNotIn('id', array_unique($assignedUserIds))->values();

        // Balance Gap
        $scores = $teams->pluck('overall_compatibility')->filter(fn ($s) => $s > 0);
        $balanceGap = $scores->isNotEmpty() ? round($scores->max() - $scores->min(), 1) : 0.0;

        return response()->json([
            'metrics' => [
                'total_students' => $students->count(),
                'complete_profiles' => $completeCount,
                'incomplete_profiles' => $incompleteCount,
                'uninitialized_profiles' => $uninitializedCount,
                'total_teams' => $teams->count(),
                'unassigned_count' => $unassignedStudents->count(),
                'pending_custom_skills' => $pendingSkills->count(),
                'balance_gap' => $balanceGap,
            ],
            'students' => $students,
            'unassigned_students' => $unassignedStudents,
            'teams' => $teams,
            'custom_skill_requests' => CustomSkillRequest::latest()->get(),
        ]);
    }
}
