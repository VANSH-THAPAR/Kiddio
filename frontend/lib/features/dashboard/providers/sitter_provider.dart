import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart'; // Make sure this path is correct relative to your file structure

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
        // Fallback or skip invalid documents
        return UserModel(
          uid: doc.id,
          email: '',
          name: 'Unknown Sitter',
          profileImage: '', // Required parameter
          role: UserRole.sitter,
        );
      }
    }).cast<UserModel>().toList(); // Cast to ensure correct list type
  });
});
