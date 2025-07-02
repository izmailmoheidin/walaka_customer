import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../constants/app_constants.dart';

class ProductsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = '';

  // Getters
  List<Product> get products => _products;
  List<Product> get filteredProducts => _filterProducts();
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Filter products based on search query and category
  List<Product> _filterProducts() {
    return _products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (product.description?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory.isEmpty || product.categoryId == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set selected category
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Fetch products filtered by category
  Future<void> fetchProductsByCategory(String categoryId) async {
    _isLoading = true;
    _error = null;
    _selectedCategory = categoryId;
    notifyListeners();
    
    try {
      final snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .get();
      
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
      
      // Update only products with the matching category
      _products = _products
          .where((p) => p.categoryId != categoryId)
          .toList()
          ..addAll(products);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all products and categories from Firestore
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch categories first
      final categoriesSnapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .orderBy('name')
          .get();

      _categories = categoriesSnapshot.docs
          .map((doc) => Category.fromMap(doc.id, doc.data()))
          .toList();

      // Then fetch products
      final productsSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      _products = productsSnapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      _error = 'Failed to fetch data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new product
  Future<void> addProduct(Product product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef = await _firestore
          .collection(AppConstants.productsCollection)
          .add(product.toMap());

      final newProduct = product.copyWith(id: docRef.id);
      _products.insert(0, newProduct);
    } catch (e) {
      _error = 'Failed to add product: $e';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing product
  Future<void> updateProduct(Product product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .update(product.toMap());

      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
    } catch (e) {
      _error = 'Failed to update product: $e';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a product
  Future<void> deleteProduct(Product product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .delete();

      _products.removeWhere((p) => p.id == product.id);
    } catch (e) {
      _error = 'Failed to delete product: $e';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete all products by category ID
  Future<void> deleteProductsByCategory(String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get all products with the specified category ID
      final querySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .get();

      // Delete each product document
      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Update local list
      _products.removeWhere((p) => p.categoryId == categoryId);
    } catch (e) {
      _error = 'Failed to delete products in category: $e';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle product status
  Future<void> toggleProductStatus(Product product) async {
    try {
      final updatedProduct = product.copyWith(
        isActive: !product.isActive,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .update(updatedProduct.toMap());

      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update product status: $e';
      throw e;
    }
  }
}
