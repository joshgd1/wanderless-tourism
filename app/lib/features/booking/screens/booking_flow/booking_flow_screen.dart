import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';
import '../../../bookings/screens/bookings_screen.dart';

final selectedDateRangeProvider = StateProvider<DateTimeRange?>((_) => null);
final selectedGroupSizeProvider = StateProvider<int>((_) => 1);
final selectedDurationProvider = StateProvider<double>((_) => 2.0);

final _guideBudgetProvider = FutureProvider.family<String, String>((ref, guideId) async {
  final api = ApiClient();
  final guide = await api.getGuide(guideId);
  return guide['budget_tier'] as String? ?? 'mid';
});

// Daily rates in THB (8-hour day 기준)
final _dailyRates = {'budget': 1500.0, 'mid': 3000.0, 'premium': 6000.0};

class BookingFlowScreen extends ConsumerStatefulWidget {
  final String guideId;

  const BookingFlowScreen({super.key, required this.guideId});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _step = 0;
  bool _loading = false;
  Map<String, dynamic>? _createdBooking;

  Future<void> _proceedToPayment() async {
    setState(() => _step = 2);
  }

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
      final dateRange = ref.read(selectedDateRangeProvider)!;
      final date = dateRange.start;
      final groupSize = ref.read(selectedGroupSizeProvider);
      final duration = ref.read(selectedDurationProvider);
      final api = ApiClient();
      final result = await api.createBooking({
        'tourist_id': touristId,
        'guide_id': widget.guideId,
        'tour_date': DateFormat('yyyy-MM-dd').format(date),
        'duration_hours': duration,
        'group_size': groupSize,
      });
      _createdBooking = result;
      ref.invalidate(bookingsListProvider);
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
          : _step == 1
              ? _ConfirmStep(
                  guideId: widget.guideId,
                  loading: _loading,
                  onSubmit: _proceedToPayment,
                  onBack: () => setState(() => _step = 0),
                )
              : _PaymentStep(
                  guideId: widget.guideId,
                  loading: _loading,
                  onPay: _submitBooking,
                  onBack: () => setState(() => _step = 1),
                ),
    );
  }
}

class _DateSelectStep extends ConsumerWidget {
  final VoidCallback onNext;
  const _DateSelectStep({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(selectedDateRangeProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Your Trip Dates', style: AppText.h1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose your start and end dates',
            style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Date range display card
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
                initialDateRange: dateRange,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.brand,
                        onPrimary: Colors.white,
                        surface: AppColors.surface,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref.read(selectedDateRangeProvider.notifier).state = picked;
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.date_range, color: AppColors.brand, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateRange != null
                              ? '${DateFormat('MMM d').format(dateRange.start)} – ${DateFormat('MMM d, yyyy').format(dateRange.end)}'
                              : 'Tap to select date range',
                          style: AppText.labelBold.copyWith(
                            color: dateRange != null ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                        if (dateRange != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${dateRange.end.difference(dateRange.start).inDays + 1} day${dateRange.end.difference(dateRange.start).inDays == 0 ? '' : 's'}',
                            style: AppText.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_calendar,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Continue',
              onPressed: dateRange != null ? onNext : null,
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
    return '\$${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(selectedDateRangeProvider);
    final groupSize = ref.watch(selectedGroupSizeProvider);
    final duration = ref.watch(selectedDurationProvider);
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
                  label: 'Dates',
                  value: dateRange != null
                      ? '${DateFormat('MMM d').format(dateRange.start)} – ${DateFormat('MMM d, yyyy').format(dateRange.end)}'
                      : 'Not selected',
                ),
                const Divider(height: AppSpacing.md),
                _InfoRow(
                  label: 'Group Size',
                  value: '$groupSize ${groupSize == 1 ? 'person' : 'people'}',
                ),
                const Divider(height: AppSpacing.md),
                _DurationSelector(duration: duration),
                const Divider(height: AppSpacing.md),
                budgetAsync.when(
                  data: (budget) {
                    final dailyRate = _dailyRates[budget] ?? 3000.0;
                    // Price = daily_rate × (duration_hours / 8) × group_size
                    final price = dailyRate * (duration / 8.0) * groupSize;
                    return _InfoRow(
                      label: 'Est. Total',
                      value: _formatPrice(price),
                      valueColor: AppColors.success,
                    );
                  },
                  loading: () => const _InfoRow(label: 'Est. Total', value: 'Loading...'),
                  error: (_, __) => const _InfoRow(label: 'Est. Total', value: '—'),
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
                    label: 'Proceed to Payment',
                    icon: Icons.credit_card,
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

class _DurationSelector extends ConsumerWidget {
  final double duration;

  const _DurationSelector({required this.duration});

  static const _durations = [2.0, 4.0, 6.0, 8.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Duration', style: AppText.label),
          Row(
            children: _durations.map((d) {
              final isSelected = d == duration;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () => ref.read(selectedDurationProvider.notifier).state = d,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brand : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: isSelected ? AppColors.brand : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '${d.toInt()}h',
                      style: AppText.label.copyWith(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PaymentStep extends ConsumerWidget {
  final String guideId;
  final bool loading;
  final VoidCallback onPay;
  final VoidCallback onBack;

  const _PaymentStep({
    required this.guideId,
    required this.loading,
    required this.onPay,
    required this.onBack,
  });

  String _formatPrice(double price) {
    return '\$${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(selectedDateRangeProvider);
    final groupSize = ref.watch(selectedGroupSizeProvider);
    final duration = ref.watch(selectedDurationProvider);
    final budgetAsync = ref.watch(_guideBudgetProvider(guideId));

    final dailyRate = budgetAsync.whenOrNull(
      data: (budget) => _dailyRates[budget] ?? 3000.0,
    ) ?? 3000.0;
    final totalPrice = dailyRate * (duration / 8.0) * groupSize;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment', style: AppText.h1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your booking is held for 10 minutes.',
            style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Card input mock
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_card, size: 20, color: AppColors.brand),
                    const SizedBox(width: 8),
                    Text('Pay with Card', style: AppText.labelBold),
                    const Spacer(),
                    Row(
                      children: const [
                        _CardIcon(color: Color(0xFF1A1F71)), // Visa blue
                        SizedBox(width: 4),
                        _CardIcon(color: Color(0xFFEB001B)), // MC red
                        SizedBox(width: 4),
                        _CardIcon(color: Color(0xFFFF5F00)), // Amex orange
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _CardTextField(
                  label: 'Card number',
                  hint: '1234 5678 9012 3456',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _CardTextField(
                        label: 'Expiry',
                        hint: 'MM / YY',
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _CardTextField(
                        label: 'CVC',
                        hint: '123',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Order summary
          AppCard(
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Dates',
                  value: dateRange != null
                      ? '${DateFormat('MMM d').format(dateRange.start)} – ${DateFormat('MMM d, yyyy').format(dateRange.end)}'
                      : '—',
                ),
                const Divider(height: AppSpacing.md),
                _SummaryRow(label: 'Duration', value: '${duration.toInt()} hours'),
                const Divider(height: AppSpacing.md),
                _SummaryRow(label: 'Group Size', value: '$groupSize ${groupSize == 1 ? 'person' : 'people'}'),
                const Divider(height: AppSpacing.md),
                _SummaryRow(
                  label: 'Total',
                  value: _formatPrice(totalPrice),
                  valueColor: AppColors.brand,
                  isBold: true,
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
                    label: 'Pay \$${totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} Now',
                    icon: Icons.lock,
                    onPressed: onPay,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'Secure payment — 256-bit SSL encryption',
                  style: AppText.caption.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardIcon extends StatelessWidget {
  final Color color;
  const _CardIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _CardTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _CardTextField({
    required this.label,
    required this.hint,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(hint, style: AppText.bodySmall.copyWith(color: AppColors.textTertiary)),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isBold ? AppText.labelBold : AppText.label),
        Text(
          value,
          style: (isBold ? AppText.labelBold : AppText.label).copyWith(
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
