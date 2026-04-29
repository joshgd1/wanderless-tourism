import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/api_client.dart';
import '../../../../core/onboarding_provider.dart';

final selectedDateProvider = StateProvider<DateTime?>((_) => null);
final selectedGroupSizeProvider = StateProvider<int>((_) => 1);

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
      final touristId = (await ref.read(touristIdProvider.future))!;
      final date = ref.read(selectedDateProvider)!;
      final groupSize = ref.read(selectedGroupSizeProvider);
      final api = ApiClient();
      final result = await api.createBooking({
        'tourist_id': touristId,
        'guide_id': widget.guideId,
        'tour_date': DateFormat('yyyy-MM-dd').format(date),
        'duration_hours': 4.0,
        'group_size': groupSize,
        'gross_value': 1500.0,
      });
      if (mounted) {
        final bookingId = result['id'] as int;
        context.go('/itinerary/$bookingId?guideId=${widget.guideId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Guide')),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a Date', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          CalendarDatePicker(
            initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 90)),
            onDateChanged: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedDate != null ? onNext : null,
              child: const Text('Continue'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final groupSize = ref.watch(selectedGroupSizeProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm Booking', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(label: 'Date', value: date != null ? DateFormat('MMM d, yyyy').format(date) : 'Not selected'),
                  const Divider(),
                  _InfoRow(label: 'Group Size', value: '$groupSize ${groupSize == 1 ? 'person' : 'people'}'),
                  const Divider(),
                  _InfoRow(label: 'Duration', value: '4 hours'),
                  const Divider(),
                  _InfoRow(label: 'Price', value: '฿1,500'),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              children: [
                TextButton(onPressed: onBack, child: const Text('Back')),
                const Spacer(),
                ElevatedButton(
                  onPressed: onSubmit,
                  child: const Text('Confirm Booking'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
