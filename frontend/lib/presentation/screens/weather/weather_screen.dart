import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../data/services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  dynamic _weatherData;
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _fadeController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // Start roughly in the middle so 'Today' is visible (7 past days * 116 width)
    _scrollController = ScrollController(initialScrollOffset: 7 * 116.0);
    _fetchWeather();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      double lat = 28.2096;
      double lng = 83.9856;
      String? city;

      // Try to get actual location, but don't fail the whole fetch if it errors
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(const Duration(seconds: 3));
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
            ).timeout(const Duration(seconds: 5));
            lat = position.latitude;
            lng = position.longitude;

            List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng).timeout(const Duration(seconds: 3));
            if (placemarks.isNotEmpty) {
              final pm = placemarks.first;
              city = pm.locality ?? pm.subAdministrativeArea;
            }
          }
        }
      } catch (locErr) {
        debugPrint('Could not fetch location: $locErr');
        // Fallback to default coordinates (Pokhara)
      }

      final data = await _weatherService.getCurrentWeather(lat, lng, city: city);
      setState(() {
        _weatherData = data;
      });
      _fadeController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load weather: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final today = DateTime.now();
      if (date.year == today.year && date.month == today.month && date.day == today.day) {
        return 'Today';
      }
      return '${_getDayName(date)} ${date.day}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildDailyForecast(List<dynamic> dailyData) {
    if (dailyData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            '14-Day Forecast',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: dailyData.length,
            itemBuilder: (context, index) {
              final day = dailyData[index];
              final dateStr = day['date'] ?? '';
              final tempMax = (day['temp_max'] as num?)?.toDouble() ?? 0.0;
              final tempMin = (day['temp_min'] as num?)?.toDouble() ?? 0.0;
              final description = day['description'] ?? '';

              final isToday = _formatDate(dateStr) == 'Today';

              return Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: isToday ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isToday ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.2),
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDate(dateStr),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 28),
                    const SizedBox(height: 12),
                    Text(
                      '${tempMax.toStringAsFixed(0)}° / ${tempMin.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cityName = _weatherData?['name'] ?? 'Loading...';
    final double? temp = _weatherData?['main']?['temp']?.toDouble();
    final description = _weatherData?['weather']?[0]?['description'] ?? '';
    
    final humidityRaw = _weatherData?['main']?['humidity'];
    final double? humidityVal = double.tryParse(humidityRaw.toString());
    final humidityStr = humidityVal != null ? humidityVal.toStringAsFixed(0) : '0';
    
    final double? windSpeedRaw = _weatherData?['wind']?['speed']?.toDouble();
    final windStr = windSpeedRaw != null ? windSpeedRaw.toStringAsFixed(1) : '0';

    final List<dynamic> dailyData = _weatherData?['daily'] ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Weather Guide', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchWeather,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF50E3C2),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage, 
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : SafeArea(
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeController,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.wb_cloudy_rounded,
                                size: 120,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                cityName,
                                style: const TextStyle(
                                  fontSize: 32, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                                  ]
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                temp != null ? '${temp.toStringAsFixed(1)}°' : '--°',
                                style: const TextStyle(
                                  fontSize: 84, 
                                  fontWeight: FontWeight.w200,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                description.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18, 
                                  color: Colors.white70, 
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 60),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      padding: const EdgeInsets.all(24.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildWeatherStat(Icons.water_drop_outlined, 'HUMIDITY', '$humidityStr%'),
                                          Container(
                                            height: 50,
                                            width: 1,
                                            color: Colors.white.withOpacity(0.3),
                                          ),
                                          _buildWeatherStat(Icons.air_outlined, 'WIND', '$windStr m/s'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              _buildDailyForecast(dailyData),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            label, 
            style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Text(
            value, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
