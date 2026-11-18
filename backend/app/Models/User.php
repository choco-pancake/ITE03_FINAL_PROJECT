<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    public $incrementing = false;
    protected $keyType = 'string';

    protected $guarded = [];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'technical_skills' => 'array',
            'skill_levels' => 'array',
            'preferred_roles' => 'array',
            'interests' => 'array',
            'available_days' => 'array',
            'tools_and_technologies' => 'array',
            'weekly_common_hours' => 'integer',
        ];
    }

    public function enrolledClasses()
    {
        return $this->belongsToMany(AcademicClass::class, 'class_enrollments', 'user_id', 'class_id');
    }

    public function teamMemberships()
    {
        return $this->hasMany(TeamMember::class, 'user_id');
    }

    public function customSkillRequests()
    {
        return $this->hasMany(CustomSkillRequest::class, 'student_id');
    }

    public function getFullNameAttribute(): string
    {
        $fullName = trim("{$this->first_name} {$this->last_name}");
        return !empty($fullName) ? $fullName : ($this->name ?: explode('@', $this->email)[0]);
    }
}
