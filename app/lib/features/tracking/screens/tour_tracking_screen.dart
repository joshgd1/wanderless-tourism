import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../core/guide_auth_provider.dart';

/// Real-time tour tracking screen — shows guide and tourist as circle icons on a map.
/// Apple Maps-style: blue circle for guide, green circle for tourist.
class TourTrackingScreen extends ConsumerStatefulWidget {
  final int bookingId;

  const TourTrackingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<TourTrackingScreen> createState() => _TourTrackingScreenState();
}

class _TourTrackingScreenState extends ConsumerState<TourTrackingScreen> {
  Timer? _refreshTimer;
  Map<String, dynamic>? _locationData;
  bool _loading = true;
  String? _error;
  bool _isGuide = false;

  @override
  void initState() {
    super.initState();
    _isGuide = ref.read(guideAuthProvider).isAuthenticated;
    _fetchLocation();
    // Refresh every 5 seconds for live tracking
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchLocation());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      final api = ApiClient();
      final data = await api.getLocation(widget.bookingId);
      if (mounted) {
        setState(() {
          _locationData = data;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load location';
          _loading = false;
        });
      }
    }
  }

  LatLng? get _guideLocation {
    final lat = _locationData?['guide_lat'];
    final lng = _locationData?['guide_lng'];
    if (lat == null || lng == null) return null;
    return LatLng(lat as double, lng as double);
  }

  LatLng? get _touristLocation {
    final lat = _locationData?['tourist_lat'];
    final lng = _locationData?['tourist_lng'];
    if (lat == null || lng == null) return null;
    return LatLng(lat as double, lng as double);
  }

  LatLng get _center {
    final guide = _guideLocation;
    final tourist = _touristLocation;
    if (guide != null && tourist != null) {
      return LatLng(
        (guide.latitude + tourist.latitude) / 2,
        (guide.longitude + tourist.longitude) / 2,
      );
    }
    return guide ?? tourist ?? const LatLng(18.7883, 98.9853); // Default: Chiang Mai
  }

  double get _zoom {
    final guide = _guideLocation;
    final tourist = _touristLocation;
    if (guide == null || tourist == null) return 15.0;
    final dist = _Distance().distance(
      LatLng(guide.latitude, guide.longitude),
      LatLng(tourist.latitude, tourist.longitude),
    );
    // Zoom to fit both markers with padding
    if (dist < 500) return 16;
    if (dist < 2000) return 14;
    if (dist < 10000) return 12;
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2E1A),
        foregroundColor: Colors.white,
        title: const Text('Live Tour Tracking'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _fetchLocation();
            },
          ),
        ],
      ),
      body: _loading && _locationData == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF25D366)))
          : _error != null && _locationData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _loading = true);
                          _fetchLocation();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Map
                    Expanded(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom: _zoom,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.wanderless.app',
                          ),
                          MarkerLayer(markers: [
                            // Guide marker — blue circle
                            if (_guideLocation != null)
                              Marker(
                                point: _guideLocation!,
                                width: 48,
                                height: 48,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3).withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            // Tourist marker — green circle
                            if (_touristLocation != null)
                              Marker(
                                point: _touristLocation!,
                                width: 48,
                                height: 48,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366).withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ]),
                        ],
                      ),
                    ),
                    // Legend panel
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _legendDot(const Color(0xFF2196F3), 'Guide'),
                              const SizedBox(width: 24),
                              _legendDot(const Color(0xFF25D366), 'Tourist'),
                              const Spacer(),
                              if (_locationData?['updated_at'] != null)
                                Text(
                                  'Updated ${_formatTime(_locationData!['updated_at'])}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _participantCard(
                                  icon: Icons.person,
                                  color: const Color(0xFF2196F3),
                                  label: 'Guide',
                                  lat: _locationData?['guide_lat'],
                                  lng: _locationData?['guide_lng'],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _participantCard(
                                  icon: Icons.person,
                                  color: const Color(0xFF25D366),
                                  label: 'Tourist',
                                  lat: _locationData?['tourist_lat'],
                                  lng: _locationData?['tourist_lng'],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _participantCard({
    required IconData icon,
    required Color color,
    required String label,
    required dynamic lat,
    required dynamic lng,
  }) {
    final hasLocation = lat != null && lng != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (hasLocation)
            Text(
              '${(lat as double).toStringAsFixed(5)}, ${(lng as double).toStringAsFixed(5)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            )
          else
            Text(
              'Location not shared',
              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (_) {
      return '';
    }
  }
}

// Distance utility using Haversine
class _Distance {
  static const double _earthRadius = 6371000; // meters

  double distance(LatLng p1, LatLng p2) {
    final lat1Rad = p1.latitude * 3.141592653589793 / 180;
    final lat2Rad = p2.latitude * 3.141592653589793 / 180;
    final deltaLat = (p2.latitude - p1.latitude) * 3.141592653589793 / 180;
    final deltaLng = (p2.longitude - p1.longitude) * 3.141592653589793 / 180;

    final a = _sin(deltaLat / 2) * _sin(deltaLat / 2) +
        _cos(lat1Rad) * _cos(lat2Rad) * _sin(deltaLng / 2) * _sin(deltaLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return _earthRadius * c;
  }

  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24 - (x * x * x * x * x * x) / 720;
  double _sqrt(double x) => x > 0 ? _newtonSqrt(x, x / 2, 10) : 0;
  double _newtonSqrt(double x, double guess, int n) {
    for (int i = 0; i < n; i++) {
      final next = (guess + x / guess) / 2;
      if ((next - guess).abs() < 1e-10) break;
      guess = next;
    }
    return guess;
  }
  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }
  double _atan(double x) {
    double result = 0;
    double term = x;
    for (int n = 0; n < 20; n++) {
      result += term / (2 * n + 1) * (n % 2 == 0 ? 1 : -1);
      term *= x * x;
    }
    return result;
  }
}
