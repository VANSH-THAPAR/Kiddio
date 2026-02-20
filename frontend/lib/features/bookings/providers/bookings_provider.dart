// lib/features/bookings/providers/bookings_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/booking_model.dart';
import '../../auth/models/user_model.dart'; // Import is still useful if we expand later

// Provider to create a booking
final bookingsControllerProvider = Provider<BookingsController>((ref) {
  return BookingsController(ref);
});

class BookingsController {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BookingsController(this._ref);

  Future<void> createBooking({
    required String sitterId,
    required String sitterName,
    required DateTime startTime,
    required DateTime endTime,
    required double totalPrice,
    String? notes,
  }) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null) throw Exception("User must be logged in to book");

    final booking = BookingModel(
      id: '', 
      parentId: user.uid,
      parentName: user.name, 
      sitterId: sitterId,
      sitterName: sitterName, 
      status: BookingStatus.pending,
      startTime: startTime,
      endTime: endTime,
      totalPrice: totalPrice,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('bookings').add(booking.toMap());
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': newStatus.name,
    });
  }
}

// Provider to fetch bookings for a user (either parent or sitter)
final userBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return const Stream.empty();

  Query query = FirebaseFirestore.instance.collection('bookings');

  if (user.role == UserRole.parent) {
    query = query.where('parentId', isEqualTo: user.uid);
  } else {
    query = query.where('sitterId', isEqualTo: user.uid);
  }

  return query.snapshots().map((snapshot) {
    final docs = snapshot.docs.map((doc) {
      return BookingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
    
    // Sort in memory locally to avoid composite index requirements for now
    docs.sort((a, b) => b.startTime.compareTo(a.startTime));
    return docs;
  });
});
