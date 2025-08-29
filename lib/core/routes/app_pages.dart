import 'package:get/get.dart';
import '../../features/splash/bindings/splash_binding.dart';
import '../../features/splash/views/splash_view.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/bindings/profile_completion_binding.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/profile_completion_view.dart';
import '../../features/dashboard/bindings/dashboard_binding.dart';
import '../../features/dashboard/views/dashboard_view.dart';
import '../../features/discover/bindings/discover_binding.dart';
import '../../features/discover/views/discover_view.dart';
import '../../features/property_details/bindings/property_details_binding.dart';
import '../../features/property_details/views/property_details_view.dart';
import '../../features/profile/bindings/profile_binding.dart';
import '../../features/profile/views/profile_view.dart';
import '../../features/profile/views/edit_profile_view.dart';
import '../../features/profile/views/preferences_view.dart';
import '../../features/profile/views/search_history_view.dart';
import '../../features/profile/views/notifications_view.dart';
import '../../features/profile/views/privacy_view.dart';
import '../../features/profile/views/help_view.dart';
import '../../features/profile/views/about_view.dart';
import '../../features/profile/controllers/preferences_controller.dart';
import '../../features/profile/controllers/search_history_controller.dart';
import '../../features/profile/controllers/notifications_controller.dart';
import '../../features/profile/controllers/privacy_controller.dart';
import '../../features/profile/controllers/help_controller.dart';
import '../../features/profile/controllers/about_controller.dart';
import '../../features/likes/bindings/likes_binding.dart';
import '../../features/likes/views/likes_view.dart';
import '../../features/visits/bindings/visits_binding.dart';
import '../../features/visits/views/visits_view.dart';
import '../../features/explore/bindings/explore_binding.dart';
import '../../features/explore/views/explore_view.dart';
import '../../features/tour/bindings/tour_binding.dart';
import '../../features/tour/views/tour_view.dart';
import '../../features/location_search/views/location_search_view.dart';
import '../../features/location_search/bindings/location_search_binding.dart';
import '../middlewares/auth_middleware.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: AppRoutes.profileCompletion,
      page: () => const ProfileCompletionView(),
      binding: ProfileCompletionBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      middlewares: [AuthMiddleware()],
      children: [
        GetPage(
            name: AppRoutes.discover,
            page: () => const DiscoverView(),
            binding: DiscoverBinding(),
          ),
          GetPage(
            name: AppRoutes.explore,
            page: () => ExploreView(),
            binding: ExploreBinding(),
          ),
          GetPage(
            name: AppRoutes.likes,
            page: () => LikesView(),
            binding: LikesBinding(),
          ),
          GetPage(
            name: AppRoutes.visits,
            page: () => const VisitsView(),
            binding: VisitsBinding(),
          ),
          GetPage(
            name: AppRoutes.profile,
            page: () => const ProfileView(),
            binding: ProfileBinding(),
          ),
        ],
    ),
    // Legacy /home retained only if needed. Prefer /discover
    GetPage(
      name: AppRoutes.propertyDetails,
      page: () => const PropertyDetailsView(),
      binding: PropertyDetailsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.tour,
      page: () => const TourView(),
      binding: TourBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.preferences,
      page: () => const PreferencesView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PreferencesController>(() => PreferencesController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.searchHistory,
      page: () => const SearchHistoryView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SearchHistoryController>(() => SearchHistoryController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<NotificationsController>(() => NotificationsController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.privacy,
      page: () => const PrivacyView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PrivacyController>(() => PrivacyController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.help,
      page: () => const HelpView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HelpController>(() => HelpController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.about,
      page: () => const AboutView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AboutController>(() => AboutController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.locationSearch,
      page: () => const LocationSearchView(),
      binding: LocationSearchBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
} 
