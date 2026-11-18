<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use App\Models\Team;
use App\Models\User;
use Illuminate\Http\Request;

class ActivityController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->header('X-User-Id');
        $currentUser = $userId ? User::find($userId) : User::where('email', 'alex.santos@university.edu')->first();

        $activities = Activity::with('teams.members')->get()->map(function ($act) use ($currentUser) {
            // Find current user's team for this activity
            $myTeam = null;
            if ($currentUser) {
                $myTeam = Team::with('members')->where('activity_id', $act->id)
                    ->whereHas('members', fn ($q) => $q->where('user_id', $currentUser->id))
                    ->first();
            }

            return [
                'id' => $act->id,
                'class_id' => $act->class_id,
                'class_name' => $act->class_name,
                'title' => $act->title,
                'description' => $act->description,
                'grouping_method' => $act->grouping_method,
                'group_capacity' => $act->group_capacity,
                'needed_groups' => $act->needed_groups,
                'min_common_hours' => $act->min_common_hours,
                'min_proficiency_level' => $act->min_proficiency_level,
                'required_skills' => $act->required_skills ?: [],
                'preferred_skills' => $act->preferred_skills ?: [],
                'status' => $act->status,
                'grouping_deadline' => $act->grouping_deadline,
                'my_team' => $myTeam ? [
                    'id' => $myTeam->id,
                    'name' => $myTeam->name,
                    'members_count' => $myTeam->members->count(),
                    'capacity' => $myTeam->capacity,
                    'is_confirmed' => $myTeam->is_confirmed,
                    'overall_compatibility' => $myTeam->overall_compatibility,
                ] : null,
            ];
        });

        return response()->json([
            'activities' => $activities,
        ]);
    }

    public function show($id)
    {
        $activity = Activity::with(['teams.members'])->findOrFail($id);
        return response()->json([
            'activity' => $activity,
        ]);
    }
}
