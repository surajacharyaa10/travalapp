import 'package:flutter/material.dart';
import '../../../data/services/places_service.dart';
import '../../../data/services/bookmark_service.dart';
import '../../../data/services/session_manager.dart';
import '../../../data/services/api_client.dart';
import 'category_places_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlacesService _placesService = PlacesService();
  final BookmarkService _bookmarkService = BookmarkService();
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _places = [];
  List<dynamic> _bookmarks = [];
  bool _isLoadingPlaces = false;
  String _selectedCategory = 'restaurant';
  String _aiRecommendations = '';
  bool _isLoadingAI = false;

  final Map<String, String> _categoryMapping = {
    'Dining': 'restaurant',
    'Hotels': 'lodging',
    'Museums': 'museum',
    'Cafes': 'cafe',
  };

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
    _fetchBookmarks();
    _fetchAIRecommendations();
  }

  Future<void> _fetchPlaces() async {
    setState(() {
      _isLoadingPlaces = true;
    });
    try {
      // Defaulting to Pokhara coordinates for nearby search
      final response = await _placesService.getNearbyPlaces(28.2096, 83.9856, _selectedCategory);
      setState(() {
        _places = response['results'] ?? [];
      });
    } catch (e) {
      debugPrint('Error fetching places: $e');
    } finally {
      setState(() {
        _isLoadingPlaces = false;
      });
    }
  }

  Future<void> _fetchBookmarks() async {
    try {
      final bookmarks = await _bookmarkService.getBookmarks();
      setState(() {
        _bookmarks = bookmarks;
      });
    } catch (e) {
      debugPrint('Error fetching bookmarks: $e');
    }
  }

  Future<void> _fetchAIRecommendations() async {
    setState(() {
      _isLoadingAI = true;
    });
    try {
      final response = await _apiClient.post('/api/recommendations', {
        'location': 'Pokhara, Nepal',
        'preferences': SessionManager.user?['preferences'] ?? ['dining', 'adventure']
      });
      setState(() {
        _aiRecommendations = response['recommendations'] ?? '';
      });
    } catch (e) {
      debugPrint('Error getting AI recommendations: $e');
      setState(() {
        _aiRecommendations = 'Could not load custom recommendations at this time.';
      });
    } finally {
      setState(() {
        _isLoadingAI = false;
      });
    }
  }

  Future<void> _toggleBookmark(Map<String, dynamic> place) async {
    final isBookmarked = _bookmarks.any((b) => b['placeId'] == place['place_id']);

    try {
      if (isBookmarked) {
        final bookmark = _bookmarks.firstWhere((b) => b['placeId'] == place['place_id']);
        await _bookmarkService.removeBookmark(bookmark['_id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from Saved Places')),
        );
      } else {
        await _bookmarkService.addBookmark(
          placeId: place['place_id'] ?? 'mock_id',
          name: place['name'] ?? 'Unknown Place',
          address: place['vicinity'] ?? 'Unknown Address',
          category: _selectedCategory,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Bookmarks!')),
        );
      }
      _fetchBookmarks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update bookmark: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = SessionManager.user?['name'] ?? 'Traveler';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text(
          'TripSense',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Text(
                userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $userName!',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const Text(
              'Where do you want to go?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),

            // AI Recommendations Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent.shade400, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'AI Personal Travel Tips',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _isLoadingAI
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Text(
                          _aiRecommendations,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Categories section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCategoryItem('Dining', Icons.restaurant, Colors.orange),
                _buildCategoryItem('Hotels', Icons.hotel, Colors.blue),
                _buildCategoryItem('Museums', Icons.museum, Colors.purple),
                _buildCategoryItem('Cafes', Icons.local_cafe, Colors.brown),
              ],
            ),
            const SizedBox(height: 30),

            // Nearby Places section
            const Text(
              'Popular Destinations Nearby',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _isLoadingPlaces
                ? const Center(child: CircularProgressIndicator())
                : _places.isEmpty
                    ? const Center(child: Text('No destinations found for this category.'))
                    : ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _places.length,
                        itemBuilder: (context, index) {
                          final place = _places[index];
                          final isBookmarked = _bookmarks.any((b) => b['placeId'] == place['place_id']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 1,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.place, color: Colors.blueAccent, size: 30),
                              ),
                              title: Text(
                                place['name'] ?? 'Unknown Destination',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(place['vicinity'] ?? 'Unknown Address'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${place['rating'] ?? "N/A"} (${place['user_ratings_total'] ?? 0} reviews)',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                  color: isBookmarked ? Colors.blueAccent : Colors.grey,
                                ),
                                onPressed: () => _toggleBookmark(place),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon, Color color) {
    final categoryCode = _categoryMapping[label] ?? 'restaurant';
    final isSelected = _selectedCategory == categoryCode;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryPlacesScreen(
              categoryName: label,
              categoryType: categoryCode,
            ),
          ),
        ).then((_) => _fetchBookmarks()); // Refresh bookmarks when returning
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.3) : color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black87 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
