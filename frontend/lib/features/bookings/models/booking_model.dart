import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';

enum BookingStatus { pending, confirmed, completed, cancelled }

class BookingModel {
  final String id;
  final String parentId;
  final String? parentName;
  final String sitterId;
  final String? sitterName;
  final BookingStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String? notes; // Added notes
  final DateTime createdAt;
  
  // Transient fields for UI (not stored in Firestore directly, but populated)
  final UserModel? sitter;
  final UserModel? parent;

  const BookingModel({
    required this.id,
    required this.parentId,
    this.parentName,
    required this.sitterId,
    this.sitterName,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    this.notes,
    required this.createdAt,
    this.sitter,
    this.parent,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      parentId: map['parentId'] ?? '',
      parentName: map['parentName'],
      sitterId: map['sitterId'] ?? '',
      sitterName: map['sitterName'],
      status: BookingStatus.values.firstWhere(
          (e) => e.toString() == 'BookingStatus.${map['status']}',
          orElse: () => BookingStatus.pending),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      // Sitter/Parent populated separately
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'parentName': parentName,
      'sitterId': sitterId,
      'sitterName': sitterName,
      'status': status.toString().split('.').last,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalPrice': totalPrice,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  BookingModel copyWith({
    UserModel? sitter,
    UserModel? parent,
    BookingStatus? status,
  }) {
    return BookingModel(
      id: id,
      parentId: parentId,
      parentName: parentName,
      sitterId: sitterId,
      sitterName: sitterName,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime,
      totalPrice: totalPrice,
      notes: notes,
      createdAt: createdAt,
      sitter: sitter ?? this.sitter,
      parent: parent ?? this.parent,
    );
  }
}
