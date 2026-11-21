<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeamModificationRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'grouping_activity_id',
        'academic_class_id',
        'team_name',
        'leader_email',
        'leader_name',
        'outgoing_student_email',
        'outgoing_student_name',
        'incoming_student_email',
        'incoming_student_name',
        'reason',
        'status',
        'professor_notes',
    ];

    public function activity(): BelongsTo
    {
        return $this->belongsTo(GroupingActivity::class, 'grouping_activity_id');
    }

    public function academicClass(): BelongsTo
    {
        return $this->belongsTo(AcademicClass::class, 'academic_class_id');
    }
}
