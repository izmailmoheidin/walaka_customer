import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double costPrice;
  final int stock;
  final String? imageUrl;
  final String categoryId;
  final String? categoryName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.costPrice = 0.0,
    required this.stock,
    this.imageUrl,
    required this.categoryId,
    this.categoryName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate profit per unit
  double get profit => price - costPrice;
  
  // Calculate profit percentage
  double get profitPercentage => costPrice > 0 ? ((price - costPrice) / costPrice) * 100 : 0;

  // Create a Product from a Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      price: (data['price'] is int) ? (data['price'] as int).toDouble() : (data['price'] ?? 0.0),
      costPrice: (data['costPrice'] is int) ? (data['costPrice'] as int).toDouble() : (data['costPrice'] ?? 0.0),
      stock: data['stock'] ?? 0,
      imageUrl: data['imageUrl'],
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      price: (map['price'] ?? 0).toDouble(),
      costPrice: (map['costPrice'] ?? 0).toDouble(),
      stock: map['stock']?.toInt() ?? 0,
      imageUrl: map['imageUrl'],
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? costPrice,
    int? stock,
    String? imageUrl,
    String? categoryId,
    String? categoryName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
