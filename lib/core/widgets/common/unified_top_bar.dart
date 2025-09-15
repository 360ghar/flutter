import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/core/controllers/page_state_service.dart';
import 'package:ghar360/core/data/models/page_state_model.dart';
import 'package:ghar360/core/widgets/common/location_selector.dart';
import 'package:ghar360/core/widgets/common/property_filter_widget.dart';

class UnifiedTopBar extends GetView<PageStateService>
    implements PreferredSizeWidget {
  final PageType pageType;
  final String title;
  final bool showSearch;
  final Function(String)? onSearchChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSearchClear;
  final List<Widget>? additionalActions;
  final PreferredSizeWidget? bottom;

  const UnifiedTopBar({
    super.key,
    required this.pageType,
    required this.title,
    this.showSearch = true,
    this.onSearchChanged,
    this.onFilterTap,
    this.onSearchClear,
    this.additionalActions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Determine bottom search row visibility
      final bool supportsSearch = _shouldShowSearch();
      final bool searchVisible =
          supportsSearch && controller.isSearchVisible(pageType);

      final PreferredSizeWidget? bottomWidget = searchVisible
          ? _buildBottomSearchBar(controller)
          : bottom; // fallback to injected bottom

      return AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        automaticallyImplyLeading: false,
        toolbarHeight: kToolbarHeight,
        titleSpacing: 16,
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              ),
        title: Row(
          children: [
            // Location selector
            LocationSelector(pageType: pageType),

            const Spacer(),

            // Search toggle (only for Explore and Likes)
            if (supportsSearch) _buildSearchToggle(controller),

            // Refreshing spinner (small)
            _buildRefreshIndicator(controller),

            // Filter button
            _buildFilterButton(context, controller),

            // Additional actions
            if (additionalActions != null) ...additionalActions!,
          ],
        ),
        bottom: bottomWidget,
      );
    });
  }

  bool _shouldShowSearch() {
    // Only show search for Explore and Likes pages
    return pageType == PageType.explore || pageType == PageType.likes;
  }

  PreferredSizeWidget _buildBottomSearchBar(PageStateService pageStateService) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Obx(() {
        final currentState = _getCurrentPageState(pageStateService);
        final searchQuery = currentState.searchQuery ?? '';
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          color: AppColors.appBarBackground,
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: TextField(
              onChanged: (value) {
                pageStateService.updatePageSearch(pageType, value);
                onSearchChanged?.call(value);
              },
              controller: TextEditingController(text: searchQuery)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: searchQuery.length),
                ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: _getSearchHint(),
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.iconColor,
                  size: 18,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.iconColor,
                          size: 18,
                        ),
                        onPressed: () {
                          pageStateService.clearPageSearch(pageType);
                          onSearchClear?.call();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    PageStateService pageStateService,
  ) {
    return Obx(() {
      final currentState = _getCurrentPageState(pageStateService);
      final activeFiltersCount = currentState.activeFiltersCount;

      return IconButton(
        icon: Stack(
          children: [
            Icon(Icons.tune, color: AppColors.iconColor, size: 24),
            if (activeFiltersCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    activeFiltersCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        onPressed:
            onFilterTap ??
            () =>
                showPropertyFilterBottomSheet(context, pageType: pageType.name),
      );
    });
  }

  Widget _buildSearchToggle(PageStateService pageStateService) {
    return Obx(() {
      final visible = pageStateService.isSearchVisible(pageType);
      return IconButton(
        icon: Icon(
          visible ? Icons.search_off : Icons.search,
          color: AppColors.iconColor,
          size: 22,
        ),
        onPressed: () => pageStateService.toggleSearch(pageType),
      );
    });
  }

  Widget _buildRefreshIndicator(PageStateService pageStateService) {
    return Obx(() {
      final refreshing = pageStateService.isPageRefreshing(pageType);
      if (!refreshing) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
          ),
        ),
      );
    });
  }

  PageStateModel _getCurrentPageState(PageStateService pageStateService) {
    switch (pageType) {
      case PageType.explore:
        return pageStateService.exploreState.value;
      case PageType.discover:
        return pageStateService.discoverState.value;
      case PageType.likes:
        return pageStateService.likesState.value;
    }
  }

  String _getSearchHint() {
    switch (pageType) {
      case PageType.explore:
        return 'Search locations...';
      case PageType.likes:
        return 'Search in your likes...';
      case PageType.discover:
        return 'Search properties...';
    }
  }

  @override
  Size get preferredSize {
    double height = kToolbarHeight;
    final bool supportsSearch = _shouldShowSearch();
    final bool searchVisible =
        supportsSearch && controller.isSearchVisible(pageType);

    if (searchVisible) {
      height += 52; // Add height for search bar
    }
    return Size.fromHeight(height);
  }
}

// Extension for easy integration with existing views
extension UnifiedTopBarBuilder on Widget {
  Widget withUnifiedTopBar({
    required PageType pageType,
    required String title,
    bool showSearch = true,
    Function(String)? onSearchChanged,
    VoidCallback? onFilterTap,
    VoidCallback? onSearchClear,
    List<Widget>? additionalActions,
  }) {
    return Scaffold(
      appBar: UnifiedTopBar(
        pageType: pageType,
        title: title,
        showSearch: showSearch,
        onSearchChanged: onSearchChanged,
        onFilterTap: onFilterTap,
        onSearchClear: onSearchClear,
        additionalActions: additionalActions,
        bottom: null,
      ),
      body: this,
    );
  }
}

// Specialized top bars for different page types
class ExploreTopBar extends UnifiedTopBar {
  const ExploreTopBar({
    super.key,
    super.onSearchChanged,
    super.onFilterTap,
    super.additionalActions,
  }) : super(
         pageType: PageType.explore,
         title: 'Explore Properties',
         showSearch: true,
       );
}

class DiscoverTopBar extends UnifiedTopBar {
  DiscoverTopBar({super.key, super.onFilterTap, super.additionalActions})
    : super(
        pageType: PageType.discover,
        title: 'app_name'.tr,
        showSearch: false, // Discover doesn't have search
      );
}

class LikesTopBar extends UnifiedTopBar {
  const LikesTopBar({
    super.key,
    super.onSearchChanged,
    super.onFilterTap,
    super.additionalActions,
  }) : super(pageType: PageType.likes, title: 'My Likes', showSearch: true);
}
