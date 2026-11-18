class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static String? activeUserId;
  static bool isConnected = false;

  /// Check if the Laravel backend is running
  static Future<bool> pingBackend() async {
    return isConnected;
  }

  /// Endpoint definitions
  static const String loginUrl = '$baseUrl/login';
  static const String registerUrl = '$baseUrl/register';
  static const String activitiesUrl = '$baseUrl/activities';
  static const String studentDashboardUrl = '$baseUrl/dashboard/student';
  static const String professorDashboardUrl = '$baseUrl/dashboard/professor';
  static const String customSkillsUrl = '$baseUrl/custom-skills';

  static String hybridMatchUrl(String activityId) => '$baseUrl/activities/$activityId/hybrid-match';
  static String activityTeamsUrl(String activityId) => '$baseUrl/activities/$activityId/teams';
}
