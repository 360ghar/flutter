import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/utils/image_cache_service.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Image gallery shown in the SliverAppBar of the property details page.
/// Supports page swiping, prefetching, and a full-screen PhotoView overlay.
class PropertyDetailsImageGallery extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailsImageGallery({super.key, required this.property});

  @override
  State<PropertyDetailsImageGallery> createState() => _PropertyDetailsImageGalleryState();
}

class _PropertyDetailsImageGalleryState extends State<PropertyDetailsImageGallery> {
  late final PageController _pageController;
  int _current = 0;
  bool _isPrefetching = false;

  List<String> get _images => widget.property.galleryImageUrls.isNotEmpty
      ? widget.property.galleryImageUrls
      : [widget.property.mainImage];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prefetchImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _prefetchImages() async {
    if (_isPrefetching) return;
    _isPrefetching = true;
    for (final url in _images.take(8)) {
      try {
        await ImageCacheService.instance.preloadImage(url);
        if (!mounted) return;
        await precacheImage(CachedNetworkImageProvider(url), context);
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _isPrefetching = false);
    }
  }

  void _openGallery(int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: AppDesign.shadowColor.withValues(alpha: 0.9),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: PhotoViewGallery.builder(
              itemCount: _images.length,
              pageController: PageController(initialPage: initialIndex),
              backgroundDecoration: BoxDecoration(
                color: AppDesign.shadowColor.withValues(alpha: 0.9),
              ),
              builder: (context, index) {
                final url = _images[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(url),
                  heroAttributes: PhotoViewHeroAttributes(tag: url),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.5,
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final itemCount = images.isNotEmpty ? images.length : 1;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _openGallery(_current),
          child: PageView.builder(
            controller: _pageController,
            itemCount: itemCount,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final url = images.isNotEmpty ? images[index] : widget.property.mainImage;
              return CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, _) => Container(
                  color: AppDesign.inputBackground,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, error, stackTrace) => Container(
                  color: AppDesign.inputBackground,
                  child: Icon(Icons.image, size: 50, color: AppDesign.disabledColor),
                ),
              );
            },
          ),
        ),
        if (itemCount > 1)
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppDesign.shadowColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_current + 1}/$itemCount',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
