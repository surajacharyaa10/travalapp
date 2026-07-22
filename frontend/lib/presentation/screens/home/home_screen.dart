import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../data/services/places_service.dart';
import '../../../data/services/bookmark_service.dart';
import '../../../data/services/session_manager.dart';
import '../../../data/services/api_client.dart';
import 'category_places_screen.dart';
import '../../widgets/ai_recommendations_panel.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/nearby_places_list.dart';

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
  List<dynamic> _aiRecommendations = [];
  bool _isLoadingAI = false;
  String _currentLocationString = 'Pokhara, Nepal'; // Default fallback

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
    _initLocationAndFetchAI();
  }

  Future<void> _initLocationAndFetchAI() async {
    setState(() {
      _isLoadingAI = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
          );

          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final pm = placemarks.first;
            final city =
                pm.locality ?? pm.subAdministrativeArea ?? 'Unknown City';
            final country = pm.country ?? 'Unknown Country';
            setState(() {
              _currentLocationString = '$city, $country';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
    }

    _fetchAIRecommendations();
  }

  Future<void> _fetchPlaces() async {
    setState(() {
      _isLoadingPlaces = true;
    });
    try {
      // Defaulting to Pokhara coordinates for nearby search
      final response = await _placesService.getNearbyPlaces(
        28.2096,
        83.9856,
        _selectedCategory,
      );
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
        'location': _currentLocationString,
        'preferences':
            SessionManager.user?['preferences'] ?? ['dining', 'adventure'],
      });
      
      final recommendations = response['recommendations'];
      setState(() {
        if (recommendations is List) {
          _aiRecommendations = recommendations;
        } else if (recommendations is String) {
          try {
            final parsed = json.decode(recommendations);
            if (parsed is List) {
              _aiRecommendations = parsed;
            } else if (parsed is Map && parsed['recommendations'] is List) {
              _aiRecommendations = parsed['recommendations'];
            } else {
              _aiRecommendations = [
                {'name': 'AI Travel Suggestions', 'description': recommendations}
              ];
            }
          } catch (_) {
            _aiRecommendations = [
              {'name': 'AI Travel Suggestions', 'description': recommendations}
            ];
          }
        } else {
          _aiRecommendations = [];
        }
      });
    } catch (e) {
      debugPrint('Error getting AI recommendations: $e');
      setState(() {
        _aiRecommendations = [];
      });
    } finally {
      setState(() {
        _isLoadingAI = false;
      });
    }
  }

  Future<void> _toggleBookmark(Map<String, dynamic> place) async {
    final isBookmarked = _bookmarks.any(
      (b) => b['placeId'] == place['place_id'],
    );

    try {
      if (isBookmarked) {
        final bookmark = _bookmarks.firstWhere(
          (b) => b['placeId'] == place['place_id'],
        );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved to Bookmarks!')));
      }
      _fetchBookmarks();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update bookmark: $e')));
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
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),

            // AI Recommendations Panel
            AiRecommendationsPanel(
              recommendations: _aiRecommendations,
              isLoading: _isLoadingAI,
            ),
            const SizedBox(height: 30),

            // Categories section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Categories',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CategorySelector(
              selectedCategory: _selectedCategory,
              onBookmarkRefreshed: _fetchBookmarks,
            ),
            const SizedBox(height: 30),

            // Nearby Places section
            const Text(
              'Popular Destinations Nearby',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            NearbyPlacesList(
              places: _places,
              bookmarks: _bookmarks,
              isLoading: _isLoadingPlaces,
              onToggleBookmark: _toggleBookmark,
            ),
          ],
        ),
      ),
    );
  }
}
