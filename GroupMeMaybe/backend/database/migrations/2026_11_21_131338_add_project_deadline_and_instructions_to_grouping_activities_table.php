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
        Schema::table('grouping_activities', function (Blueprint $table) {
            $table->dateTime('project_submission_deadline')->nullable()->after('grouping_deadline');
            $table->string('instruction_file_path')->nullable();
            $table->string('instruction_file_name')->nullable();
        });
        DB::table('grouping_activities')->update([
            'project_submission_deadline' => DB::raw('grouping_deadline'),
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('grouping_activities', function (Blueprint $table) {
            $table->dropColumn(['project_submission_deadline', 'instruction_file_path', 'instruction_file_name']);
        });
    }
};
