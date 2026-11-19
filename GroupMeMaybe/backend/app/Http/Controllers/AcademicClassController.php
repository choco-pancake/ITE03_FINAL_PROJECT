<?php

namespace App\Http\Controllers;

use App\Models\AcademicClass;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AcademicClassController extends Controller
{
    /**
     * Display a listing of classes.
     */
    public function index(): JsonResponse
    {
        $classes = AcademicClass::withCount('activities')->get();
        return response()->json($classes);
    }

    /**
     * Store a newly created class.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'section' => 'nullable|string|max:50',
            'class_code' => 'required|string|unique:academic_classes,class_code',
            'description' => 'nullable|string',
            'student_count' => 'nullable|integer|min:0',
        ]);

        $class = AcademicClass::create($validated);

        return response()->json($class, 201);
    }

    /**
     * Display the specified class.
     */
    public function show(int $id): JsonResponse
    {
        $class = AcademicClass::with('activities')->findOrFail($id);
        return response()->json($class);
    }

    /**
     * Update the specified class.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $class = AcademicClass::findOrFail($id);
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'section' => 'nullable|string|max:50',
            'class_code' => 'sometimes|string|unique:academic_classes,class_code,' . $id,
            'description' => 'nullable|string',
            'student_count' => 'nullable|integer|min:0',
        ]);

        $class->update($validated);

        return response()->json($class);
    }

    /**
     * Remove the specified class.
     */
    public function destroy(int $id): JsonResponse
    {
        $class = AcademicClass::findOrFail($id);
        $class->delete();

        return response()->json(null, 204);
    }
}
