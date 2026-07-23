import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/session_manager.dart';
import '../../../data/services/api_client.dart';
import '../main_navigation_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isLoadingPreferences = true;
  String? _errorMessage;

  // Master list of preferences fetched live from the backend — no hardcoding.
  List<Map<String, String>> _allAvailablePreferences = [];
  // User's actual selected preference IDs (from what they tapped).
  final Set<String> _selectedPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoadingPreferences = true;
    });

    try {
      final prefsRes = await _apiClient.get('/api/auth/preferences');
      if (prefsRes is List) {
        _allAvailablePreferences = prefsRes.map<Map<String, String>>((item) {
          return {
            'id': item['id']?.toString() ?? '',
            'name': item['name']?.toString() ?? '',
            'icon': item['icon']?.toString() ?? '✨',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      // If the fetch fails, we simply show none rather than
      // silently substituting a fake/hardcoded list.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPreferences = false;
        });
      }
    }
  }

  void _togglePreference(String prefId) {
    setState(() {
      if (_selectedPreferences.contains(prefId)) {
        _selectedPreferences.remove(prefId);
      } else {
        _selectedPreferences.add(prefId);
      }
    });
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Send exactly what the user selected — real preference IDs
      // from the backend list, not hardcoded strings.
      final response = await _authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        preferences: _selectedPreferences.toList(),
      );

      if (response['token'] != null) {
        SessionManager.login(response['token'], response['user']);
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigationShell(),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid signup response';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sign Up'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore destinations customized for you',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Choose Travel Preferences',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Loaded live from GET /api/auth/preferences — no hardcoded list.
                if (_isLoadingPreferences)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_allAvailablePreferences.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Could not load preferences. Pull to refresh or continue without selecting any.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allAvailablePreferences.map((pref) {
                      final isSelected = _selectedPreferences.contains(
                        pref['id'],
                      );
                      return FilterChip(
                        avatar: Text(
                          pref['icon']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                        label: Text(pref['name']!),
                        selected: isSelected,
                        selectedColor: Colors.blueAccent.withOpacity(0.2),
                        checkmarkColor: Colors.blueAccent,
                        onSelected: (_) => _togglePreference(pref['id']!),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign Up', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
