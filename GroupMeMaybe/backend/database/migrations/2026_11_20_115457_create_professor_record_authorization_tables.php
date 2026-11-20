<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (DB::table('academic_classes')->exists()) {
            throw new RuntimeException('Assign existing classes to their professors before adding required class ownership.');
        }

        Schema::table('academic_classes', function (Blueprint $table): void {
            $table->foreignId('professor_id')->constrained('users')->restrictOnDelete();
        });

        Schema::create('academic_class_enrollments', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('academic_class_id')->constrained()->cascadeOnDelete();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->unique(['academic_class_id', 'student_id']);
            $table->timestamps();
        });

        Schema::create('student_record_changes', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('professor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('student_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('academic_class_id')->nullable()->constrained()->nullOnDelete();
            $table->string('professor_email');
            $table->string('student_email');
            $table->json('before');
            $table->json('after');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('student_record_changes');
        Schema::dropIfExists('academic_class_enrollments');
        Schema::table('academic_classes', function (Blueprint $table): void {
            $table->dropConstrainedForeignId('professor_id');
        });
    }
};
