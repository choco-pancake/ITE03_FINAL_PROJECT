<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CustomSkillRequest extends Model
{
    protected $fillable = [
        'user_id', 'student_name', 'student_id', 'block', 'skill_name',
        'domain', 'status', 'remarks',
    ];

    protected $attributes = [
        'status' => 'pending',
    ];
}
