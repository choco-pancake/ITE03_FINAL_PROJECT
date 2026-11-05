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
            'student_count' => 'nullable|integer|min:1',
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
}
