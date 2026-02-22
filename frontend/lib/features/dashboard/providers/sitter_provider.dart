import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/models/user_model.dart'; 
import '../../auth/providers/auth_controller.dart'; // Import user provider

final sittersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'sitter')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      try {
        // Parse the document data to a UserModel
        return UserModel.fromMap(doc.data(), doc.id);
      } catch (e) {
        // Fallback or skip invalid documents but try to keep name/email if possible
        final data = doc.data();
        return UserModel(
          uid: doc.id,
          email: data['email'] as String? ?? '',
          name: data['name'] as String? ?? 'Unknown Sitter',
          profileImage: data['profileImage'] as String?, // Try to preserve image
          role: UserRole.sitter,
          // Other fields might be issue so omit them in fallback
        );
      }
    }).cast<UserModel>().toList(); // Cast to ensure correct list type
  });
});

final nearbySittersProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final sittersAsync = ref.watch(sittersProvider);
  final authState = ref.watch(authControllerProvider);
  final user = authState.user;

  return sittersAsync.whenData((sitters) {
    if (user?.latitude == null || user?.longitude == null) {
      return sitters;
    }

    final sortedSitters = List<UserModel>.from(sitters);
    sortedSitters.sort((a, b) {
      if (a.latitude == null || a.longitude == null) return 1;
      if (b.latitude == null || b.longitude == null) return -1;

      final distA = Geolocator.distanceBetween(
          user!.latitude!, user.longitude!, a.latitude!, a.longitude!);
      final distB = Geolocator.distanceBetween(
          user.latitude!, user.longitude!, b.latitude!, b.longitude!);

      return distA.compareTo(distB);
    });

    return sortedSitters;
  });
});

