import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/services/api_client.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiClient _apiClient = ApiClient();
  final MapController _mapController = MapController();
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  LatLng _currentLocation = const LatLng(28.2096, 83.9856); // Default Pokhara
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    try {
      // Fetch User Location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(const Duration(seconds: 3));
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 5));
          
          _currentLocation = LatLng(position.latitude, position.longitude);
        }
      }

      // Add user marker
      _markers.add(
        Marker(
          point: _currentLocation,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.my_location,
            color: Colors.blueAccent,
            size: 32,
          ),
        ),
      );

      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      debugPrint('Map Init Error: $e');
      setState(() {
        _errorMessage = 'Failed to load map: $e';
        _isLoading = false;
      });
    }
  }

  void _centerOnUser() {
    _mapController.move(_currentLocation, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation,
          initialZoom: 14.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: '${ApiClient.baseUrl}/api/map/tile/{z}/{x}/{y}',
            userAgentPackageName: 'com.example.travelapp',
          ),
          MarkerLayer(
            markers: _markers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUser,
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.blueAccent),
      ),
    );
  }
}
