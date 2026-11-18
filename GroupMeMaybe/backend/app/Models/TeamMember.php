<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TeamMember extends Model
{
    protected $table = 'team_members';
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'is_locked' => 'boolean',
            'weekly_common_hours' => 'integer',
            'skills' => 'array',
            'interests' => 'array',
            'available_days' => 'array',
            'skill_levels' => 'array',
        ];
    }

    public function team()
    {
        return $this->belongsTo(Team::class, 'team_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
