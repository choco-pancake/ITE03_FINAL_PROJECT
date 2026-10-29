<?php

namespace App\Http\Controllers;

use App\Models\Profile;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    // READ all
    public function index()
    {
        return response()->json(Profile::all());
    }

    // CREATE
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:profiles,email',
            'skills' => 'required|array',
            'interests' => 'nullable|array',
            'preferred_role' => 'required|string',
            'availability' => 'required|string',
        ]);

        $profile = Profile::create($data);
        return response()->json($profile, 201);
    }

    // READ one
    public function show(Profile $profile)
    {
        return response()->json($profile);
    }

    // UPDATE
    public function update(Request $request, Profile $profile)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:profiles,email,' . $profile->id,
            'skills' => 'sometimes|array',
            'interests' => 'nullable|array',
            'preferred_role' => 'sometimes|string',
            'availability' => 'sometimes|string',
        ]);

        $profile->update($data);
        return response()->json($profile);
    }

    // DELETE
    public function destroy(Profile $profile)
    {
        $profile->delete();
        return response()->json(null, 204);
    }
}
