import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user data
  Future<AdminUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // If the user exists in Auth but not in Firestore, sign them out
        await _auth.signOut();
        return null;
      }

      return AdminUser.fromMap(user.uid, doc.data()!);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<AdminUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) return null;

      // Update last login
      final userDoc = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userCredential.user!.uid);

      final doc = await userDoc.get();
      if (!doc.exists) {
        // If the user exists in Auth but not in Firestore, sign them out
        await _auth.signOut();
        return null;
      }

      await userDoc.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return AdminUser.fromMap(userCredential.user!.uid, doc.data()!);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Wrong password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = e.message ?? 'An error occurred';
      }
      throw message;
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get auth state changes
  Stream<AdminUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      return AdminUser.fromMap(user.uid, doc.data()!);
    });
  }
}
