<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Academic Classes
        Schema::create('academic_classes', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('code'); // e.g. IT201
            $table->string('name'); // e.g. Web Development
            $table->string('section'); // e.g. BSIT 2A
            $table->string('enrollment_code')->unique();
            $table->string('professor_id')->default('prof-1');
            $table->string('professor_name')->default('Prof. Ghian Velasco');
            $table->timestamps();
        });

        // 2. Class Student Pivot
        Schema::create('class_enrollments', function (Blueprint $table) {
            $table->id();
            $table->string('class_id');
            $table->string('user_id');
            $table->timestamps();

            $table->foreign('class_id')->references('id')->on('academic_classes')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });

        // 3. Course Activities / Projects
        Schema::create('activities', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('class_id');
            $table->string('class_name');
            $table->string('title');
            $table->text('description');
            $table->string('grouping_method')->default('auto'); // hybrid, auto, manual
            $table->integer('group_capacity')->default(5);
            $table->integer('needed_groups')->default(6);
            $table->integer('min_common_hours')->default(5);
            $table->string('min_proficiency_level')->default('Intermediate');
            $table->json('required_skills')->nullable();
            $table->json('preferred_skills')->nullable();
            $table->dateTime('grouping_deadline');
            $table->dateTime('student_modification_deadline');
            $table->string('status')->default('open'); // open, grouping_in_progress, completed
            $table->timestamps();

            $table->foreign('class_id')->references('id')->on('academic_classes')->onDelete('cascade');
        });

        // 4. Teams
        Schema::create('teams', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('name');
            $table->string('activity_id');
            $table->string('class_id');
            $table->string('leader_id');
            $table->integer('capacity')->default(5);
            $table->boolean('is_confirmed')->default(false);
            $table->boolean('is_student_formed')->default(true);
            $table->boolean('is_auto_filled')->default(false);
            $table->double('previous_score')->nullable();
            $table->double('skill_coverage')->default(85.0);
            $table->double('interest_match')->default(80.0);
            $table->double('availability_overlap')->default(80.0);
            $table->double('overall_compatibility')->default(85.0);
            $table->timestamps();

            $table->foreign('activity_id')->references('id')->on('activities')->onDelete('cascade');
            $table->foreign('class_id')->references('id')->on('academic_classes')->onDelete('cascade');
        });

        // 5. Team Members
        Schema::create('team_members', function (Blueprint $table) {
            $table->id();
            $table->string('team_id');
            $table->string('user_id');
            $table->string('name');
            $table->string('block');
            $table->string('assigned_role');
            $table->boolean('is_locked')->default(true);
            $table->integer('weekly_common_hours')->default(8);
            $table->json('skills')->nullable();
            $table->json('interests')->nullable();
            $table->json('available_days')->nullable();
            $table->json('skill_levels')->nullable();
            $table->timestamps();

            $table->foreign('team_id')->references('id')->on('teams')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });

        // 6. Custom Skill Requests
        Schema::create('custom_skill_requests', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('student_id');
            $table->string('student_name');
            $table->string('skill_name');
            $table->string('category');
            $table->text('justification');
            $table->string('status')->default('pending'); // pending, approved, rejected
            $table->text('reviewer_remarks')->nullable();
            $table->dateTime('date_requested');
            $table->timestamps();

            $table->foreign('student_id')->references('id')->on('users')->onDelete('cascade');
        });

        // 7. Notifications
        Schema::create('notifications', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('recipient_id'); // user_id or 'all' or 'prof-1'
            $table->string('title');
            $table->text('message');
            $table->string('type')->default('general');
            $table->boolean('is_read')->default(false);
            $table->dateTime('timestamp');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('custom_skill_requests');
        Schema::dropIfExists('team_members');
        Schema::dropIfExists('teams');
        Schema::dropIfExists('activities');
        Schema::dropIfExists('class_enrollments');
        Schema::dropIfExists('academic_classes');
    }
};
