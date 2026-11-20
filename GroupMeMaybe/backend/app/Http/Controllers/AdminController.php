<?php

namespace App\Http\Controllers;

use App\Models\AcademicClass;
use App\Models\GroupingActivity;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;

class AdminController extends Controller
{
    private static string $settingsFile = 'app/system_settings.json';

    public static function getSettings(): array
    {
        $path = storage_path(self::$settingsFile);
        $defaults = [
            'faculty_code' => env('FACULTY_ACCESS_CODE', 'BSIT-FACULTY-2026'),
            'semester_mode' => 'auto',
            'manual_semester' => '1st Semester',
            'manual_academic_year' => '2026-2027',
        ];

        if (File::exists($path)) {
            $data = json_decode(File::get($path), true);
            if (is_array($data)) {
                return array_merge($defaults, $data);
            }
        }

        return $defaults;
    }

    public static function saveSettings(array $settings): void
    {
        $path = storage_path(self::$settingsFile);
        $dir = dirname($path);
        if (!File::exists($dir)) {
            File::makeDirectory($dir, 0755, true);
        }
        File::put($path, json_encode($settings, JSON_PRETTY_PRINT));
    }

    public static function resolveCurrentSemester(): array
    {
        $settings = self::getSettings();
        if (($settings['semester_mode'] ?? 'auto') === 'manual') {
            return [
                'semester' => $settings['manual_semester'] ?? '1st Semester',
                'academic_year' => $settings['manual_academic_year'] ?? '2026-2027',
                'mode' => 'manual',
            ];
        }

        // Automatic university date-based formula
        $month = (int) date('n');
        $year = (int) date('Y');

        if ($month >= 8 && $month <= 12) {
            $sem = '1st Semester';
            $ay = $year . '-' . ($year + 1);
        } elseif ($month >= 1 && $month <= 5) {
            $sem = '2nd Semester';
            $ay = ($year - 1) . '-' . $year;
        } else {
            $sem = 'Midyear / Summer Term';
            $ay = ($year - 1) . '-' . $year;
        }

        return [
            'semester' => $sem,
            'academic_year' => $ay,
            'mode' => 'auto',
        ];
    }

    public function publicSettings(): JsonResponse
    {
        $sem = self::resolveCurrentSemester();
        return response()->json([
            'semester' => $sem['semester'],
            'academic_year' => $sem['academic_year'],
            'mode' => $sem['mode'],
        ]);
    }

    public function overview(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized. Administrator access required.'], 403);
        }

        $settings = self::getSettings();
        $sem = self::resolveCurrentSemester();

        return response()->json([
            'total_faculty' => User::where('role', 'professor')->count(),
            'total_students' => User::where('role', 'student')->count(),
            'total_classes' => AcademicClass::count(),
            'total_activities' => GroupingActivity::count(),
            'active_faculty_code' => $settings['faculty_code'] ?? 'BSIT-FACULTY-2026',
            'semester' => $sem['semester'],
            'academic_year' => $sem['academic_year'],
            'semester_mode' => $settings['semester_mode'] ?? 'auto',
            'manual_semester' => $settings['manual_semester'] ?? '1st Semester',
            'manual_academic_year' => $settings['manual_academic_year'] ?? '2026-2027',
        ]);
    }

    public function faculty(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized. Administrator access required.'], 403);
        }

        $faculty = User::where('role', 'professor')
            ->select(['id', 'name', 'first_name', 'last_name', 'email', 'department_or_section', 'created_at'])
            ->orderBy('name')
            ->get();

        return response()->json($faculty);
    }

    public function students(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized. Administrator access required.'], 403);
        }

        $students = User::where('role', 'student')
            ->select(['id', 'name', 'first_name', 'last_name', 'email', 'department_or_section', 'created_at'])
            ->orderBy('name')
            ->get();

        // Attach profile completion stats
        $profiles = Profile::all()->keyBy('user_id');

        $result = $students->map(function ($s) use ($profiles) {
            $prof = $profiles->get($s->id);
            $hasRole = $prof && !empty($prof->preferred_role);
            $hasSkills = $prof && is_array($prof->skills) && count($prof->skills) > 0;
            $status = ($hasRole && $hasSkills) ? 'complete' : (($hasRole || $hasSkills) ? 'incomplete' : 'uninitialized');

            return [
                'id' => $s->id,
                'name' => $s->name,
                'email' => $s->email,
                'section' => $s->department_or_section ?? 'General',
                'status' => $status,
                'preferred_role' => $prof?->preferred_role,
                'skills' => $prof?->skills ?? [],
                'created_at' => $s->created_at?->toIso8601String(),
            ];
        });

        return response()->json($result);
    }

    public function updateFacultyCode(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized. Administrator access required.'], 403);
        }

        $validated = $request->validate([
            'faculty_code' => 'required|string|min:4|max:50',
        ]);

        $settings = self::getSettings();
        $settings['faculty_code'] = trim($validated['faculty_code']);
        self::saveSettings($settings);

        return response()->json([
            'message' => 'Faculty Authorization Code updated successfully.',
            'faculty_code' => $settings['faculty_code'],
        ]);
    }

    public function updateSemester(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized. Administrator access required.'], 403);
        }

        $validated = $request->validate([
            'mode' => 'required|string|in:auto,manual',
            'semester' => 'nullable|string',
            'academic_year' => 'nullable|string',
        ]);

        $settings = self::getSettings();
        $settings['semester_mode'] = $validated['mode'];
        if ($validated['mode'] === 'manual') {
            if (!empty($validated['semester'])) {
                $settings['manual_semester'] = $validated['semester'];
            }
            if (!empty($validated['academic_year'])) {
                $settings['manual_academic_year'] = $validated['academic_year'];
            }
        }
        self::saveSettings($settings);

        $sem = self::resolveCurrentSemester();

        return response()->json([
            'message' => 'Academic calendar configuration updated successfully.',
            'semester' => $sem['semester'],
            'academic_year' => $sem['academic_year'],
            'semester_mode' => $settings['semester_mode'],
        ]);
    }
}
