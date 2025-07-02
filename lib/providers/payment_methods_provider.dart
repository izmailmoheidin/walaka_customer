import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/payment_method.dart';

class PaymentMethodsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PaymentMethod> get activePaymentMethods => _paymentMethods.where((method) => method.isActive).toList();

  // Initialize the provider
  Future<void> init() async {
    if (_paymentMethods.isNotEmpty) return;
    await fetchPaymentMethods();
  }

  // Fetch payment methods from Firestore
  Future<void> fetchPaymentMethods() async {
    _setLoading(true);
    _clearError();

    try {
      // Print debug information
      debugPrint('Fetching payment methods from Firestore...');
      
      // Try different collection names
      final collections = ['paymentMethods', 'payment_methods', 'PaymentMethods'];
      List<QueryDocumentSnapshot> allDocs = [];
      bool permissionError = false;
      
      try {
        for (final collectionName in collections) {
          debugPrint('Trying collection: $collectionName');
          try {
            final snapshot = await _firestore.collection(collectionName).get();
            debugPrint('Found ${snapshot.docs.length} documents in $collectionName');
            allDocs.addAll(snapshot.docs);
          } catch (e) {
            debugPrint('Error accessing collection $collectionName: $e');
            if (e.toString().contains('permission-denied')) {
              permissionError = true;
            }
          }
        }
      } catch (e) {
        debugPrint('Error in collection loop: $e');
        permissionError = true;
      }
      
      debugPrint('Found ${allDocs.length} payment methods in total');
      
      if (allDocs.isEmpty) {
        if (permissionError) {
          debugPrint('Using fallback payment methods due to permission errors');
          _useFallbackPaymentMethods();
          return;
        }
        
        // Check if we should create a sample payment method
        final shouldCreate = await _checkAndCreateSamplePaymentMethod();
        if (shouldCreate) {
          // Fetch again after creating sample
          return fetchPaymentMethods();
        }
      }
      
      if (allDocs.isNotEmpty) {
        _paymentMethods = allDocs
            .map((doc) {
              try {
                debugPrint('Processing document ID: ${doc.id}');
                return PaymentMethod.fromFirestore(doc);
              } catch (e) {
                debugPrint('Error processing payment method document ${doc.id}: $e');
                return null;
              }
            })
            .where((method) => method != null)
            .cast<PaymentMethod>()
            .toList();
      } else {
        _useFallbackPaymentMethods();
      }
      
      debugPrint('Successfully loaded ${_paymentMethods.length} payment methods');
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching payment methods: $e');
      _setError('Failed to load payment methods: $e');
      _useFallbackPaymentMethods();
    } finally {
      _setLoading(false);
    }
  }

  // Check if we need to create a sample payment method
  Future<bool> _checkAndCreateSamplePaymentMethod() async {
    try {
      debugPrint('Checking if we should create a sample payment method...');
      
      // Check all possible collection names
      final collections = ['paymentMethods', 'payment_methods', 'PaymentMethods'];
      bool hasAnyMethods = false;
      
      for (final collectionName in collections) {
        final snapshot = await _firestore.collection(collectionName).limit(1).get();
        if (snapshot.docs.isNotEmpty) {
          hasAnyMethods = true;
          break;
        }
      }
      
      if (!hasAnyMethods) {
        debugPrint('No payment methods found, creating a sample one...');
        
        // Create a sample payment method in the payment_methods collection
        final now = DateTime.now();
        final data = {
          'name': 'Somtel E-dahab',
          'number': '615045015',
          'shortcutCode': '*110*paymentnumber*amount#',
          'icon': 'IconData(0xe4a3)',
          'color': 'Color(0xffffc107)',
          'isActive': true,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        };
        
        await _firestore.collection('payment_methods').add(data);
        debugPrint('Sample payment method created successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error creating sample payment method: $e');
      return false;
    }
  }

  // Upload an image to Firebase Storage and get the URL
  Future<String?> uploadPaymentMethodImage(File imageFile, String methodName) async {
    _setLoading(true);
    _clearError();

    try {
      final fileName = 'payment_methods/${DateTime.now().millisecondsSinceEpoch}_${methodName.replaceAll(' ', '_')}.jpg';
      final ref = _storage.ref().child(fileName);
      
      // Upload the file
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Image uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      _setError('Error uploading image: $e');
      debugPrint('Error uploading image: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Upload a web image (Uint8List) to Firebase Storage
  Future<String?> uploadWebPaymentMethodImage(Uint8List imageBytes, String methodName) async {
    _setLoading(true);
    _clearError();

    try {
      final fileName = 'payment_methods/${DateTime.now().millisecondsSinceEpoch}_${methodName.replaceAll(' ', '_')}.jpg';
      final ref = _storage.ref().child(fileName);
      
      // Upload the bytes
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Web image uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      _setError('Error uploading web image: $e');
      debugPrint('Error uploading web image: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Add a new payment method
  Future<bool> addPaymentMethod(PaymentMethod paymentMethod, {File? imageFile, Uint8List? webImageBytes}) async {
    _setLoading(true);
    _clearError();

    try {
      final now = DateTime.now();
      
      // If an image is provided, upload it first
      String? imageUrl;
      if (kIsWeb && webImageBytes != null) {
        // Handle web platform image upload
        imageUrl = await uploadWebPaymentMethodImage(webImageBytes, paymentMethod.name);
        if (imageUrl == null) {
          throw Exception('Failed to upload web image');
        }
      } else if (!kIsWeb && imageFile != null) {
        // Handle mobile platform image upload
        imageUrl = await uploadPaymentMethodImage(imageFile, paymentMethod.name);
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }
      
      // Create a copy of the payment method with the image URL
      final methodWithImage = paymentMethod.copyWith(
        imageUrl: imageUrl ?? paymentMethod.imageUrl,
        createdAt: now,
        updatedAt: now,
      );
      
      final data = methodWithImage.toFirestore();
      final docRef = await _firestore.collection('payment_methods').add(data);
      
      // Add the new payment method to the local list
      final newMethod = PaymentMethod.fromFirestore(
        await docRef.get(),
      );
      
      _paymentMethods.add(newMethod);
      _paymentMethods.sort((a, b) => a.name.compareTo(b.name));
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error adding payment method: $e');
      debugPrint('Error adding payment method: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing payment method
  Future<bool> updatePaymentMethod(PaymentMethod paymentMethod, {File? imageFile, Uint8List? webImageBytes}) async {
    _setLoading(true);
    _clearError();

    try {
      final now = DateTime.now();
      
      // If an image is provided, upload it first
      String? imageUrl;
      if (kIsWeb && webImageBytes != null) {
        // Handle web platform image upload
        imageUrl = await uploadWebPaymentMethodImage(webImageBytes, paymentMethod.name);
        if (imageUrl == null) {
          throw Exception('Failed to upload web image');
        }
      } else if (!kIsWeb && imageFile != null) {
        // Handle mobile platform image upload
        imageUrl = await uploadPaymentMethodImage(imageFile, paymentMethod.name);
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }
      
      // Create a copy of the payment method with the image URL and updated timestamp
      final methodWithImage = paymentMethod.copyWith(
        imageUrl: imageUrl ?? paymentMethod.imageUrl,
        updatedAt: now,
      );
      
      final data = methodWithImage.toFirestore();
      await _firestore.collection('payment_methods').doc(paymentMethod.id).update(data);
      
      // Update the payment method in the local list
      final index = _paymentMethods.indexWhere((m) => m.id == paymentMethod.id);
      if (index != -1) {
        _paymentMethods[index] = methodWithImage;
        _paymentMethods.sort((a, b) => a.name.compareTo(b.name));
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error updating payment method: $e');
      debugPrint('Error updating payment method: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a payment method
  Future<bool> deletePaymentMethod(String id) async {
    _setLoading(true);
    _clearError();

    try {
      // Find the payment method to get its image URL
      final methodIndex = _paymentMethods.indexWhere((method) => method.id == id);
      if (methodIndex != -1) {
        final method = _paymentMethods[methodIndex];
        
        // Delete the image from storage if it exists
        if (method.imageUrl != null) {
          try {
            // Extract the path from the URL
            final ref = _storage.refFromURL(method.imageUrl!);
            await ref.delete();
            debugPrint('Deleted image: ${method.imageUrl}');
          } catch (e) {
            debugPrint('Error deleting image: $e');
            // Continue with deletion even if image deletion fails
          }
        }
      }
      
      await _firestore.collection('payment_methods').doc(id).delete();
      
      // Remove the payment method from the local list
      _paymentMethods.removeWhere((method) => method.id == id);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error deleting payment method: $e');
      debugPrint('Error deleting payment method: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle payment method active status
  Future<bool> togglePaymentMethodStatus(String id) async {
    _setLoading(true);
    _clearError();

    try {
      // Find the payment method
      final methodIndex = _paymentMethods.indexWhere((method) => method.id == id);
      if (methodIndex == -1) {
        throw Exception('Payment method not found');
      }
      
      final method = _paymentMethods[methodIndex];
      final newStatus = !method.isActive;
      
      // Update in Firestore
      await _firestore.collection('payment_methods').doc(id).update({
        'isActive': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // Update in local list
      _paymentMethods[methodIndex] = method.copyWith(
        isActive: newStatus,
        updatedAt: DateTime.now(),
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error toggling payment method status: $e');
      debugPrint('Error toggling payment method status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods for loading state and errors
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Provides fallback payment methods when Firestore access fails
  void _useFallbackPaymentMethods() {
    debugPrint('Setting up fallback payment methods');
    _paymentMethods = [
      PaymentMethod(
        id: 'evc-plus-fallback',
        name: 'EVC Plus',
        number: '*770*',
        shortcutCode: '*770*',
        isActive: true,
        description: 'Hormuud EVC Plus payment method',
        icon: Icons.phone_android,
        color: Colors.green,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PaymentMethod(
        id: 'zaad-fallback',
        name: 'ZAAD',
        number: '*220*',
        shortcutCode: '*220*',
        isActive: true,
        description: 'Somtel ZAAD payment method',
        icon: Icons.account_balance_wallet,
        color: Colors.blue,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PaymentMethod(
        id: 'edahab-fallback',
        name: 'eDahab',
        number: '*300*',
        shortcutCode: '*300*',
        isActive: true,
        description: 'Dahabshiil eDahab payment method',
        icon: Icons.payment,
        color: Colors.orange,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    _setLoading(false);
  }
}
