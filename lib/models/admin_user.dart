import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String uid;
  final String email;
  final String? displayName;
  final String role;
  final DateTime? lastLogin;
  final bool isActive;

  AdminUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    this.lastLogin,
    this.isActive = true,
  });

  factory AdminUser.fromMap(String uid, Map<String, dynamic> data) {
    return AdminUser(
      uid: uid,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      role: data['role'] as String,
      lastLogin: data['lastLogin'] != null 
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'isActive': isActive,
    };
  }

  AdminUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return AdminUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }
}
