<?php

use App\Http\Controllers\AcademicClassController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CustomSkillRequestController;
use App\Http\Controllers\GroupingActivityController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\PreSubmissionSwapController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\ProjectSubmissionController;
use App\Http\Controllers\StudentRecordController;
use Illuminate\Support\Facades\Route;

// Authentication routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/google-auth', [AuthController::class, 'googleAuth']);
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/account/password', [AuthController::class, 'changePassword']);
    Route::delete('/account', [AuthController::class, 'deleteAccount']);
    Route::get('/profile', [ProfileController::class, 'mine']);
    Route::put('/profile', [ProfileController::class, 'saveMine']);
    Route::post('/classes/enroll', [AcademicClassController::class, 'enroll']);
    Route::delete('/classes/{id}/students/{studentId}', [AcademicClassController::class, 'unenroll']);
    Route::get('/classes/{id}/students', [AcademicClassController::class, 'students']);
    Route::apiResource('classes', AcademicClassController::class);
    Route::get('/professor/students', [StudentRecordController::class, 'index']);
    Route::get('/classes/{id}/project-statuses', [ProjectSubmissionController::class, 'classStatuses']);
    Route::get('/activities/{id}/project-submissions', [ProjectSubmissionController::class, 'index']);
    Route::post('/activities/{id}/project-submissions', [ProjectSubmissionController::class, 'store']);
    Route::get('/project-submissions/{submission}/file', [ProjectSubmissionController::class, 'download']);
    Route::patch('/project-submissions/{submission}/grade', [ProjectSubmissionController::class, 'grade']);
    Route::get('/custom-skill-requests', [CustomSkillRequestController::class, 'index']);
    Route::post('/custom-skill-requests', [CustomSkillRequestController::class, 'store']);
    Route::patch('/custom-skill-requests/{skillRequest}', [CustomSkillRequestController::class, 'update']);
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/{notification}/read', [NotificationController::class, 'markRead']);
    Route::get('/notification-preferences', [NotificationController::class, 'preferences']);
    Route::put('/notification-preferences', [NotificationController::class, 'updatePreferences']);
    Route::get('/pre-submission-swaps', [PreSubmissionSwapController::class, 'index']);
    Route::get('/activities/{id}/instructions', [GroupingActivityController::class, 'downloadInstructions']);
    Route::post('/activities/{id}/teams/pre-submission-swaps', [PreSubmissionSwapController::class, 'store']);
    Route::post('/pre-submission-swaps/{swap}/decision', [PreSubmissionSwapController::class, 'decide']);

    // Admin & Department Chair routes
    Route::get('/admin/overview', [AdminController::class, 'overview']);
    Route::get('/admin/faculty', [AdminController::class, 'faculty']);
    Route::get('/admin/students', [AdminController::class, 'students']);
    Route::post('/admin/faculty-code', [AdminController::class, 'updateFacultyCode']);
    Route::post('/admin/semester', [AdminController::class, 'updateSemester']);
});

Route::get('/settings/semester', [AdminController::class, 'publicSettings']);

Route::get('/test', function () {
    return response()->json([
        'success' => true,
        'message' => 'Flutter successfully connected to Laravel!',
        'data' => [
            'frontend' => 'Flutter Web',
            'backend' => 'Laravel',
            'database' => config('database.default'),
        ],
    ]);
});

Route::apiResource('profiles', ProfileController::class)->only(['index', 'show']);

// Professor Activities / Projects Module (Aivhan) & Scarcity (Yvonne)
Route::get('activities/summary', [GroupingActivityController::class, 'summary']);
Route::get('activities/{id}/scarcity', [GroupingActivityController::class, 'scarcity']);
Route::get('activities/{id}/teams', [GroupingActivityController::class, 'teams']);
Route::middleware('auth:sanctum')->post('activities/{id}/teams', [GroupingActivityController::class, 'createTeam']);
Route::middleware('auth:sanctum')->post('activities/{id}/teams/join', [GroupingActivityController::class, 'joinTeam']);
Route::middleware('auth:sanctum')->post('activities/{id}/teams/respond-join', [GroupingActivityController::class, 'respondJoinRequest']);
Route::middleware('auth:sanctum')->post('activities/{id}/teams/submit-evaluation', [GroupingActivityController::class, 'submitGroupEvaluation']);
Route::middleware('auth:sanctum')->post('activities/{id}/teams/review', [GroupingActivityController::class, 'reviewTeamProposal']);
Route::middleware('auth:sanctum')->post('activities/{id}/teams/request-member-change', [GroupingActivityController::class, 'requestMemberChange']);
Route::middleware('auth:sanctum')->post('activities/{id}/teams/invite', [GroupingActivityController::class, 'inviteStudent']);
Route::middleware('auth:sanctum')->get('activities/{id}/teams/invite-candidates', [GroupingActivityController::class, 'inviteCandidates']);
Route::middleware('auth:sanctum')->post('activities/{id}/teams/respond-invite', [GroupingActivityController::class, 'respondInvitation']);
Route::get('modification-requests', [GroupingActivityController::class, 'getModificationRequests']);
Route::post('modification-requests/{id}/decision', [GroupingActivityController::class, 'decideModificationRequest']);
Route::middleware('auth:sanctum')->post('activities/{id}/auto-form', [GroupingActivityController::class, 'autoFormUnassigned']);
Route::post('activities/{id}/add-skill', [GroupingActivityController::class, 'addSkill']);
Route::post('activities/{id}/accept-group', [GroupingActivityController::class, 'acceptGroup']);
Route::post('activities/{id}/request-change', [GroupingActivityController::class, 'requestChange']);
Route::apiResource('activities', GroupingActivityController::class);
