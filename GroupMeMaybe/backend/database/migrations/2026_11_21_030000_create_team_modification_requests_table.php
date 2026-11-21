<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('team_modification_requests', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('grouping_activity_id')->constrained('grouping_activities')->cascadeOnDelete();
            $table->foreignId('academic_class_id')->nullable()->constrained('academic_classes')->nullOnDelete();
            $table->string('team_name');
            $table->string('leader_email');
            $table->string('leader_name');
            $table->string('outgoing_student_email');
            $table->string('outgoing_student_name');
            $table->string('incoming_student_email');
            $table->string('incoming_student_name');
            $table->text('reason');
            $table->string('status')->default('pending'); // pending, approved, declined
            $table->text('professor_notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('team_modification_requests');
    }
};
