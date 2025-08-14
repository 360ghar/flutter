import 'dart:async';
import 'package:get/get.dart';
import '../../../data/models/property_model.dart';
import '../../../data/providers/api_service.dart';

class LikesController extends GetxController {
  late final ApiService _api;

  // Liked segment state
  final RxList<PropertyModel> likedItems = <PropertyModel>[].obs;
  final RxInt likedPage = 1.obs;
  final RxInt likedTotalPages = 1.obs;
  final RxBool likedIsLoading = false.obs;
  final RxBool likedIsFetchingMore = false.obs;
  final RxBool likedHasMore = true.obs;
  final RxString likedQuery = ''.obs;

  // Passed segment state
  final RxList<PropertyModel> passedItems = <PropertyModel>[].obs;
  final RxInt passedPage = 1.obs;
  final RxInt passedTotalPages = 1.obs;
  final RxBool passedIsLoading = false.obs;
  final RxBool passedIsFetchingMore = false.obs;
  final RxBool passedHasMore = true.obs;
  final RxString passedQuery = ''.obs;

  static const int pageSize = 50;
  static const int concurrency = 8;

  void init() {
    _api = Get.find<ApiService>();
    refresh(isLiked: true);
    refresh(isLiked: false);
  }

  Future<void> refresh({required bool isLiked}) async {
    if (isLiked) {
      likedIsLoading.value = true;
      likedPage.value = 1;
      likedHasMore.value = true;
      likedItems.clear();
      await _loadPage(isLiked: true, page: 1);
      likedIsLoading.value = false;
    } else {
      passedIsLoading.value = true;
      passedPage.value = 1;
      passedHasMore.value = true;
      passedItems.clear();
      await _loadPage(isLiked: false, page: 1);
      passedIsLoading.value = false;
    }
  }

  Future<void> fetchMore({required bool isLiked}) async {
    if (isLiked) {
      if (likedIsFetchingMore.value || !likedHasMore.value) return;
      likedIsFetchingMore.value = true;
      await _loadPage(isLiked: true, page: likedPage.value + 1);
      likedIsFetchingMore.value = false;
    } else {
      if (passedIsFetchingMore.value || !passedHasMore.value) return;
      passedIsFetchingMore.value = true;
      await _loadPage(isLiked: false, page: passedPage.value + 1);
      passedIsFetchingMore.value = false;
    }
  }

  Future<void> _loadPage({required bool isLiked, required int page}) async {
    final res = await _api.getSwipeHistoryPage(page: page, limit: pageSize, isLiked: isLiked);
    final ids = res.swipes.map((s) => s.propertyId).toList();

    final List<PropertyModel> pageItems = [];
    for (int i = 0; i < ids.length; i += concurrency) {
      final chunk = ids.sublist(i, (i + concurrency).clamp(0, ids.length));
      final futures = chunk.map((id) => _api.getPropertyDetails(id)).toList();
      final results = await Future.wait(futures, eagerError: false);
      pageItems.addAll(results);
    }

    if (isLiked) {
      if (page == 1) likedItems.clear();
      likedItems.addAll(pageItems);
      likedPage.value = page;
      likedTotalPages.value = res.totalPages;
      likedHasMore.value = likedPage.value < likedTotalPages.value;
    } else {
      if (page == 1) passedItems.clear();
      passedItems.addAll(pageItems);
      passedPage.value = page;
      passedTotalPages.value = res.totalPages;
      passedHasMore.value = passedPage.value < passedTotalPages.value;
    }
  }

  void updateSearchQuery(String q, {required bool isLikedTab}) {
    if (isLikedTab) {
      likedQuery.value = q.trim();
    } else {
      passedQuery.value = q.trim();
    }
  }
}
