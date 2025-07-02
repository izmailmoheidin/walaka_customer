import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' show Platform;

/// A widget that handles Firebase Storage image loading with CORS handling for web
class FirebaseImageWidget extends StatefulWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const FirebaseImageWidget({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<FirebaseImageWidget> createState() => _FirebaseImageWidgetState();
}

class _FirebaseImageWidgetState extends State<FirebaseImageWidget> {
  late Future<String?> _processedImageUrl;
  
  @override
  void initState() {
    super.initState();
    _processedImageUrl = _getImageUrl();
  }
  
  @override
  void didUpdateWidget(FirebaseImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _processedImageUrl = _getImageUrl();
    }
  }
  
  Future<String?> _getImageUrl() async {
    return FirebaseImageHelper.getImageUrl(widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _processedImageUrl,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingContainer();
        }
        
        final imageUrl = snapshot.data;
        if (imageUrl == null || imageUrl.isEmpty) {
          return _buildErrorContainer();
        }
        
        return _buildImageWidget(imageUrl);
      },
    );
  }
  
  Widget _buildImageWidget(String url) {
    Widget imageWidget = Image.network(
      url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingContainer();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading image $url: $error');
        return _buildErrorContainer();
      },
    );
    
    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
  
  Widget _buildLoadingContainer() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: widget.borderRadius,
      ),
      child: widget.placeholder ?? Center(
        child: CircularProgressIndicator(
          color: Colors.blue.shade800,
          strokeWidth: 2,
        ),
      ),
    );
  }
  
  Widget _buildErrorContainer() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: widget.borderRadius,
      ),
      child: widget.errorWidget ?? Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
        ),
        width: widget.width,
        height: widget.height,
        child: Center(
          child: Text(
            'W',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: widget.width > widget.height ? widget.height / 2.5 : widget.width / 2.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// A helper class for Firebase Storage image loading
class FirebaseImageHelper {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Get a properly formatted and CORS-friendly image URL
  static Future<String?> getImageUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    
    try {
      // If it's a storage path (not a URL), get the download URL
      String finalUrl;
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        try {
          String path = imageUrl;
          if (path.startsWith('/')) {
            path = path.substring(1);
          }
          // Get the download URL from Firebase Storage
          finalUrl = await _storage.ref(path).getDownloadURL();
          debugPrint('Retrieved Firebase Storage URL: $finalUrl');
        } catch (e) {
          debugPrint('Error resolving storage path: $e');
          return null;
        }
      } else {
        finalUrl = imageUrl;
      }
      
      // For web, apply necessary CORS fixes
      if (kIsWeb) {
        // Fix common URL format issues
        // Handle both firebasestorage.app and appspot.com URLs consistently
        if (finalUrl.contains('firebasestorage.app')) {
          // Leave as is, don't modify domain
          debugPrint('Using original firebasestorage.app URL');
        }
        
        // Extract and correct any token or query parameters if needed
        if (finalUrl.contains('?alt=media') && finalUrl.contains('&token=')) {
          try {
            final uri = Uri.parse(finalUrl);
            final queryParams = uri.queryParameters;
            if (queryParams.containsKey('token')) {
              // Ensure token is properly included
              final baseUrl = finalUrl.split('?')[0];
              final token = queryParams['token'];
              finalUrl = '$baseUrl?alt=media&token=$token';
              debugPrint('Reformatted URL with token: $finalUrl');
            }
          } catch (e) {
            debugPrint('Error parsing URL: $e');
          }
        }
        
        // Apply CORS proxy to avoid CORS issues on web
        if (!finalUrl.contains('wsrv.nl')) {
          // Fix double-encoding issues in the URL
          // This is a common issue with Firebase Storage URLs
          if (finalUrl.contains('%252F')) {
            finalUrl = finalUrl.replaceAll('%252F', '%2F');
            debugPrint('Fixed double-encoding in URL: $finalUrl');
          }
          
          // Remove any double-encoded tokens or parameters
          if (finalUrl.contains('%26token')) {
            finalUrl = finalUrl.replaceAll('%26token', '&token');
            debugPrint('Fixed encoded token parameter: $finalUrl');
          }
          
          if (finalUrl.contains('%3Falt')) {
            finalUrl = finalUrl.replaceAll('%3Falt', '?alt');
            debugPrint('Fixed encoded alt parameter: $finalUrl');
          }
          
          if (finalUrl.contains('%3D')) {
            finalUrl = finalUrl.replaceAll('%3D', '=');
            debugPrint('Fixed encoded equal sign: $finalUrl');
          }
          
          // Check if URL already has properly encoded path segments
          if (finalUrl.contains('/o/categories%2F') || 
              finalUrl.contains('/o/payment_methods%2F') ||
              finalUrl.contains('/o/products%2F')) {
            // URL is already properly encoded, use as is with proxy
            finalUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(finalUrl)}';
          } else if (finalUrl.contains('/o/categories/') || 
                     finalUrl.contains('/o/payment_methods/') ||
                     finalUrl.contains('/o/products/')) {
            // URL has unencoded slashes in path, encode them properly
            String baseUrl = finalUrl.split('/o/')[0] + '/o/';
            String pathPart = finalUrl.split('/o/')[1];
            
            // Properly encode path segments while preserving query parameters
            String encodedPath;
            String queryParams = '';
            if (pathPart.contains('?')) {
              encodedPath = pathPart.split('?')[0];
              queryParams = '?${pathPart.split('?')[1]}';
            } else {
              encodedPath = pathPart;
            }
            
            // Replace directory separators with encoded version
            encodedPath = encodedPath.replaceAll('/', '%2F');
            
            // Build final URL with proxy
            String urlToEncode = '$baseUrl$encodedPath$queryParams';
            debugPrint('Pre-proxy URL: $urlToEncode');
            finalUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(urlToEncode)}';
          } else {
            // Default encoding
            finalUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(finalUrl)}';
          }
          
          debugPrint('Applied CORS proxy: $finalUrl');
        }
      }
      
      return finalUrl;
    } catch (e) {
      debugPrint('Error processing image URL: $e');
      return null;
    }
  }
  
  /// Create a Firebase image widget with proper CORS handling
  static Widget buildImage({
    required String? imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    return FirebaseImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      borderRadius: borderRadius,
    );
  }
}
