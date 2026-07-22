import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    // Assuming backend has a /api/auth/login endpoint
    final response = await _apiClient.post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return response; // Contains token and user details
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, {List<String>? preferences}) async {
    // Assuming backend has a /api/auth/register endpoint
    final response = await _apiClient.post('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'preferences': preferences ?? [],
    });
    return response;
  }
}
