import 'package:flutter/material.dart';
import '../screens/home/place_details_screen.dart';

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

  void _openPlaceDetails(BuildContext context, Map<String, dynamic> place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceDetailsScreen(place: place),
      ),
    );
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
            onTap: () => _openPlaceDetails(context, place),
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
