import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';
import '../../../../shared/models/booking.dart';

final bookingsListProvider = FutureProvider<List<Booking>>((ref) async {
  final authState = ref.watch(authProvider);
  final touristId = authState.touristId;
  if (touristId == null) return [];
  final api = ApiClient();
  final data = await api.getBookings();
  return data.map((e) => Booking.fromJson(e)).toList();
});

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsListProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: AppColors.textPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.textPrimary,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                    child: Row(
                      children: [
                        Text(
                          'My Trips',
                          style: AppText.h2.copyWith(color: Colors.white),
                        ),
                        const Spacer(),
                        _IconBtn(
                          icon: Icons.notifications_outlined,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: bookingsAsync.when(
              loading: () => const AppLoading(message: 'Loading trips...'),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load bookings',
                subtitle: e.toString(),
                action: PrimaryButton(
                  label: 'Retry',
                  onPressed: () => ref.refresh(bookingsListProvider),
                ),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return EmptyState(
                    icon: Icons.card_travel_outlined,
                    title: 'No trips planned yet',
                    subtitle: 'Find a guide and start planning!',
                    action: PrimaryButton(
                      label: 'Find a Guide',
                      onPressed: () => context.go('/discover'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.all(isWide ? AppSpacing.lg : AppSpacing.md),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _BookingCard(
                        booking: booking,
                        onTap: () => context.push(
                          '/itinerary/${booking.id}?guideId=${booking.guideId}',
                        ),
                        onCancel: _canCancel(booking.status)
                            ? () => _confirmAndUpdate(context, ref, booking)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _canCancel(String status) {
    return status.toUpperCase() == 'REQUESTED' ||
        status.toUpperCase() == 'CONFIRMED';
  }

  Future<void> _confirmAndUpdate(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel this trip?', style: AppText.h3),
        content: Text(
          booking.status.toUpperCase() == 'CONFIRMED'
              ? 'Cancelling a confirmed booking may affect your refund. The guide will be notified.'
              : 'Are you sure you want to cancel this booking request? The guide will be notified.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Keep Booking',
              style: AppText.label.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes, Cancel',
              style: AppText.label.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _cancelBooking(context, ref, booking);
  }

  Future<void> _cancelBooking(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    try {
      final api = ApiClient();
      await api.updateBookingStatus(booking.id, 'CANCELLED');
      ref.refresh(bookingsListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking cancelled'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      }
    }
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconBtn({required this.icon, required this.onPressed});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(widget.icon, color: Colors.white.withOpacity(_isHovered ? 1 : 0.7), size: 20),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _BookingCard({
    required this.booking,
    required this.onTap,
    this.onCancel,
  });

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED': return AppColors.statusConfirmed;
      case 'REQUESTED': return AppColors.statusRequested;
      case 'PAID': return AppColors.statusPaid;
      case 'IN_PROGRESS': return AppColors.statusInProgress;
      case 'COMPLETED': return AppColors.statusCompleted;
      case 'CANCELLED': return AppColors.statusCancelled;
      default: return AppColors.textTertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED': return 'Confirmed';
      case 'REQUESTED': return 'Requested';
      case 'PAID': return 'Paid';
      case 'IN_PROGRESS': return 'In Progress';
      case 'COMPLETED': return 'Completed';
      case 'CANCELLED': return 'Cancelled';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    final statusColor = _statusColor(status);
    final isInProgress = status.toUpperCase() == 'IN_PROGRESS';

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: _statusLabel(status),
                color: statusColor,
              ),
              const Spacer(),
              Text(
                'Booking #${booking.id}',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.person, color: AppColors.textTertiary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.guideName ?? 'Guide',
                      style: AppText.labelBold,
                    ),
                    Text(
                      'Guide',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(booking.tourDate, style: AppText.labelBold),
                  Text(
                    '${booking.durationHours.toStringAsFixed(1)}h',
                    style: AppText.caption,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(booking.destination, style: AppText.bodySmall),
              ),
              if (isInProgress) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppColors.info),
                      const SizedBox(width: 4),
                      Text(
                        'Live',
                        style: AppText.captionBold.copyWith(color: AppColors.info, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (isInProgress) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Track Tour',
                icon: Icons.location_on,
                onPressed: () => context.push('/track/${booking.id}'),
              ),
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: 'Cancel Trip',
                icon: Icons.close,
                color: AppColors.error,
                onPressed: onCancel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
