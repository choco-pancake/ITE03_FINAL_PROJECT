<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use App\Models\Team;
use App\Services\HybridMatcherService;
use Illuminate\Http\Request;

class TeamController extends Controller
{
    protected HybridMatcherService $hybridService;

    public function __construct(HybridMatcherService $hybridService)
    {
        $this->hybridService = $hybridService;
    }

    public function index($activityId)
    {
        $teams = Team::with('members')->where('activity_id', $activityId)->get();
        return response()->json([
            'teams' => $teams,
        ]);
    }

    public function show($id)
    {
        $team = Team::with('members')->findOrFail($id);
        return response()->json([
            'team' => $team,
        ]);
    }

    public function hybridMatch(Request $request, $activityId)
    {
        $activity = Activity::findOrFail($activityId);

        $strategy = $request->input('strategy', 'fillIncompleteFirst');
        $ws = floatval($request->input('skills_weight', 0.40));
        $wh = floatval($request->input('hours_weight', 0.30));
        $wi = floatval($request->input('interest_weight', 0.30));
        $customH = $request->has('min_common_hours') ? intval($request->input('min_common_hours')) : null;

        $result = $this->hybridService->execute($activity, $strategy, $ws, $wh, $wi, $customH);

        return response()->json($result);
    }
}
