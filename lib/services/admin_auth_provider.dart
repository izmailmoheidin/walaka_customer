import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';
import '../constants/app_constants.dart';

class AdminAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AdminUser? _adminUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  AdminUser? get adminUser => _adminUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor
  AdminAuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Handle auth state changes
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _adminUser = null;
      notifyListeners();
      return;
    }

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) {
        await _auth.signOut();
        _adminUser = null;
      } else {
        _adminUser = AdminUser.fromMap(firebaseUser.uid, doc.data()!);
      }
    } catch (e) {
      debugPrint('Error getting admin user: $e');
      _error = e.toString();
      _adminUser = null;
    }

    notifyListeners();
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        _error = 'Failed to sign in';
        notifyListeners();
        return false;
      }

      // Update last login
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userCredential.user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return true;
    } on FirebaseAuthException catch (e) {
      // Provide a user-friendly error message for common authentication errors
      switch(e.code) {
        case 'user-not-found':
          _error = 'No account found with this email. Please check your email or create a new account.';
          break;
        case 'wrong-password':
          _error = 'Incorrect password. Please try again or reset your password.';
          break;
        case 'invalid-email':
          _error = 'Invalid email format. Please enter a valid email address.';
          break;
        case 'user-disabled':
          _error = 'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          _error = 'Too many failed login attempts. Please try again later or reset your password.';
          break;
        default:
          _error = e.message ?? 'Authentication failed';
      }
      
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _adminUser = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }
}
