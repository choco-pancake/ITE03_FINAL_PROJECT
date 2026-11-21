<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pre_submission_swaps', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('grouping_activity_id')->constrained('grouping_activities')->cascadeOnDelete();
            $table->string('team_name');
            $table->string('leader_email');
            $table->string('outgoing_email');
            $table->string('incoming_email');
            $table->string('incoming_role');
            $table->text('reason');
            $table->string('outgoing_decision')->default('pending');
            $table->string('incoming_decision')->default('pending');
            $table->string('status')->default('pending');
            $table->timestamps();
            $table->index(['grouping_activity_id', 'team_name', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pre_submission_swaps');
    }
};
