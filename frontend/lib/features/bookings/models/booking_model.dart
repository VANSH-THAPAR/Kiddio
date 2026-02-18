import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, completed, cancelled }

class BookingModel {
  final String id;
  final String parentId;
  final String sitterId;
  final String sitterName; // Denormalized for easy display
  final String parentName; // Denormalized for easy display
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final BookingStatus status;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.parentId,
    required this.sitterId,
    required this.sitterName,
    required this.parentName,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  // Helper to get duration in hours
  double get durationInHours {
    return endTime.difference(startTime).inMinutes / 60.0;
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      parentId: map['parentId'] ?? '',
      sitterId: map['sitterId'] ?? '',
      sitterName: map['sitterName'] ?? 'Unknown Sitter',
      parentName: map['parentName'] ?? 'Unknown Parent',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      totalPrice: map['totalPrice']?.toDouble() ?? 0.0,
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'sitterId': sitterId,
      'sitterName': sitterName,
      'parentName': parentName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
