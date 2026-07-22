import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyPlacesList extends StatelessWidget {
  final List<dynamic> places;
  final List<dynamic> bookmarks;
  final bool isLoading;
  final Function(Map<String, dynamic> place) onToggleBookmark;

  const NearbyPlacesList({
    super.key,
    required this.places,
    required this.bookmarks,
    required this.isLoading,
    required this.onToggleBookmark,
  });

  Future<void> _openInGoogleMaps(Map<String, dynamic> place) async {
    final lat = place['geometry']?['location']?['lat'];
    final lng = place['geometry']?['location']?['lng'];
    
    if (lat != null && lng != null) {
      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch maps for ${place['name']}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (places.isEmpty) {
      return const Center(child: Text('No destinations found for this category.'));
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        final isBookmarked = bookmarks.any((b) => b['placeId'] == place['place_id']);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 1,
          child: ListTile(
            onTap: () => _openInGoogleMaps(place),
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
              onPressed: () => onToggleBookmark(place),
            ),
          ),
        );
      },
    );
  }
}
