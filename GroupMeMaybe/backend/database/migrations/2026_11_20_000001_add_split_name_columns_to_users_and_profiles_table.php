<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'first_name')) {
                $table->string('first_name')->nullable()->after('id');
            }
            if (!Schema::hasColumn('users', 'middle_name')) {
                $table->string('middle_name')->nullable()->after('first_name');
            }
            if (!Schema::hasColumn('users', 'last_name')) {
                $table->string('last_name')->nullable()->after('middle_name');
            }
        });

        Schema::table('profiles', function (Blueprint $table) {
            if (!Schema::hasColumn('profiles', 'first_name')) {
                $table->string('first_name')->nullable()->after('id');
            }
            if (!Schema::hasColumn('profiles', 'middle_name')) {
                $table->string('middle_name')->nullable()->after('first_name');
            }
            if (!Schema::hasColumn('profiles', 'last_name')) {
                $table->string('last_name')->nullable()->after('middle_name');
            }
        });

        // Backfill existing user names
        $users = DB::table('users')->get();
        foreach ($users as $user) {
            if (!empty($user->name)) {
                $parts = preg_split('/\s+/', trim($user->name));
                $first = $parts[0] ?? '';
                $last = count($parts) > 1 ? end($parts) : '';
                $middle = count($parts) > 2 ? implode(' ', array_slice($parts, 1, count($parts) - 2)) : null;

                DB::table('users')->where('id', $user->id)->update([
                    'first_name' => $first,
                    'middle_name' => $middle,
                    'last_name' => $last,
                ]);
            }
        }

        // Backfill existing profile names
        $profiles = DB::table('profiles')->get();
        foreach ($profiles as $profile) {
            if (!empty($profile->name)) {
                $parts = preg_split('/\s+/', trim($profile->name));
                $first = $parts[0] ?? '';
                $last = count($parts) > 1 ? end($parts) : '';
                $middle = count($parts) > 2 ? implode(' ', array_slice($parts, 1, count($parts) - 2)) : null;

                DB::table('profiles')->where('id', $profile->id)->update([
                    'first_name' => $first,
                    'middle_name' => $middle,
                    'last_name' => $last,
                ]);
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['first_name', 'middle_name', 'last_name']);
        });

        Schema::table('profiles', function (Blueprint $table) {
            $table->dropColumn(['first_name', 'middle_name', 'last_name']);
        });
    }
};
