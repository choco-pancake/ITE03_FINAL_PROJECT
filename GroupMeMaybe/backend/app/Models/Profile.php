<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Profile extends Model
{
    protected $fillable = [
        'name', 'email', 'skills', 'interests',
        'preferred_role', 'availability',
    ];

    protected $casts = [
        'skills' => 'array',
        'interests' => 'array',
    ];
}