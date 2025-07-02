import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// A widget that displays images with CORS workarounds for web
class CorsImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CorsImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorContainer();
    }

    // Process the URL to work around CORS issues
    String processedUrl = _processUrl(imageUrl!);

    // Build the image widget
    Widget imageWidget = Image.network(
      processedUrl,
      width: width,
      height: height,
      fit: fit,
      // Disable caching on web
      cacheWidth: kIsWeb ? null : (width != null ? (width! * 2).toInt() : null),
      cacheHeight: kIsWeb ? null : (height != null ? (height! * 2).toInt() : null),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingIndicator();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading image: $error, URL: $processedUrl');
        return _buildErrorContainer();
      },
    );

    // Apply border radius if specified
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Process the URL to work around CORS issues
  String _processUrl(String url) {
    if (!kIsWeb) {
      return url; // No processing needed for mobile
    }

    // For web, we need to work around CORS issues
    
    // Option 1: Use ImgProxy approach (more reliable)
    // This uses a free service that doesn't require registration
    String processedUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}';
    
    // Option 2: Use AllOrigins proxy (alternative)
    // processedUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
    
    // Option 3: Add cache-busting parameter (if the above doesn't work)
    // final timestamp = DateTime.now().millisecondsSinceEpoch;
    // processedUrl = '$url${url.contains('?') ? '&' : '?'}t=$timestamp';
    
    debugPrint('Using image proxy: $processedUrl');
    return processedUrl;
  }

  Widget _buildLoadingIndicator() {
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContainer() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: borderRadius,
      ),
      child: errorWidget ?? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 24,
              color: Colors.grey.shade500,
            ),
            if (height != null && height! > 50) ...[
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
  }
}
