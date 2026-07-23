import 'package:flutter/foundation.dart';
import 'api_client.dart';

class ChatApiService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> sendChatMessage(
      String message, Map<String, dynamic>? locationContext) async {
    try {
      final response = await _apiClient.post('/api/chat', {
        'message': message,
        'locationContext': locationContext ?? {},
      });

      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      return {
        'text_reply': 'Sorry, I am having trouble connecting to my brain right now.',
        'places': []
      };
    }
  }
}
