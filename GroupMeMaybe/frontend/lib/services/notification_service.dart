import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/portal_notification.dart';
import 'auth_service.dart';

class NotificationSnapshot {
  const NotificationSnapshot(this.items, this.unreadCount);

  final List<PortalNotification> items;
  final int unreadCount;
}

class NotificationService {
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer ${AuthService.authToken ?? ''}',
  };

  Future<NotificationSnapshot> getNotifications() async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/notifications'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not load notifications.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return NotificationSnapshot(
      (data['notifications'] as List)
          .map(
            (item) => PortalNotification.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      data['unread_count'] as int,
    );
  }

  Future<void> markRead(int id) async {
    final response = await http.patch(
      Uri.parse('${AuthService.baseUrl}/notifications/$id/read'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not mark notification as read.');
    }
  }

  Future<Map<String, bool>> getPreferences() async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/notification-preferences'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not load notification preferences.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'group_activity': data['group_activity'] == true,
      'custom_skills': data['custom_skills'] == true,
    };
  }

  Future<void> updatePreferences({
    bool? groupActivity,
    bool? customSkills,
  }) async {
    final response = await http.put(
      Uri.parse('${AuthService.baseUrl}/notification-preferences'),
      headers: _headers,
      body: jsonEncode({
        'group_activity': ?groupActivity,
        'custom_skills': ?customSkills,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Could not save notification preferences.');
    }
  }
}
