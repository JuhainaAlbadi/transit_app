import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  final List<Map<String, dynamic>> _stations = [
    {'name': 'Ruwi Bus Station',   'lat': 23.6139, 'lng': 58.5922, 'country': 'Oman'},
    {'name': 'Seeb Bus Station',   'lat': 23.6760, 'lng': 58.1890, 'country': 'Oman'},
    {'name': 'Al Khuwair',         'lat': 23.6005, 'lng': 58.5200, 'country': 'Oman'},
    {'name': 'Sohar Bus Station',  'lat': 24.3473, 'lng': 56.7453, 'country': 'Oman'},
    {'name': 'Salalah Bus Station','lat': 17.0151, 'lng': 54.0924, 'country': 'Oman'},
    {'name': 'Brussels-Midi',      'lat': 50.8355, 'lng': 4.3360,  'country': 'Belgium'},
    {'name': 'Brussels-Central',   'lat': 50.8455, 'lng': 4.3570,  'country': 'Belgium'},
    {'name': 'Antwerp-Central',    'lat': 51.2172, 'lng': 4.4211,  'country': 'Belgium'},
    {'name': 'Ghent-Sint-Pieters', 'lat': 51.0359, 'lng': 3.7108,  'country': 'Belgium'},
    {'name': 'Bruges',             'lat': 51.1973, 'lng': 3.2165,  'country': 'Belgium'},
  ];

  String _filter = 'All';
  Map<String, dynamic>? _selected;
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  bool _loadingRoute = false;
  String? _routeError;
  double? _routeDurationSeconds;
  double? _routeDistanceMeters;

  List<Map<String, dynamic>> get _filtered => _filter == 'All'
      ? _stations
      : _stations.where((s) => s['country'] == _filter).toList();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {}
  }

  Future<void> _fetchRoute(Map<String, dynamic> station) async {
    if (_userLocation == null) {
      setState(() => _routeError = 'Could not get your location.');
      return;
    }

    setState(() {
      _loadingRoute = true;
      _routePoints = [];
      _routeError = null;
    });

    try {
      final url = 'http://router.project-osrm.org/route/v1/driving/'
          '${_userLocation!.longitude},${_userLocation!.latitude};'
          "${station['lng']},${station['lat']}"
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok') {
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          setState(() {
            _routePoints = coords
                .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                .toList();
            _routeDurationSeconds = (route['duration'] as num).toDouble();
            _routeDistanceMeters = (route['distance'] as num).toDouble();
          });
        } else {
          setState(() => _routeError = 'No route found between these locations.');
        }
      } else {
        setState(() => _routeError = 'Routing service unavailable.');
      }
    } catch (e) {
      setState(() => _routeError = 'Failed to fetch route.');
    } finally {
      setState(() => _loadingRoute = false);
    }
  }

  String _formatDuration(double seconds) {
    final total = seconds.round();
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m} min';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit Map'),
        actions: [
          if (_routePoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear route',
              onPressed: () => setState(() {
                _routePoints = [];
                _selected = null;
                _routeError = null;
                _routeDurationSeconds = null;
                _routeDistanceMeters = null;
              }),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: DropdownButton<String>(
              value: _filter,
              dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              items: ['All', 'Oman', 'Belgium']
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v, style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _filter = v!;
                _selected = null;
                _routePoints = [];
              }),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(23.6, 58.6),
              initialZoom: 5.5,
              onTap: (_, __) => setState(() {
                _selected = null;
                _routePoints = [];
                _routeError = null;
                _routeDurationSeconds = null;
                _routeDistanceMeters = null;
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.transit_app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4,
                      color: Colors.blue,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // User location marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.my_location, color: Colors.white, size: 18),
                      ),
                    ),
                  // Station markers
                  ..._filtered.map((station) {
                    final isSelected = _selected == station;
                    return Marker(
                      point: LatLng(station['lat'], station['lng']),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selected = station);
                          _mapController.move(
                              LatLng(station['lat'], station['lng']), 12);
                          _fetchRoute(station);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.orange
                                : station['country'] == 'Oman'
                                    ? Colors.red
                                    : Colors.blue[700],
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            station['country'] == 'Oman'
                                ? Icons.directions_bus
                                : Icons.train,
                            color: Colors.white,
                            size: isSelected ? 22 : 18,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Loading indicator
          if (_loadingRoute)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Finding route...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Error message
          if (_routeError != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_routeError!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                ),
              ),
            ),

          // Station info card
          if (_selected != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _selected!['country'] == 'Oman'
                            ? Icons.directions_bus
                            : Icons.train,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selected!['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(_selected!['country'],
                                style: const TextStyle(color: Colors.grey)),
                            if (_routeDurationSeconds != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(_formatDuration(_routeDurationSeconds!),
                                      style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.straighten, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(_formatDistance(_routeDistanceMeters!),
                                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _selected = null;
                          _routePoints = [];
                          _routeDurationSeconds = null;
                          _routeDistanceMeters = null;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            backgroundColor: Theme.of(context).colorScheme.primary,
            onPressed: () => _mapController.move(
                _mapController.camera.center, _mapController.camera.zoom + 1),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            backgroundColor: Theme.of(context).colorScheme.primary,
            onPressed: () => _mapController.move(
                _mapController.camera.center, _mapController.camera.zoom - 1),
            child: const Icon(Icons.remove, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
