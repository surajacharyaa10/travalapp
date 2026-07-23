import 'package:flutter/material.dart';

import '../../../data/services/session_manager.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/bookmark_service.dart';
import '../../../data/services/preference_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  final BookmarkService _bookmarkService = BookmarkService();
  final PreferenceService _preferenceService = PreferenceService();

  bool _isLoadingProfile = true;

  bool _aiPersonalization = true;
  bool _locationAutoDetect = true;

  Map<String, dynamic>? _userData;
  int _bookmarkCount = 0;

  List<PreferenceOption> _allAvailablePreferences = [];
  Set<String> _selectedPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadProfileAndData();
  }

  Future<void> _loadProfileAndData() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      // Load available preferences
      _allAvailablePreferences = await _preferenceService
          .getAvailablePreferences();

      // Load user profile
      final profileRes = await _apiClient.get('/api/auth/profile');

      if (profileRes is Map<String, dynamic>) {
        _userData = profileRes;
        SessionManager.user = profileRes;
      }

      // Load bookmarks
      final bookmarksRes = await _bookmarkService.getBookmarks();

      _bookmarkCount = bookmarksRes.length;

      // Sync saved preferences
      final List<dynamic> currentPrefs =
          _userData?['preferences'] ??
          SessionManager.user?['preferences'] ??
          [];

      final validIds = _allAvailablePreferences.map((e) => e.id).toSet();

      _selectedPreferences = currentPrefs
          .map((e) => e.toString())
          .where((id) => validIds.contains(id))
          .toSet();
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of TripSense?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              SessionManager.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _userData ?? SessionManager.user;

    final name = user?['name'] ?? 'Traveler';
    final email = user?['email'] ?? 'traveler@example.com';

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        title: const Text(
          'Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfileAndData,
          ),
        ],
      ),

      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),

              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    color: Colors.white,

                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),

                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.blueAccent,

                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "U",

                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(email, style: TextStyle(color: Colors.grey[600])),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: Colors.grey[100],

                            borderRadius: BorderRadius.circular(16),
                          ),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,

                            children: [
                              _buildStatItem(
                                "Saved",
                                "$_bookmarkCount",
                                Icons.bookmark,
                              ),

                              _buildStatItem(
                                "Preferences",
                                "${_selectedPreferences.length}",
                                Icons.tune,
                              ),

                              _buildStatItem(
                                "AI Active",
                                "ON",
                                Icons.auto_awesome,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ONLY ONE READ ONLY PREFERENCE SECTION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),

                    child: Card(
                      elevation: 0,

                      color: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(20),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.tune,
                                  color: Colors.blueAccent,
                                ),

                                const SizedBox(width: 10),

                                const Text(
                                  "My Travel Preferences",

                                  style: TextStyle(
                                    fontSize: 18,

                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Preferences selected during signup.",

                              style: TextStyle(
                                color: Colors.grey[600],

                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _selectedPreferences.isEmpty
                                ? Container(
                                    width: double.infinity,

                                    padding: const EdgeInsets.all(16),

                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],

                                      borderRadius: BorderRadius.circular(12),
                                    ),

                                    child: const Text(
                                      "No preferences selected",

                                      textAlign: TextAlign.center,

                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,

                                    runSpacing: 10,

                                    children: _allAvailablePreferences
                                        .where(
                                          (pref) => _selectedPreferences
                                              .contains(pref.id),
                                        )
                                        .map(
                                          (pref) => Chip(
                                            avatar: Text(
                                              pref.icon,

                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),

                                            label: Text(pref.name),

                                            backgroundColor: Colors.blueAccent,

                                            labelStyle: const TextStyle(
                                              color: Colors.white,

                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // AI Settings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),

                    child: Card(
                      elevation: 0,
                      color: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(
                              Icons.auto_awesome,
                              color: Colors.blueAccent,
                            ),

                            title: const Text(
                              "AI Personalization",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),

                            subtitle: const Text(
                              "Get personalized travel recommendations",
                            ),

                            value: _aiPersonalization,

                            onChanged: (value) {
                              setState(() {
                                _aiPersonalization = value;
                              });
                            },
                          ),

                          const Divider(height: 1),

                          SwitchListTile(
                            secondary: const Icon(
                              Icons.location_on_outlined,
                              color: Colors.blueAccent,
                            ),

                            title: const Text(
                              "Auto Location Detection",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),

                            subtitle: const Text(
                              "Use location for better recommendations",
                            ),

                            value: _locationAutoDetect,

                            onChanged: (value) {
                              setState(() {
                                _locationAutoDetect = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Privacy & Support
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),

                    child: Card(
                      elevation: 0,

                      color: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.shield_outlined,
                              color: Colors.grey,
                            ),

                            title: const Text("Privacy Policy"),

                            trailing: const Icon(Icons.chevron_right, size: 20),

                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "TripSense Privacy Policy v1.0",
                                  ),
                                ),
                              );
                            },
                          ),

                          const Divider(height: 1),

                          ListTile(
                            leading: const Icon(
                              Icons.help_outline,
                              color: Colors.grey,
                            ),

                            title: const Text("Help & Support"),

                            trailing: const Icon(Icons.chevron_right, size: 20),

                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Contact support at support@tripsense.ai",
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),

                    child: SizedBox(
                      width: double.infinity,

                      height: 52,

                      child: OutlinedButton.icon(
                        onPressed: () => _logout(context),

                        icon: const Icon(Icons.logout, color: Colors.red),

                        label: const Text(
                          "Logout",

                          style: TextStyle(
                            color: Colors.red,

                            fontSize: 16,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.5),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(icon, size: 16, color: Colors.blueAccent),

            const SizedBox(width: 4),

            Text(
              value,

              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),

        const SizedBox(height: 2),

        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
