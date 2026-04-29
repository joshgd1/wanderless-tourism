import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/booking.dart';

final itineraryProvider = FutureProvider.family<Itinerary, int>((ref, bookingId) async {
  final api = ApiClient();
  final data = await api.getItinerary(bookingId);
  return Itinerary.fromJson(data);
});

class ItineraryScreen extends ConsumerWidget {
  final int bookingId;
  final String guideId;

  const ItineraryScreen({super.key, required this.bookingId, required this.guideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(itineraryProvider(bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Your Itinerary')),
      body: itineraryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (itinerary) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Booking #$bookingId', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Chip(
                            label: Text(itinerary.status.toUpperCase()),
                            backgroundColor: Colors.green[50],
                            labelStyle: TextStyle(color: Colors.green[700], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Planned Stops', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...itinerary.stops.map((stop) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text('${stop.order}'),
                    ),
                    title: Text(stop.name),
                    subtitle: Text('${stop.durationHours} hours'),
                  ),
                );
              }),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              context.go('/rate/$bookingId?guideId=${widget.guideId}');
            },
            child: const Text('Rate Experience'),
          ),
        ),
      ),
    );
  }
}
