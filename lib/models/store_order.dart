import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StoreOrder {
  final String id;
  final String gameType;
  final String gameTitle;
  final String creditAmount;
  final double price;
  final String gameId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String customerName;
  final String paymentNumber;
  final String paymentMethod;
  final String? paymentStatus;
  final DateTime? paymentCompletedAt;
  final String? userPhoneNumber;
  final bool userVisible;
  
  StoreOrder({
    required this.id,
    required this.gameType,
    required this.gameTitle,
    required this.creditAmount,
    required this.price,
    required this.gameId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.customerName,
    required this.paymentNumber,
    required this.paymentMethod,
    this.paymentStatus,
    this.paymentCompletedAt,
    this.userPhoneNumber,
    this.userVisible = false,
  });
  
  // Convert StoreOrder to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameType': gameType,
      'gameTitle': gameTitle,
      'creditAmount': creditAmount,
      'price': price,
      'gameId': gameId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'customerName': customerName,
      'paymentNumber': paymentNumber,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentCompletedAt': paymentCompletedAt != null ? Timestamp.fromDate(paymentCompletedAt!) : null,
      'userPhoneNumber': userPhoneNumber,
      'userVisible': userVisible,
    };
  }
  
  // Create StoreOrder from Firestore document
  factory StoreOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Debug logging
    debugPrint('Parsing order ${doc.id} with fields: ${data.keys.join(", ")}');
    
    // Handle date fields that might be Timestamps or DateTime strings
    DateTime getDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }
    
    // Extract createdAt from the correct field (client app uses 'createdAt')
    DateTime createdAt;
    if (data['createdAt'] != null) {
      createdAt = getDateTime(data['createdAt']);
    } else if (data['date'] != null) {
      createdAt = getDateTime(data['date']);
    } else {
      createdAt = DateTime.now();
    }
    
    // Extract updatedAt (fallback to createdAt if not available)
    final updatedAt = data['updatedAt'] != null ? 
        getDateTime(data['updatedAt']) : createdAt;
    
    return StoreOrder(
      id: doc.id,
      gameType: data['gameType'] ?? '',
      gameTitle: data['gameTitle'] ?? '',
      creditAmount: data['creditAmount'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      gameId: data['gameId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: createdAt,
      updatedAt: updatedAt,
      customerName: data['customerName'] ?? '',
      paymentNumber: data['paymentNumber'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      paymentStatus: data['paymentStatus'],
      paymentCompletedAt: data['paymentCompletedAt'] != null ? 
          getDateTime(data['paymentCompletedAt']) : null,
      userPhoneNumber: data['userPhoneNumber'],
      userVisible: data['userVisible'] ?? false,
    );
  }
  
  // Create a copy of the order with updated fields
  StoreOrder copyWith({
    String? id,
    String? gameType,
    String? gameTitle,
    String? creditAmount,
    double? price,
    String? gameId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? paymentNumber,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? paymentCompletedAt,
    String? userPhoneNumber,
    bool? userVisible,
  }) {
    return StoreOrder(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      gameTitle: gameTitle ?? this.gameTitle,
      creditAmount: creditAmount ?? this.creditAmount,
      price: price ?? this.price,
      gameId: gameId ?? this.gameId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentCompletedAt: paymentCompletedAt ?? this.paymentCompletedAt,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      userVisible: userVisible ?? this.userVisible,
    );
  }
}
