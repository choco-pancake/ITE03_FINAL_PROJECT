<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    public $incrementing = false;
    protected $keyType = 'string';
    protected $table = 'notifications';
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'is_read' => 'boolean',
            'timestamp' => 'datetime',
        ];
    }
}
