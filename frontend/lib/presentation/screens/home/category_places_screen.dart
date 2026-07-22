import 'package:flutter/material.dart';
import '../../../data/services/places_service.dart';
import '../../../data/services/bookmark_service.dart';
import 'place_details_screen.dart';

class CategoryPlacesScreen extends StatefulWidget {
  final String categoryName;
  final String categoryType;

  const CategoryPlacesScreen({
    super.key,
    required this.categoryName,
    required this.categoryType,
  });

  @override
  State<CategoryPlacesScreen> createState() => _CategoryPlacesScreenState();
}

class _CategoryPlacesScreenState extends State<CategoryPlacesScreen> {
  final PlacesService _placesService = PlacesService();
  final BookmarkService _bookmarkService = BookmarkService();

  List<dynamic> _places = [];
  List<dynamic> _bookmarks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
    _fetchBookmarks();
  }

  Future<void> _fetchPlaces() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch near the default Pokhara coordinates
      final response = await _placesService.getNearbyPlaces(28.2096, 83.9856, widget.categoryType);
      if (mounted) {
        setState(() {
          _places = response['results'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching category places: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchBookmarks() async {
    try {
      final bookmarks = await _bookmarkService.getBookmarks();
      if (mounted) {
        setState(() {
          _bookmarks = bookmarks;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bookmarks: $e');
    }
  }

  Future<void> _toggleBookmark(Map<String, dynamic> place) async {
    final isBookmarked = _bookmarks.any((b) => b['placeId'] == place['place_id']);

    try {
      if (isBookmarked) {
        final bookmark = _bookmarks.firstWhere((b) => b['placeId'] == place['place_id']);
        await _bookmarkService.removeBookmark(bookmark['_id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from Saved Places')),
          );
        }
      } else {
        await _bookmarkService.addBookmark(
          placeId: place['place_id'] ?? 'mock_id',
          name: place['name'] ?? 'Unknown Place',
          address: place['vicinity'] ?? 'Unknown Address',
          category: widget.categoryType,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to Bookmarks!')),
          );
        }
      }
      _fetchBookmarks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update bookmark: $e')),
        );
      }
    }
  }

  void _openPlaceDetails(Map<String, dynamic> place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceDetailsScreen(place: place),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _places.isEmpty
              ? const Center(child: Text('No destinations found for this category.'))
              : RefreshIndicator(
                  onRefresh: () async {
                    _fetchPlaces();
                    _fetchBookmarks();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
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
                          onTap: () => _openPlaceDetails(place),
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
                ),
    );
  }
}
