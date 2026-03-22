import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/design/app_design_tokens.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/webview_helper.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isFavourite;
  final VoidCallback onFavouriteToggle;
  final VoidCallback onTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.isFavourite,
    required this.onFavouriteToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppDesign.propertyCardBackground,
      shadowColor: AppDesign.shadowColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevent unbounded height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                RobustNetworkImage(
                  imageUrl: property.mainImage,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppBorderRadius.card),
                  ),
                  memCacheWidth: 400,
                  memCacheHeight: 200,
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppDesignTokens.neutral900.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        color: isFavourite ? AppDesign.favoriteActive : colorScheme.onPrimary,
                      ),
                      onPressed: onFavouriteToggle,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Prevent unbounded height
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppDesign.propertyCardText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        property.formattedPrice,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppDesign.propertyCardPrice,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    property.shortAddressDisplay,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppDesign.propertyCardSubtext,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _buildFeature(Icons.bed, '${property.bedrooms} ${'bedrooms'.tr}'),
                      const SizedBox(width: AppSpacing.md),
                      _buildFeature(
                        Icons.bathtub_outlined,
                        '${property.bathrooms} ${'bathrooms'.tr}',
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _buildFeature(Icons.square_foot, '${property.areaSqft} ${'sqft'.tr}'),
                    ],
                  ),
                  if (property.hasAnyMedia) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (property.hasPhotos) _mediaBadge(Icons.photo_library, 'images'.tr),
                        if (property.hasVideos || property.hasVideoTour)
                          _mediaBadge(Icons.videocam, 'video'.tr),
                        if (property.hasVirtualTour) _mediaBadge(Icons.threesixty, '360\u00b0'),
                        if (property.hasStreetView) _mediaBadge(Icons.streetview, 'street_view'.tr),
                        if (property.hasFloorPlan) _mediaBadge(Icons.apartment, 'floor_plan'.tr),
                      ],
                    ),
                  ],

                  // 360° Tour Embedded Section
                  if (property.virtualTourUrl != null && property.virtualTourUrl!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.threesixty, size: 20, color: AppDesign.primaryYellow),
                            const SizedBox(width: 8),
                            Text(
                              'virtual_tour_title'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppDesign.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                Get.toNamed(AppRoutes.tour, arguments: property.virtualTourUrl);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppDesign.primaryYellow.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppDesign.primaryYellow.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.fullscreen,
                                      size: 14,
                                      color: AppDesign.primaryYellow,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'fullscreen_mode'.tr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppDesign.primaryYellow,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // 360° Tour preview (WebView claims gestures via eager recognizers)
                        Container(
                          height: 320,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppDesign.border),
                            boxShadow: AppDesign.getCardShadow(),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _Embedded360Tour(tourUrl: property.virtualTourUrl!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppDesign.propertyFeatureIcon),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppDesign.propertyFeatureText, height: 1.4),
        ),
      ],
    );
  }

  Widget _mediaBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppDesign.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppDesign.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppDesign.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppDesign.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Embedded360Tour extends StatefulWidget {
  final String tourUrl;

  const _Embedded360Tour({required this.tourUrl});

  @override
  State<_Embedded360Tour> createState() => _Embedded360TourState();
}

class _Embedded360TourState extends State<_Embedded360Tour> {
  WebViewController? controller;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      WebViewHelper.ensureInitialized();
      const consoleSilencer = '''
        if (window && window.console) {
          window.console.log = function() {};
          window.console.warn = function() {};
          window.console.error = function() {};
          window.console.info = function() {};
          window.console.debug = function() {};
        }
      ''';

      controller = WebViewHelper.createBaseController();
      controller!
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  isLoading = true;
                });
              }
              controller!.runJavaScript(consoleSilencer);
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  isLoading = false;
                });
              }
              controller!.runJavaScript(consoleSilencer);
            },
            onWebResourceError: (WebResourceError error) {
              DebugLogger.warning('WebView error in 360° tour: ${error.description}');
              if (mounted) {
                setState(() {
                  isLoading = false;
                  hasError = true;
                });
              }
            },
          ),
        );

      final sanitizedUrl = widget.tourUrl;
      final htmlContent =
          '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            margin: 0;
            padding: 0;
            background: #f0f0f0;
            overflow: hidden;
          }
          iframe {
            width: 100vw;
            height: 100vh;
            border: none;
            display: block;
          }
        </style>
        <script type="text/javascript">
          $consoleSilencer
        </script>
      </head>
      <body>
        <iframe class="ku-embed"
                frameborder="0"
                allow="xr-spatial-tracking; gyroscope; accelerometer"
                allowfullscreen
                scrolling="no"
                src="$sanitizedUrl">
        </iframe>
      </body>
      </html>
    ''';

      controller!.loadHtmlString(htmlContent);
    } catch (e, stackTrace) {
      DebugLogger.error('Error initializing WebView for 360° tour', e, stackTrace);
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasError || controller == null) {
      return Container(
        color: AppDesign.inputBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.public_off,
                size: 48,
                color: AppDesign.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'tour_unavailable_title'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppDesign.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'tour_unavailable_body'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: AppDesign.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(
          controller: controller!,
          gestureRecognizers: WebViewHelper.createInteractiveGestureRecognizers(),
        ),
        if (isLoading)
          Container(
            color: AppDesign.inputBackground,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppDesign.primaryYellow, strokeWidth: 2),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'loading_virtual_tour'.tr,
                    style: TextStyle(fontSize: 12, color: AppDesign.textSecondary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
