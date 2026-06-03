import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;

  const AuthResult({required this.success, this.errorMessage});
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  static Future<AuthResult> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return const AuthResult(
          success: false,
          errorMessage: 'Login failed. Please try again.',
        );
      }

      final roleResult = await _fetchUserRole(user.uid);
      if (!roleResult.success) {
        await _auth.signOut();
        return AuthResult(success: false, errorMessage: roleResult.errorMessage);
      }

      if (roleResult.role == null) {
        await _auth.signOut();
        return const AuthResult(
          success: false,
          errorMessage:
              'Profile not found. Sign up again with the same email or contact support.',
        );
      }

      await StorageService.saveUserData(user.email ?? email, roleResult.role!);
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, errorMessage: _mapAuthError(e));
    } on FirebaseException catch (e) {
      return AuthResult(success: false, errorMessage: _mapFirestoreError(e));
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Login error: $e');
    }
  }

  /// Create account and store Donor/NGO role in Firestore.
  static Future<AuthResult> signup(
    String email,
    String password,
    String role,
  ) async {
    User? user;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      user = credential.user;
      if (user == null) {
        return const AuthResult(
          success: false,
          errorMessage: 'Signup failed. Please try again.',
        );
      }

      await _firestore.collection('users').doc(user.uid).set({
        'email': email.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await StorageService.saveSignupData(email.trim(), role);
      await _auth.signOut();

      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase signup error: code=${e.code}, message=${e.message}');
      return AuthResult(success: false, errorMessage: _mapAuthError(e));
    } on FirebaseException catch (e) {
      debugPrint('Firestore signup error: code=${e.code}, message=${e.message}');
      if (user != null) {
        await user.delete();
      }
      return AuthResult(success: false, errorMessage: _mapFirestoreError(e));
    } catch (e) {
      debugPrint('Signup error: $e');
      if (user != null) {
        await user.delete();
      }
      return AuthResult(success: false, errorMessage: 'Signup error: $e');
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await StorageService.clearUserData();
  }

  /// Load role for an already signed-in Firebase user (app restart).
  static Future<AuthResult> syncSessionFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthResult(success: false);
    }

    try {
      final roleResult = await _fetchUserRole(user.uid);
      if (!roleResult.success) {
        await signOut();
        return AuthResult(success: false, errorMessage: roleResult.errorMessage);
      }

      if (roleResult.role == null) {
        await signOut();
        return const AuthResult(
          success: false,
          errorMessage: 'Could not load your profile. Please log in again.',
        );
      }

      await StorageService.saveUserData(user.email ?? '', roleResult.role!);
      return const AuthResult(success: true);
    } on FirebaseException catch (e) {
      return AuthResult(success: false, errorMessage: _mapFirestoreError(e));
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Session error: $e');
    }
  }

  static Future<({bool success, String? role, String? errorMessage})>
      _fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return (success: true, role: null, errorMessage: null);
      }
      return (success: true, role: doc.data()?['role'] as String?, errorMessage: null);
    } on FirebaseException catch (e) {
      debugPrint('Firestore read error: code=${e.code}, message=${e.message}');
      return (
        success: false,
        role: null,
        errorMessage: _mapFirestoreError(e),
      );
    }
  }

  static String _mapFirestoreError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return 'Firestore blocked this request. In Firebase Console → Firestore → '
          'Rules, publish the rules from firestore.rules in this project, then try again.';
    }
    return 'Database error: ${e.message ?? e.code}';
  }

  static String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Console.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        final detail = e.message ?? 'Authentication failed.';
        return '$detail (${e.code})';
    }
  }
}
