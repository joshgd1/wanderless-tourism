import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';

final selectedDateProvider = StateProvider<DateTime?>((_) => null);
final selectedGroupSizeProvider = StateProvider<int>((_) => 1);

final _guideBudgetProvider = FutureProvider.family<String, String>((ref, guideId) async {
  final api = ApiClient();
  final guide = await api.getGuide(guideId);
  return guide['budget_tier'] as String? ?? 'mid';
});

final _tierPrices = {'budget': 1000.0, 'mid': 2000.0, 'premium': 4000.0};

class BookingFlowScreen extends ConsumerStatefulWidget {
  final String guideId;

  const BookingFlowScreen({super.key, required this.guideId});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _step = 0;
  bool _loading = false;

  Future<void> _submitBooking() async {
    setState(() => _loading = true);
    try {
      final authState = ref.read(authProvider);
      final touristId = authState.touristId;
      if (touristId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please sign in to book a guide'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          );
        }
        return;
      }
      final date = ref.read(selectedDateProvider)!;
      final groupSize = ref.read(selectedGroupSizeProvider);
      final api = ApiClient();
      final result = await api.createBooking({
        'tourist_id': touristId,
        'guide_id': widget.guideId,
        'tour_date': DateFormat('yyyy-MM-dd').format(date),
        'duration_hours': 4.0,
        'group_size': groupSize,
      });
      if (mounted) {
        final bookingId = result['id'] as int;
        context.go('/itinerary/$bookingId?guideId=${widget.guideId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: Colors.white,
        title: Text('Book Guide', style: AppText.h3.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _step == 0
          ? _DateSelectStep(onNext: () => setState(() => _step = 1))
          : _ConfirmStep(
              guideId: widget.guideId,
              loading: _loading,
              onSubmit: _submitBooking,
              onBack: () => setState(() => _step = 0),
            ),
    );
  }
}

class _DateSelectStep extends ConsumerWidget {
  final VoidCallback onNext;
  const _DateSelectStep({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a Date', style: AppText.h1),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: CalendarDatePicker(
              initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              onDateChanged: (date) {
                ref.read(selectedDateProvider.notifier).state = date;
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Continue',
              onPressed: selectedDate != null ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmStep extends ConsumerWidget {
  final String guideId;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _ConfirmStep({
    required this.guideId,
    required this.loading,
    required this.onSubmit,
    required this.onBack,
  });

  String _formatPrice(double price) {
    return '฿${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final groupSize = ref.watch(selectedGroupSizeProvider);
    final budgetAsync = ref.watch(_guideBudgetProvider(guideId));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm Booking', style: AppText.h1),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                  label: 'Date',
                  value: date != null ? DateFormat('MMM d, yyyy').format(date) : 'Not selected',
                ),
                const Divider(height: AppSpacing.md),
                _InfoRow(
                  label: 'Group Size',
                  value: '$groupSize ${groupSize == 1 ? 'person' : 'people'}',
                ),
                const Divider(height: AppSpacing.md),
                const _InfoRow(label: 'Duration', value: '4 hours'),
                const Divider(height: AppSpacing.md),
                budgetAsync.when(
                  data: (budget) {
                    final price = _tierPrices[budget] ?? 2000.0;
                    return _InfoRow(
                      label: 'Est. Price',
                      value: _formatPrice(price),
                      valueColor: AppColors.success,
                    );
                  },
                  loading: () => const _InfoRow(label: 'Est. Price', value: 'Loading...'),
                  error: (_, __) => const _InfoRow(label: 'Est. Price', value: '—'),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (loading)
            const AppLoading()
          else
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Back',
                    onPressed: onBack,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'Confirm Booking',
                    onPressed: onSubmit,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.label),
          Text(
            value,
            style: AppText.labelBold.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
