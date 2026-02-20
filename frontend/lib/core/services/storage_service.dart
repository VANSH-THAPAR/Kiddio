
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

final storageServiceProvider = Provider((ref) => StorageService());

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      final String fileName = path.basename(imageFile.path);
      // Extension is already part of basename or can be extracted if needed
      // final String extension = path.extension(imageFile.path); 
      final String storagePath = 'users/$uid/profile_$fileName';
      
      final Reference ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(imageFile);
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
