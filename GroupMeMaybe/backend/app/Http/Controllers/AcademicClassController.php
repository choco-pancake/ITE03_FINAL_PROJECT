<?php

namespace App\Http\Controllers;

use App\Models\AcademicClass;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AcademicClassController extends Controller
{
    /**
     * Display a listing of classes.
     */
    public function index(Request $request): JsonResponse
    {
        $query = AcademicClass::query()->withCount('activities');
        if ($request->user()->role === 'professor') {
            $query->where('professor_id', $request->user()->id);
        } elseif ($request->user()->role === 'student') {
            $query->whereHas('students', fn ($students) => $students->whereKey($request->user()->id));
        }

        $classes = $query->get();

        return response()->json($classes);
    }

    /**
     * Store a newly created class.
     */
    public function store(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'professor') {
            return response()->json(['message' => 'Only instructors can create classes.'], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'section' => 'nullable|string|max:50',
            'class_code' => 'required|string|unique:academic_classes,class_code',
            'description' => 'nullable|string',
        ]);

        $class = AcademicClass::create([
            ...$validated,
            'professor_id' => $request->user()->id,
            'student_count' => 0,
        ]);

        return response()->json($class, 201);
    }

    /**
     * Display the specified class.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $class = AcademicClass::with('activities')->findOrFail($id);
        if (! $this->canView($request, $class)) {
            return response()->json(['message' => 'You cannot view this class.'], 403);
        }

        return response()->json($class);
    }

    /**
     * Update the specified class.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $class = AcademicClass::findOrFail($id);
        if ($request->user()->role !== 'professor' || $class->professor_id !== $request->user()->id) {
            return response()->json(['message' => 'Only the class instructor can edit this class.'], 403);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'section' => 'nullable|string|max:50',
            'class_code' => 'sometimes|string|unique:academic_classes,class_code,'.$id,
            'description' => 'nullable|string',
        ]);

        $class->update($validated);

        return response()->json($class);
    }

    /**
     * Remove the specified class.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $class = AcademicClass::findOrFail($id);
        if ($request->user()->role !== 'professor' || $class->professor_id !== $request->user()->id) {
            return response()->json(['message' => 'Only the class instructor can delete this class.'], 403);
        }

        $class->delete();

        return response()->json(null, 204);
    }

    public function enroll(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'student') {
            return response()->json(['message' => 'Only students can enroll in classes.'], 403);
        }

        $validated = $request->validate(['class_code' => 'required|string|max:255']);
        $rawCode = trim($validated['class_code']);
        $upperCode = strtoupper($rawCode);

        $class = AcademicClass::where('class_code', $upperCode)
            ->orWhere('class_code', $rawCode)
            ->orWhereRaw('UPPER(TRIM(class_code)) = ?', [$upperCode])
            ->first();

        if ($class === null) {
            return response()->json([
                'message' => "Class code \"{$rawCode}\" not found. Please verify the code with your instructor.",
            ], 404);
        }

        DB::transaction(function () use ($class, $request): void {
            $lockedClass = AcademicClass::whereKey($class->id)->lockForUpdate()->firstOrFail();
            $lockedClass->students()->syncWithoutDetaching([$request->user()->id]);
            $lockedClass->update(['student_count' => $lockedClass->students()->count()]);
        });

        return response()->json($class->refresh());
    }

    private function canView(Request $request, AcademicClass $class): bool
    {
        if ($request->user()->role === 'admin') {
            return true;
        }
        if ($request->user()->role === 'professor') {
            return $class->professor_id === $request->user()->id;
        }

        return $request->user()->role === 'student'
            && $class->students()->whereKey($request->user()->id)->exists();
    }
}
