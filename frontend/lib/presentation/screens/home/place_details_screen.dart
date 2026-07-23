import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  String? _imageUrl;
  String? _description;
  bool _isLoadingInfo = true;

  @override
  void initState() {
    super.initState();
    _fetchPlacePhotoAndDescription();
  }

  Future<void> _fetchPlacePhotoAndDescription() async {
    final String name = widget.place['name'] ?? 'Destination';
    final String nameLower = name.toLowerCase();
    final String address = widget.place['vicinity'] ?? widget.place['address'] ?? '';
    
    final rawTypes = (widget.place['types'] as List?)?.join(' ').toLowerCase() ?? '';
    final rawCategories = (widget.place['categories'] as List?)?.join(' ').toLowerCase() ?? '';
    final rawSingleCat = widget.place['category']?.toString().toLowerCase() ?? '';
    final fullCategorySignal = '$rawTypes $rawCategories $rawSingleCat $nameLower';

    // 1. Check direct photo URL if present
    if (widget.place['photoUrl'] != null && widget.place['photoUrl'].toString().isNotEmpty) {
      _imageUrl = widget.place['photoUrl'];
    }

    // 2. Curated Database for iconic brands and places
    final knownPlaces = [
      {
        'key': 'himalayan java',
        'img': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800',
        'desc': 'Himalayan Java Coffee is Nepal\'s premier specialty coffee chain, founded in Thamel, Kathmandu in 1999. Renowned for serving high-quality Nepali organic coffee, artisanal brews, and fresh baked pastries.'
      },
      {
        'key': 'pashupati',
        'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Pashupatinath_Temple-2020.jpg/800px-Pashupatinath_Temple-2020.jpg',
        'desc': 'Pashupatinath Temple is a sacred Hindu temple dedicated to Lord Shiva, situated on the banks of the Bagmati River in Kathmandu, Nepal. It is recognized as a UNESCO World Heritage site.'
      },
      {
        'key': 'pokhara',
        'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Pokhara_Valley.jpg/800px-Pokhara_Valley.jpg',
        'desc': 'Pokhara is a world-famous lakefront city in central Nepal, known as the gateway to the Annapurna Circuit. Famous for Phewa Lake, mountain reflections, and adventure activities.'
      },
      {
        'key': 'lumbini',
        'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Maya_Devi_Temple_Lumbini_Nepal.jpg/800px-Maya_Devi_Temple_Lumbini_Nepal.jpg',
        'desc': 'Lumbini is a UNESCO World Heritage site in Nepal, celebrated worldwide as the sacred historic birthplace of Siddhartha Gautama (Lord Buddha).'
      },
      {
        'key': 'annapurna',
        'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Annapurna_I_ABC.jpg/800px-Annapurna_I_ABC.jpg',
        'desc': 'Annapurna Base Camp sits at 4,130m in the heart of the Annapurna sanctuary, offering breathtaking 360-degree views of Himalayan giant peaks.'
      },
      {
        'key': 'everest',
        'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Everest_North_Face_toward_base_camp_Tibet_Luca_Galuzzi_2006.jpg/800px-Everest_North_Face_toward_base_camp_Tibet_Luca_Galuzzi_2006.jpg',
        'desc': 'Mount Everest Base Camp is an iconic global trekking destination located at the foot of the highest mountain on Earth.'
      },
      {
        'key': 'durbar',
        'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Kathmandu-Durbar_Square-06-Mahavishnu-Kuh-Vishnu-Pratapamalla-Jagannath-2007-gje.jpg/800px-Kathmandu-Durbar_Square-06-Mahavishnu-Kuh-Vishnu-Pratapamalla-Jagannath-2007-gje.jpg',
        'desc': 'Kathmandu Durbar Square is a historic royal plaza featuring ancient palaces, courtyards, and pagoda temples dating back to the Malla dynasty.'
      },
      {
        'key': 'sweet basil',
        'img': 'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=800',
        'desc': 'Sweet Basil Thai is a popular Thai restaurant located on Mission Street, San Francisco. Highly rated for authentic Green Curry, Pad Thai, and fresh basil stir-fry.'
      },
      {
        'key': 'chautari roti',
        'img': 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=800',
        'desc': 'Chautari Roti Pasal is a beloved local eatery in Pokhara, Nepal. Famous for freshly baked roti, traditional curry, and authentic Nepali breakfast.'
      }
    ];

    for (final match in knownPlaces) {
      if (nameLower.contains(match['key']!)) {
        _imageUrl ??= match['img'];
        _description ??= match['desc'];
        break;
      }
    }

    try {
      // 3. Try Wikipedia API query if not found
      if (_imageUrl == null || _description == null) {
        final wikiUrl = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(name)}');
        final response = await http.get(wikiUrl, headers: {'User-Agent': 'TravelApp/1.0 (contact@travelapp.com)'});

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['thumbnail'] != null && data['thumbnail']['source'] != null) {
            _imageUrl ??= data['thumbnail']['source'];
          }
          if (data['extract'] != null && data['extract'].toString().isNotEmpty) {
            _description ??= data['extract'];
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching wiki details: $e');
    } finally {
      if (mounted) {
        // 4. Keyword-based imagery & description fallbacks
        if (_imageUrl == null || _imageUrl!.isEmpty) {
          if (fullCategorySignal.contains('coffee') || fullCategorySignal.contains('java') || fullCategorySignal.contains('cafe')) {
            _imageUrl = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800';
            _description ??= '$name is a popular coffee house & cafe at ${address.isEmpty ? "a prime central location" : address}. Famous for fresh roasted coffee, espresso drinks, and a relaxing vibe.';
          } else if (fullCategorySignal.contains('hotel') || fullCategorySignal.contains('stay') || fullCategorySignal.contains('resort') || fullCategorySignal.contains('inn')) {
            _imageUrl = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800';
            _description ??= '$name is a top-rated hotel and accommodation spot located at ${address.isEmpty ? "a great central location" : address}. Known for cozy rooms, warm hospitality, and a pleasant stay.';
          } else if (fullCategorySignal.contains('thai') || fullCategorySignal.contains('asian')) {
            _imageUrl = 'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=800';
            _description ??= '$name is a vibrant restaurant at ${address.isEmpty ? "a convenient area" : address}. Famous for authentic spices, fresh ingredients, and signature regional dishes.';
          } else if (fullCategorySignal.contains('bakery') || fullCategorySignal.contains('roti') || fullCategorySignal.contains('pasal')) {
            _imageUrl = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800';
            _description ??= '$name is an authentic bakery & food shop situated at ${address.isEmpty ? "a local neighbourhood" : address}. Loved for fresh baked items and daily specialties.';
          } else if (fullCategorySignal.contains('restaurant') || fullCategorySignal.contains('catering') || fullCategorySignal.contains('dining') || fullCategorySignal.contains('food')) {
            _imageUrl = 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800';
            _description ??= '$name is a fine dining restaurant located at ${address.isEmpty ? "a prime location" : address}. Highly rated for delicious food, great ambiance, and attentive service.';
          } else {
            _imageUrl = 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=800';
            _description ??= '$name is a prominent attraction situated at ${address.isEmpty ? "a prime location" : address}. Recommended by travellers for its unique experience.';
          }
        }

        _description ??= 'Discover $name, located at ${address.isEmpty ? "a prime location" : address}. Highly rated by visitors for its welcoming atmosphere.';
        _isLoadingInfo = false;
        setState(() {});
      }
    }
  }

  Future<void> _getDirections(BuildContext context) async {
    final lat = widget.place['geometry']?['location']?['lat'] ?? widget.place['lat'];
    final lng = widget.place['geometry']?['location']?['lng'] ?? widget.place['lng'];
    
    if (lat != null && lng != null) {
      try {
        final Uri androidMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
        final Uri appleMapsUrl = Uri.parse('https://maps.apple.com/?saddr=Current%20Location&daddr=$lat,$lng&dirflg=d');
        final Uri fallbackUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

        if (Theme.of(context).platform == TargetPlatform.android) {
          if (await canLaunchUrl(androidMapsUrl)) {
            await launchUrl(androidMapsUrl, mode: LaunchMode.externalApplication);
          } else if (await canLaunchUrl(fallbackUrl)) {
            await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
          }
        } else if (Theme.of(context).platform == TargetPlatform.iOS) {
          if (await canLaunchUrl(appleMapsUrl)) {
            await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
          } else if (await canLaunchUrl(fallbackUrl)) {
            await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
          }
        } else {
          if (await canLaunchUrl(fallbackUrl)) {
            await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error launching maps: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.place['name'] ?? 'Unknown Destination';
    final String address = widget.place['vicinity'] ?? widget.place['address'] ?? 'Address available on map';
    final double rating = (widget.place['rating'] ?? 4.5).toDouble();
    final int reviews = widget.place['user_ratings_total'] ?? 100;
    
    final rawTypes = (widget.place['types'] as List?) ?? (widget.place['categories'] as List?) ?? [];
    final String categories = rawTypes.isNotEmpty 
      ? rawTypes.map((e) => e.toString().replaceAll('_', ' ').toUpperCase()).join(', ') 
      : 'FEATURED DESTINATION';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Header
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey[200],
                      child: _imageUrl != null
                          ? Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.network(
                                'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800',
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title and Rating
                  Text(
                    name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '$rating',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($reviews reviews)',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.blueAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Categories
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.category, color: Colors.blueAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          categories,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4, letterSpacing: 1.1),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Overview / Short Description section
                  const Text(
                    'About & Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingInfo
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Text(
                          _description ?? 'No detailed description available.',
                          style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Bottom action button area
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _getDirections(context),
                icon: const Icon(Icons.directions, color: Colors.white),
                label: const Text(
                  'Get Directions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
