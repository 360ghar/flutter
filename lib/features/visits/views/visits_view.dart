import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/data/models/visit_model.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/features/visits/controllers/visits_controller.dart';
import 'package:ghar360/features/visits/widgets/agent_card.dart';
import 'package:ghar360/features/visits/widgets/visit_card.dart';
import 'package:ghar360/features/visits/widgets/visits_skeleton_loaders.dart';
import 'package:url_launcher/url_launcher.dart';

// Helpers for launching dialer/WhatsApp with Indian numbers
String _formatIndianNumber(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  // Remove leading zeroes
  String d = digits.replaceFirst(RegExp(r'^0+'), '');
  if (d.startsWith('91') && d.length == 12) {
    return d; // already with country code
  }
  if (d.length == 10) {
    return '91$d';
  }
  // Fallback: if longer than 12, take last 10 as local and prefix 91
  if (d.length > 10) {
    final last10 = d.substring(d.length - 10);
    return '91$last10';
  }
  return d; // may be incomplete; handled by callers
}

Future<void> _launchDialer(String? rawNumber) async {
  final formatted = _formatIndianNumber(rawNumber);
  if (formatted.isEmpty) {
    Get.snackbar('Unavailable', 'Agent contact number not available');
    return;
  }
  // Prefer constructing Uri via scheme/path to ensure proper encoding
  final telUri = Uri(scheme: 'tel', path: '+$formatted');

  // Try external application first (best UX on Android)
  try {
    final launched = await launchUrl(telUri, mode: LaunchMode.externalApplication);
    if (launched) return;
  } catch (_) {}

  // Fallback to platform default
  try {
    final launched = await launchUrl(telUri, mode: LaunchMode.platformDefault);
    if (launched) return;
  } catch (_) {}

  // iOS-specific fallback using telprompt (older behavior)
  if (GetPlatform.isIOS) {
    final telPromptUri = Uri(scheme: 'telprompt', path: '+$formatted');
    try {
      final launched = await launchUrl(telPromptUri, mode: LaunchMode.platformDefault);
      if (launched) return;
    } catch (_) {}
  }

  // Final fallback: try without '+' (some OEM dialers handle E.164 poorly)
  final plainTelUri = Uri(scheme: 'tel', path: formatted);
  try {
    final launched = await launchUrl(plainTelUri, mode: LaunchMode.platformDefault);
    if (launched) return;
  } catch (_) {}

  Get.snackbar('Action Failed', 'Could not open phone dialer');
}

Future<void> _launchWhatsApp(String? rawNumber) async {
  final formatted = _formatIndianNumber(rawNumber);
  if (formatted.isEmpty) {
    Get.snackbar('Unavailable', 'Agent contact number not available');
    return;
  }
  // Use wa.me to reliably open WhatsApp if installed, else browser
  final uri = Uri.parse('https://wa.me/$formatted');
  final ok = await canLaunchUrl(uri);
  if (!ok) {
    Get.snackbar('Action Failed', 'Could not open WhatsApp');
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

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
                    labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                            Obx(
                              () => controller.upcomingVisits.isNotEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
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
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('past_visits'.tr),
                            const SizedBox(width: 8),
                            Obx(
                              () => controller.pastVisits.isNotEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
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
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle background refresh indicator (like other pages)
                Obx(
                  () => controller.isBackgroundRefreshing.value
                      ? const LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                        )
                      : const SizedBox.shrink(),
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
        Container(height: 48, color: AppColors.scaffoldBackground),

        // Agent skeleton loader
        Container(
          color: AppColors.scaffoldBackground,
          child: const Padding(padding: EdgeInsets.all(20), child: RelationshipManagerSkeleton()),
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
      child: Column(children: List.generate(3, (index) => const VisitCardSkeleton())),
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
              DebugLogger.info(
                '🖼️ Building Upcoming tab | count=${controller.upcomingVisits.length}',
              );
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
                    .map(
                      (visit) => VisitCard(
                        visit: visit,
                        isUpcoming: true,
                        dateText: controller.formatVisitDate(visit.scheduledDate),
                        timeText: controller.formatVisitTime(visit.scheduledDate),
                        onTap: () {
                          if (visit.property != null) {
                            Get.toNamed(AppRoutes.propertyDetails, arguments: visit.property);
                          }
                        },
                        onReschedule: () => _showRescheduleDialog(visit),
                        onCancel: () => _showCancelDialog(visit),
                      ),
                    )
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
              DebugLogger.info('🖼️ Building Past tab | count=${controller.pastVisits.length}');
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
                    .map(
                      (visit) => VisitCard(
                        visit: visit,
                        isUpcoming: false,
                        dateText: controller.formatVisitDate(visit.scheduledDate),
                        timeText: controller.formatVisitTime(visit.scheduledDate),
                        onTap: () {
                          if (visit.property != null) {
                            Get.toNamed(AppRoutes.propertyDetails, arguments: visit.property);
                          }
                        },
                        onReschedule: () => _showRescheduleDialog(visit),
                        onCancel: () => _showCancelDialog(visit),
                      ),
                    )
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
          _launchDialer(agent.contactNumber);
        },
        onWhatsApp: () {
          _launchWhatsApp(agent.contactNumber);
        },
      );
    });
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
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
    );
  }

  void _showRescheduleDialog(VisitModel visit) {
    DateTime selectedDate = visit.scheduledDate;
    const defaultHour = 10; // Use default time (10:00 AM)
    const defaultMinute = 0;

    Get.dialog(
      AlertDialog(
        title: Text('reschedule_visit'.tr),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${'reschedule_visit_to_prefix'.tr} ${visit.propertyTitle}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Date Selection
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppColors.primaryYellow),
                  title: Text('date'.tr),
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
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
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
            child: Text('reschedule'.tr),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(VisitModel visit) {
    final TextEditingController reasonController = TextEditingController();
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          final canSubmit = reasonController.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text('cancel_visit'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${'cancel_visit_confirm_prefix'.tr} ${visit.propertyTitle}?'),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'reason_required_label'.tr,
                    hintText: 'reason_required_hint'.tr,
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
              TextButton(onPressed: () => Get.back(), child: Text('no'.tr)),
              ElevatedButton(
                onPressed: canSubmit
                    ? () {
                        final reason = reasonController.text.trim();
                        controller.cancelVisit(visit.id.toString(), reason: reason);
                        Get.back();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: Text('yes_cancel'.tr),
              ),
            ],
          );
        },
      ),
    );
  }
}
