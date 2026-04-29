import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/booking.dart';

final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  // In a real app we'd have a list endpoint; for now return empty
  return [];
});

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No bookings yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/discover'),
                    child: const Text('Find a Guide'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text('Booking #${booking.id}'),
                  subtitle: Text('${booking.tourDate} • ${booking.status}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/itinerary/${booking.id}?guideId=${booking.guideId}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
