import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import '../../../data/services/chat_api_service.dart';
import '../../../data/services/bookmark_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<dynamic>? places;

  ChatMessage({required this.text, required this.isUser, this.places});
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatApiService _chatService = ChatApiService();
  final BookmarkService _bookmarkService = BookmarkService();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hi there! I'm TripSense AI. Where would you like to explore today?",
      isUser: false,
    ),
  ];
  bool _isLoading = false;
  List<dynamic> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
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

  Future<void> _toggleBookmark(Map<String, dynamic> place) async {
    final placeId = place['place_id'] ?? place['name'] ?? 'place_id';
    final isBookmarked = _bookmarks.any(
      (b) => b['placeId'] == placeId || b['name'] == place['name'],
    );

    try {
      if (isBookmarked) {
        final bookmark = _bookmarks.firstWhere(
          (b) => b['placeId'] == placeId || b['name'] == place['name'],
        );
        await _bookmarkService.removeBookmark(bookmark['_id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from Saved Places')),
        );
      } else {
        await _bookmarkService.addBookmark(
          placeId: placeId.toString(),
          name: place['name'] ?? 'Unknown Place',
          address: place['address'] ?? 'Unknown Address',
          category: 'AI Recommendation',
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

  Future<Map<String, dynamic>> _getCurrentLocationContext() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return {};

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return {};
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        return {
          'lat': position.latitude,
          'lng': position.longitude,
          'city': pm.locality ?? pm.subAdministrativeArea,
          'country': pm.country,
        };
      }
    } catch (e) {
      debugPrint('Location error in chat: $e');
    }
    return {};
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final locationContext = await _getCurrentLocationContext();
    final response = await _chatService.sendChatMessage(text, locationContext);

    setState(() {
      _messages.add(
        ChatMessage(
          text: response['text_reply'] ?? 'Here are some suggestions:',
          isUser: false,
          places: response['places'] as List<dynamic>?,
        ),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openMap(double lat, double lng, String name) async {
    final Uri googleMapsUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final Uri appleMapsUri = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
    final Uri webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

    try {
      if (Platform.isAndroid && await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else if (Platform.isIOS && await canLaunchUrl(appleMapsUri)) {
        await launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map: $e')),
        );
      }
    }
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: message.isUser ? Colors.blueAccent : Colors.grey[200],
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: message.isUser ? const Radius.circular(0) : const Radius.circular(16),
                bottomLeft: !message.isUser ? const Radius.circular(0) : const Radius.circular(16),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
          if (message.places != null && message.places!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: message.places!.map((place) {
                  final placeMap = Map<String, dynamic>.from(place);
                  final placeId = placeMap['place_id'] ?? placeMap['name'] ?? '';
                  final isBookmarked = _bookmarks.any(
                    (b) => b['placeId'] == placeId || b['name'] == placeMap['name'],
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      onTap: () {
                        final lat = placeMap['lat'] is num ? (placeMap['lat'] as num).toDouble() : null;
                        final lng = placeMap['lng'] is num ? (placeMap['lng'] as num).toDouble() : null;
                        if (lat != null && lng != null) {
                          _openMap(lat, lng, placeMap['name'] ?? '');
                        }
                      },
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.place, color: Colors.white),
                      ),
                      title: Text(
                        placeMap['name'] ?? 'Unknown Place',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(placeMap['address'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? Colors.blueAccent : Colors.grey,
                            ),
                            onPressed: () {
                              _toggleBookmark(placeMap);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.directions, color: Colors.green),
                            onPressed: () {
                              final lat = placeMap['lat'] is num ? (placeMap['lat'] as num).toDouble() : null;
                              final lng = placeMap['lng'] is num ? (placeMap['lng'] as num).toDouble() : null;
                              if (lat != null && lng != null) {
                                _openMap(lat, lng, placeMap['name'] ?? '');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TripSense AI'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                )
              ]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about best hotels, places...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
