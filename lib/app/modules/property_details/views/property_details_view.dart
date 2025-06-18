import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/property_controller.dart';
import '../../../controllers/visits_controller.dart';
import '../../../data/models/property_model.dart';
import '../../../utils/app_colors.dart';

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
      final controller = Get.find<PropertyController>();
      property = controller.getPropertyById(arguments);
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
            'Property Details',
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
                      'Share',
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
                itemCount: safeProperty.images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    safeProperty.images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.inputBackground,
                        child: Icon(
                          Icons.image, 
                          size: 50, 
                          color: AppColors.disabledColor,
                        ),
                      );
                    },
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
                                  '₹${safeProperty.price.toStringAsFixed(0)}',
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
                              safeProperty.propertyType,
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
                              safeProperty.address,
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
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFeature(Icons.bed, '${safeProperty.bedrooms}', 'Bedrooms'),
                          _buildFeature(Icons.bathtub_outlined, '${safeProperty.bathrooms}', 'Bathrooms'),
                          _buildFeature(Icons.square_foot, '${safeProperty.area.toInt()}', 'Sq Ft'),
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
                       safeProperty.description,
                       style: TextStyle(
                         fontSize: 16,
                         color: AppColors.textSecondary,
                         height: 1.5,
                       ),
                     ),
                     const SizedBox(height: 24),
                     
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
                      children: safeProperty.amenities.map((amenity) {
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
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // 360° Tour Button
                    if (safeProperty.tour360Url != null && safeProperty.tour360Url!.isNotEmpty)
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Get.toNamed('/tour', arguments: safeProperty.tour360Url);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.threesixty),
                              label: const Text(
                                'View 360° Tour',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    
                                         // Agent Information
                     Text(
                       'Property Agent',
                       style: TextStyle(
                         fontSize: 20,
                         fontWeight: FontWeight.bold,
                         color: AppColors.textPrimary,
                       ),
                     ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primaryYellow,
                            backgroundImage: safeProperty.agentImage.isNotEmpty
                                ? NetworkImage(safeProperty.agentImage)
                                : null,
                            child: safeProperty.agentImage.isEmpty
                                ? Text(
                                    safeProperty.agentName.isNotEmpty 
                                        ? safeProperty.agentName[0].toUpperCase() 
                                        : 'A',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                                                 Text(
                                   safeProperty.agentName,
                                   style: TextStyle(
                                     fontSize: 18,
                                     fontWeight: FontWeight.bold,
                                     color: AppColors.textPrimary,
                                   ),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   safeProperty.agentPhone,
                                   style: TextStyle(
                                     fontSize: 14,
                                     color: AppColors.textSecondary,
                                   ),
                                 ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Get.snackbar(
                                'Call Agent',
                                'Calling ${safeProperty.agentName}',
                                snackPosition: SnackPosition.TOP,
                              );
                            },
                            icon: const Icon(Icons.phone, color: AppColors.accentGreen),
                          ),
                        ],
                      ),
                    ),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.snackbar(
                    'Contact Agent',
                    'Contacting ${safeProperty.agentName}',
                    snackPosition: SnackPosition.TOP,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryYellow),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.message, color: AppColors.primaryYellow),
                label: const Text(
                  'Contact',
                  style: TextStyle(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
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
          ],
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