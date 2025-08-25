import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/visits_controller.dart';
import '../../../core/data/models/visit_model.dart';
import '../../../core/utils/app_colors.dart';
import '../../../../widgets/common/robust_network_image.dart';
import '../widgets/visits_skeleton_loaders.dart';

class VisitsView extends GetView<VisitsController> {
  const VisitsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize data loading once on widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasLoadedVisits.value && !controller.isLoading.value) {
        controller.loadVisitsLazy();
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return _buildLoadingState();
            }

            return Column(
              children: [
                // TabBar at the top
                Container(
                  color: AppColors.scaffoldBackground,
                  child: TabBar(
                    indicatorColor: AppColors.primaryYellow,
                    indicatorWeight: 3,
                    labelColor: AppColors.primaryYellow,
                    unselectedLabelColor: AppColors.tabUnselected,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('scheduled_visits'.tr),
                            const SizedBox(width: 8),
                            Obx(() => controller.upcomingVisits.isNotEmpty
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryYellow,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${controller.upcomingVisits.length}',
                                      style: TextStyle(
                                        color: AppColors.buttonText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink()),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('past_visits'.tr),
                            const SizedBox(width: 8),
                            Obx(() => controller.pastVisits.isNotEmpty
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.inputBackground,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${controller.pastVisits.length}',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Relationship Manager Section - Always visible
                Container(
                  color: AppColors.scaffoldBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildRelationshipManagerCard(),
                  ),
                ),
                
                // Tab Views
                Expanded(
                  child: TabBarView(
                    children: [
                      // Upcoming Visits Tab
                      _buildUpcomingVisitsTab(),
                      
                      // Past Visits Tab
                      _buildPastVisitsTab(),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),

      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // TabBar skeleton
        Container(
          height: 48,
          color: AppColors.scaffoldBackground,
        ),
        
        // Agent skeleton loader
        Container(
          color: AppColors.scaffoldBackground,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: RelationshipManagerSkeleton(),
          ),
        ),
        
        // Tab content skeleton loaders
        Expanded(
          child: TabBarView(
            children: [
              // Upcoming visits skeleton
              _buildSkeletonList(),
              // Past visits skeleton
              _buildSkeletonList(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSkeletonList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          3,
          (index) => const VisitCardSkeleton(),
        ),
      ),
    );
  }

  Widget _buildUpcomingVisitsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (controller.upcomingVisits.isEmpty) {
              return _buildEmptyState(
                'no_visits'.tr,
                'Book a property visit to see it here',
                Icons.calendar_today_outlined,
                AppColors.primaryYellow,
              );
            }
            
            return Column(
              children: controller.upcomingVisits
                  .map((visit) => _buildVisitCard(visit, true))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPastVisitsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (controller.pastVisits.isEmpty) {
              return _buildEmptyState(
                'no_visits'.tr,
                'Your completed visits will appear here',
                Icons.history,
                AppColors.iconColor,
              );
            }
            
            return Column(
              children: controller.pastVisits
                  .map((visit) => _buildVisitCard(visit, false))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRelationshipManagerCard() {
    // Initialize agent data loading once on card build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasLoadedAgent.value && !controller.isLoadingAgent.value) {
        controller.loadRelationshipManagerLazy();
      }
    });

    return Obx(() {
      if (controller.isLoadingAgent.value) {
        return const RelationshipManagerSkeleton();
      }
      
      final agent = controller.relationshipManager.value;
      if (agent == null) {
        return const RelationshipManagerSkeleton();
      }
      
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryYellow.withValues(alpha: 0.1),
              AppColors.primaryYellow.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryYellow.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.support_agent,
                  color: AppColors.primaryYellow,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Relationship Manager',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                RobustNetworkImageExtension.avatar(
                  imageUrl: agent.avatarUrl ?? '',
                  size: 60,
                  placeholder: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(Icons.person, size: 30, color: AppColors.iconColor),
                  ),
                  errorWidget: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(Icons.person, size: 30, color: AppColors.iconColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        agent.experienceLevelString,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: AppColors.primaryYellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            agent.userSatisfactionRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.work_outline,
                            size: 16,
                            color: AppColors.iconColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            agent.experienceLevelString,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Call functionality
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryYellow,
                      side: BorderSide(color: AppColors.primaryYellow),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // WhatsApp functionality
                    },
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: AppColors.buttonText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildVisitCard(VisitModel visit, bool isUpcoming) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RobustNetworkImage(
                imageUrl: '', // Property image not available in new model structure
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
                errorWidget: Container(
                  width: 60,
                  height: 60,
                  color: AppColors.inputBackground,
                  child: Icon(Icons.image, color: AppColors.iconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.propertyTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          controller.formatVisitDate(visit.scheduledDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          controller.formatVisitTime(visit.scheduledDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusChip(visit.status),
            ],
          ),

          if (isUpcoming && visit.status == VisitStatus.scheduled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRescheduleDialog(visit),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryYellow),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Reschedule',
                      style: TextStyle(
                        color: AppColors.primaryYellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCancelDialog(visit),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(VisitStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case VisitStatus.scheduled:
        color = AppColors.primaryYellow;
        text = 'Scheduled';
        break;
      case VisitStatus.confirmed:
        color = AppColors.accentGreen;
        text = 'Confirmed';
        break;
      case VisitStatus.completed:
        color = AppColors.accentGreen;
        text = 'Completed';
        break;
      case VisitStatus.cancelled:
        color = AppColors.errorRed;
        text = 'Cancelled';
        break;
      case VisitStatus.rescheduled:
        color = AppColors.primaryYellow;
        text = 'Rescheduled';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(VisitModel visit) {
    DateTime selectedDate = visit.scheduledDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(visit.scheduledDate);
    
    Get.dialog(
      AlertDialog(
        title: const Text('Reschedule Visit'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reschedule your visit to ${visit.propertyTitle}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                
                // Date Selection
                ListTile(
                  leading: Icon(Icons.calendar_today, color: AppColors.primaryYellow),
                  title: const Text('Date'),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
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
                  leading: Icon(Icons.access_time, color: AppColors.primaryYellow),
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
              
              controller.rescheduleVisit(visit.id.toString(), newDateTime);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.buttonText,
            ),
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(VisitModel visit) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Visit'),
        content: Text('Are you sure you want to cancel your visit to ${visit.propertyTitle}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.cancelVisit(visit.id.toString());
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}