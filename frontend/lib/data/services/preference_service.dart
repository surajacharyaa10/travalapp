// lib/data/services/preference_service.dart
import 'api_client.dart';

class PreferenceOption {
  final String id;
  final String name;
  final String icon;

  const PreferenceOption({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory PreferenceOption.fromJson(Map<String, dynamic> json) {
    return PreferenceOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '✨',
    );
  }
}

class PreferenceService {
  final ApiClient _apiClient = ApiClient();

  /// Fetches the master list of travel preferences from the backend.
  /// Used by both SignupScreen and ProfileScreen so there is exactly
  /// one place that knows how to talk to /api/auth/preferences.
  Future<List<PreferenceOption>> getAvailablePreferences() async {
    final res = await _apiClient.get('/api/auth/preferences');

    if (res is List) {
      return res
          .map(
            (item) => PreferenceOption.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }
}
