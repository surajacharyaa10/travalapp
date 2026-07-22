import 'api_client.dart';

class WeatherService {
  final ApiClient _apiClient = ApiClient();

  Future<dynamic> getCurrentWeather(double lat, double lng, {String? city}) async {
    String endpoint = '/api/weather/current?lat=$lat&lng=$lng';
    if (city != null && city.isNotEmpty) {
      endpoint += '&city=${Uri.encodeComponent(city)}';
    }
    final response = await _apiClient.get(endpoint);
    return response;
  }

  Future<dynamic> getWeatherForecast(double lat, double lng) async {
    // Assuming backend endpoint: /api/weather/forecast?lat=...&lng=...
    final response = await _apiClient.get('/api/weather/forecast?lat=$lat&lng=$lng');
    return response;
  }
}
