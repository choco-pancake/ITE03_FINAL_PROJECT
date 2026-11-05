<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AcademicClass extends Model
{
    use HasFactory;

    protected $table = 'academic_classes';

    protected $fillable = [
        'name',
        'section',
        'class_code',
        'description',
        'student_count',
    ];

    protected $casts = [
        'student_count' => 'integer',
    ];

    public function activities(): HasMany
    {
        return $this->hasMany(GroupingActivity::class, 'academic_class_id');
    }

    public function getDisplayNameAttribute(): string
    {
        return $this->section ? "{$this->name} - {$this->section}" : $this->name;
    }
}
