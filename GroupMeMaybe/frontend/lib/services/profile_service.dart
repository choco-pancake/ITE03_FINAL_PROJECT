import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/profile.dart';
import 'auth_service.dart';

class ProfileService {
  // Flutter WEB uses localhost/127.0.0.1.
  // (10.0.2.2 is only for the Android emulator.)
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> get _authHeaders => {
    ..._headers,
    'Authorization': 'Bearer ${AuthService.authToken ?? ''}',
  };

  Future<Profile?> getMyProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: _authHeaders,
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode == 200) return Profile.fromJson(jsonDecode(res.body));
    throw Exception('Failed to load your profile (${res.statusCode})');
  }

  Future<Profile> saveMyProfile(Profile profile) async {
    final res = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: _authHeaders,
      body: jsonEncode(profile.toJson()),
    );
    if (res.statusCode == 200) return Profile.fromJson(jsonDecode(res.body));
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
