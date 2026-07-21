import 'api_client.dart';

class NewsService {
  final ApiClient _apiClient = ApiClient();

  Future<dynamic> getLocalNews(String location) async {
    // Assuming backend endpoint: /api/news/local?q=...
    final response = await _apiClient.get('/api/news/local?q=$location');
    return response;
  }
}
