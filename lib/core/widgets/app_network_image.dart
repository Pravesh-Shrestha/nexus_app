import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return errorWidget ?? const Icon(Icons.broken_image, color: Colors.grey);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? Container(
        width: width,
        height: height,
        color: Colors.white10,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white30),
          ),
        ),
      ),
      errorWidget: (context, url, error) => errorWidget ?? const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

ImageProvider appNetworkImageProvider(String url) {
  if (url.isEmpty || !url.startsWith('http')) {
    return const AssetImage('assets/images/splash/Frame.png'); // Fallback placeholder asset
  }
  return CachedNetworkImageProvider(url);
}
