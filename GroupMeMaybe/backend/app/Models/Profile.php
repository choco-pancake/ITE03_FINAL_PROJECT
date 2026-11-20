<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Profile extends Model
{
    protected $fillable = [
        'first_name', 'middle_name', 'last_name',
        'name', 'email', 'skills', 'interests',
        'preferred_role', 'availability', 'details',
    ];

    protected $casts = [
        'skills' => 'array',
        'interests' => 'array',
        'details' => 'array',
    ];
}
