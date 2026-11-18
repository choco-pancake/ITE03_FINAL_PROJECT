<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Activity extends Model
{
    public $incrementing = false;
    protected $keyType = 'string';
    protected $table = 'activities';
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'required_skills' => 'array',
            'preferred_skills' => 'array',
            'group_capacity' => 'integer',
            'needed_groups' => 'integer',
            'min_common_hours' => 'integer',
            'grouping_deadline' => 'datetime',
            'student_modification_deadline' => 'datetime',
        ];
    }

    public function academicClass()
    {
        return $this->belongsTo(AcademicClass::class, 'class_id');
    }

    public function teams()
    {
        return $this->hasMany(Team::class, 'activity_id');
    }
}
