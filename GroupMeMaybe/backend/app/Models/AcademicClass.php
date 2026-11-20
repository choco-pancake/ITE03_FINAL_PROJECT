<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AcademicClass extends Model
{
    use HasFactory;

    protected $table = 'academic_classes';

    protected $fillable = [
        'name',
        'professor_id',
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

    public function professor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'professor_id');
    }

    public function students(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'academic_class_enrollments', 'academic_class_id', 'student_id')->withTimestamps();
    }

    public function getDisplayNameAttribute(): string
    {
        return $this->section ? "{$this->name} - {$this->section}" : $this->name;
    }
}
