import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String number;
  final String shortcutCode;
  final String? imageUrl;  // New field for image URL
  final String? description; // Description of the payment method
  final IconData? icon;    // Made optional
  final Color color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.number,
    required this.shortcutCode,
    this.imageUrl,         // New optional parameter
    this.description,      // Optional description field
    this.icon,             // Made optional
    required this.color,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert IconData to a string representation for Firestore
  String? _iconDataToString(IconData? icon) {
    if (icon == null) return null;
    return 'IconData(0x${icon.codePoint.toRadixString(16)})';
  }

  // Convert Color to a string representation for Firestore
  String _colorToString(Color color) {
    return 'Color(0x${color.value.toRadixString(16)})';
  }

  // Convert from string representation to IconData
  static IconData? _stringToIconData(String? iconString) {
    if (iconString == null) return null;
    // Extract the hex code from the string
    final hexCodeMatch = RegExp(r'0x([0-9a-fA-F]+)').firstMatch(iconString);
    if (hexCodeMatch != null) {
      final hexCode = hexCodeMatch.group(1);
      return IconData(int.parse(hexCode!, radix: 16), fontFamily: 'MaterialIcons');
    }
    return null;
  }

  // Convert from string representation to Color
  static Color _stringToColor(String colorString) {
    // Extract the hex code from the string
    final hexCode = colorString.split('0x')[1].split(')')[0];
    return Color(int.parse(hexCode, radix: 16));
  }

  // Factory constructor to create a PaymentMethod from a Firestore document
  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Debug print the document data
    debugPrint('Payment method data: $data');
    
    // Handle icon data conversion with better error handling
    IconData? getIconData() {
      try {
        if (data['icon'] != null) {
          final iconString = data['icon'] as String;
          return _stringToIconData(iconString);
        }
      } catch (e) {
        debugPrint('Error parsing icon data: $e');
      }
      return null; // No default icon
    }
    
    // Handle color conversion with better error handling
    Color getColor() {
      try {
        if (data['color'] != null) {
          final colorString = data['color'] as String;
          // Extract the hex code from the string
          final hexCodeMatch = RegExp(r'0x([0-9a-fA-F]+)').firstMatch(colorString);
          if (hexCodeMatch != null) {
            final hexCode = hexCodeMatch.group(1);
            return Color(int.parse(hexCode!, radix: 16));
          }
        }
      } catch (e) {
        debugPrint('Error parsing color data: $e');
      }
      return Colors.blue; // Default color
    }
    
    return PaymentMethod(
      id: doc.id,
      name: data['name'] as String? ?? '',
      number: data['number'] as String? ?? '',
      shortcutCode: data['shortcutCode'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,  // New field
      description: data['description'] as String?, // Description field
      icon: getIconData(),
      color: getColor(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Format the shortcut code with the price, handling decimal points
  String formatShortcutWithPrice(double price) {
    // Convert the price to a string with 2 decimal places
    String priceStr = price.toStringAsFixed(2);
    
    // Split the price into whole and decimal parts
    List<String> parts = priceStr.split('.');
    String wholePart = parts[0];
    String decimalPart = parts[1];
    
    // Remove trailing zeros from decimal part
    while (decimalPart.endsWith('0') && decimalPart.length > 1) {
      decimalPart = decimalPart.substring(0, decimalPart.length - 1);
    }
    
    // Format the price according to the decimal point logic
    String formattedPrice;
    if (decimalPart == '0') {
      // If no decimal part, just use the whole number
      formattedPrice = wholePart;
    } else {
      // For decimal points, use separate asterisks (e.g., 1*25 for 1.25)
      formattedPrice = '$wholePart*$decimalPart';
    }
    
    // Replace 'amount' in the shortcut code with the formatted price
    return shortcutCode.replaceAll('amount', formattedPrice);
  }

  // Convert PaymentMethod to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'name': name,
      'number': number,
      'shortcutCode': shortcutCode,
      'color': _colorToString(color),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
    
    // Only add imageUrl if it exists
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl!;
    }
    
    // Only add description if it exists
    if (description != null) {
      data['description'] = description!;
    }
    
    // Only add icon if it exists
    if (icon != null) {
      data['icon'] = _iconDataToString(icon)!;
    }
    
    return data;
  }

  // Create a copy of this PaymentMethod with some fields replaced
  PaymentMethod copyWith({
    String? id,
    String? name,
    String? number,
    String? shortcutCode,
    String? imageUrl,
    String? description,
    IconData? icon,
    Color? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      shortcutCode: shortcutCode ?? this.shortcutCode,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
