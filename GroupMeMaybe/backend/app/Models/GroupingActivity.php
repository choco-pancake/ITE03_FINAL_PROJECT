<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GroupingActivity extends Model
{
    use HasFactory;

    protected $table = 'grouping_activities';

    protected $fillable = [
        'academic_class_id',
        'class_name',
        'title',
        'description',
        'grouping_method',
        'group_capacity',
        'number_of_groups',
        'required_skills',
        'preferred_skills',
        'min_proficiency_level',
        'min_common_hours',
        'grouping_deadline',
        'student_modification_deadline',
        'status',
        'students_count',
    ];

    protected $casts = [
        'required_skills' => 'array',
        'preferred_skills' => 'array',
        'grouping_deadline' => 'datetime',
        'student_modification_deadline' => 'datetime',
        'group_capacity' => 'integer',
        'number_of_groups' => 'integer',
        'min_common_hours' => 'integer',
        'students_count' => 'integer',
    ];

    public function academicClass(): BelongsTo
    {
        return $this->belongsTo(AcademicClass::class, 'academic_class_id');
    }
}
