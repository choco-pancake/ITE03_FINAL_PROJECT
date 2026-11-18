<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomSkillRequest;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Http\Request;

class CustomSkillController extends Controller
{
    public function index()
    {
        return response()->json([
            'custom_skills' => CustomSkillRequest::latest()->get(),
        ]);
    }

    public function submit(Request $request)
    {
        $validated = $request->validate([
            'student_id' => 'required|string',
            'skill_name' => 'required|string',
            'category' => 'required|string',
            'justification' => 'required|string',
        ]);

        $student = User::find($validated['student_id']);
        $studentName = $student ? $student->full_name : 'Student';

        $req = CustomSkillRequest::create([
            'id' => 'skill-req-' . time(),
            'student_id' => $validated['student_id'],
            'student_name' => $studentName,
            'skill_name' => $validated['skill_name'],
            'category' => $validated['category'],
            'justification' => $validated['justification'],
            'status' => 'pending',
            'date_requested' => now(),
        ]);

        Notification::create([
            'id' => 'notif-' . time(),
            'recipient_id' => 'prof-1',
            'title' => 'New Skill Approval Request',
            'message' => "{$studentName} requested addition of '{$validated['skill_name']}'.",
            'type' => 'customSkill',
            'is_read' => false,
            'timestamp' => now(),
        ]);

        return response()->json([
            'message' => 'Custom skill submitted for review.',
            'request' => $req,
        ], 201);
    }

    public function approve(Request $request, $id)
    {
        $skillReq = CustomSkillRequest::findOrFail($id);
        $skillReq->status = 'approved';
        $skillReq->reviewer_remarks = $request->input('remarks', 'Approved for official course grouping.');
        $skillReq->save();

        // Update student profile with new skill
        $student = User::find($skillReq->student_id);
        if ($student) {
            $skills = $student->technical_skills ?: [];
            if (!in_array($skillReq->skill_name, $skills)) {
                $skills[] = $skillReq->skill_name;
                $student->technical_skills = $skills;
                $student->save();
            }
        }

        Notification::create([
            'id' => 'notif-' . time(),
            'recipient_id' => $skillReq->student_id,
            'title' => 'Custom Skill Approved: ' . $skillReq->skill_name,
            'message' => "Prof. Ghian approved '{$skillReq->skill_name}'. It is now added to your verified skills.",
            'type' => 'customSkill',
            'is_read' => false,
            'timestamp' => now(),
        ]);

        return response()->json([
            'message' => 'Skill approved successfully.',
            'request' => $skillReq,
        ]);
    }

    public function reject(Request $request, $id)
    {
        $skillReq = CustomSkillRequest::findOrFail($id);
        $skillReq->status = 'rejected';
        $skillReq->reviewer_remarks = $request->input('remarks', 'Does not align with course competencies.');
        $skillReq->save();

        return response()->json([
            'message' => 'Skill request declined.',
            'request' => $skillReq,
        ]);
    }
}
