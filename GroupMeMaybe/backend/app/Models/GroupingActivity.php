<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class GroupingActivity extends Model
{
    use HasFactory;

    protected $table = 'grouping_activities';

    protected $hidden = ['instruction_file_path'];

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
        'project_submission_deadline',
        'instruction_file_path',
        'instruction_file_name',
        'student_modification_deadline',
        'status',
        'students_count',
        'formed_teams',
    ];

    protected $casts = [
        'required_skills' => 'array',
        'preferred_skills' => 'array',
        'formed_teams' => 'array',
        'grouping_deadline' => 'datetime',
        'project_submission_deadline' => 'datetime',
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

    public function projectSubmissions(): HasMany
    {
        return $this->hasMany(ProjectSubmission::class, 'grouping_activity_id');
    }
}
