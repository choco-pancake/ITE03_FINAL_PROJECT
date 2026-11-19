import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final int? id;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String name;
  final String email;
  final String role; // 'student' or 'professor'
  final String? departmentOrSection;

  const AuthUser({
    this.id,
    this.firstName,
    this.middleName,
    this.lastName,
    required this.name,
    required this.email,
    required this.role,
    this.departmentOrSection,
  });

  String get effectiveFirstName {
    if (firstName != null && firstName!.trim().isNotEmpty) {
      return firstName!.trim();
    }
    if (name.trim().isNotEmpty) {
      return name.trim().split(RegExp(r'\s+')).first;
    }
    return 'Student';
  }

  bool get isProfessor =>
      role.toLowerCase() == 'professor' || role.toLowerCase() == 'instructor';
  bool get isStudent => !isProfessor;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final fName = json['first_name'] as String?;
    final mName = json['middle_name'] as String?;
    final lName = json['last_name'] as String?;
    final rawName = (json['name'] ?? '') as String;
    return AuthUser(
      id: json['id'],
      firstName: fName,
      middleName: mName,
      lastName: lName,
      name: rawName.isNotEmpty ? rawName : '$fName $lName'.trim(),
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      departmentOrSection: json['department_or_section'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'middle_name': middleName,
    'last_name': lastName,
    'name': name,
    'email': email,
    'role': role,
    'department_or_section': departmentOrSection,
  };
}

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static AuthUser? currentUser;
  static String? authToken;

  static const String _prefKeyRememberMe = 'gmm_remember_me';
  static const String _prefKeySavedEmail = 'gmm_saved_email';
  static const String _prefKeySavedToken = 'gmm_saved_token';
  static const String _prefKeySavedUser = 'gmm_saved_user';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Save or clear Remember Me credentials and full session in persistent storage
  static Future<void> saveSession({
    required AuthUser user,
    required String token,
    required bool rememberMe,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyRememberMe, rememberMe);
      if (rememberMe) {
        await prefs.setString(_prefKeySavedEmail, user.email.trim());
        await prefs.setString(_prefKeySavedToken, token);
        await prefs.setString(_prefKeySavedUser, jsonEncode(user.toJson()));
      } else {
        await prefs.remove(_prefKeySavedEmail);
        await prefs.remove(_prefKeySavedToken);
        await prefs.remove(_prefKeySavedUser);
      }
    } catch (_) {}
  }

  /// Restore persisted session on app startup if Remember Me was enabled
  static Future<AuthUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_prefKeyRememberMe) ?? false;
      if (!remember) return null;

      final token = prefs.getString(_prefKeySavedToken);
      final userJson = prefs.getString(_prefKeySavedUser);
      if (token != null && userJson != null) {
        final user = AuthUser.fromJson(jsonDecode(userJson));
        currentUser = user;
        authToken = token;
        return user;
      }
    } catch (_) {}
    return null;
  }

  /// Save or clear Remember Me credentials in persistent storage
  static Future<void> saveRememberedEmail(String email, bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyRememberMe, rememberMe);
      if (rememberMe) {
        await prefs.setString(_prefKeySavedEmail, email.trim());
      } else {
        await prefs.remove(_prefKeySavedEmail);
      }
    } catch (_) {}
  }

  /// Retrieve the remembered email if Remember Me was selected
  static Future<String?> getRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_prefKeyRememberMe) ?? false;
      if (remember) {
        return prefs.getString(_prefKeySavedEmail);
      }
    } catch (_) {}
    return null;
  }

  /// Check if Remember Me is currently enabled
  static Future<bool> isRememberMeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKeyRememberMe) ?? false;
    } catch (_) {}
    return false;
  }

  static String _responseMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }

  /// Sign in with email and password
  Future<AuthUser> login(String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: _headers,
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(milliseconds: 2500));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = AuthUser.fromJson(data['user']);
        currentUser = user;
        authToken = data['token'];
        return user;
      }

      throw Exception(_responseMessage(res, 'Login failed'));
    } on TimeoutException {
      throw Exception('Login timed out. Check that the server is running.');
    } on http.ClientException {
      throw Exception('Cannot reach the server. Check your connection.');
    }
  }

  /// Register a new user
  Future<AuthUser> register({
    String? name,
    String? firstName,
    String? middleName,
    String? lastName,
    required String email,
    required String password,
    required String role,
    String? facultyCode,
    String? departmentOrSection,
    String? preferredRole,
    List<String>? skills,
  }) async {
    final effectiveDept = role.toLowerCase() == 'professor'
        ? 'Department of Information Technology (BSIT)'
        : (departmentOrSection ?? 'BSIT 2A');

    final computedName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : [firstName, middleName, lastName]
            .where((s) => s != null && s.trim().isNotEmpty)
            .join(' ');

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: _headers,
            body: jsonEncode({
              'first_name': firstName?.trim(),
              'middle_name': middleName?.trim(),
              'last_name': lastName?.trim(),
              'name': computedName,
              'email': email.trim(),
              'password': password,
              'role': role,
              'faculty_code': facultyCode?.trim(),
              'department_or_section': effectiveDept,
              'preferred_role': preferredRole,
              'skills': skills,
            }),
          )
          .timeout(const Duration(milliseconds: 2500));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = AuthUser.fromJson(data['user']);
        currentUser = user;
        authToken = data['token'];
        return user;
      }

      throw Exception(_responseMessage(res, 'Registration failed'));
    } on TimeoutException {
      throw Exception(
        'Registration timed out. Check that the server is running.',
      );
    } on http.ClientException {
      throw Exception('Cannot reach the server. Check your connection.');
    }
  }

  /// Sign in or register with Google OAuth
  Future<AuthUser> googleAuth({
    required String idToken,
    required String intent,
    String? role,
    String? departmentOrSection,
    String? preferredRole,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/google-auth'),
            headers: _headers,
            body: jsonEncode({
              'id_token': idToken,
              'intent': intent,
              'role': role,
              'department_or_section': departmentOrSection,
              'preferred_role': preferredRole,
            }),
          )
          .timeout(const Duration(milliseconds: 2500));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final user = AuthUser.fromJson(data['user']);
        currentUser = user;
        authToken = data['token'];
        return user;
      }

      throw Exception(_responseMessage(res, 'Google authentication failed'));
    } on TimeoutException {
      throw Exception(
        'Google sign-in timed out. Check that the server is running.',
      );
    } on http.ClientException {
      throw Exception('Cannot reach the server. Check your connection.');
    }
  }

  /// Sign out
  Future<void> logout() async {
    try {
      if (authToken != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {..._headers, 'Authorization': 'Bearer $authToken'},
        );
      }
    } catch (_) {}
    currentUser = null;
    authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeySavedToken);
      await prefs.remove(_prefKeySavedUser);
    } catch (_) {}
  }
}
