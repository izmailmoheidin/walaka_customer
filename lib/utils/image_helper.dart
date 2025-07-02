import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/admin_theme.dart';

/// Helper class for handling image loading, caching, and error states
class ImageHelper {
  /// Load a network image with proper caching and error handling
  static Widget loadNetworkImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    bool showDebugLogs = true,
  }) {
    // Check if image URL is valid
    final hasValidImage = imageUrl != null && 
                         imageUrl.isNotEmpty && 
                         (imageUrl.startsWith('http://') || 
                          imageUrl.startsWith('https://'));
    
    if (!hasValidImage) {
      if (showDebugLogs) {
        debugPrint('Invalid image URL: $imageUrl');
      }
      return _buildErrorContainer(width, height, borderRadius, errorWidget);
    }
    
    // For web, use direct Image.network for better compatibility with Firebase Storage
    if (kIsWeb) {
      Widget image = Image.network(
        imageUrl!,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildLoadingIndicator(width, height);
        },
        errorBuilder: (context, error, stackTrace) {
          if (showDebugLogs) {
            debugPrint('Error loading image (web): $error, URL: $imageUrl');
          }
          return _buildErrorContainer(width, height, borderRadius, errorWidget);
        },
      );
      
      // Apply border radius if specified
      if (borderRadius != null) {
        image = ClipRRect(
          borderRadius: borderRadius,
          child: image,
        );
      }
      
      return image;
    }
    
    // For mobile, use CachedNetworkImage
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      memCacheWidth: width != null ? (width * 2).toInt() : null, // 2x for high DPI
      memCacheHeight: height != null ? (height * 2).toInt() : null,
      maxWidthDiskCache: 800, // Limit disk cache size
      maxHeightDiskCache: 800,
      placeholder: (context, url) => placeholder ?? _buildLoadingIndicator(width, height),
      errorWidget: (context, url, error) {
        if (showDebugLogs) {
          debugPrint('Error loading image (mobile): $error, URL: $url');
        }
        return _buildErrorContainer(width, height, borderRadius, errorWidget);
      },
    );
    
    // Apply border radius if specified
    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius,
        child: image,
      );
    }
    
    return image;
  }
  
  /// Build a loading indicator widget
  static Widget _buildLoadingIndicator(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.primaryColor),
          ),
        ),
      ),
    );
  }
  
  /// Build an error container widget
  static Widget _buildErrorContainer(
    double? width, 
    double? height, 
    BorderRadius? borderRadius,
    Widget? customErrorWidget,
  ) {
    final container = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: borderRadius,
      ),
      child: customErrorWidget ?? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 24,
              color: Colors.grey.shade500,
            ),
            if (height != null && height > 50) ...[
              const SizedBox(height: 8),
              Text(
                'Image not available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
    
    return container;
  }
}
