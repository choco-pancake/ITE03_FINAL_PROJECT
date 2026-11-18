<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AcademicClass extends Model
{
    public $incrementing = false;
    protected $keyType = 'string';
    protected $table = 'academic_classes';
    protected $guarded = [];

    public function enrolledStudents()
    {
        return $this->belongsToMany(User::class, 'class_enrollments', 'class_id', 'user_id');
    }

    public function activities()
    {
        return $this->hasMany(Activity::class, 'class_id');
    }

    public function teams()
    {
        return $this->hasMany(Team::class, 'class_id');
    }
}
