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

  bool get isAdmin =>
      role.toLowerCase() == 'admin' || role.toLowerCase() == 'administrator';
  bool get isProfessor =>
      role.toLowerCase() == 'professor' || role.toLowerCase() == 'instructor';
  bool get isStudent => !isProfessor && !isAdmin;

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

class StoredAccount {
  final AuthUser user;
  final String token;

  const StoredAccount({required this.user, required this.token});

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'token': token,
  };

  factory StoredAccount.fromJson(Map<String, dynamic> json) => StoredAccount(
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    token: (json['token'] ?? '').toString(),
  );
}

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static AuthUser? currentUser;
  static String? authToken;
  static final Set<String> promptedCompleteProfileAccounts = {};

  static const String _prefKeyRememberMe = 'gmm_remember_me';
  static const String _prefKeySavedEmail = 'gmm_saved_email';
  static const String _prefKeySavedToken = 'gmm_saved_token';
  static const String _prefKeySavedUser = 'gmm_saved_user';
  static const String _prefKeyActiveToken = 'gmm_active_token';
  static const String _prefKeyActiveUser = 'gmm_active_user';
  static const String _prefKeyKnownAccounts = 'gmm_known_accounts';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Persist the active session so page refreshes in web do not drop credentials
  static Future<void> saveActiveSession(AuthUser user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyActiveToken, token);
      await prefs.setString(_prefKeyActiveUser, jsonEncode(user.toJson()));
      await saveKnownAccount(user, token);
    } catch (_) {}
  }

  /// Retrieve list of known accounts saved on this device/browser
  static Future<List<StoredAccount>> getKnownAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_prefKeyKnownAccounts) ?? [];
      final accounts = <StoredAccount>[];
      for (final raw in listJson) {
        try {
          accounts.add(StoredAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>));
        } catch (_) {}
      }
      return accounts;
    } catch (_) {
      return [];
    }
  }

  /// Record or update an account in the known accounts list
  static Future<void> saveKnownAccount(AuthUser user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getKnownAccounts();
      final updated = existing
          .where((a) => a.user.email.trim().toLowerCase() != user.email.trim().toLowerCase())
          .toList();
      updated.insert(0, StoredAccount(user: user, token: token));
      final serialized = updated.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_prefKeyKnownAccounts, serialized);
    } catch (_) {}
  }

  /// Switch active session to another previously stored account
  static Future<bool> switchToAccount(StoredAccount account) async {
    AuthUser? user;
    try {
      user = await _userForToken(account.token);
    } catch (_) {
      return false;
    }
    if (user == null) {
      await removeKnownAccount(account.user.email);
      return false;
    }
    currentUser = user;
    authToken = account.token;
    await saveActiveSession(user, account.token);
    return true;
  }

  /// Remove an account from known accounts list
  static Future<void> removeKnownAccount(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getKnownAccounts();
      final updated = existing
          .where((a) => a.user.email.trim().toLowerCase() != email.trim().toLowerCase())
          .toList();
      final serialized = updated.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_prefKeyKnownAccounts, serialized);
    } catch (_) {}
  }

  /// Save or clear Remember Me credentials and full session in persistent storage
  static Future<void> saveSession({
    required AuthUser user,
    required String token,
    required bool rememberMe,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyRememberMe, rememberMe);
      await saveActiveSession(user, token);
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

  /// Restore persisted session on app startup or browser page refresh
  static Future<AuthUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token =
          prefs.getString(_prefKeyActiveToken) ??
          prefs.getString(_prefKeySavedToken);
      final userJson =
          prefs.getString(_prefKeyActiveUser) ??
          prefs.getString(_prefKeySavedUser);
      if (token != null && userJson != null) {
        final user = await _userForToken(token);
        if (user != null) {
          currentUser = user;
          authToken = token;
          await saveActiveSession(user, token);
          return user;
        }
        await prefs.remove(_prefKeyActiveToken);
        await prefs.remove(_prefKeyActiveUser);
        await prefs.remove(_prefKeySavedToken);
        await prefs.remove(_prefKeySavedUser);
        await removeKnownAccount(AuthUser.fromJson(jsonDecode(userJson)).email);
      }
    } catch (_) {}
    currentUser = null;
    authToken = null;
    return null;
  }

  static Future<AuthUser?> _userForToken(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {..._headers, 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 401) return null;
    if (response.statusCode != 200) throw Exception('Could not verify the saved session.');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthUser.fromJson(body['user'] as Map<String, dynamic>);
  }

  /// Retrieve the active authentication token, checking memory first and storage fallback
  static Future<String?> getValidToken() async {
    if (authToken != null && authToken!.trim().isNotEmpty) {
      return authToken;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_prefKeyActiveToken) ??
          prefs.getString(_prefKeySavedToken) ??
          prefs.getString('auth_token');
      if (token != null && token.trim().isNotEmpty) {
        authToken = token;
        return token;
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
        await saveActiveSession(user, data['token']);
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
        : [
            firstName,
            middleName,
            lastName,
          ].where((s) => s != null && s.trim().isNotEmpty).join(' ');

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
        await saveActiveSession(user, data['token']);
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
    String? facultyCode,
    String? departmentOrSection,
    String? preferredRole,
  }) async {
    try {
      final payload = <String, dynamic>{
        'id_token': idToken,
        'intent': intent,
      };
      if (role != null) payload['role'] = role;
      if (facultyCode != null) payload['faculty_code'] = facultyCode;
      if (departmentOrSection != null) {
        payload['department_or_section'] = departmentOrSection;
      }
      if (preferredRole != null) payload['preferred_role'] = preferredRole;

      final res = await http
          .post(
            Uri.parse('$baseUrl/google-auth'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final user = AuthUser.fromJson(data['user']);
        currentUser = user;
        authToken = data['token'];
        await saveActiveSession(user, data['token']);
        return user;
      }

      throw Exception(_responseMessage(res, 'Google authentication failed'));
    } on TimeoutException {
      throw Exception(
        'Google sign-in request timed out. The server is running, but did not finish verification. Please try again.',
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
    promptedCompleteProfileAccounts.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyActiveToken);
      await prefs.remove(_prefKeyActiveUser);
      await prefs.remove(_prefKeySavedToken);
      await prefs.remove(_prefKeySavedUser);
    } catch (_) {}
  }

  Future<void> changePassword({
    required String password,
    String? currentPassword,
    String? idToken,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/account/password'),
      headers: {..._headers, 'Authorization': 'Bearer $authToken'},
      body: jsonEncode({
        'current_password': currentPassword,
        'id_token': idToken,
        'password': password,
        'password_confirmation': password,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(_responseMessage(res, 'Password change failed'));
    }
  }

  Future<void> deleteAccount({required String email}) async {
    final preferencePrefix =
        'gmm_notifications_${currentUser?.id ?? currentUser?.email ?? 'guest'}';
    final res = await http.delete(
      Uri.parse('$baseUrl/account'),
      headers: {..._headers, 'Authorization': 'Bearer $authToken'},
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode != 200) {
      throw Exception(_responseMessage(res, 'Account deletion failed'));
    }
    currentUser = null;
    authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyActiveToken);
    await prefs.remove(_prefKeyActiveUser);
    await prefs.remove(_prefKeySavedToken);
    await prefs.remove(_prefKeySavedUser);
    await prefs.remove(_prefKeySavedEmail);
    await prefs.remove(_prefKeyRememberMe);
    await prefs.remove('${preferencePrefix}_group');
    await prefs.remove('${preferencePrefix}_skills');
  }
}
