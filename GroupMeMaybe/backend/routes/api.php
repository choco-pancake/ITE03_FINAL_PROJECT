<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ProfileController;

Route::get('/test', function () {
    return response()->json([
        'success' => true,
        'message' => 'Flutter successfully connected to Laravel!',
        'data' => [
            'frontend' => 'Flutter Web',
            'backend' => 'Laravel',
            'database' => 'MySQL',
        ],
    ]);
});

Route::apiResource('profiles', ProfileController::class);