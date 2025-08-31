import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/visits_controller.dart';
import '../../../core/data/models/visit_model.dart';
import '../../../core/utils/app_colors.dart';
import '../widgets/visits_skeleton_loaders.dart';
import '../widgets/visit_card.dart';
import '../widgets/agent_card.dart';

class VisitsView extends StatefulWidget {
  const VisitsView({super.key});

  @override
  State<VisitsView> createState() => _VisitsViewState();
}

class _VisitsViewState extends State<VisitsView> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final VisitsController controller;
  late TabController _tabController;
  bool _isInitialized = false;
  int _currentTab = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    controller = Get.find<VisitsController>();
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _tabController.index;
        });
      }
    });
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Show minimal loading state during initialization
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              Container(height: 48, color: AppColors.scaffoldBackground),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Custom TabBar without heavy DefaultTabController
            _buildCustomTabBar(),
            
            // Relationship Manager Card
            RepaintBoundary(
              child: Container(
                color: AppColors.scaffoldBackground,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildRelationshipManagerCard(),
                ),
              ),
            ),
            
            // Content Area - Simple conditional rendering instead of TabBarView
            Expanded(
              child: _currentTab == 0
                  ? _buildUpcomingVisitsContent()
                  : _buildPastVisitsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      color: AppColors.scaffoldBackground,
      child: TabBar(
        controller: _tabController,
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
                Obx(() {
                  final count = controller.upcomingVisits.length;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: AppColors.buttonText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('past_visits'.tr),
                const SizedBox(width: 8),
                Obx(() {
                  final count = controller.pastVisits.length;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingVisitsContent() {
    return RefreshIndicator(
      onRefresh: controller.refreshVisits,
      child: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingList();
        }

        if (controller.upcomingVisits.isEmpty) {
          return _buildEmptyState(
            'no_visits'.tr,
            'Book a property visit to see it here',
            Icons.calendar_today_outlined,
            AppColors.primaryYellow,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.upcomingVisits.length,
          itemBuilder: (context, index) {
            final visit = controller.upcomingVisits[index];
            return VisitCard(
              visit: visit,
              isUpcoming: true,
              dateText: controller.formatVisitDate(visit.scheduledDate),
              timeText: controller.formatVisitTime(visit.scheduledDate),
              onReschedule: () => _showRescheduleDialog(visit),
              onCancel: () => _showCancelDialog(visit),
            );
          },
        );
      }),
    );
  }

  Widget _buildPastVisitsContent() {
    return RefreshIndicator(
      onRefresh: controller.refreshVisits,
      child: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingList();
        }

        if (controller.pastVisits.isEmpty) {
          return _buildEmptyState(
            'no_visits'.tr,
            'Your completed visits will appear here',
            Icons.history,
            AppColors.iconColor,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.pastVisits.length,
          itemBuilder: (context, index) {
            final visit = controller.pastVisits[index];
            return VisitCard(
              visit: visit,
              isUpcoming: false,
              dateText: controller.formatVisitDate(visit.scheduledDate),
              timeText: controller.formatVisitTime(visit.scheduledDate),
              onReschedule: () => _showRescheduleDialog(visit),
              onCancel: () => _showCancelDialog(visit),
            );
          },
        );
      }),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => const VisitCardSkeleton(),
    );
  }

  Widget _buildRelationshipManagerCard() {
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

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: color),
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
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRescheduleDialog(VisitModel visit) {
    DateTime selectedDate = visit.scheduledDate;
    const defaultHour = 10;
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
                ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryYellow,
                  ),
                  title: const Text('Date'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
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
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
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
            Text(
              'Are you sure you want to cancel your visit to ${visit.propertyTitle}?',
            ),
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
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
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