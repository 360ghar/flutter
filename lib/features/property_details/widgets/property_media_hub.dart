import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/image_cache_service.dart';
import 'package:ghar360/core/utils/theme.dart';
import 'package:ghar360/core/utils/webview_helper.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PropertyMediaBadges extends StatelessWidget {
  const PropertyMediaBadges({super.key, required this.property});

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (property.hasPhotos) _badge(icon: Icons.photo, label: 'images'.tr),
      if (property.hasVideos) _badge(icon: Icons.videocam, label: 'video'.tr),
      if (property.hasVirtualTour) _badge(icon: Icons.threesixty, label: 'virtual_tour_title'.tr),
      if (property.hasStreetView) _badge(icon: Icons.streetview, label: 'street_view'.tr),
      if (property.hasFloorPlan) _badge(icon: Icons.apartment, label: 'floor_plan'.tr),
    ];

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }

  Widget _badge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class PropertyMediaHub extends StatefulWidget {
  const PropertyMediaHub({super.key, required this.property, this.googleMapsApiKey});

  final PropertyModel property;
  final String? googleMapsApiKey;

  @override
  State<PropertyMediaHub> createState() => _PropertyMediaHubState();
}

class _PropertyMediaHubState extends State<PropertyMediaHub> {
  late final List<String> _images;
  bool _prefetching = false;

  @override
  void initState() {
    super.initState();
    _images = widget.property.galleryImageUrls.isNotEmpty
        ? widget.property.galleryImageUrls
        : [widget.property.mainImage];
    _prefetchImages();
  }

  Future<void> _prefetchImages() async {
    if (_prefetching) return;
    _prefetching = true;
    for (final url in _images.take(12)) {
      try {
        await ImageCacheService.instance.preloadImage(url);
        if (mounted) {
          await precacheImage(CachedNetworkImageProvider(url), context);
        }
      } catch (e) {
        DebugLogger.debug('Image prefetch failed for $url: $e');
      }
    }
    if (mounted) {
      setState(() {
        _prefetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final primaryVideo = property.primaryVideoUrl ?? property.mediaVideoUrls.firstOrNull;
    final googleKey = widget.googleMapsApiKey ?? dotenv.env['GOOGLE_PLACES_API_KEY'];

    final sections = <Widget>[];
    void addSection(Widget child) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 16));
      }
      sections.add(child);
    }

    if (property.hasVirtualTour) {
      addSection(_VirtualTourCard(url: property.virtualTourUrl!, thumbnail: property.mainImage));
    }

    addSection(_MediaGalleryCard(images: _images, title: 'gallery'.tr));

    if (property.hasStreetView) {
      addSection(_StreetViewCard(property: property, googleMapsApiKey: googleKey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sections,
        if (property.hasVideos && primaryVideo != null) ...[
          const SizedBox(height: 16),
          _InlineVideoPlayer(
            videoUrl: primaryVideo,
            extraVideos: property.mediaVideoUrls.where((v) => v != primaryVideo).toList(),
          ),
        ],
        if (property.hasFloorPlan) ...[
          const SizedBox(height: 16),
          _FloorPlanCard(imageUrls: property.floorPlanImageUrls),
        ],
      ],
    );
  }
}

class _MediaGalleryCard extends StatefulWidget {
  const _MediaGalleryCard({required this.images, required this.title});

  final List<String> images;
  final String title;

  @override
  State<_MediaGalleryCard> createState() => _MediaGalleryCardState();
}

class _MediaGalleryCardState extends State<_MediaGalleryCard> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: AppColors.shadowColor.withValues(alpha: 0.9),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: PhotoViewGallery.builder(
              itemCount: widget.images.length,
              pageController: PageController(initialPage: initialIndex),
              backgroundDecoration: BoxDecoration(
                color: AppColors.shadowColor.withValues(alpha: 0.9),
              ),
              builder: (context, index) {
                final url = widget.images[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(url),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.5,
                  heroAttributes: PhotoViewHeroAttributes(tag: url),
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
    final hasImages = widget.images.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.getCardShadow(),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library, color: AppColors.primaryYellow, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (hasImages)
                TextButton(onPressed: () => _openViewer(_index), child: Text('view'.tr)),
            ],
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasImages
                  ? Stack(
                      children: [
                        PageView.builder(
                          controller: _controller,
                          itemCount: widget.images.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          itemBuilder: (context, index) {
                            final url = widget.images[index];
                            return CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (context, _) =>
                                  Container(color: AppColors.inputBackground),
                              errorWidget: (context, error, stackTrace) => Container(
                                color: AppColors.inputBackground,
                                child: Icon(Icons.image, color: AppColors.textSecondary),
                              ),
                            );
                          },
                        ),
                        if (widget.images.length > 1)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.shadowColor.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_index + 1}/${widget.images.length}',
                                style: const TextStyle(
                                  color: AppTheme.darkTextPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: AppColors.inputBackground,
                      child: Center(
                        child: Text(
                          'no_images_available'.tr,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
            ),
          ),
          if (hasImages && widget.images.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.images.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = widget.images[index];
                  final isActive = index == _index;
                  return GestureDetector(
                    onTap: () => _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    ),
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive ? AppColors.primaryYellow : AppColors.border,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => Container(color: AppColors.inputBackground),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({required this.videoUrl, required this.extraVideos});

  final String videoUrl;
  final List<String> extraVideos;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(widget.videoUrl);
      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
      );
      _controller = controller;
    } catch (e) {
      DebugLogger.error('Video player init failed', e);
      _error = 'video_load_failed'.tr;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.getCardShadow(),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam, color: AppColors.primaryYellow),
              const SizedBox(width: 8),
              Text(
                'video_tour'.tr,
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              TextButton(onPressed: () => _openExternal(widget.videoUrl), child: Text('open'.tr)),
            ],
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: _controller?.value.aspectRatio ?? 16 / 9,
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _initialize, child: Text('retry'.tr)),
                    ],
                  )
                : _chewieController != null
                ? Chewie(controller: _chewieController!)
                : Container(color: AppColors.inputBackground),
          ),
          if (widget.extraVideos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.extraVideos
                  .map(
                    (url) => ActionChip(
                      label: Text(
                        Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? 'video'.tr,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      avatar: const Icon(Icons.play_circle_fill, size: 18),
                      onPressed: () => _openExternal(url),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _VirtualTourCard extends StatefulWidget {
  const _VirtualTourCard({required this.url, required this.thumbnail});

  final String url;
  final String thumbnail;

  @override
  State<_VirtualTourCard> createState() => _VirtualTourCardState();
}

class _VirtualTourCardState extends State<_VirtualTourCard> {
  WebViewController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final controller = WebViewHelper.createBaseController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _applySensorBlock(controller),
          onPageFinished: (_) {
            _setLoaded();
            _applySensorBlock(controller);
          },
          onWebResourceError: (_) => _setLoaded(),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    // Apply once more right after load in case the tour boots scripts early.
    _applySensorBlock(controller);
    _controller = controller;
  }

  Future<void> _openFullScreen(BuildContext context) async {
    final controller = WebViewHelper.createBaseController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _applySensorBlock(controller),
          onPageFinished: (_) => _applySensorBlock(controller),
          onWebResourceError: (_) {},
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    await showDialog<void>(
      context: context,
      barrierColor: AppColors.shadowColor.withValues(alpha: 0.9),
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: AppColors.shadowColor,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: WebViewWidget(controller: controller)),
              Positioned(
                right: 12,
                top: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.darkTextPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applySensorBlock(WebViewController controller) async {
    const script = '''
      (function() {
        const blocked = new Set(['deviceorientation', 'deviceorientationabsolute', 'devicemotion']);
        const originalAdd = window.addEventListener;
        window.addEventListener = function(type, listener, options) {
          if (blocked.has(type)) return;
          return originalAdd.call(window, type, listener, options);
        };
        blocked.forEach(type => {
          window.addEventListener(type, function(event) {
            event.stopImmediatePropagation();
            event.preventDefault();
            return false;
          }, { capture: true });
        });
        ['ondeviceorientation','ondeviceorientationabsolute','ondevicemotion'].forEach((prop) => {
          try {
            Object.defineProperty(window, prop, { get() { return null; }, set(_) {}, configurable: true });
          } catch (e) {}
        });
      })();
    ''';
    try {
      await controller.runJavaScript(script);
    } catch (e) {
      DebugLogger.debug('Sensor block script failed: $e');
    }
  }

  void _setLoaded() {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.getCardShadow(),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.threesixty, color: AppColors.primaryYellow),
              const SizedBox(width: 8),
              Text(
                'virtual_tour_title'.tr,
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _openFullScreen(context),
                child: Text('fullscreen_mode'.tr),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 520, // Fixed height to prevent shrinking/jumping.
              child: Stack(
                children: [
                  if (_controller != null)
                    WebViewWidget(
                      controller: _controller!,
                      gestureRecognizers: WebViewHelper.createInteractiveGestureRecognizers(),
                    )
                  else
                    RobustNetworkImage(imageUrl: widget.thumbnail, fit: BoxFit.cover),
                  if (_loading)
                    Container(
                      color: AppColors.shadowColor.withValues(alpha: 0.2),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreetViewCard extends StatelessWidget {
  const _StreetViewCard({required this.property, this.googleMapsApiKey});

  final PropertyModel property;
  final String? googleMapsApiKey;

  Future<void> _openStreetView() async {
    final urlString = property.streetViewLaunchUrl;
    if (urlString == null) return;
    final uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staticUrl = property.streetViewStaticImage(googleMapsApiKey ?? '');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.getCardShadow(),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.streetview, color: AppColors.primaryYellow),
              const SizedBox(width: 8),
              Text(
                'street_view'.tr,
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              TextButton(onPressed: _openStreetView, child: Text('open'.tr)),
            ],
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: staticUrl != null
                  ? RobustNetworkImage(imageUrl: staticUrl, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.inputBackground,
                      child: Center(
                        child: Text(
                          'street_view_unavailable'.tr,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorPlanCard extends StatelessWidget {
  const _FloorPlanCard({required this.imageUrls});

  final List<String> imageUrls;

  void _openViewer(BuildContext context, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: AppColors.shadowColor.withValues(alpha: 0.9),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: PhotoViewGallery.builder(
              itemCount: imageUrls.length,
              pageController: PageController(initialPage: initialIndex),
              backgroundDecoration: BoxDecoration(
                color: AppColors.shadowColor.withValues(alpha: 0.9),
              ),
              builder: (context, index) {
                final url = imageUrls[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(url),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.5,
                  heroAttributes: PhotoViewHeroAttributes(tag: url),
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
    final hasImages = imageUrls.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.getCardShadow(),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment, color: AppColors.primaryYellow),
              const SizedBox(width: 8),
              Text(
                'floor_plan'.tr,
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasImages
                  ? GestureDetector(
                      onTap: () => _openViewer(context, 0),
                      child: RobustNetworkImage(imageUrl: imageUrls.first, fit: BoxFit.cover),
                    )
                  : Container(
                      color: AppColors.inputBackground,
                      child: Center(
                        child: Text(
                          'no_floor_plan_uploaded'.tr,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
