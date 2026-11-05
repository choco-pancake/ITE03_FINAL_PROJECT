<?php

namespace App\Http\Controllers;

use App\Models\GroupingActivity;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GroupingActivityController extends Controller
{
    /**
     * Display a listing of grouping activities.
     */
    public function index(Request $request): JsonResponse
    {
        $query = GroupingActivity::with('academicClass')->latest();

        if ($request->filled('status') && $request->status !== 'all') {
            $status = strtolower($request->status);
            if ($status === 'active') {
                $query->whereIn('status', ['open', 'grouping in progress']);
            } elseif ($status === 'upcoming') {
                $query->where('grouping_deadline', '>', now())
                      ->where('status', '!=', 'completed');
            } else {
                $query->where('status', $status);
            }
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('class_name', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        if ($request->filled('class_id')) {
            $query->where('academic_class_id', $request->class_id);
        }

        $activities = $query->get();

        return response()->json($activities);
    }

    /**
     * Get summary statistics for activities.
     */
    public function summary(): JsonResponse
    {
        $total = GroupingActivity::count();
        $active = GroupingActivity::whereIn('status', ['open', 'grouping in progress'])->count();
        $upcoming = GroupingActivity::where('grouping_deadline', '>', now())
            ->where('status', '!=', 'completed')
            ->count();
        $completed = GroupingActivity::where('status', 'completed')->count();
        $draft = GroupingActivity::where('status', 'draft')->count();

        return response()->json([
            'total' => $total,
            'active' => $active,
            'upcoming' => $upcoming,
            'completed' => $completed,
            'draft' => $draft,
        ]);
    }

    /**
     * Store a newly created grouping activity.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'class_name' => 'required|string|max:255',
            'academic_class_id' => 'nullable|exists:academic_classes,id',
            'description' => 'nullable|string',
            'grouping_method' => 'required|string|in:auto,manual,hybrid',
            'group_capacity' => 'required|integer|min:2|max:50',
            'number_of_groups' => 'nullable|integer|min:1|max:100',
            'required_skills' => 'required|array|min:1',
            'required_skills.*' => 'string',
            'preferred_skills' => 'nullable|array',
            'preferred_skills.*' => 'string',
            'min_proficiency_level' => 'required|string|in:Beginner,Intermediate,Advanced',
            'min_common_hours' => 'required|integer|min:1|max:168',
            'grouping_deadline' => 'required|date',
            'student_modification_deadline' => 'nullable|date',
            'status' => 'nullable|string|in:draft,open,grouping in progress,completed',
            'students_count' => 'nullable|integer|min:0',
        ]);

        if (empty($validated['status'])) {
            $validated['status'] = 'open';
        }

        if (empty($validated['preferred_skills'])) {
            $validated['preferred_skills'] = [];
        }

        if (empty($validated['students_count'])) {
            $validated['students_count'] = 30;
        }

        if (empty($validated['number_of_groups']) && !empty($validated['group_capacity'])) {
            $validated['number_of_groups'] = (int) ceil($validated['students_count'] / $validated['group_capacity']);
        }

        $activity = GroupingActivity::create($validated);
        $activity->load('academicClass');

        return response()->json($activity, 201);
    }

    /**
     * Display the specified grouping activity.
     */
    public function show(int $id): JsonResponse
    {
        $activity = GroupingActivity::with('academicClass')->findOrFail($id);
        return response()->json($activity);
    }

    /**
     * Update the specified grouping activity.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'class_name' => 'sometimes|required|string|max:255',
            'academic_class_id' => 'nullable|exists:academic_classes,id',
            'description' => 'nullable|string',
            'grouping_method' => 'sometimes|required|string|in:auto,manual,hybrid',
            'group_capacity' => 'sometimes|required|integer|min:2|max:50',
            'number_of_groups' => 'nullable|integer|min:1|max:100',
            'required_skills' => 'sometimes|required|array|min:1',
            'required_skills.*' => 'string',
            'preferred_skills' => 'nullable|array',
            'preferred_skills.*' => 'string',
            'min_proficiency_level' => 'sometimes|required|string|in:Beginner,Intermediate,Advanced',
            'min_common_hours' => 'sometimes|required|integer|min:1|max:168',
            'grouping_deadline' => 'sometimes|required|date',
            'student_modification_deadline' => 'nullable|date',
            'status' => 'sometimes|required|string|in:draft,open,grouping in progress,completed',
            'students_count' => 'nullable|integer|min:0',
        ]);

        $activity->update($validated);
        $activity->load('academicClass');

        return response()->json($activity);
    }

    /**
     * Remove the specified grouping activity.
     */
    public function destroy(int $id): JsonResponse
    {
        $activity = GroupingActivity::findOrFail($id);
        $activity->delete();

        return response()->json(['message' => 'Activity deleted successfully'], 200);
    }
}
