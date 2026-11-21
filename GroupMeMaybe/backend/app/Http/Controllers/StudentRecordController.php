<?php

namespace App\Http\Controllers;

use App\Models\Profile;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentRecordController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'professor') {
            return response()->json(['message' => 'Instructor access required.'], 403);
        }

        $professorId = $request->user()->id;
        $students = User::query()
            ->where('role', 'student')
            ->whereHas('academicClasses', fn ($classes) => $classes->where('academic_classes.professor_id', $professorId))
            ->with(['academicClasses' => fn ($classes) => $classes->where('academic_classes.professor_id', $professorId)])
            ->orderBy('name')
            ->get();
        $profiles = Profile::whereIn('email', $students->pluck('email'))->get()->keyBy('email');

        return response()->json(['students' => $students->map(function (User $student) use ($profiles): array {
            $profile = $profiles->get($student->email);
            $details = $profile?->details ?? [];

            $realStudentId = trim((string) ($details['student_id'] ?? ''));
            if ($realStudentId === '') {
                $realStudentId = '24-'.str_pad((string) $student->id, 4, '0', STR_PAD_LEFT).'-001';
            }

            $enrolledSection = $student->academicClasses->first()?->section;
            $realBlock = trim((string) ($details['block'] ?? ''));
            if ($realBlock === '' && ! empty($enrolledSection)) {
                $realBlock = trim((string) $enrolledSection);
            }
            if ($realBlock === '') {
                $realBlock = trim((string) ($student->department_or_section ?? ''));
            }
            if ($realBlock === '') {
                $realBlock = 'General';
            }

            $realYearLevel = trim((string) ($details['year_level'] ?? ''));
            if ($realYearLevel === '') {
                if (preg_match('/^1\d-/', $realBlock)) {
                    $realYearLevel = '1st Year';
                } elseif (preg_match('/^2\d-/', $realBlock)) {
                    $realYearLevel = '2nd Year';
                } elseif (preg_match('/^3\d-/', $realBlock)) {
                    $realYearLevel = '3rd Year';
                } elseif (preg_match('/^4\d-/', $realBlock)) {
                    $realYearLevel = '4th Year';
                } else {
                    $realYearLevel = '2nd Year';
                }
            }

            $nameParts = preg_split('/\s+/', trim($student->name));
            $fallbackFirst = $nameParts[0] ?? 'Student';
            $fallbackLast = count($nameParts) > 1 ? end($nameParts) : 'User';
            $fallbackMiddle = count($nameParts) > 2 ? implode(' ', array_slice($nameParts, 1, count($nameParts) - 2)) : '';

            return [
                'id' => $student->id,
                'name' => $student->name,
                'email' => $student->email,
                'first_name' => $profile?->first_name ?: ($student->first_name ?: $fallbackFirst),
                'middle_name' => $profile?->middle_name ?? ($student->middle_name ?? $fallbackMiddle),
                'last_name' => $profile?->last_name ?: ($student->last_name ?: $fallbackLast),
                'student_id' => $realStudentId,
                'year_level' => $realYearLevel,
                'block' => $realBlock,
                'classes' => $student->academicClasses->map(fn ($class): array => [
                    'id' => $class->id,
                    'name' => $class->name,
                    'section' => $class->section,
                ])->values(),
            ];
        })->values()]);
    }
}
