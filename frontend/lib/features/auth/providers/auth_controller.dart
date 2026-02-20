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

  AuthState copyWith({bool? isLoading, UserModel? user, String? error, bool clearError = false}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
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
        // Only update if state.user is not already null to avoid unnecessary rebuilds
        if (state.user != null) state = state.copyWith(user: null);
      } else {
        // Fetch full profile from Firestore whenever Auth state changes
        // Use Future.microtask to avoid build phase issues if needed, but not strictly required in listen
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
        
        // Only update state if user model is different (to avoid unnecessary rebuilds or overwrites)
        // Or blindly update?
        // Let's check if the current local state is "loading" or empty.
        // If we are in the middle of signup, we might have set the local state manually.
        // But signup sets state AFTER firestore write.
        
        state = state.copyWith(user: userModel, clearError: true); // Clear error on success
      } else {
        // Doc doesn't exist yet.
        // If this is triggered by auth state change during signup, we should NOT create default user immediately
        // as signup process is about to write the correct data.
        // How to distinguish?
        // We can check if state.isLoading is true?
        // If signup sets isLoading=true.
        
        if (state.isLoading) {
           // Probably signup in progress, let signup handle the user creation and state update.
           // Do nothing.
           return;
        }

        // If not loading, try to create a default one based on Auth info
        /* 
        // Logic commented out to prevent race condition during signup. 
        // Only enable if you support external auth providers (Google, etc.) that don't go through our signup flow.
        
        final user = _auth.currentUser;
        if (user != null && user.uid == uid) {
             final newUser = UserModel(
                uid: uid,
                email: user.email ?? "",
                name: user.displayName ?? "New User",
                role: UserRole.parent, // Default to parent if unknown
                profileImage: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.displayName ?? "User")}&background=random',
             );
             await _firestore.collection('users').doc(uid).set(newUser.toMap());
             state = state.copyWith(user: newUser, error: null);
        } else {
             state = state.copyWith(error: "User profile not found. Please contact support.");
        }
        */
        // Instead, just set error or wait.
        // Setting error might redirect to login if we treat error as logged out? No.
        // But user is authenticated.
        // Let's just wait.
      }
    } catch (e) {
      state = state.copyWith(error: "Failed to load profile: $e");
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Wait for the user profile to be fetched before clearing loading state
      if (cred.user != null) {
        await _fetchUserProfile(cred.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapFirebaseError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "An unexpected error occurred");
    } finally {
      // Only clear loading if we didn't encouter an error (handled above)
      // and if the state is still loading (i.e. successful fetch)
      if (state.isLoading) {
         state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    double? hourlyRate,
    String? bio,
    int? yearsOfExperience,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
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
        // Sitter specific data
        hourlyRate: role == UserRole.sitter ? hourlyRate : null,
        bio: role == UserRole.sitter ? bio : null,
        yearsOfExperience: role == UserRole.sitter ? yearsOfExperience : null,
        isVerified: false,
        reviewCount: 0,
        rating: 0.0,
      );

      // 4. Save to Firestore
      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      // 5. Update Local State
      state = state.copyWith(isLoading: false, user: newUser, clearError: true);

      // Force a re-fetch after signup to ensure consistency with Firestore
      // _fetchUserProfile(uid); 
      // Actually, since we just wrote it, local state is freshest. 
      // But maybe good to verify?

      // 6. Send Verification Email
      await user.sendEmailVerification();
    
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapFirebaseError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Signup Failed: $e");
    } finally {
       // Only update if still loading, to prevent overwriting error states or manually set completion states
       if (state.isLoading) {
         state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> updateProfile({
    String? name,
    String? profileImage,
    String? bio,
    double? hourlyRate,
    int? yearsOfExperience,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = currentUser.copyWith(
        name: name,
        profileImage: profileImage,
        bio: bio,
        hourlyRate: hourlyRate,
        yearsOfExperience: yearsOfExperience,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      // 1. Update Firestore
      await _firestore.collection('users').doc(updatedUser.uid).update(updatedUser.toMap());

      // 2. Update Firebase Auth Display Name if needed
      if (name != null) {
        await _auth.currentUser?.updateDisplayName(name);
      }

      // 3. Update Local State
      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Failed to update profile: $e");
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
