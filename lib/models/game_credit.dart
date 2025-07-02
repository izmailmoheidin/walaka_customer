import 'package:cloud_firestore/cloud_firestore.dart';

class GameCredit {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String gameType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameCredit({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.gameType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'gameType': gameType,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory GameCredit.fromMap(String id, Map<String, dynamic> map) {
    return GameCredit(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity']?.toInt() ?? 0,
      gameType: map['gameType'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  GameCredit copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? gameType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameCredit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      gameType: gameType ?? this.gameType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
