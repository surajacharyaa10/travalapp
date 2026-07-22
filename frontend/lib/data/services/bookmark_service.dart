import 'api_client.dart';

class BookmarkService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getBookmarks() async {
    final response = await _apiClient.get('/api/bookmarks');
    if (response is List) {
      return response;
    }
    return [];
  }

  Future<dynamic> addBookmark({
    required String placeId,
    required String name,
    required String address,
    required String category,
  }) async {
    final response = await _apiClient.post('/api/bookmarks', {
      'placeId': placeId,
      'name': name,
      'address': address,
      'category': category,
    });
    return response;
  }

  // Delete/remove bookmark by ID (the Mongo DB _id)
  Future<dynamic> removeBookmark(String id) async {
    final response = await _apiClient.delete('/api/bookmarks/$id');
    return response;
  }
}
