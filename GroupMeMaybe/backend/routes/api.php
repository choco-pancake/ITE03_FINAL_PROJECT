<?php

use App\Http\Controllers\Api\ActivityController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CustomSkillController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\TeamController;
use Illuminate\Support\Facades\Route;

// Authentication
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::get('/me', [AuthController::class, 'me']);

// Dashboards (Student & Professor)
Route::get('/dashboard/student', [DashboardController::class, 'getStudentDashboard']);
Route::get('/dashboard/professor', [DashboardController::class, 'getProfessorDashboard']);

// Course Projects / Activities Gallery
Route::get('/activities', [ActivityController::class, 'index']);
Route::get('/activities/{id}', [ActivityController::class, 'show']);

// Teams & Hybrid Algorithm Engine
Route::get('/activities/{activityId}/teams', [TeamController::class, 'index']);
Route::post('/activities/{activityId}/hybrid-match', [TeamController::class, 'hybridMatch']);
Route::get('/teams/{id}', [TeamController::class, 'show']);

// Custom Skills Workflow
Route::get('/custom-skills', [CustomSkillController::class, 'index']);
Route::post('/custom-skills', [CustomSkillController::class, 'submit']);
Route::post('/custom-skills/{id}/approve', [CustomSkillController::class, 'approve']);
Route::post('/custom-skills/{id}/reject', [CustomSkillController::class, 'reject']);
