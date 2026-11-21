<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProjectSubmission extends Model
{
    protected $fillable = [
        'grouping_activity_id', 'team_name', 'submitted_by',
        'file_path', 'file_name', 'submitted_at', 'grade',
        'feedback', 'graded_by', 'graded_at',
    ];

    protected $hidden = ['file_path'];

    protected $casts = [
        'submitted_at' => 'datetime',
        'grade' => 'decimal:2',
        'graded_at' => 'datetime',
    ];

    public function activity(): BelongsTo
    {
        return $this->belongsTo(GroupingActivity::class, 'grouping_activity_id');
    }
}
