import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// A utility class to handle cross-platform image display
/// This handles both File objects for mobile and Uint8List for web
class CrossPlatformImage {
  final File? file;
  final Uint8List? webImage;
  final String? imageUrl;
  
  CrossPlatformImage({this.file, this.webImage, this.imageUrl});
  
  bool get isEmpty => file == null && webImage == null && (imageUrl == null || imageUrl!.isEmpty);
  bool get isNotEmpty => !isEmpty;
  
  /// Creates a widget to display the image based on the platform
  Widget toImageWidget({
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
  }) {
    if (kIsWeb && webImage != null) {
      return Image.memory(
        webImage!,
        fit: fit,
        width: width,
        height: height,
      );
    } else if (!kIsWeb && file != null) {
      return Image.file(
        file!,
        fit: fit,
        width: width,
        height: height,
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return placeholder ?? Container(
            color: Colors.grey[300],
            child: Center(
              child: Icon(Icons.broken_image, color: Colors.grey[600]),
            ),
          );
        },
      );
    } else {
      return placeholder ?? Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image, color: Colors.grey[400]),
        ),
      );
    }
  }
}
