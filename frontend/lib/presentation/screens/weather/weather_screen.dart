import 'package:flutter/material.dart';
import '../../../data/services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  dynamic _weatherData;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Default to Pokhara coordinates
      final data = await _weatherService.getCurrentWeather(28.2096, 83.9856);
      setState(() {
        _weatherData = data;
      });
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

  @override
  Widget build(BuildContext context) {
    final cityName = _weatherData?['name'] ?? 'Loading...';
    final double? temp = _weatherData?['main']?['temp']?.toDouble();
    final description = _weatherData?['weather']?[0]?['description'] ?? '';
    final humidity = _weatherData?['main']?['humidity'] ?? 0;
    final double? windSpeed = _weatherData?['wind']?['speed']?.toDouble();

    return Scaffold(
      backgroundColor: Colors.blueAccent[50],
      appBar: AppBar(
        title: const Text('Weather Guide', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWeather,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_queue,
                          size: 100,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          cityName,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          temp != null ? '${temp.toStringAsFixed(1)}°C' : '--°C',
                          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w300),
                        ),
                        Text(
                          description.toUpperCase(),
                          style: const TextStyle(fontSize: 16, color: Colors.black54, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildWeatherStat(Icons.opacity, 'Humidity', '$humidity%'),
                                  _buildWeatherStat(Icons.air, 'Wind', '${windSpeed ?? 0} m/s'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 28),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
