import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../shared/models/booking.dart';
import '../../../../design_system.dart';

final itineraryProvider = FutureProvider.family<Itinerary, int>((ref, bookingId) async {
  final api = ApiClient();
  final data = await api.getItinerary(bookingId);
  return Itinerary.fromJson(data);
});

class ItineraryScreen extends ConsumerWidget {
  final int bookingId;
  final String guideId;

  const ItineraryScreen({
    super.key,
    required this.bookingId,
    required this.guideId,
  });

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return AppColors.success;
      case 'PENDING':
      case 'PROPOSED':
        return AppColors.warning;
      case 'IN_PROGRESS':
        return AppColors.info;
      case 'COMPLETED':
        return AppColors.success;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(itineraryProvider(bookingId));

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
                              'My Trip',
                              style: AppText.h3.copyWith(color: Colors.white),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
                              onPressed: () {},
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
          SliverToBoxAdapter(
            child: itineraryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: AppLoading(message: 'Loading itinerary...'),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Failed to load',
                  subtitle: e.toString(),
                ),
              ),
              data: (itinerary) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                StatusBadge(
                                  label: itinerary.status.toUpperCase(),
                                  color: _statusColor(itinerary.status),
                                ),
                                const Spacer(),
                                Text('Booking #$bookingId', style: AppText.caption),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.brand.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.tour, color: AppColors.brand, size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Planned by the Guide', style: AppText.caption),
                                      const SizedBox(height: 2),
                                      Text('Guide $guideId', style: AppText.h3),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Icon(Icons.route_outlined, size: 18, color: AppColors.brand),
                          const SizedBox(width: 6),
                          Text('Itinerary', style: AppText.h3),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...itinerary.stops.asMap().entries.map((entry) {
                        final stop = entry.value;
                        final index = entry.key;
                        final isLast = index == itinerary.stops.length - 1;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.brand,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${stop.order}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 60,
                                    color: AppColors.brand.withOpacity(0.3),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: AppCard(
                                margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(stop.name, style: AppText.labelBold),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.schedule, size: 14, color: AppColors.textTertiary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${stop.durationHours.toStringAsFixed(1)} hours',
                                          style: AppText.caption,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: itineraryAsync.when(
            loading: () => const SizedBox(height: 52),
            error: (_, __) => const SizedBox(height: 52),
            data: (itinerary) {
              final isInProgress = itinerary.status.toUpperCase() == 'IN_PROGRESS';
              return Row(
                children: [
                  if (isInProgress) ...[
                    Expanded(
                      child: PrimaryButton(
                        label: 'Track Tour',
                        icon: Icons.location_on,
                        onPressed: () => context.go('/track/$bookingId'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label: 'Rate Experience',
                      icon: Icons.star,
                      onPressed: () => context.go('/rate/$bookingId?guideId=$guideId'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
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
