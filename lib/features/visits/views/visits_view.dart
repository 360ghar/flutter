import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/visits_controller.dart';
import '../../../core/data/models/visit_model.dart';
import '../../../core/utils/app_colors.dart';
import '../widgets/visits_skeleton_loaders.dart';
import '../widgets/visit_card.dart';
import '../widgets/agent_card.dart';

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
    return RefreshIndicator(
      onRefresh: controller.refreshVisits,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    .map((visit) => VisitCard(
                          visit: visit,
                          isUpcoming: true,
                          dateText: controller.formatVisitDate(visit.scheduledDate),
                          timeText: controller.formatVisitTime(visit.scheduledDate),
                          onReschedule: () => _showRescheduleDialog(visit),
                          onCancel: () => _showCancelDialog(visit),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPastVisitsTab() {
    return RefreshIndicator(
      onRefresh: controller.refreshVisits,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    .map((visit) => VisitCard(
                          visit: visit,
                          isUpcoming: false,
                          dateText: controller.formatVisitDate(visit.scheduledDate),
                          timeText: controller.formatVisitTime(visit.scheduledDate),
                          onReschedule: () => _showRescheduleDialog(visit),
                          onCancel: () => _showCancelDialog(visit),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
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
      
      return AgentCard(
        agent: agent,
        onCall: () {
          // Call functionality
        },
        onWhatsApp: () {
          // WhatsApp functionality
        },
      );
    });
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
    const defaultHour = 10; // Use default time (10:00 AM)
    const defaultMinute = 0;
    
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
                
                // Time selection removed; default time will be applied
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
                defaultHour,
                defaultMinute,
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
    final TextEditingController reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Visit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to cancel your visit to ${visit.propertyTitle}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Not available on this date',
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              controller.cancelVisit(
                visit.id.toString(),
                reason: reason.isEmpty ? null : reason,
              );
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
