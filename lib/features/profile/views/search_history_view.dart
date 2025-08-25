import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/mixins/theme_mixin.dart';

class SearchHistoryView extends StatelessWidget with ThemeMixin {
  const SearchHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'Search History',
      actions: [
        IconButton(
          icon: Icon(Icons.clear_all, color: AppColors.iconColor),
          onPressed: () => _showClearAllDialog(),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Statistics
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Search Statistics'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.search,
                          title: 'Total Searches',
                          value: '247',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.calendar_today,
                          title: 'This Month',
                          value: '32',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.trending_up,
                          title: 'Most Searches',
                          value: 'New York',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.schedule,
                          title: 'Last Search',
                          value: '2 hours ago',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Recent Searches
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildSectionTitle('Recent Searches'),
                      TextButton(
                        onPressed: () => _showClearRecentDialog(),
                        child: Text(
                          'Clear Recent',
                          style: TextStyle(
                            color: AppColors.primaryYellow,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSearchItem(
                    query: 'Luxury apartments Manhattan',
                    timestamp: '2 hours ago',
                    results: '24 properties found',
                    onTap: () => _repeatSearch('Luxury apartments Manhattan'),
                    onDelete: () => _deleteSearchItem('recent_1'),
                  ),
                  _buildSearchItem(
                    query: '3 bedroom house Brooklyn',
                    timestamp: '1 day ago',
                    results: '18 properties found',
                    onTap: () => _repeatSearch('3 bedroom house Brooklyn'),
                    onDelete: () => _deleteSearchItem('recent_2'),
                  ),
                  _buildSearchItem(
                    query: 'Studio apartment under \$2000',
                    timestamp: '2 days ago',
                    results: '45 properties found',
                    onTap: () => _repeatSearch('Studio apartment under \$2000'),
                    onDelete: () => _deleteSearchItem('recent_3'),
                  ),
                  _buildSearchItem(
                    query: 'Pet-friendly apartments Queens',
                    timestamp: '1 week ago',
                    results: '31 properties found',
                    onTap: () => _repeatSearch('Pet-friendly apartments Queens'),
                    onDelete: () => _deleteSearchItem('recent_4'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Saved Searches
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Saved Searches'),
                  const SizedBox(height: 16),
                  _buildSavedSearchItem(
                    title: 'Downtown Loft',
                    query: 'Loft apartments in Downtown NYC under \$3000',
                    notifications: true,
                    lastUpdate: '3 new properties',
                    onTap: () => _viewSavedSearch('saved_1'),
                    onToggleNotifications: () => _toggleNotifications('saved_1'),
                    onDelete: () => _deleteSavedSearch('saved_1'),
                  ),
                  _buildSavedSearchItem(
                    title: 'Family Home Westchester',
                    query: '4+ bedroom houses in Westchester County',
                    notifications: false,
                    lastUpdate: 'No new properties',
                    onTap: () => _viewSavedSearch('saved_2'),
                    onToggleNotifications: () => _toggleNotifications('saved_2'),
                    onDelete: () => _deleteSavedSearch('saved_2'),
                  ),
                  _buildSavedSearchItem(
                    title: 'Affordable Studio',
                    query: 'Studio apartments under \$1500 in Manhattan',
                    notifications: true,
                    lastUpdate: '1 new property',
                    onTap: () => _viewSavedSearch('saved_3'),
                    onToggleNotifications: () => _toggleNotifications('saved_3'),
                    onDelete: () => _deleteSavedSearch('saved_3'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Search Filters History
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Popular Filters'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('2-3 Bedrooms', () => _applyFilter('bedrooms')),
                      _buildFilterChip('\$1500-2500', () => _applyFilter('price')),
                      _buildFilterChip('Pet Friendly', () => _applyFilter('pets')),
                      _buildFilterChip('Parking Included', () => _applyFilter('parking')),
                      _buildFilterChip('Gym/Fitness', () => _applyFilter('gym')),
                      _buildFilterChip('Washer/Dryer', () => _applyFilter('laundry')),
                      _buildFilterChip('Manhattan', () => _applyFilter('manhattan')),
                      _buildFilterChip('Brooklyn', () => _applyFilter('brooklyn')),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Search Settings
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Search Settings'),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.auto_delete, color: AppColors.iconColor),
                    title: Text(
                      'Auto-Delete History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Automatically delete search history after 30 days',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Switch(
                      value: true,
                      onChanged: (_) => _toggleAutoDelete(),
                      activeColor: AppColors.switchActive,
                      activeTrackColor: AppColors.switchTrackActive,
                      inactiveThumbColor: AppColors.switchInactive,
                      inactiveTrackColor: AppColors.switchTrackInactive,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: Icon(Icons.trending_up, color: AppColors.iconColor),
                    title: Text(
                      'Search Suggestions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Show suggestions based on search history',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Switch(
                      value: true,
                      onChanged: (_) => _toggleSearchSuggestions(),
                      activeColor: AppColors.switchActive,
                      activeTrackColor: AppColors.switchTrackActive,
                      inactiveThumbColor: AppColors.switchInactive,
                      inactiveTrackColor: AppColors.switchTrackInactive,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primaryYellow,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchItem({
    required String query,
    required String timestamp,
    required String results,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryYellow.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.search,
          color: AppColors.primaryYellow,
          size: 20,
        ),
      ),
      title: Text(
        query,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            results,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timestamp,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton(
        icon: Icon(Icons.more_vert, color: AppColors.iconColor),
        color: AppColors.surface,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'repeat',
            child: Row(
              children: [
                Icon(Icons.replay, color: AppColors.iconColor),
                const SizedBox(width: 12),
                Text(
                  'Repeat Search',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: AppColors.errorRed),
                const SizedBox(width: 12),
                Text(
                  'Delete',
                  style: TextStyle(color: AppColors.errorRed),
                ),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'repeat') {
            onTap();
          } else if (value == 'delete') {
            onDelete();
          }
        },
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSavedSearchItem({
    required String title,
    required String query,
    required bool notifications,
    required String lastUpdate,
    required VoidCallback onTap,
    required VoidCallback onToggleNotifications,
    required VoidCallback onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      elevation: 2,
      shadowColor: AppColors.shadowColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        notifications ? Icons.notifications : Icons.notifications_off,
                        color: notifications ? AppColors.primaryYellow : AppColors.iconColor,
                        size: 20,
                      ),
                      onPressed: onToggleNotifications,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: AppColors.errorRed,
                        size: 20,
                      ),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              query,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    lastUpdate,
                    style: TextStyle(
                      fontSize: 12,
                      color: lastUpdate.contains('new') 
                          ? AppColors.successGreen
                          : AppColors.textTertiary,
                      fontWeight: lastUpdate.contains('new')
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  child: Text(
                    'View Results',
                    style: TextStyle(
                      color: AppColors.primaryYellow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryYellow.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryYellow.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primaryYellow,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Action methods
  void _showClearAllDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Clear All Search History',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to clear all your search history? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Search History Cleared',
                'All search history has been cleared',
                backgroundColor: AppColors.snackbarBackground,
                colorText: AppColors.snackbarText,
              );
            },
            child: Text(
              'Clear All',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearRecentDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Clear Recent Searches',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Clear recent search history?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Recent Searches Cleared',
                'Recent search history has been cleared',
                backgroundColor: AppColors.snackbarBackground,
                colorText: AppColors.snackbarText,
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _repeatSearch(String query) {
    Get.snackbar(
      'Repeating Search',
      'Searching for: $query',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _deleteSearchItem(String id) {
    Get.snackbar(
      'Search Deleted',
      'Search item has been removed from history',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _viewSavedSearch(String id) {
    Get.snackbar(
      'Viewing Saved Search',
      'Loading saved search results...',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _toggleNotifications(String id) {
    Get.snackbar(
      'Notifications',
      'Notification settings updated',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _deleteSavedSearch(String id) {
    Get.snackbar(
      'Saved Search Deleted',
      'Saved search has been removed',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _applyFilter(String filter) {
    Get.snackbar(
      'Filter Applied',
      'Applied filter: $filter',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _toggleAutoDelete() {
    Get.snackbar(
      'Auto-Delete',
      'Auto-delete setting updated',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _toggleSearchSuggestions() {
    Get.snackbar(
      'Search Suggestions',
      'Search suggestions setting updated',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }
}