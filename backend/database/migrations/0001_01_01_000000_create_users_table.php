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
        Schema::create('users', function (Blueprint $table) {
            $table->string('id')->primary(); // Support e.g. stud-alex, prof-1, or numeric IDs
            $table->string('first_name')->default('');
            $table->string('last_name')->default('');
            $table->string('name')->default('');
            $table->string('email')->unique();
            $table->string('student_id')->nullable(); // Student ID or Employee ID
            $table->string('role')->default('student'); // student, professor
            $table->string('block')->default('BSIT 2A');
            $table->string('photo_url')->nullable();
            $table->string('profile_status')->default('uninitialized'); // complete, incomplete, uninitialized
            $table->string('proficiency_rating')->default('intermediate'); // beginner, intermediate, advanced
            $table->integer('weekly_common_hours')->default(8);
            $table->json('technical_skills')->nullable();
            $table->json('skill_levels')->nullable();
            $table->json('preferred_roles')->nullable();
            $table->json('interests')->nullable();
            $table->json('available_days')->nullable();
            $table->string('preferred_meeting_time')->nullable();
            $table->string('collaboration_mode')->default('Hybrid');
            $table->text('previous_experience')->nullable();
            $table->json('tools_and_technologies')->nullable();
            $table->string('assigned_team_id')->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('sessions');
    }
};
