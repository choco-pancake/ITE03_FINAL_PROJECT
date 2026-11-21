<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PreSubmissionSwap extends Model
{
    protected $fillable = [
        'grouping_activity_id', 'team_name', 'leader_email',
        'outgoing_email', 'incoming_email', 'incoming_role', 'reason',
        'outgoing_decision', 'incoming_decision', 'status',
    ];
}
