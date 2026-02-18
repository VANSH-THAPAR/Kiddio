import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'dart:async';

// State for the AuthController
class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  const AuthState({this.isLoading = false, this.user, this.error});

  AuthState copyWith({bool? isLoading, UserModel? user, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

// The AuthController class
class AuthController extends Notifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authStateChangesSubscription;

  @override
  AuthState build() {
    // Listen to Firebase auth changes
    _authStateChangesSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        state = state.copyWith(user: null);
      } else {
        // Fetch full profile from Firestore whenever Auth state changes
        _fetchUserProfile(user.uid);
      }
    });
    
    // Cleanup subscription on dispose is handled by ref.onDispose
    ref.onDispose(() {
      _authStateChangesSubscription?.cancel();
    });

    return const AuthState();
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        // Correctly parse the data using the factory method
        final userData = doc.data()!;
        final userModel = UserModel.fromMap(userData, uid);
        state = state.copyWith(user: userModel);
      } else {
        // If the user exists in Auth but not Firestore (rare edge case), handle gracefully
        state = state.copyWith(error: "User profile incomplete. Please contact support.");
      }
    } catch (e) {
      state = state.copyWith(error: "Failed to load profile: $e");
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // The listener in build() will handle fetching the profile
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapFirebaseError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "An unexpected error occurred");
    } finally {
      // Create a copy with isLoading: false without modifying other fields
      // We don't want to clear the user if the listener already set it
      if (state.isLoading) {
         state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> signup(String name, String email, String password, UserRole role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Create User in Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      final user = cred.user;
      if (user == null) throw Exception("User creation failed");

      // 2. Update Display Name
      await user.updateDisplayName(name);

      // 3. Create UserModel
      final String uid = user.uid;
      final newUser = UserModel(
        uid: uid,
        email: email,
        name: name,
        profileImage: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random',
        role: role,
        // Default empty values for Sitter fields
        bio: role == UserRole.sitter ? "Hi! I'm new here." : null,
        hourlyRate: role == UserRole.sitter ? 15.0 : null,
        rating: role == UserRole.sitter ? 0.0 : null,
        reviewCount: role == UserRole.sitter ? 0 : null,
        certifications: role == UserRole.sitter ? <String>[] : null,
        skills: role == UserRole.sitter ? <String>[] : null,
      );

      // 4. Save to Firestore
      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      // 5. Send Verification Email
      await user.sendEmailVerification();
      
      // Note: The listener will fire and fetch the profile we just saved.
    
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapFirebaseError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Signup Failed: $e");
    } finally {
       if (state.isLoading) {
         state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const AuthState();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    if (e.code == 'user-not-found') return "No user found for that email.";
    if (e.code == 'wrong-password') return "Wrong password provided.";
    if (e.code == 'email-already-in-use') return "The account already exists for that email.";
    if (e.code == 'invalid-email') return "The email address is invalid.";
    if (e.code == 'weak-password') return "The password is too weak.";
    return e.message ?? "Authentication failed";
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
