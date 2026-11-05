<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\GroupingActivityController;
use App\Http\Controllers\AcademicClassController;

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

// Professor Activities / Projects Module (Aivhan)
Route::get('activities/summary', [GroupingActivityController::class, 'summary']);
Route::apiResource('activities', GroupingActivityController::class);
Route::apiResource('classes', AcademicClassController::class);
