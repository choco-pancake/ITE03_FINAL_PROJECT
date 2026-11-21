<?php

namespace App\Http\Controllers;

use App\Models\AppNotification;
use App\Models\GroupingActivity;
use App\Models\PreSubmissionSwap;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PreSubmissionSwapController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $email = strtolower($request->user()->email);
        $swaps = PreSubmissionSwap::where('status', 'pending')
            ->where(function ($query) use ($email): void {
                $query->where('leader_email', $email)
                    ->orWhere('outgoing_email', $email)
                    ->orWhere('incoming_email', $email);
            })->get();

        return response()->json(['swaps' => $swaps]);
    }

    public function store(Request $request, int $id): JsonResponse
    {
        $data = $request->validate([
            'team_name' => 'required|string',
            'outgoing_email' => 'required|email',
            'incoming_email' => 'required|email|different:outgoing_email',
            'reason' => 'required|string',
        ]);
        $result = DB::transaction(function () use ($request, $id, $data): array {
            $activity = GroupingActivity::with('academicClass')->lockForUpdate()->findOrFail($id);
            $teams = $activity->formed_teams ?? [];
            $team = collect($teams)->first(fn ($item) => ($item['name'] ?? '') === $data['team_name']);
            if ($team === null) {
                return [404, 'Team not found.'];
            }
            if (strtolower($team['leader_email'] ?? '') !== strtolower($request->user()->email)) {
                return [403, 'Only the team leader can propose a replacement.'];
            }
            if ($this->isSubmitted($team)) {
                return [422, 'Submitted teams must use professor review.'];
            }
            if (PreSubmissionSwap::where('grouping_activity_id', $id)->where('team_name', $data['team_name'])->where('status', 'pending')->exists()) {
                return [422, 'A replacement is already pending for this team.'];
            }
            $outgoing = collect($team['members'] ?? [])->first(fn ($member) => strtolower($member['email'] ?? '') === strtolower($data['outgoing_email']) && empty($member['is_pending']) && ($member['status'] ?? '') !== 'pending');
            if ($outgoing === null || ! empty($outgoing['is_leader'])) {
                return [422, 'Choose an official member other than the leader.'];
            }
            $incoming = User::whereRaw('LOWER(email) = ?', [strtolower($data['incoming_email'])])->where('role', 'student')->first();
            if ($incoming === null || $activity->academicClass === null || ! $activity->academicClass->students()->whereKey($incoming->id)->exists()) {
                return [422, 'The replacement must be an enrolled student.'];
            }
            if ((Profile::where('email', $incoming->email)->first()?->details['is_complete'] ?? false) !== true) {
                return [422, 'The replacement must complete their profile first.'];
            }
            foreach ($teams as $otherTeam) {
                foreach ($otherTeam['members'] ?? [] as $member) {
                    if (strtolower($member['email'] ?? '') === strtolower($incoming->email)) {
                        return [422, 'The replacement is already in a team for this project.'];
                    }
                }
            }
            $swap = PreSubmissionSwap::create([
                'grouping_activity_id' => $id,
                'team_name' => $data['team_name'],
                'leader_email' => strtolower($request->user()->email),
                'outgoing_email' => strtolower($outgoing['email']),
                'incoming_email' => strtolower($incoming->email),
                'incoming_role' => $outgoing['role'] ?? 'Member',
                'reason' => $data['reason'],
            ]);
            foreach ([$outgoing['email'], $incoming->email] as $email) {
                $recipient = User::whereRaw('LOWER(email) = ?', [strtolower($email)])->first();
                if ($recipient !== null) {
                    $this->notify($recipient, $swap, 'Member replacement proposal', "A replacement was proposed for {$swap->team_name}. Open your team to approve or decline.");
                }
            }

            return [201, $swap];
        });

        return is_string($result[1])
            ? response()->json(['message' => $result[1]], $result[0])
            : response()->json(['swap' => $result[1]], $result[0]);
    }

    public function decide(Request $request, PreSubmissionSwap $swap): JsonResponse
    {
        $data = $request->validate(['decision' => 'required|in:approve,decline,cancel']);
        $result = DB::transaction(function () use ($request, $swap, $data): array {
            $activity = GroupingActivity::with('academicClass')->lockForUpdate()->findOrFail($swap->grouping_activity_id);
            $swap->refresh();
            if ($swap->status !== 'pending') {
                return [422, 'This proposal is no longer pending.'];
            }
            $email = strtolower($request->user()->email);
            $field = $email === $swap->outgoing_email ? 'outgoing_decision' : ($email === $swap->incoming_email ? 'incoming_decision' : null);
            if ($data['decision'] === 'cancel') {
                if ($email !== $swap->leader_email) {
                    return [403, 'Only the leader can cancel this proposal.'];
                }
                $swap->status = 'cancelled';
            } elseif ($field === null) {
                return [403, 'Only affected students can decide this proposal.'];
            } elseif ($swap->$field !== 'pending') {
                return [422, 'You already responded.'];
            } elseif ($data['decision'] === 'decline') {
                $swap->$field = 'declined';
                $swap->status = 'declined';
            } else {
                $swap->$field = 'approved';
                if ($swap->outgoing_decision === 'approved' && $swap->incoming_decision === 'approved') {
                    $teams = $activity->formed_teams ?? [];
                    foreach ($teams as &$team) {
                        if (($team['name'] ?? '') !== $swap->team_name) {
                            continue;
                        }
                        if ($this->isSubmitted($team)) {
                            return [422, 'The team has already been submitted.'];
                        }
                        foreach ($teams as $otherTeam) {
                            foreach ($otherTeam['members'] ?? [] as $member) {
                                if (strtolower($member['email'] ?? '') === $swap->incoming_email) {
                                    return [422, 'The replacement has joined another team.'];
                                }
                            }
                        }
                        foreach ($team['members'] as &$member) {
                            if (strtolower($member['email'] ?? '') === $swap->outgoing_email) {
                                if (! empty($member['is_leader']) || ! empty($member['is_pending']) || ($member['status'] ?? '') === 'pending') {
                                    return [422, 'The outgoing member is no longer eligible.'];
                                }
                                $incoming = User::whereRaw('LOWER(email) = ?', [$swap->incoming_email])->firstOrFail();
                                if ($activity->academicClass === null || ! $activity->academicClass->students()->whereKey($incoming->id)->exists()) {
                                    return [422, 'The replacement is no longer enrolled in this class.'];
                                }
                                if ((Profile::where('email', $incoming->email)->first()?->details['is_complete'] ?? false) !== true) {
                                    return [422, 'The replacement profile is no longer complete.'];
                                }
                                $member['name'] = $incoming->name;
                                $member['email'] = $incoming->email;
                                $member['role'] = $swap->incoming_role;
                                $member['avatar'] = strtoupper(substr($incoming->name, 0, 1));
                                $member['status'] = 'accepted';
                                $member['is_pending'] = false;
                                $member['skills'] = Profile::whereRaw('LOWER(email) = ?', [$swap->incoming_email])->first()?->skills ?? [];
                                $team['balance_score'] = (new GroupingActivityController)->calculateTeamBalanceScore($activity, $team);
                                $activity->formed_teams = $teams;
                                $activity->save();
                                $swap->status = 'approved';
                                break 2;
                            }
                        }

                        return [422, 'The outgoing member is no longer in this team.'];
                    }
                    if ($swap->status !== 'approved') {
                        return [422, 'Team not found.'];
                    }
                }
            }
            $swap->save();
            foreach ([$swap->leader_email, $swap->outgoing_email, $swap->incoming_email] as $recipientEmail) {
                $recipient = User::whereRaw('LOWER(email) = ?', [$recipientEmail])->first();
                if ($recipient !== null && strtolower($recipient->email) !== $email) {
                    $this->notify($recipient, $swap, 'Member replacement update', "The proposal for {$swap->team_name} is {$swap->status}.");
                }
            }

            return [200, $swap];
        });

        return is_string($result[1])
            ? response()->json(['message' => $result[1]], $result[0])
            : response()->json(['swap' => $result[1]], $result[0]);
    }

    private function isSubmitted(array $team): bool
    {
        $status = strtolower($team['status'] ?? '');

        return ! empty($team['submitted_at']) || ($status !== 'unsubmitted' && (str_contains($status, 'submitted') || str_contains($status, 'evaluat')));
    }

    private function notify(User $user, PreSubmissionSwap $swap, string $title, string $message): void
    {
        AppNotification::create([
            'user_id' => $user->id,
            'kind' => 'pre_submission_swap',
            'title' => $title,
            'message' => $message,
            'target' => 'groups',
            'event_key' => 'pre-swap:'.$swap->id.':'.$user->id.':'.Str::uuid(),
        ]);
    }
}
