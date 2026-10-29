import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/profile.dart';

class ProfileService {
  // Flutter WEB uses localhost/127.0.0.1.
  // (10.0.2.2 is only for the Android emulator.)
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

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
