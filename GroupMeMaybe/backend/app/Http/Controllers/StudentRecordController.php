<?php

namespace App\Http\Controllers;

use App\Models\AppNotification;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

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

            return [
                'id' => $student->id,
                'name' => $student->name,
                'email' => $student->email,
                'first_name' => $profile?->first_name ?: $student->first_name,
                'middle_name' => $profile?->middle_name ?? $student->middle_name,
                'last_name' => $profile?->last_name ?: $student->last_name,
                'student_id' => $details['student_id'] ?? '',
                'year_level' => $details['year_level'] ?? '',
                'block' => $details['block'] ?? $student->department_or_section,
                'classes' => $student->academicClasses->map(fn ($class): array => [
                    'id' => $class->id,
                    'name' => $class->name,
                    'section' => $class->section,
                ])->values(),
            ];
        })->values()]);
    }

    public function update(Request $request, User $student): JsonResponse
    {
        if ($request->user()->role !== 'professor') {
            return response()->json(['message' => 'Instructor access required.'], 403);
        }
        if ($student->role !== 'student') {
            return response()->json(['message' => 'Only student records can be edited.'], 403);
        }

        $class = $student->academicClasses()->where('academic_classes.professor_id', $request->user()->id)->first();
        if ($class === null) {
            return response()->json(['message' => 'This student is not enrolled in one of your classes.'], 403);
        }

        $validated = $request->validate([
            'first_name' => 'required|string|max:255',
            'middle_name' => 'nullable|string|max:255',
            'last_name' => 'required|string|max:255',
            'student_id' => 'required|string|max:100',
            'year_level' => 'required|string|max:30',
            'block' => 'required|string|max:100',
        ]);
        foreach ($validated as $key => $value) {
            $validated[$key] = is_string($value) ? trim($value) : $value;
        }
        if ($validated['first_name'] === '' || $validated['last_name'] === '' || $validated['student_id'] === '' || $validated['year_level'] === '' || $validated['block'] === '') {
            throw ValidationException::withMessages(['record' => 'Required record fields cannot be empty.']);
        }

        $result = DB::transaction(function () use ($student, $class, $request, $validated): array {
            $lockedStudent = User::whereKey($student->id)->lockForUpdate()->firstOrFail();
            $profile = Profile::where('email', $lockedStudent->email)->lockForUpdate()->first();
            if ($profile === null) {
                throw ValidationException::withMessages(['record' => 'Student profile is missing.']);
            }

            $details = $profile->details ?? [];
            $before = [
                'first_name' => $lockedStudent->first_name ?? '',
                'middle_name' => $lockedStudent->middle_name ?? '',
                'last_name' => $lockedStudent->last_name ?? '',
                'student_id' => $details['student_id'] ?? '',
                'year_level' => $details['year_level'] ?? '',
                'block' => $details['block'] ?? $lockedStudent->department_or_section ?? '',
            ];
            $after = [
                'first_name' => $validated['first_name'],
                'middle_name' => $validated['middle_name'] ?? '',
                'last_name' => $validated['last_name'],
                'student_id' => $validated['student_id'],
                'year_level' => $validated['year_level'],
                'block' => $validated['block'],
            ];
            if ($before === $after) {
                throw ValidationException::withMessages(['record' => 'No record changes were entered.']);
            }

            $fullName = trim(implode(' ', array_filter([$after['first_name'], $after['middle_name'], $after['last_name']], fn ($part): bool => $part !== '')));
            $lockedStudent->update([
                'first_name' => $after['first_name'],
                'middle_name' => $after['middle_name'] ?: null,
                'last_name' => $after['last_name'],
                'name' => $fullName,
                'department_or_section' => $after['block'],
            ]);
            $details['student_id'] = $after['student_id'];
            $details['year_level'] = $after['year_level'];
            $details['block'] = $after['block'];
            $profile->update([
                'first_name' => $after['first_name'],
                'middle_name' => $after['middle_name'] ?: null,
                'last_name' => $after['last_name'],
                'name' => $fullName,
                'details' => $details,
            ]);

            $changeId = DB::table('student_record_changes')->insertGetId([
                'professor_id' => $request->user()->id,
                'student_id' => $lockedStudent->id,
                'academic_class_id' => $class->id,
                'professor_email' => $request->user()->email,
                'student_email' => $lockedStudent->email,
                'before' => json_encode($before, JSON_THROW_ON_ERROR),
                'after' => json_encode($after, JSON_THROW_ON_ERROR),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            AppNotification::create([
                'user_id' => $lockedStudent->id,
                'event_key' => 'student-record:'.$changeId,
                'kind' => 'record',
                'title' => 'Student record updated',
                'message' => 'Your instructor updated your name or academic information.',
                'target' => 'settings',
            ]);

            return ['student_id' => $lockedStudent->id, 'change_id' => $changeId, 'before' => $before, 'after' => $after];
        });

        return response()->json($result);
    }
}
