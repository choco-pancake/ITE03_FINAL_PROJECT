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
        Schema::create('grouping_activities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('academic_class_id')->nullable()->constrained('academic_classes')->nullOnDelete();
            $table->string('class_name');
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('grouping_method')->default('auto'); // auto, manual, hybrid
            $table->unsignedInteger('group_capacity')->default(5);
            $table->unsignedInteger('number_of_groups')->default(6);
            $table->json('required_skills');
            $table->json('preferred_skills')->nullable();
            $table->string('min_proficiency_level')->default('Intermediate'); // Beginner, Intermediate, Advanced
            $table->unsignedInteger('min_common_hours')->default(5);
            $table->dateTime('grouping_deadline');
            $table->dateTime('student_modification_deadline')->nullable();
            $table->string('status')->default('open'); // draft, open, grouping in progress, completed
            $table->unsignedInteger('students_count')->default(30);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('grouping_activities');
    }
};
