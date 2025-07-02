import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/game_category.dart';

class GameCategoriesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<GameCategory> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<GameCategory> get categories => _categories;
  List<GameCategory> get filteredCategories => _filterCategories();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Filter categories based on search query
  List<GameCategory> _filterCategories() {
    if (_searchQuery.isEmpty) {
      return _categories;
    }
    
    return _categories.where((category) {
      return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Fetch categories from Firestore
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('game_categories')
          .orderBy('createdAt', descending: true)
          .get();
      
      _categories = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GameCategory.fromMap(doc.id, data);
      }).toList();
      
    } catch (e) {
      _error = 'Failed to fetch categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new category
  Future<bool> addCategory(GameCategory category, dynamic imageSource) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String imageUrl = category.imageUrl;
      
      // Upload image if provided
      if (imageSource != null) {
        final storageRef = _storage.ref().child('category_images/${DateTime.now().millisecondsSinceEpoch}');
        UploadTask uploadTask;
        
        try {
          if (kIsWeb && imageSource is Uint8List) {
            // For web, upload bytes
            uploadTask = storageRef.putData(
              imageSource,
              SettableMetadata(contentType: 'image/jpeg') // Explicitly set content type
            );
          } else if (!kIsWeb && imageSource is File) {
            // For mobile, upload file
            uploadTask = storageRef.putFile(imageSource);
          } else {
            throw Exception('Invalid image format');
          }
          
          final snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
          
          // Debug log to see the URL
          debugPrint('Uploaded image URL: $imageUrl');
        } catch (e) {
          debugPrint('Error uploading image: $e');
          rethrow;
        }
      }
      
      // Create updated category with image URL
      final updatedCategory = category.copyWith(
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );
      
      // Add to Firestore
      await _firestore
          .collection('game_categories')
          .add(updatedCategory.toMap());
      
      await fetchCategories(); // Refresh the list
      return true;
    } catch (e) {
      _error = 'Failed to add category: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update existing category
  Future<bool> updateCategory(GameCategory category, dynamic imageSource) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String imageUrl = category.imageUrl;
      
      // Upload new image if provided
      if (imageSource != null) {
        final storageRef = _storage.ref().child('category_images/${DateTime.now().millisecondsSinceEpoch}');
        UploadTask uploadTask;
        
        if (kIsWeb && imageSource is Uint8List) {
          // For web, upload bytes
          uploadTask = storageRef.putData(imageSource);
        } else if (!kIsWeb && imageSource is File) {
          // For mobile, upload file
          uploadTask = storageRef.putFile(imageSource);
        } else {
          throw Exception('Invalid image format');
        }
        
        final snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }
      
      // Update category with image URL
      final updatedCategory = category.copyWith(
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );
      
      // Update in Firestore
      await _firestore
          .collection('game_categories')
          .doc(category.id)
          .update(updatedCategory.toMap());
      
      await fetchCategories(); // Refresh the list
      return true;
    } catch (e) {
      _error = 'Failed to update category: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete category and associated game credits
  Future<bool> deleteCategory(GameCategory category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First, find and delete any game credits associated with this category
      // If your game credits have a direct relationship with the game category ID
      // This assumes the category.id is the same as the gameType used in GameCreditsProvider
      if (category.id != null && category.id.isNotEmpty) {
        // Check if there are credits under this game type
        final QuerySnapshot creditsSnapshot = await _firestore
            .collection('games')
            .doc(category.id)
            .collection('credits')
            .get();
        
        // Batch delete all associated credits
        final batch = _firestore.batch();
        for (var doc in creditsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        // Also try deleting the game document itself if it exists
        try {
          await _firestore.collection('games').doc(category.id).delete();
        } catch (e) {
          // Ignore error if the document doesn't exist
          print('Note: Game document may not exist or couldn\'t be deleted: $e');
        }
      }
      
      // Then delete the category
      await _firestore
          .collection('game_categories') // Using consistent collection name
          .doc(category.id)
          .delete();
      
      // Delete image from storage if it's a Firebase Storage URL
      if (category.imageUrl.startsWith('https://firebasestorage.googleapis.com')) {
        try {
          await _storage.refFromURL(category.imageUrl).delete();
        } catch (e) {
          print('Warning: Could not delete image from storage: $e');
          // Continue even if image deletion fails
        }
      }
      
      await fetchCategories(); // Refresh the list
      return true;
    } catch (e) {
      _error = 'Failed to delete category: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
