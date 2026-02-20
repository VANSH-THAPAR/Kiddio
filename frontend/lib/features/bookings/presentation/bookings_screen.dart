
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/bookings_provider.dart';
import '../models/booking_model.dart';
import '../../auth/providers/auth_controller.dart';
import '../../auth/models/user_model.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text("No bookings found."));
          }
          return ListView.builder(
            itemCount: bookings.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final isParent = user?.role == UserRole.parent;
              final otherPartyName = isParent ? (booking.sitterName ?? 'Sitter') : (booking.parentName ?? 'Parent');
              final statusColor = _getStatusColor(booking.status);
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            otherPartyName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              booking.status.name.toUpperCase(),
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(DateFormat('MMM dd, yyyy').format(booking.startTime)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text("${DateFormat('hh:mm a').format(booking.startTime)} - ${DateFormat('hh:mm a').format(booking.endTime)}"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                         const SizedBox(height: 8),
                         Text("Note: ${booking.notes}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "\$${booking.totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                        ),
                      ),
                      if (!isParent && booking.status == BookingStatus.pending) ...[
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                ref.read(bookingsControllerProvider).updateBookingStatus(booking.id, BookingStatus.cancelled);
                              },
                              child: const Text("Refuse", style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(bookingsControllerProvider).updateBookingStatus(booking.id, BookingStatus.confirmed);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text("Accept"),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
  
  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return Colors.orange;
      case BookingStatus.confirmed: return Colors.green;
      case BookingStatus.cancelled: return Colors.red;
      case BookingStatus.completed: return Colors.blue;
    }
    return Colors.grey;
  }
}
