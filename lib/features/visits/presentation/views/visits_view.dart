import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/data/models/visit_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/core/utils/app_toast.dart';
import 'package:ghar360/core/widgets/common/segmented_control.dart';
import 'package:ghar360/features/visits/presentation/controllers/visits_controller.dart';
import 'package:ghar360/features/visits/presentation/widgets/agent_card.dart';
import 'package:ghar360/features/visits/presentation/widgets/visit_card.dart';
import 'package:ghar360/features/visits/presentation/widgets/visits_skeleton_loaders.dart';
import 'package:url_launcher/url_launcher.dart';

String _formatIndianNumber(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  String d = digits.replaceFirst(RegExp(r'^0+'), '');
  if (d.startsWith('91') && d.length == 12) {
    return d;
  }
  if (d.length == 10) {
    return '91$d';
  }
  if (d.length > 10) {
    final last10 = d.substring(d.length - 10);
    return '91$last10';
  }
  return d;
}

Future<void> _launchDialer(String? rawNumber) async {
  final formatted = _formatIndianNumber(rawNumber);
  if (formatted.isEmpty) {
    AppToast.warning('unavailable'.tr, 'agent_contact_unavailable'.tr);
    return;
  }
  final telUri = Uri(scheme: 'tel', path: '+$formatted');

  try {
    final launched = await launchUrl(telUri, mode: LaunchMode.externalApplication);
    if (launched) return;
  } catch (_) {}

  try {
    final launched = await launchUrl(telUri, mode: LaunchMode.platformDefault);
    if (launched) return;
  } catch (_) {}

  if (GetPlatform.isIOS) {
    final telPromptUri = Uri(scheme: 'telprompt', path: '+$formatted');
    try {
      final launched = await launchUrl(telPromptUri, mode: LaunchMode.platformDefault);
      if (launched) return;
    } catch (_) {}
  }

  final plainTelUri = Uri(scheme: 'tel', path: formatted);
  try {
    final launched = await launchUrl(plainTelUri, mode: LaunchMode.platformDefault);
    if (launched) return;
  } catch (_) {}

  AppToast.error('action_failed'.tr, 'could_not_open_phone_dialer'.tr);
}

Future<void> _launchWhatsApp(String? rawNumber) async {
  final formatted = _formatIndianNumber(rawNumber);
  if (formatted.isEmpty) {
    AppToast.warning('unavailable'.tr, 'agent_contact_unavailable'.tr);
    return;
  }
  final uri = Uri.parse('https://wa.me/$formatted');
  final ok = await canLaunchUrl(uri);
  if (!ok) {
    AppToast.error('action_failed'.tr, 'could_not_open_whatsapp'.tr);
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class VisitsView extends GetView<VisitsController> {
  const VisitsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Semantics(
        label: 'qa.visits.screen',
        identifier: 'qa.visits.screen',
        child: Scaffold(
          key: const ValueKey('qa.visits.screen'),
          backgroundColor: AppDesign.scaffoldBackground,
          body: SafeArea(
            child: Obx(() {
              final Widget child;
              final Key key;

              if (controller.isLoading.value) {
                key = const ValueKey('loading');
                child = _buildLoadingState();
              } else {
                key = const ValueKey('content');
                child = _VisitsContent(controller: controller);
              }

              return AnimatedSwitcher(
                duration: AppDurations.contentFade,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: KeyedSubtree(key: key, child: child),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Container(height: 48, color: AppDesign.scaffoldBackground),
        Container(
          color: AppDesign.scaffoldBackground,
          child: const Padding(padding: EdgeInsets.all(20), child: RelationshipManagerSkeleton()),
        ),
        Expanded(child: TabBarView(children: [_buildSkeletonList(), _buildSkeletonList()])),
      ],
    );
  }

  Widget _buildSkeletonList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: List.generate(3, (index) => const VisitCardSkeleton())),
    );
  }
}

class _VisitsContent extends StatefulWidget {
  final VisitsController controller;

  const _VisitsContent({required this.controller});

  @override
  State<_VisitsContent> createState() => _VisitsContentState();
}

class _VisitsContentState extends State<_VisitsContent> {
  TabController? _tabController;

  void _onTabChanged() {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inherited = DefaultTabController.of(context);
    if (inherited != _tabController) {
      _tabController?.removeListener(_onTabChanged);
      _tabController = inherited;
      _tabController!.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _tabController?.index ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            0,
          ),
          child: SegmentedControl(
            selectedIndex: selectedIndex,
            segments: [
              SegmentItem(
                label: 'scheduled_visits'.tr,
                badge: widget.controller.upcomingVisits.length,
                semanticsLabel: 'qa.visits.tab.scheduled',
                semanticsIdentifier: 'qa.visits.tab.scheduled',
              ),
              SegmentItem(
                label: 'past_visits'.tr,
                badge: widget.controller.pastVisits.length,
                semanticsLabel: 'qa.visits.tab.past',
                semanticsIdentifier: 'qa.visits.tab.past',
              ),
            ],
            onSegmentChanged: (index) => _tabController?.animateTo(index),
          ),
        ),
        Obx(
          () => widget.controller.isBackgroundRefreshing.value
              ? const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: AppDesign.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppDesign.primaryYellow),
                )
              : const SizedBox.shrink(),
        ),
        Container(
          color: AppDesign.scaffoldBackground,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: _buildRelationshipManagerCard(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController!,
            children: [_buildUpcomingVisitsTab(), _buildPastVisitsTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingVisitsTab() {
    return RefreshIndicator(
      onRefresh: widget.controller.refreshVisits,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              if (widget.controller.upcomingVisits.isEmpty) {
                return _buildEmptyState('no_visits'.tr, 'no_upcoming_visits_subtitle'.tr);
              }

              return Column(
                children: widget.controller.upcomingVisits
                    .map(
                      (visit) => VisitCard(
                        visit: visit,
                        isUpcoming: true,
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
      onRefresh: widget.controller.refreshVisits,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              if (widget.controller.pastVisits.isEmpty) {
                return _buildEmptyState('no_visits'.tr, 'no_past_visits_subtitle'.tr);
              }

              return Column(
                children: widget.controller.pastVisits
                    .map(
                      (visit) => VisitCard(
                        visit: visit,
                        isUpcoming: false,
                        onTap: () {
                          if (visit.property != null) {
                            Get.toNamed(AppRoutes.propertyDetails, arguments: visit.property);
                          }
                        },
                        onReschedule: () {},
                        onCancel: () {},
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
    return Obx(() {
      if (widget.controller.isLoadingAgent.value) {
        return const RelationshipManagerSkeleton();
      }

      final agent = widget.controller.relationshipManager.value;
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

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      width: double.infinity,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 18,
              color: AppDesign.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: AppDesign.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(VisitModel visit) {
    final now = DateTime.now();
    DateTime selectedDate = visit.scheduledDate.isBefore(now) ? now : visit.scheduledDate;
    TimeOfDay selectedTime = visit.scheduledDate.isBefore(now)
        ? TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)))
        : TimeOfDay.fromDateTime(visit.scheduledDate);
    bool isLoading = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('reschedule_visit'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${'reschedule_visit_to_prefix'.tr} ${visit.propertyTitle}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppDesign.primaryYellow),
                  title: Text('date'.tr),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  onTap: isLoading
                      ? null
                      : () async {
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
                ListTile(
                  leading: const Icon(Icons.access_time, color: AppDesign.primaryYellow),
                  title: Text('time'.tr),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: isLoading
                      ? null
                      : () async {
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
            ),
            actions: [
              TextButton(onPressed: isLoading ? null : () => Get.back(), child: Text('cancel'.tr)),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final newDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        if (newDateTime.isBefore(DateTime.now())) {
                          AppToast.warning('invalid_time'.tr, 'select_future_datetime'.tr);
                          return;
                        }

                        setState(() {
                          isLoading = true;
                        });

                        final success = await widget.controller.rescheduleVisit(
                          visit.id.toString(),
                          newDateTime,
                        );

                        if (success) {
                          Get.back();
                        } else {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.primaryYellow,
                  foregroundColor: AppDesign.buttonText,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('reschedule'.tr),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCancelDialog(VisitModel visit) {
    final TextEditingController reasonController = TextEditingController();
    bool isLoading = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          final canSubmit = reasonController.text.trim().isNotEmpty && !isLoading;
          return AlertDialog(
            title: Text('cancel_visit'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${'cancel_visit_confirm_prefix'.tr} ${visit.propertyTitle}?'),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  enabled: !isLoading,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'reason_required_label'.tr,
                    hintText: 'reason_required_hint'.tr,
                    filled: true,
                    fillColor: AppDesign.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppDesign.border),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: isLoading ? null : () => Get.back(), child: Text('no'.tr)),
              ElevatedButton(
                onPressed: canSubmit
                    ? () async {
                        final reason = reasonController.text.trim();

                        setState(() {
                          isLoading = true;
                        });

                        final success = await widget.controller.cancelVisit(
                          visit.id.toString(),
                          reason: reason,
                        );

                        if (success) {
                          Get.back();
                        } else {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.errorRed,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('yes_cancel'.tr),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      reasonController.dispose();
    });
  }
}
