import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';

class CustomerProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Customer? _currentCustomer;
  bool _isLoading = false;
  String? _error;

  Customer? get currentCustomer => _currentCustomer;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get customer data from Firestore
  Future<void> loadCustomerData(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customerDoc = await _firestore.collection('customers').doc(userId).get();
      
      if (customerDoc.exists) {
        _currentCustomer = Customer.fromMap(userId, customerDoc.data()!);
      } else {
        _error = 'Customer profile not found';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update customer profile information
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customerRef = _firestore.collection('customers').doc(userId);
      
      Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (address != null) updateData['address'] = address;
      
      await customerRef.update(updateData);
      
      // Refresh customer data
      await loadCustomerData(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear current customer data (e.g., on logout)
  void clearCustomerData() {
    _currentCustomer = null;
    _error = null;
    notifyListeners();
  }
}
