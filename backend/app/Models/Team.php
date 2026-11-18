<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Team extends Model
{
    public $incrementing = false;
    protected $keyType = 'string';
    protected $table = 'teams';
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'capacity' => 'integer',
            'is_confirmed' => 'boolean',
            'is_student_formed' => 'boolean',
            'is_auto_filled' => 'boolean',
            'previous_score' => 'double',
            'skill_coverage' => 'double',
            'interest_match' => 'double',
            'availability_overlap' => 'double',
            'overall_compatibility' => 'double',
        ];
    }

    public function activity()
    {
        return $this->belongsTo(Activity::class, 'activity_id');
    }

    public function academicClass()
    {
        return $this->belongsTo(AcademicClass::class, 'class_id');
    }

    public function leader()
    {
        return $this->belongsTo(User::class, 'leader_id');
    }

    public function members()
    {
        return $this->hasMany(TeamMember::class, 'team_id');
    }

    public function getScoreDeltaAttribute(): float
    {
        return $this->previous_score !== null ? round($this->overall_compatibility - $this->previous_score, 1) : 0.0;
    }
}
