import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/utils/webview_helper.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../../widgets/common/robust_network_image.dart';

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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.propertyCardBackground,
      shadowColor: AppColors.shadowColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  memCacheWidth: 400,
                  memCacheHeight: 200,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        color: isFavourite ? AppColors.favoriteActive : Colors.white,
                      ),
                      onPressed: onFavouriteToggle,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.propertyCardText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        property.formattedPrice,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.propertyCardPrice,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.addressDisplay,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.propertyCardSubtext,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildFeature(
                        Icons.bed,
                        '${property.bedrooms} Beds',
                      ),
                      const SizedBox(width: 16),
                      _buildFeature(
                        Icons.bathtub_outlined,
                        '${property.bathrooms} Baths',
                      ),
                      const SizedBox(width: 16),
                      _buildFeature(
                        Icons.square_foot,
                        '${property.areaSqft} sqft',
                      ),
                    ],
                  ),
                  
                  // 360° Tour Embedded Section
                  if (property.virtualTourUrl != null && property.virtualTourUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.threesixty,
                              size: 20,
                              color: AppColors.primaryYellow,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '360° Virtual Tour',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                Get.toNamed('/tour', arguments: property.virtualTourUrl);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryYellow.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fullscreen,
                                      size: 14,
                                      color: AppColors.primaryYellow,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Fullscreen',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryYellow,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 360° Tour with Gesture Blocking to prevent card swipe interference
                        GestureDetector(
                          // Absorb pan gestures to prevent parent swipe detection
                          onPanStart: (_) {},
                          onPanUpdate: (_) {},
                          onPanEnd: (_) {},
                          child: Container(
                            height: 320,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppColors.getCardShadow(),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _Embedded360Tour(tourUrl: property.virtualTourUrl!),
                            ),
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
        Icon(
          icon, 
          size: 20, 
          color: AppColors.propertyFeatureIcon,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.propertyFeatureText,
            height: 1.4,
          ),
        ),
      ],
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
      controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
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
    
      // Create optimized HTML for embedded Kuula tour
      final htmlContent = '''
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
      </head>
      <body>
        <iframe class="ku-embed" 
                frameborder="0" 
                allow="xr-spatial-tracking; gyroscope; accelerometer" 
                allowfullscreen 
                scrolling="no" 
                src="${widget.tourUrl}">
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
        color: AppColors.inputBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.public_off,
                size: 48,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                '360° Tour Unavailable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Virtual tour could not be loaded',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        WebViewWidget(controller: controller!),
        if (isLoading)
          Container(
            color: AppColors.inputBackground,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primaryYellow,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading 360° Tour...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
} 