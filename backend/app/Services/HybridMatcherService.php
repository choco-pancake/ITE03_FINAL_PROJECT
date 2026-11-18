<?php

namespace App\Services;

use App\Models\Activity;
use App\Models\Team;
use App\Models\TeamMember;
use App\Models\User;

class HybridMatcherService
{
    const DEFAULT_SKILLS_WEIGHT = 0.40;
    const DEFAULT_HOURS_WEIGHT = 0.30;
    const DEFAULT_INTEREST_WEIGHT = 0.30;

    /**
     * Executes the 7-Step Hybrid Mode Computation
     */
    public function execute(
        Activity $activity,
        string $strategy = 'fillIncompleteFirst',
        float $ws = self::DEFAULT_SKILLS_WEIGHT,
        float $wh = self::DEFAULT_HOURS_WEIGHT,
        float $wi = self::DEFAULT_INTEREST_WEIGHT,
        ?int $customH = null
    ): array {
        $logs = [];
        $T = $activity->group_capacity > 0 ? $activity->group_capacity : 5;
        $H = $customH ?? ($activity->min_common_hours > 0 ? $activity->min_common_hours : 5);

        $logs[] = "--- HYBRID MODE COMPUTATION STARTED ---";
        $logs[] = "Activity: '{$activity->title}' | Target Capacity (T): {$T} | Min Common Hours (H): {$H} hrs/wk";
        $logs[] = "Weights: Skills " . intval($ws * 100) . "% | Hours " . intval($wh * 100) . "% | Interest " . intval($wi * 100) . "%";

        // Load existing teams for this activity with members
        $existingTeams = Team::with('members')->where('activity_id', $activity->id)->get();

        // Find assigned user IDs
        $assignedUserIds = [];
        foreach ($existingTeams as $t) {
            foreach ($t->members as $m) {
                $assignedUserIds[] = $m->user_id;
            }
        }

        // Find unassigned enrolled students in the class
        $enrolledStudents = User::whereHas('enrolledClasses', function ($q) use ($activity) {
            $q->where('academic_classes.id', $activity->class_id);
        })->whereNotIn('id', $assignedUserIds)->get();

        $initialU = $enrolledStudents->count();

        // STEP 1: Count students and open slots
        $incompleteTeams = $existingTeams->filter(fn ($t) => $t->members->count() < $T);
        $openSlots = 0;
        foreach ($incompleteTeams as $t) {
            $openSlots += ($T - $t->members->count());
        }

        $logs[] = "[Step 1] Unassigned Students (U): {$initialU}";
        $logs[] = "[Step 1] Incomplete Teams: {$incompleteTeams->count()} | Total Open Slots: {$openSlots}";

        if ($initialU === 0) {
            $logs[] = "No unassigned students to place. Hybrid formation complete.";
            return [
                'success' => true,
                'logs' => $logs,
                'swaps_performed' => 0,
                'balance_gap' => $this->calculateBalanceGap($existingTeams),
                'teams' => $existingTeams,
            ];
        }

        $pool = $enrolledStudents->values();
        $studentsUsedToFill = 0;
        $newTeamsTarget = 0;

        // STEP 2: Decide how many go where
        if ($strategy === 'fillIncompleteFirst') {
            $studentsUsedToFill = min($initialU, $openSlots);
            $leftoverCount = $initialU - $studentsUsedToFill;
            $newTeamsTarget = intdiv($leftoverCount, $T);
            $remainder = $leftoverCount % $T;

            $logs[] = "[Step 2] Strategy A: Fill Incomplete Teams First selected.";
            $logs[] = "[Step 2] Students allocated to fill slots: {$studentsUsedToFill} | Leftovers: {$leftoverCount}";
            $logs[] = "[Step 2] Base new teams to form: {$newTeamsTarget} | Remainder: {$remainder}";

            if ($remainder > 0) {
                if ($remainder >= $T - 1) {
                    $newTeamsTarget += 1;
                    $logs[] = "[Step 2] Remainder {$remainder} >= T-1 (" . ($T - 1) . "): forming 1 smaller team of size {$remainder}.";
                } else {
                    $logs[] = "[Step 2] Remainder {$remainder} < T-1 (" . ($T - 1) . "): distributing +1 extra members to teams (T+1 allowed, student never left alone).";
                }
            }
        } else {
            $newTeamsTarget = intdiv($initialU, $T);
            $remainder = $initialU % $T;
            $logs[] = "[Step 2] Strategy B: Form New Teams Only selected.";
            $logs[] = "[Step 2] New Teams to form: {$newTeamsTarget} | Remainder: {$remainder}";
        }

        // STEP 4: Fill incomplete teams (the "gain" computation)
        // Starting with those who have fewest free hours (hardest to place)
        if ($strategy === 'fillIncompleteFirst' && $studentsUsedToFill > 0) {
            $pool = $pool->sortBy('weekly_common_hours')->values();
            $placedCount = 0;
            $filledStudentsIds = [];

            foreach ($pool as $student) {
                if ($placedCount >= $studentsUsedToFill) {
                    break;
                }

                $bestTeam = null;
                $bestGain = -999.0;
                $bestNewScore = -1.0;

                foreach ($existingTeams as $team) {
                    if ($team->members->count() >= $T) {
                        continue; // skip full
                    }

                    $currentScore = $this->computeTeamScore($team->members->all(), $activity, $ws, $wh, $wi, $H);
                    $hypotheticalMembers = array_merge($team->members->all(), [$this->convertToMemberModel($student, $team->id, false)]);
                    $hypoScore = $this->computeTeamScore($hypotheticalMembers, $activity, $ws, $wh, $wi, $H);

                    if ($hypoScore < 0) {
                        continue; // rejected if common hours = 0
                    }

                    $gain = $hypoScore - $currentScore;
                    if ($gain > $bestGain) {
                        $bestGain = $gain;
                        $bestTeam = $team;
                        $bestNewScore = $hypoScore;
                    }
                }

                if ($bestTeam) {
                    if (!$bestTeam->is_auto_filled) {
                        $bestTeam->previous_score = $bestTeam->overall_compatibility;
                        $bestTeam->is_auto_filled = true;
                    }

                    $newMember = $this->convertToMemberModel($student, $bestTeam->id, false);
                    $newMember->save();
                    $bestTeam->load('members');

                    $this->recalculateTeamMetrics($bestTeam, $activity, $ws, $wh, $wi, $H);
                    $bestTeam->save();

                    $filledStudentsIds[] = $student->id;
                    $placedCount++;

                    $gainPct = round($bestGain * 100, 1);
                    $newPct = round($bestNewScore * 100, 1);
                    $logs[] = "[Step 4] Placed '{$student->full_name}' ({$student->weekly_common_hours}h free) into '{$bestTeam->name}'. Gain: " . ($gainPct >= 0 ? "+{$gainPct}" : $gainPct) . "% -> New Score: {$newPct}%";
                }
            }

            $pool = $pool->reject(fn ($s) => in_array($s->id, $filledStudentsIds))->values();
        }

        // STEP 5: Form new teams from leftover students (Seed + Gain)
        $newlyFormedTeams = collect();

        if ($pool->isNotEmpty() && $newTeamsTarget > 0) {
            $logs[] = "[Step 5] Forming {$newTeamsTarget} new teams from " . $pool->count() . " leftover students.";

            // 5a. Pick Seeds:
            // Seed 1 = student with most skills
            $pool = $pool->sortByDesc(fn ($s) => count($s->technical_skills ?? []))->values();
            $seeds = collect([$pool->shift()]);
            $logs[] = "[Step 5] Seed 1 picked: '{$seeds[0]->full_name}' with " . count($seeds[0]->technical_skills ?? []) . " skills.";

            // Subsequent seeds: lowest average pair compatibility to existing seeds
            while ($seeds->count() < $newTeamsTarget && $pool->isNotEmpty()) {
                $nextSeed = null;
                $lowestAvgCompat = 999.0;

                foreach ($pool as $candidate) {
                    $totalCompat = 0.0;
                    foreach ($seeds as $seed) {
                        $totalCompat += $this->computePairCompatibility($candidate, $seed);
                    }
                    $avgCompat = $totalCompat / $seeds->count();
                    if ($avgCompat < $lowestAvgCompat) {
                        $lowestAvgCompat = $avgCompat;
                        $nextSeed = $candidate;
                    }
                }

                if ($nextSeed) {
                    $seeds->push($nextSeed);
                    $pool = $pool->reject(fn ($s) => $s->id === $nextSeed->id)->values();
                    $logs[] = "[Step 5] Seed {$seeds->count()} picked: '{$nextSeed->full_name}' (Lowest Avg Pair Compat: " . round($lowestAvgCompat * 100, 1) . "%).";
                } else {
                    break;
                }
            }

            // Create teams for seeds
            $teamNumber = $existingTeams->count() + 1;
            foreach ($seeds as $seed) {
                $teamId = 'team-hybrid-' . time() . '-' . rand(100, 999);
                $newTeam = Team::create([
                    'id' => $teamId,
                    'name' => "Team {$teamNumber} (Hybrid)",
                    'activity_id' => $activity->id,
                    'class_id' => $activity->class_id,
                    'leader_id' => $seed->id,
                    'capacity' => $T,
                    'is_confirmed' => false,
                    'is_student_formed' => false,
                    'is_auto_filled' => true,
                ]);

                $member = $this->convertToMemberModel($seed, $newTeam->id, false);
                $member->save();

                $newTeam->load('members');
                $this->recalculateTeamMetrics($newTeam, $activity, $ws, $wh, $wi, $H);
                $newTeam->save();

                $newlyFormedTeams->push($newTeam);
                $existingTeams->push($newTeam);
                $teamNumber++;
            }

            // 5b. Add the rest using gain computation, fewest free hours first
            $pool = $pool->sortBy('weekly_common_hours')->values();
            $placedLeftovers = [];

            foreach ($pool as $student) {
                $bestTeam = null;
                $bestGain = -999.0;

                foreach ($newlyFormedTeams as $team) {
                    if ($team->members->count() >= $T + 1) {
                        continue;
                    }

                    $currentScore = $this->computeTeamScore($team->members->all(), $activity, $ws, $wh, $wi, $H);
                    $hypothetical = array_merge($team->members->all(), [$this->convertToMemberModel($student, $team->id, false)]);
                    $hypoScore = $this->computeTeamScore($hypothetical, $activity, $ws, $wh, $wi, $H);

                    if ($hypoScore < 0) {
                        continue;
                    }

                    $gain = $hypoScore - $currentScore;
                    if ($gain > $bestGain) {
                        $bestGain = $gain;
                        $bestTeam = $team;
                    }
                }

                if ($bestTeam) {
                    $member = $this->convertToMemberModel($student, $bestTeam->id, false);
                    $member->save();
                    $bestTeam->load('members');
                    $this->recalculateTeamMetrics($bestTeam, $activity, $ws, $wh, $wi, $H);
                    $bestTeam->save();

                    $placedLeftovers[] = $student->id;
                    $logs[] = "[Step 5] Added '{$student->full_name}' to '{$bestTeam->name}'. Gain: " . round($bestGain * 100, 1) . "%";
                }
            }

            $pool = $pool->reject(fn ($s) => in_array($s->id, $placedLeftovers))->values();
        }

        // STEP 6: Swap improvement (auto-assigned members only)
        $swapsCount = 0;
        $improvementFound = true;
        $pass = 1;

        $logs[] = "[Step 6] Running Swap Improvement (auto-assigned members only)...";

        while ($improvementFound && $pass <= 4) {
            $improvementFound = false;

            for ($i = 0; $i < $existingTeams->count(); $i++) {
                for ($j = $i + 1; $j < $existingTeams->count(); $j++) {
                    $teamX = $existingTeams[$i];
                    $teamY = $existingTeams[$j];

                    $unlockedX = $teamX->members->filter(fn ($m) => !$m->is_locked)->values();
                    $unlockedY = $teamY->members->filter(fn ($m) => !$m->is_locked)->values();

                    foreach ($unlockedX as $mx) {
                        foreach ($unlockedY as $my) {
                            $before = $this->computeTeamScore($teamX->members->all(), $activity, $ws, $wh, $wi, $H) +
                                      $this->computeTeamScore($teamY->members->all(), $activity, $ws, $wh, $wi, $H);

                            $hypoX = array_filter($teamX->members->all(), fn ($m) => $m->id !== $mx->id);
                            $hypoX[] = $my;

                            $hypoY = array_filter($teamY->members->all(), fn ($m) => $m->id !== $my->id);
                            $hypoY[] = $mx;

                            $scoreHypoX = $this->computeTeamScore($hypoX, $activity, $ws, $wh, $wi, $H);
                            $scoreHypoY = $this->computeTeamScore($hypoY, $activity, $ws, $wh, $wi, $H);

                            if ($scoreHypoX < 0 || $scoreHypoY < 0) {
                                continue;
                            }

                            $after = $scoreHypoX + $scoreHypoY;

                            if ($after > $before + 0.005) {
                                // Execute swap in database
                                $mx->team_id = $teamY->id;
                                $mx->save();
                                $my->team_id = $teamX->id;
                                $my->save();

                                $teamX->load('members');
                                $teamY->load('members');
                                $this->recalculateTeamMetrics($teamX, $activity, $ws, $wh, $wi, $H);
                                $this->recalculateTeamMetrics($teamY, $activity, $ws, $wh, $wi, $H);
                                $teamX->save();
                                $teamY->save();

                                $swapsCount++;
                                $improvementFound = true;
                                $diffPct = round(($after - $before) * 100, 1);
                                $logs[] = "[Step 6] Swapped auto-assigned '{$mx->name}' with '{$my->name}'. Score gain: +{$diffPct}%";
                                break 2;
                            }
                        }
                    }
                    if ($improvementFound) break;
                }
                if ($improvementFound) break;
            }
            $pass++;
        }

        $logs[] = "[Step 6] Swap improvement completed. Total swaps performed: {$swapsCount}";

        // STEP 7: Roles & balance indicator
        foreach ($existingTeams as $team) {
            $takenRoles = [];
            foreach ($team->members->filter(fn ($m) => $m->is_locked) as $m) {
                $takenRoles[] = $m->assigned_role;
            }

            foreach ($team->members->filter(fn ($m) => !$m->is_locked) as $m) {
                $user = User::find($m->user_id);
                $preferred = $user ? ($user->preferred_roles ?? []) : [];
                $chosenRole = 'Developer';

                foreach ($preferred as $pref) {
                    if (stripos($pref, 'leader') !== false && in_array('Project Leader / Team Leader', $takenRoles)) {
                        continue;
                    }
                    if (!in_array($pref, $takenRoles)) {
                        $chosenRole = $pref;
                        break;
                    }
                }

                $m->assigned_role = $chosenRole;
                $m->save();
                $takenRoles[] = $chosenRole;
            }

            if (empty($team->leader_id) && $team->members->isNotEmpty()) {
                $team->leader_id = $team->members->first()->user_id;
                $team->save();
            }
        }

        $balanceGap = $this->calculateBalanceGap($existingTeams);
        $logs[] = "[Step 7] Final Results: Balance Gap = {$balanceGap}% (" . ($balanceGap <= 15 ? "Well Balanced" : "Moderate Gap") . ")";

        return [
            'success' => true,
            'logs' => $logs,
            'swaps_performed' => $swapsCount,
            'balance_gap' => $balanceGap,
            'open_slots' => $openSlots,
            'unassigned_count' => $initialU,
            'students_filled' => $studentsUsedToFill,
            'new_teams_count' => $newlyFormedTeams->count(),
            'teams' => Team::with('members')->where('activity_id', $activity->id)->get(),
        ];
    }

    /**
     * TeamScore Formula:
     * TeamScore = ws * SkillCoverage + wh * CommonHoursRatio + wi * AvgInterest - Penalty
     */
    public function computeTeamScore(
        array $members,
        Activity $activity,
        float $ws = self::DEFAULT_SKILLS_WEIGHT,
        float $wh = self::DEFAULT_HOURS_WEIGHT,
        float $wi = self::DEFAULT_INTEREST_WEIGHT,
        int $H = 5
    ): float {
        if (empty($members)) {
            return 0.0;
        }

        // 1. Skill Coverage
        $reqSkills = $activity->required_skills ?? [];
        $skillCoverage = 0.0;

        if (!empty($reqSkills)) {
            $totalImportance = 0.0;
            $weightedCoverage = 0.0;

            foreach ($reqSkills as $req) {
                $importance = 1.0;
                $minLevelNeeded = 3;
                $totalImportance += $importance;

                $highestLevel = 0;
                foreach ($members as $m) {
                    $levels = is_array($m->skill_levels) ? $m->skill_levels : [];
                    $skills = is_array($m->skills) ? $m->skills : [];
                    $lvl = $levels[$req] ?? (in_array($req, $skills) ? 3 : 0);
                    if ($lvl > $highestLevel) $highestLevel = $lvl;
                }

                $ratio = min(1.0, $highestLevel / $minLevelNeeded);
                $weightedCoverage += ($ratio * $importance);
            }

            $skillCoverage = $totalImportance > 0 ? ($weightedCoverage / $totalImportance) : 0.8;
        } else {
            $distinct = [];
            $totalCount = 0;
            foreach ($members as $m) {
                $skills = is_array($m->skills) ? $m->skills : [];
                $distinct = array_unique(array_merge($distinct, $skills));
                $totalCount += count($skills);
            }
            $skillCoverage = $totalCount > 0 ? min(1.0, count($distinct) / $totalCount) : 0.75;
        }

        // 2. Common Hours Ratio
        $smallestFree = 999;
        foreach ($members as $m) {
            $hrs = $m->weekly_common_hours ?: 8;
            if ($hrs < $smallestFree) $smallestFree = $hrs;
        }
        if ($smallestFree <= 0) $smallestFree = 1;

        $commonHoursEstimate = $this->estimateCommonHours($members, $smallestFree);
        $commonHoursRatio = min(1.0, $commonHoursEstimate / $smallestFree);

        // 3. Avg Interest Overlap
        $avgInterest = 0.0;
        $count = count($members);
        if ($count >= 2) {
            $pairCount = 0;
            $totalJaccard = 0.0;
            for ($i = 0; $i < $count; $i++) {
                for ($j = $i + 1; $j < $count; $j++) {
                    $int1 = is_array($members[$i]->interests) ? $members[$i]->interests : [];
                    $int2 = is_array($members[$j]->interests) ? $members[$j]->interests : [];
                    $inter = count(array_intersect($int1, $int2));
                    $union = count(array_unique(array_merge($int1, $int2)));
                    $jaccard = $union > 0 ? ($inter / $union) : 0.3;
                    $totalJaccard += $jaccard;
                    $pairCount++;
                }
            }
            $avgInterest = $pairCount > 0 ? ($totalJaccard / $pairCount) : 0.3;
        } else {
            $avgInterest = 0.5;
        }

        // 4. Penalty
        // If common hours = 0, placement is rejected (-1.0)
        $penalty = 0.0;
        if ($commonHoursEstimate === 0) {
            return -1.0;
        } elseif ($commonHoursEstimate < $H) {
            $penalty = 0.3 * ($H - $commonHoursEstimate) / $H;
        }

        $score = ($ws * $skillCoverage) + ($wh * $commonHoursRatio) + ($wi * $avgInterest) - $penalty;
        return max(0.0, $score);
    }

    public function estimateCommonHours(array $members, int $smallestFree): int
    {
        if (empty($members)) return 0;
        if (count($members) === 1) return $members[0]->weekly_common_hours ?: 8;

        $commonDays = is_array($members[0]->available_days) ? $members[0]->available_days : [];
        for ($i = 1; $i < count($members); $i++) {
            $days = is_array($members[$i]->available_days) ? $members[$i]->available_days : [];
            $commonDays = array_intersect($commonDays, $days);
        }

        if (empty($commonDays)) {
            return max(0, intval($smallestFree * 0.2));
        }

        $firstDaysCount = count($members[0]->available_days ?? [1]);
        $dayRatio = count($commonDays) / max(1, $firstDaysCount);
        $estimated = intval(round($smallestFree * $dayRatio));
        return max(1, min($smallestFree, $estimated));
    }

    public function computePairCompatibility(User $u1, User $u2): float
    {
        $skills1 = $u1->technical_skills ?? [];
        $skills2 = $u2->technical_skills ?? [];
        $union = count(array_unique(array_merge($skills1, $skills2)));
        $inter = count(array_intersect($skills1, $skills2));
        $skillOverlap = $union > 0 ? ($inter / $union) : 0.0;

        $days1 = $u1->available_days ?? [];
        $days2 = $u2->available_days ?? [];
        $commonDays = count(array_intersect($days1, $days2));
        $smallerFree = min($u1->weekly_common_hours ?: 8, $u2->weekly_common_hours ?: 8);
        $hoursRatio = $smallerFree > 0 ? (($commonDays / 5.0) * $smallerFree) / $smallerFree : 0.5;

        $int1 = $u1->interests ?? [];
        $int2 = $u2->interests ?? [];
        $intUnion = count(array_unique(array_merge($int1, $int2)));
        $intInter = count(array_intersect($int1, $int2));
        $interestOverlap = $intUnion > 0 ? ($intInter / $intUnion) : 0.2;

        return (0.4 * (1.0 - $skillOverlap)) + (0.3 * min(1.0, max(0.0, $hoursRatio))) + (0.3 * min(1.0, max(0.0, $interestOverlap)));
    }

    private function convertToMemberModel(User $user, string $teamId, bool $isLocked = true): TeamMember
    {
        return new TeamMember([
            'team_id' => $teamId,
            'user_id' => $user->id,
            'name' => $user->full_name,
            'block' => $user->block ?: 'BSIT 2A',
            'assigned_role' => !empty($user->preferred_roles) ? $user->preferred_roles[0] : 'Developer',
            'is_locked' => $isLocked,
            'weekly_common_hours' => $user->weekly_common_hours ?: 8,
            'skills' => $user->technical_skills,
            'interests' => $user->interests,
            'available_days' => $user->available_days,
            'skill_levels' => $user->skill_levels,
        ]);
    }

    public function recalculateTeamMetrics(Team $team, Activity $activity, float $ws, float $wh, float $wi, int $H): void
    {
        $rawScore = $this->computeTeamScore($team->members->all(), $activity, $ws, $wh, $wi, $H);
        $team->overall_compatibility = round(min(100.0, max(0.0, $rawScore * 100)), 1);

        $smallestFree = 999;
        foreach ($team->members as $m) {
            $hrs = $m->weekly_common_hours ?: 8;
            if ($hrs < $smallestFree) $smallestFree = $hrs;
        }
        if ($smallestFree === 999) $smallestFree = 8;
        $commonHours = $this->estimateCommonHours($team->members->all(), $smallestFree);

        $team->availability_overlap = round(min(100.0, ($commonHours / $smallestFree) * 100), 1);
        $team->skill_coverage = round(min(100.0, max(50.0, $team->overall_compatibility * 0.45 + 50)), 1);
        $team->interest_match = round(min(100.0, max(55.0, $team->overall_compatibility * 0.40 + 55)), 1);
    }

    private function calculateBalanceGap($teams): float
    {
        if ($teams->isEmpty()) return 0.0;
        $scores = $teams->pluck('overall_compatibility')->filter(fn ($s) => $s > 0);
        if ($scores->isEmpty()) return 0.0;
        return round($scores->max() - $scores->min(), 1);
    }
}
