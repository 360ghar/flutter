import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/property_controller.dart';
import '../../visits/controllers/visits_controller.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/controller_helper.dart';
import '../../../../widgets/common/robust_network_image.dart';

class PropertyDetailsView extends StatelessWidget {
  const PropertyDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Handle both PropertyModel object and String ID
    final dynamic arguments = Get.arguments;
    PropertyModel? property;
    
    if (arguments is PropertyModel) {
      property = arguments;
    } else if (arguments is String) {
      // For string IDs, we'll need to handle this in a FutureBuilder or similar
      // For now, return error state
      property = null;
    }

    if (property == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBarBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.appBarIcon),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'property_details'.tr,
            style: TextStyle(
              color: AppColors.appBarText, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Property not found',
            style: TextStyle(
              fontSize: 18, 
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Ensure PropertyController is available
    ControllerHelper.ensurePropertyController();
    final controller = Get.find<PropertyController>();
    final visitsController = Get.find<VisitsController>();
    
    // Add null check to ensure property is not null
    final PropertyModel safeProperty = property;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.appBarBackground,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Obx(() => IconButton(
                  icon: Icon(
                    controller.isFavourite(safeProperty.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: controller.isFavourite(safeProperty.id)
                        ? AppColors.favoriteActive
                        : Colors.white,
                  ),
                  onPressed: () {
                    if (controller.isFavourite(safeProperty.id)) {
                      controller.removeFromFavourites(safeProperty.id);
                    } else {
                      controller.addToFavourites(safeProperty.id);
                    }
                  },
                )),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    Get.snackbar(
                      'share_property'.tr,
                      'Sharing ${safeProperty.title}',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppColors.snackbarBackground,
                      colorText: AppColors.snackbarText,
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: PageView.builder(
                itemCount: safeProperty.images?.length ?? 0,
                itemBuilder: (context, index) {
                  return RobustNetworkImage(
                    imageUrl: safeProperty.images?[index].imageUrl ?? safeProperty.mainImage,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: AppColors.inputBackground,
                      child: Icon(
                        Icons.image, 
                        size: 50, 
                        color: AppColors.disabledColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Property Details Content
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.scaffoldBackground,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price and Title
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.getCardShadow(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${safeProperty.getEffectivePrice().toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.propertyCardPrice,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  safeProperty.title,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              safeProperty.propertyTypeString,
                              style: TextStyle(
                                color: AppColors.buttonText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Address and Location
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.getCardShadow(),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on, 
                            color: AppColors.iconColor, 
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              safeProperty.addressDisplay,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Property Features
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.getCardShadow(),
                      ),
                      child: Column(
                        children: [
                          // Primary features row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (safeProperty.bedrooms != null)
                                _buildFeature(Icons.bed, '${safeProperty.bedrooms}', 'Bedrooms'),
                              if (safeProperty.bathrooms != null)
                                _buildFeature(Icons.bathtub_outlined, '${safeProperty.bathrooms}', 'Bathrooms'),
                              if (safeProperty.areaSqft != null)
                                _buildFeature(Icons.square_foot, '${safeProperty.areaSqft?.toInt()}', 'Sq Ft'),
                            ],
                          ),
                          
                          // Secondary features row
                          if (safeProperty.balconies != null || safeProperty.parkingSpaces != null || safeProperty.floorNumber != null) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                if (safeProperty.balconies != null)
                                  _buildFeature(Icons.balcony, '${safeProperty.balconies}', 'Balconies'),
                                if (safeProperty.parkingSpaces != null)
                                  _buildFeature(Icons.local_parking, '${safeProperty.parkingSpaces}', 'Parking'),
                                if (safeProperty.floorNumber != null)
                                  _buildFeature(Icons.layers, '${safeProperty.floorNumber}/${safeProperty.totalFloors ?? "?"}', 'Floor'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                                         // Description
                     Text(
                       'Description',
                       style: TextStyle(
                         fontSize: 20,
                         fontWeight: FontWeight.bold,
                         color: AppColors.textPrimary,
                       ),
                     ),
                     const SizedBox(height: 12),
                     Text(
                       safeProperty.description ?? 'No description available',
                       style: TextStyle(
                         fontSize: 16,
                         color: AppColors.textSecondary,
                         height: 1.5,
                       ),
                     ),
                     const SizedBox(height: 24),
                     
                     // Additional Property Information
                     _buildPropertyInfoSection(safeProperty),
                     const SizedBox(height: 24),
                     
                     // Pricing Details
                     _buildPricingSection(safeProperty),
                     const SizedBox(height: 24),
                     
                     // Owner/Agent Information
                     if (safeProperty.hasOwner || safeProperty.builderName?.isNotEmpty == true) ...[
                       _buildContactSection(safeProperty),
                       const SizedBox(height: 24),
                     ],
                     
                     // Amenities
                     Text(
                       'Amenities',
                       style: TextStyle(
                         fontSize: 20,
                         fontWeight: FontWeight.bold,
                         color: AppColors.textPrimary,
                       ),
                     ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: safeProperty.amenities?.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
                          ),
                                                     child: Text(
                             amenity,
                             style: TextStyle(
                               color: AppColors.textPrimary,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                        );
                      }).toList() ?? [],
                    ),
                    const SizedBox(height: 24),
                    
                    // 360° Tour Embedded Section
                    if (safeProperty.virtualTourUrl != null && safeProperty.virtualTourUrl!.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.threesixty,
                                size: 24,
                                color: AppColors.primaryYellow,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '360° Virtual Tour',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              Get.toNamed('/tour', arguments: safeProperty.virtualTourUrl);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fullscreen,
                                    size: 16,
                                    color: AppColors.primaryYellow,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Fullscreen View',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primaryYellow,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 450,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.getCardShadow(),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _Embedded360TourDetails(tourUrl: safeProperty.virtualTourUrl!),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    const SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showBookVisitDialog(context, safeProperty, visitsController),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.calendar_today),
            label: const Text(
              'Book Visit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primaryYellow),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyInfoSection(PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Property Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Status', property.statusString),
          _buildInfoRow('Purpose', property.purposeString),
          if (property.ageText.isNotEmpty)
            _buildInfoRow('Age', property.ageText),
          if (property.maxOccupancy != null)
            _buildInfoRow('Max Occupancy', '${property.maxOccupancy} people'),
          if (property.minimumStayDays != null)
            _buildInfoRow('Minimum Stay', '${property.minimumStayDays} days'),
          if (property.availableFrom?.isNotEmpty == true)
            _buildInfoRow('Available From', property.availableFrom!),
        ],
      ),
    );
  }

  Widget _buildPricingSection(PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: AppColors.primaryYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pricing Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Base Price', '₹${property.basePrice.toStringAsFixed(0)}'),
          if (property.monthlyRent != null)
            _buildInfoRow('Monthly Rent', '₹${property.monthlyRent!.toStringAsFixed(0)}'),
          if (property.dailyRate != null)
            _buildInfoRow('Daily Rate', '₹${property.dailyRate!.toStringAsFixed(0)}'),
          if (property.securityDeposit != null)
            _buildInfoRow('Security Deposit', '₹${property.securityDeposit!.toStringAsFixed(0)}'),
          if (property.maintenanceCharges != null)
            _buildInfoRow('Maintenance', '₹${property.maintenanceCharges!.toStringAsFixed(0)}'),
          if (property.pricePerSqft != null)
            _buildInfoRow('Price per Sq Ft', '₹${property.pricePerSqft!.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildContactSection(PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone, color: AppColors.primaryYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (property.hasOwner) ...[
            _buildInfoRow('Owner', property.ownerDisplayName),
            if (property.hasOwnerContact)
              _buildInfoRow('Contact', property.ownerContact!),
          ],
          if (property.builderName?.isNotEmpty == true)
            _buildInfoRow('Builder', property.builderName!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookVisitDialog(BuildContext context, PropertyModel safeProperty, VisitsController visitsController) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Book Property Visit',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Schedule a visit to ${safeProperty.title}',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Date Selection
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppColors.primaryYellow),
                  title: Text(
                    'Date',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                
                // Time Selection
                ListTile(
                  leading: const Icon(Icons.access_time, color: AppColors.primaryYellow),
                  title: Text(
                    'Time',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    selectedTime.format(context),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final visitDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
              
              visitsController.bookVisit(safeProperty, visitDateTime);
              Get.back();
              
              Get.snackbar(
                'Visit Booked!',
                'Your visit to ${safeProperty.title} is scheduled for ${selectedDate.day}/${selectedDate.month} at ${selectedTime.format(context)}',
                snackPosition: SnackPosition.TOP,
                backgroundColor: AppColors.accentGreen,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('Book Visit'),
          ),
        ],
      ),
    );
  }
}

class _Embedded360TourDetails extends StatefulWidget {
  final String tourUrl;
  
  const _Embedded360TourDetails({required this.tourUrl});
  
  @override
  State<_Embedded360TourDetails> createState() => _Embedded360TourDetailsState();
}

class _Embedded360TourDetailsState extends State<_Embedded360TourDetails> {
  late final WebViewController controller;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
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
            if (mounted) {
              setState(() {
                isLoading = false;
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
    
    controller.loadHtmlString(htmlContent);
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (isLoading)
          Container(
            color: AppColors.inputBackground,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primaryYellow,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading 360° Tour...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
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