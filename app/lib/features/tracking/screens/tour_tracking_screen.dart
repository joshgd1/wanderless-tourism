import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../core/guide_auth_provider.dart';
import '../../../../design_system.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchLocation();
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
    return guide ?? tourist ?? const LatLng(18.7883, 98.9853);
  }

  double get _zoom {
    final guide = _guideLocation;
    final tourist = _touristLocation;
    if (guide == null || tourist == null) return 15.0;
    const distance = Distance();
    final dist = distance.as(LengthUnit.Meter, guide, tourist);
    if (dist < 500) return 16;
    if (dist < 2000) return 14;
    if (dist < 10000) return 12;
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: AppColors.textPrimary,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.textPrimary,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _DarkGridPainter()),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                        child: Row(
                          children: [
                            _BackBtn(onTap: () => context.pop()),
                            const SizedBox(width: 12),
                            Text(
                              'Live Tour Tracking',
                              style: AppText.h3.copyWith(color: Colors.white),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white70),
                              onPressed: () {
                                setState(() => _loading = true);
                                _fetchLocation();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: _loading && _locationData == null
                ? const AppLoading(message: 'Loading location...')
                : _error != null && _locationData == null
                    ? EmptyState(
                        icon: Icons.location_off,
                        title: 'Unable to load location',
                        subtitle: _error,
                        action: PrimaryButton(
                          label: 'Retry',
                          onPressed: () {
                            setState(() => _loading = true);
                            _fetchLocation();
                          },
                        ),
                      )
                    : Column(
                        children: [
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
                                  if (_guideLocation != null)
                                    Marker(
                                      point: _guideLocation!,
                                      width: 48,
                                      height: 48,
                                      child: _LocationMarker(
                                        color: AppColors.info,
                                        icon: Icons.person,
                                      ),
                                    ),
                                  if (_touristLocation != null)
                                    Marker(
                                      point: _touristLocation!,
                                      width: 48,
                                      height: 48,
                                      child: _LocationMarker(
                                        color: AppColors.success,
                                        icon: Icons.person,
                                      ),
                                    ),
                                ]),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border(top: BorderSide(color: AppColors.border)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _LegendDot(color: AppColors.info, label: 'Guide'),
                                    const SizedBox(width: 24),
                                    _LegendDot(color: AppColors.success, label: 'Tourist'),
                                    const Spacer(),
                                    if (_locationData?['updated_at'] != null)
                                      Text(
                                        'Updated ${_formatTime(_locationData!['updated_at'])}',
                                        style: AppText.caption,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ParticipantCard(
                                        icon: Icons.person,
                                        color: AppColors.info,
                                        label: 'Guide',
                                        lat: _locationData?['guide_lat'],
                                        lng: _locationData?['guide_lng'],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ParticipantCard(
                                        icon: Icons.person,
                                        color: AppColors.success,
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

class _LocationMarker extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _LocationMarker({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
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
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
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
        Text(label, style: AppText.label),
      ],
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final dynamic lat;
  final dynamic lng;

  const _ParticipantCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = lat != null && lng != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
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
                style: AppText.labelBold.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (hasLocation)
            Text(
              '${(lat as double).toStringAsFixed(5)}, ${(lng as double).toStringAsFixed(5)}',
              style: AppText.caption,
            )
          else
            Text(
              'Location not shared',
              style: AppText.caption.copyWith(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}

class _BackBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(Icons.arrow_back, color: Colors.white.withOpacity(_isHovered ? 1 : 0.7), size: 20),
        ),
      ),
    );
  }
}

class _DarkGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
