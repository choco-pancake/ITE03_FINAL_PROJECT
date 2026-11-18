<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CustomSkillRequest extends Model
{
    public $incrementing = false;
    protected $keyType = 'string';
    protected $table = 'custom_skill_requests';
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'date_requested' => 'datetime',
        ];
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }
}
