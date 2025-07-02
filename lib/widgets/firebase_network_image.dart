import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/admin_theme.dart';

/// A widget that displays images from Firebase Storage with proper error handling for web
class FirebaseNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const FirebaseNetworkImage({
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
  State<FirebaseNetworkImage> createState() => _FirebaseNetworkImageState();
}

class _FirebaseNetworkImageState extends State<FirebaseNetworkImage> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _finalImageUrl;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  @override
  void didUpdateWidget(FirebaseNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }
  
  Future<void> _loadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      String url = widget.imageUrl!;
      
      // If the URL is a Firebase Storage path (not a full URL), get the download URL
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        try {
          final ref = FirebaseStorage.instance.ref().child(url);
          url = await ref.getDownloadURL();
          debugPrint('Converted Firebase Storage path to URL: $url');
        } catch (e) {
          debugPrint('Error getting download URL: $e');
          // Continue with the original URL if this fails
        }
      }
      
      // For web, add a cache-busting parameter
      if (kIsWeb) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        url = '$url?t=$timestamp';
        debugPrint('Using cache-busted URL for web: $url');
      }
      
      setState(() {
        _finalImageUrl = url;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading image: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }
    
    if (_hasError || _finalImageUrl == null) {
      return _buildErrorContainer();
    }

    // Build the image widget
    Widget imageWidget = Image.network(
      _finalImageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error displaying image: $error, URL: $_finalImageUrl');
        return _buildErrorContainer();
      },
      // Disable caching on web
      cacheWidth: kIsWeb ? null : (widget.width != null ? (widget.width! * 2).toInt() : null),
      cacheHeight: kIsWeb ? null : (widget.height != null ? (widget.height! * 2).toInt() : null),
    );

    // Apply border radius if specified
    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: widget.width,
      height: widget.height,
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

  Widget _buildErrorContainer() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: widget.borderRadius,
      ),
      child: widget.errorWidget ?? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 24,
              color: Colors.grey.shade500,
            ),
            if (widget.height != null && widget.height! > 50) ...[
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
