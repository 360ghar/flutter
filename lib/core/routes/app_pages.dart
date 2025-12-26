import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/middlewares/auth_middleware.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/features/auth/bindings/auth_binding.dart';
import 'package:ghar360/features/auth/bindings/forgot_password_binding.dart';
import 'package:ghar360/features/auth/bindings/phone_entry_binding.dart';
import 'package:ghar360/features/auth/bindings/profile_completion_binding.dart';
import 'package:ghar360/features/auth/bindings/signup_binding.dart';
import 'package:ghar360/features/auth/views/forgot_password_view.dart';
import 'package:ghar360/features/auth/views/login_view.dart';
import 'package:ghar360/features/auth/views/phone_entry_view.dart';
import 'package:ghar360/features/auth/views/profile_completion_view.dart';
import 'package:ghar360/features/auth/views/signup_view.dart';
import 'package:ghar360/features/dashboard/bindings/dashboard_binding.dart';
import 'package:ghar360/features/dashboard/views/dashboard_view.dart';
import 'package:ghar360/features/discover/bindings/discover_binding.dart';
import 'package:ghar360/features/discover/views/discover_view.dart';
import 'package:ghar360/features/explore/bindings/explore_binding.dart';
import 'package:ghar360/features/explore/views/explore_view.dart';
import 'package:ghar360/features/likes/bindings/likes_binding.dart';
import 'package:ghar360/features/likes/views/likes_view.dart';
import 'package:ghar360/features/location_search/bindings/location_search_binding.dart';
import 'package:ghar360/features/location_search/views/location_search_view.dart';
import 'package:ghar360/features/profile/bindings/feedback_binding.dart';
import 'package:ghar360/features/profile/bindings/profile_binding.dart';
import 'package:ghar360/features/profile/controllers/preferences_controller.dart';
import 'package:ghar360/features/profile/views/about_view.dart';
import 'package:ghar360/features/profile/views/edit_profile_view.dart';
import 'package:ghar360/features/profile/views/feedback_view.dart';
import 'package:ghar360/features/profile/views/help_view.dart';
import 'package:ghar360/features/profile/views/preferences_view.dart';
import 'package:ghar360/features/profile/views/privacy_view.dart';
import 'package:ghar360/features/profile/views/profile_view.dart';
import 'package:ghar360/features/property_details/bindings/property_details_binding.dart';
import 'package:ghar360/features/property_details/views/property_details_view.dart';
import 'package:ghar360/features/splash/bindings/splash_binding.dart';
import 'package:ghar360/features/splash/views/splash_view.dart';
import 'package:ghar360/features/tools/bindings/tools_binding.dart';
import 'package:ghar360/features/tools/views/area_converter_view.dart';
import 'package:ghar360/features/tools/views/capital_gains_view.dart';
import 'package:ghar360/features/tools/views/carpet_area_view.dart';
import 'package:ghar360/features/tools/views/document_checklist_view.dart';
import 'package:ghar360/features/tools/views/emi_calculator_view.dart';
import 'package:ghar360/features/tools/views/loan_eligibility_view.dart';
import 'package:ghar360/features/tools/views/tools_view.dart';
import 'package:ghar360/features/tour/bindings/tour_binding.dart';
import 'package:ghar360/features/tour/views/tour_view.dart';
import 'package:ghar360/features/visits/bindings/visits_binding.dart';
import 'package:ghar360/features/visits/views/visits_view.dart';

// Use package import to ensure middleware classes are resolved correctly

class AppPages {
  // Default page transition settings for consistent animations
  static const Transition _defaultTransition = Transition.fadeIn;
  static const Duration _defaultTransitionDuration = AppDurations.pageTransition;
  static const Curve _defaultCurve = Curves.easeOutCubic;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fade,
      transitionDuration: _defaultTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.phoneEntry,
      page: () => const PhoneEntryView(),
      binding: PhoneEntryBinding(),
      middlewares: [GuestMiddleware()],
      transition: _defaultTransition,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      middlewares: [GuestMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignUpView(),
      binding: SignUpBinding(),
      middlewares: [GuestMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
      middlewares: [GuestMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.profileCompletion,
      page: () => const ProfileCompletionView(),
      binding: ProfileCompletionBinding(),
      transition: _defaultTransition,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      middlewares: [AuthMiddleware()],
      transition: _defaultTransition,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
      children: [
        GetPage(
          name: AppRoutes.discover,
          page: () => const DiscoverView(),
          binding: DiscoverBinding(),
        ),
        GetPage(
          name: AppRoutes.explore,
          page: () => const ExploreView(),
          binding: ExploreBinding(),
        ),
        GetPage(name: AppRoutes.likes, page: () => const LikesView(), binding: LikesBinding()),
        GetPage(name: AppRoutes.visits, page: () => const VisitsView(), binding: VisitsBinding()),
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
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    // Deep link routes - NO AuthMiddleware to allow public access from shared links
    GetPage(
      name: AppRoutes.propertyShortLink, // /p/:id
      page: () => const PropertyDetailsView(),
      binding: PropertyDetailsBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.propertyDeepLink, // /property/:id
      page: () => const PropertyDetailsView(),
      binding: PropertyDetailsBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.tour,
      page: () => const TourView(),
      binding: TourBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.zoom,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.preferences,
      page: () => const PreferencesView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PreferencesController>(() => PreferencesController());
      }),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.privacy,
      page: () => const PrivacyView(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.help,
      page: () => const HelpView(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.feedback,
      page: () => const FeedbackView(),
      binding: FeedbackBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.about,
      page: () => const AboutView(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.locationSearch,
      page: () => const LocationSearchView(),
      binding: LocationSearchBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.downToUp,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    // Tools and calculators
    GetPage(
      name: AppRoutes.tools,
      page: () => const ToolsView(),
      binding: ToolsBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.areaConverter,
      page: () => const AreaConverterView(),
      binding: AreaConverterBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.loanEligibility,
      page: () => const LoanEligibilityView(),
      binding: LoanEligibilityBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.emiCalculator,
      page: () => const EmiCalculatorView(),
      binding: EmiCalculatorBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.carpetArea,
      page: () => const CarpetAreaView(),
      binding: CarpetAreaBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.documentChecklist,
      page: () => const DocumentChecklistView(),
      binding: DocumentChecklistBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
    GetPage(
      name: AppRoutes.capitalGains,
      page: () => const CapitalGainsView(),
      binding: CapitalGainsBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _defaultTransitionDuration,
      curve: _defaultCurve,
    ),
  ];
}
