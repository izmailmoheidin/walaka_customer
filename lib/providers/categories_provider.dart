import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../constants/app_constants.dart';
import './products_provider.dart';

class CategoriesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Category> get categories => _categories;
  List<Category> get activeCategories => _categories.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch categories
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .orderBy('name')
          .get();

      _categories = snapshot.docs
          .map((doc) => Category.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      _error = 'Failed to fetch categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(dynamic imageFile, String path) async {
    try {
      // Generate unique filename
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('$path/$fileName');
      TaskSnapshot uploadTask;
      
      if (imageFile is File) {
        // Mobile upload
        debugPrint('Uploading mobile image file');
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'picked-file-path': imageFile.path},
        );
        uploadTask = await ref.putFile(imageFile, metadata);
      } else if (imageFile is Uint8List) {
        // Web upload
        debugPrint('Uploading web image bytes');
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
        );
        uploadTask = await ref.putData(imageFile, metadata);
      } else {
        throw Exception('Unsupported image file type');
      }
      
      if (uploadTask.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        debugPrint('Image uploaded successfully: $url');
        return url;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Delete image from Firebase Storage
  Future<void> _deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  // Add category
  Future<void> addCategory(String name, String? description, dynamic imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile, AppConstants.categoryImagesPath);
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      final category = Category(
        id: '',
        name: name.trim(),
        description: description?.trim(),
        imageUrl: imageUrl,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(AppConstants.categoriesCollection)
          .add(category.toMap());

      final newCategory = category.copyWith(id: docRef.id);
      _categories.add(newCategory);
      _categories.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _error = 'Failed to add category: $e';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update category
  Future<void> updateCategory(Category category, {dynamic newImageFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? imageUrl = category.imageUrl;
      
      if (newImageFile != null) {
        // Upload new image
        final newImageUrl = await _uploadImage(newImageFile, AppConstants.categoryImagesPath);
        if (newImageUrl == null) {
          throw Exception('Failed to upload new image');
        }

        // Delete old image if exists
        if (category.imageUrl != null && category.imageUrl!.isNotEmpty) {
          try {
            await _deleteImage(category.imageUrl!);
          } catch (e) {
            debugPrint('Error deleting old image: $e');
            // Continue even if delete fails
          }
        }

        imageUrl = newImageUrl;
      }

      final updatedCategory = category.copyWith(
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(category.id)
          .update(updatedCategory.toMap());

      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
        _categories.sort((a, b) => a.name.compareTo(b.name));
      }
    } catch (e) {
      _error = 'Failed to update category: $e';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete category
  Future<void> deleteCategory(Category category, {required BuildContext context}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First delete all products in this category
      final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
      await productsProvider.deleteProductsByCategory(category.id);

      // Then delete the category
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(category.id)
          .delete();

      if (category.imageUrl != null) {
        await _deleteImage(category.imageUrl!);
      }

      _categories.removeWhere((c) => c.id == category.id);
    } catch (e) {
      _error = 'Failed to delete category: $e';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle category status
  Future<void> toggleCategoryStatus(Category category) async {
    try {
      final updatedCategory = category.copyWith(
        isActive: !category.isActive,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(category.id)
          .update(updatedCategory.toMap());

      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update category status: $e';
      throw e;
    }
  }
}
