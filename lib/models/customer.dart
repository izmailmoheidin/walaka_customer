import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String? phoneNumber;
  final String? name;
  final String? email;
  final String? address;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  Customer({
    required this.id,
    this.phoneNumber,
    this.name,
    this.email,
    this.address,
    this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'address': address,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      id: id,
      phoneNumber: map['phoneNumber'],
      name: map['name'],
      email: map['email'],
      address: map['address'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      lastLogin: map['lastLogin'] != null 
          ? (map['lastLogin'] as Timestamp).toDate() 
          : null,
    );
  }

  Customer copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    String? address,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return Customer(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
