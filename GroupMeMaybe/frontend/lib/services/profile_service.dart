import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';
import 'auth_service.dart';

class ProfileService {
  // Flutter WEB uses localhost/127.0.0.1.
  // (10.0.2.2 is only for the Android emulator.)
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static bool isProfileComplete = false;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, String>> _resolveAuthHeaders() async {
    String? token = AuthService.authToken;
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('gmm_active_token') ?? prefs.getString('gmm_saved_token');
      if (token != null) {
        AuthService.authToken = token;
      }
    }
    return {
      ..._headers,
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Future<bool> checkProfileComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = AuthService.currentUser?.id?.toString() ??
          AuthService.currentUser?.email ??
          'active';
      final cachedComplete = prefs.getBool('gmm_profile_complete_$userKey');
      if (cachedComplete == true) {
        isProfileComplete = true;
      }

      final profile = await getMyProfile();
      if (profile == null) {
        isProfileComplete = false;
        await prefs.setBool('gmm_profile_complete_$userKey', false);
        return false;
      }
      isProfileComplete = profile.details['is_complete'] == true;
      await prefs.setBool('gmm_profile_complete_$userKey', isProfileComplete);
      return isProfileComplete;
    } catch (_) {
      return isProfileComplete;
    }
  }

  Future<Profile?> getMyProfile() async {
    final headers = await _resolveAuthHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: headers,
    );
    if (res.statusCode == 401) {
      AuthService.authToken = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('gmm_active_token');
      } catch (_) {}
      throw Exception('Session expired or unauthenticated. Please log in again.');
    }
    if (res.statusCode == 404) {
      isProfileComplete = false;
      return null;
    }
    if (res.statusCode == 200) {
      final prof = Profile.fromJson(jsonDecode(res.body));
      isProfileComplete = prof.details['is_complete'] == true;
      return prof;
    }
    throw Exception('Failed to load your profile (${res.statusCode})');
  }

  Future<Profile> saveMyProfile(Profile profile) async {
    final headers = await _resolveAuthHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: headers,
      body: jsonEncode(profile.toJson()),
    );
    if (res.statusCode == 401) {
      AuthService.authToken = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('gmm_active_token');
      } catch (_) {}
      throw Exception('Session expired or unauthenticated. Please log in again.');
    }
    if (res.statusCode == 200 || res.statusCode == 201) {
      final saved = Profile.fromJson(jsonDecode(res.body));
      isProfileComplete = saved.details['is_complete'] == true;
      try {
        final prefs = await SharedPreferences.getInstance();
        final userKey = AuthService.currentUser?.id?.toString() ??
            AuthService.currentUser?.email ??
            'active';
        await prefs.setBool('gmm_profile_complete_$userKey', isProfileComplete);
      } catch (_) {}
      return saved;
    }
    throw Exception('Failed to save your profile: ${res.body}');
  }

  // READ all
  Future<List<Profile>> getProfiles() async {
    final res = await http.get(
      Uri.parse('$baseUrl/profiles'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Profile.fromJson(e)).toList();
    }
    throw Exception('Failed to load profiles (${res.statusCode})');
  }

  // CREATE
  Future<Profile> createProfile(Profile p) async {
    final res = await http.post(
      Uri.parse('$baseUrl/profiles'),
      headers: _headers,
      body: jsonEncode(p.toJson()),
    );
    if (res.statusCode == 201) return Profile.fromJson(jsonDecode(res.body));
    throw Exception('Failed to create: ${res.body}');
  }

  // UPDATE
  Future<Profile> updateProfile(int id, Profile p) async {
    final res = await http.put(
      Uri.parse('$baseUrl/profiles/$id'),
      headers: _headers,
      body: jsonEncode(p.toJson()),
    );
    if (res.statusCode == 200) return Profile.fromJson(jsonDecode(res.body));
    throw Exception('Failed to update: ${res.body}');
  }

  // DELETE
  Future<void> deleteProfile(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/profiles/$id'),
      headers: _headers,
    );
    if (res.statusCode != 204) throw Exception('Failed to delete');
  }
}
