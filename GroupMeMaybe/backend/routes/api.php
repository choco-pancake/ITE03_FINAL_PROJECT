<?php

use App\Http\Controllers\AcademicClassController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CustomSkillRequestController;
use App\Http\Controllers\GroupingActivityController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\ProfileController;
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
    Route::get('/custom-skill-requests', [CustomSkillRequestController::class, 'index']);
    Route::post('/custom-skill-requests', [CustomSkillRequestController::class, 'store']);
    Route::patch('/custom-skill-requests/{skillRequest}', [CustomSkillRequestController::class, 'update']);
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/{notification}/read', [NotificationController::class, 'markRead']);
    Route::get('/notification-preferences', [NotificationController::class, 'preferences']);
    Route::put('/notification-preferences', [NotificationController::class, 'updatePreferences']);
});

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

Route::apiResource('profiles', ProfileController::class);

// Professor Activities / Projects Module (Aivhan) & Scarcity (Yvonne)
Route::get('activities/summary', [GroupingActivityController::class, 'summary']);
Route::get('activities/{id}/scarcity', [GroupingActivityController::class, 'scarcity']);
Route::get('activities/{id}/teams', [GroupingActivityController::class, 'teams']);
Route::post('activities/{id}/teams', [GroupingActivityController::class, 'createTeam']);
Route::post('activities/{id}/teams/invite', [GroupingActivityController::class, 'inviteStudent']);
Route::post('activities/{id}/auto-form', [GroupingActivityController::class, 'autoFormUnassigned']);
Route::post('activities/{id}/add-skill', [GroupingActivityController::class, 'addSkill']);
Route::apiResource('activities', GroupingActivityController::class);
Route::apiResource('classes', AcademicClassController::class);
