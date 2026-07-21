import 'api_client.dart';

class PlacesService {
  final ApiClient _apiClient = ApiClient();

  Future<dynamic> getNearbyPlaces(double lat, double lng, String type) async {
    // Assuming backend endpoint: /api/places/nearby?lat=...&lng=...&type=...
    final response = await _apiClient.get('/api/places/nearby?lat=$lat&lng=$lng&type=$type');
    return response;
  }

  Future<dynamic> searchPlaces(String query) async {
    // Assuming backend endpoint: /api/places/search?q=...
    final response = await _apiClient.get('/api/places/search?q=$query');
    return response;
  }
}
