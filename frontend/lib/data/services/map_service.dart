import 'api_client.dart';

class MapService {
  final ApiClient _apiClient = ApiClient();

  Future<dynamic> getDirections(String origin, String destination) async {
    // Assuming backend endpoint: /api/map/directions?origin=...&destination=...
    final response = await _apiClient.get('/api/map/directions?origin=$origin&destination=$destination');
    return response;
  }
}
