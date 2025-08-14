import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/debug_logger.dart';

class SearchHistoryController extends GetxController {
  final GetStorage _storage = GetStorage();
  
  final RxList<Map<String, dynamic>> searchHistory = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredHistory = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSearchHistory();
  }

  void _loadSearchHistory() {
    isLoading.value = true;
    try {
      final List<dynamic>? storedHistory = _storage.read('searchHistory');
      if (storedHistory != null) {
        searchHistory.value = storedHistory.cast<Map<String, dynamic>>();
      } else {
        // Add some sample data
        searchHistory.value = _getSampleSearchHistory();
        _saveSearchHistory();
      }
      filteredHistory.value = List.from(searchHistory);
    } catch (e, stackTrace) {
      searchHistory.value = _getSampleSearchHistory();
      filteredHistory.value = List.from(searchHistory);
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> _getSampleSearchHistory() {
    final now = DateTime.now();
    return [
      {
        'id': '1',
        'query': '3 BHK apartment',
        'location': 'Noida, UP',
        'filters': ['₹50L-₹80L', '1000-1500 sqft', 'Ready to move'],
        'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'resultCount': 24,
      },
      {
        'id': '2',
        'query': 'Villa near metro',
        'location': 'Gurgaon, HR',
        'filters': ['₹1Cr+', '2000+ sqft', 'With parking'],
        'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        'resultCount': 8,
      },
      {
        'id': '3',
        'query': 'Studio apartment',
        'location': 'Bangalore, KA',
        'filters': ['₹30L-₹50L', 'Furnished', 'IT corridor'],
        'timestamp': now.subtract(const Duration(days: 3)).toIso8601String(),
        'resultCount': 15,
      },
      {
        'id': '4',
        'query': 'Independent house',
        'location': 'Delhi',
        'filters': ['₹80L-₹1.2Cr', '1500+ sqft', 'Garden area'],
        'timestamp': now.subtract(const Duration(days: 5)).toIso8601String(),
        'resultCount': 12,
      },
      {
        'id': '5',
        'query': '2 BHK flat',
        'location': 'Mumbai, MH',
        'filters': ['₹60L-₹90L', '800-1200 sqft', 'Sea facing'],
        'timestamp': now.subtract(const Duration(days: 7)).toIso8601String(),
        'resultCount': 31,
      },
    ];
  }

  void filterHistory(String query) {
    if (query.isEmpty) {
      filteredHistory.value = List.from(searchHistory);
    } else {
      filteredHistory.value = searchHistory.where((search) {
        final searchQuery = search['query']?.toString().toLowerCase() ?? '';
        final location = search['location']?.toString().toLowerCase() ?? '';
        final filters = search['filters']?.join(' ').toLowerCase() ?? '';
        
        return searchQuery.contains(query.toLowerCase()) ||
               location.contains(query.toLowerCase()) ||
               filters.contains(query.toLowerCase());
      }).toList();
    }
  }

  void addToHistory(Map<String, dynamic> searchData) {
    try {
      // Add timestamp if not present
      if (!searchData.containsKey('timestamp')) {
        searchData['timestamp'] = DateTime.now().toIso8601String();
      }
      
      // Add unique ID if not present
      if (!searchData.containsKey('id')) {
        searchData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // Remove duplicate if exists (same query and location)
      searchHistory.removeWhere((item) =>
          item['query'] == searchData['query'] &&
          item['location'] == searchData['location']);

      // Add to beginning of list
      searchHistory.insert(0, searchData);

      // Keep only last 50 searches
      if (searchHistory.length > 50) {
        searchHistory.removeRange(50, searchHistory.length);
      }

      filteredHistory.value = List.from(searchHistory);
      _saveSearchHistory();
    } catch (e, stackTrace) {
      Get.snackbar('Error', 'Failed to save search history');
    }
  }

  void removeFromHistory(String id) {
    try {
      searchHistory.removeWhere((item) => item['id'] == id);
      filteredHistory.value = List.from(searchHistory);
      _saveSearchHistory();
      
      Get.snackbar(
        'Removed',
        'Search removed from history',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      Get.snackbar('Error', 'Failed to remove search');
    }
  }

  void clearAllHistory() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Search History'),
        content: const Text('Are you sure you want to clear all search history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              searchHistory.clear();
              filteredHistory.clear();
              _saveSearchHistory();
              Get.back();
              Get.snackbar(
                'Cleared',
                'Search history cleared successfully',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void repeatSearch(Map<String, dynamic> search) {
    // Navigate back to search/home page with the search parameters
    Get.back(); // Go back to profile
    Get.offNamed('/discover', arguments: {
      'search': search,
      'autoSearch': true,
    });
  }

  void _saveSearchHistory() {
    try {
      _storage.write('searchHistory', searchHistory.toList());
    } catch (e, stackTrace) {
      DebugLogger.error('Error saving search history', e, stackTrace);
    }
  }

  String formatDate(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} minutes ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e, stackTrace) {
      return '';
    }
  }
}