import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class DocumentItem {
  final String id;
  final String titleKey;
  final String descriptionKey;
  bool isChecked;

  DocumentItem({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    this.isChecked = false,
  });
}

class DocumentCategory {
  final String titleKey;
  final List<DocumentItem> items;

  DocumentCategory({required this.titleKey, required this.items});
}

class DocumentChecklistController extends GetxController {
  final RxList<DocumentCategory> categories = <DocumentCategory>[].obs;
  final RxInt totalItems = 0.obs;
  final RxInt checkedItems = 0.obs;

  final _storage = GetStorage();
  static const _storageKey = 'document_checklist';

  @override
  void onInit() {
    super.onInit();
    _initializeCategories();
    _loadSavedState();
  }

  void _initializeCategories() {
    categories.value = [
      DocumentCategory(
        titleKey: 'doc_category_title',
        items: [
          DocumentItem(
            id: 'title_deed',
            titleKey: 'doc_title_deed',
            descriptionKey: 'doc_title_deed_desc',
          ),
          DocumentItem(
            id: 'sale_deed',
            titleKey: 'doc_sale_deed',
            descriptionKey: 'doc_sale_deed_desc',
          ),
          DocumentItem(
            id: 'mother_deed',
            titleKey: 'doc_mother_deed',
            descriptionKey: 'doc_mother_deed_desc',
          ),
        ],
      ),
      DocumentCategory(
        titleKey: 'doc_category_legal',
        items: [
          DocumentItem(
            id: 'encumbrance',
            titleKey: 'doc_encumbrance',
            descriptionKey: 'doc_encumbrance_desc',
          ),
          DocumentItem(id: 'khata', titleKey: 'doc_khata', descriptionKey: 'doc_khata_desc'),
          DocumentItem(
            id: 'mutation',
            titleKey: 'doc_mutation',
            descriptionKey: 'doc_mutation_desc',
          ),
        ],
      ),
      DocumentCategory(
        titleKey: 'doc_category_noc',
        items: [
          DocumentItem(
            id: 'society_noc',
            titleKey: 'doc_society_noc',
            descriptionKey: 'doc_society_noc_desc',
          ),
          DocumentItem(
            id: 'bank_noc',
            titleKey: 'doc_bank_noc',
            descriptionKey: 'doc_bank_noc_desc',
          ),
          DocumentItem(id: 'rera', titleKey: 'doc_rera', descriptionKey: 'doc_rera_desc'),
        ],
      ),
      DocumentCategory(
        titleKey: 'doc_category_financial',
        items: [
          DocumentItem(
            id: 'property_tax',
            titleKey: 'doc_property_tax',
            descriptionKey: 'doc_property_tax_desc',
          ),
          DocumentItem(
            id: 'utility_bills',
            titleKey: 'doc_utility_bills',
            descriptionKey: 'doc_utility_bills_desc',
          ),
          DocumentItem(
            id: 'maintenance_dues',
            titleKey: 'doc_maintenance_dues',
            descriptionKey: 'doc_maintenance_dues_desc',
          ),
        ],
      ),
      DocumentCategory(
        titleKey: 'doc_category_possession',
        items: [
          DocumentItem(
            id: 'possession_letter',
            titleKey: 'doc_possession_letter',
            descriptionKey: 'doc_possession_letter_desc',
          ),
          DocumentItem(
            id: 'occupancy_cert',
            titleKey: 'doc_occupancy_cert',
            descriptionKey: 'doc_occupancy_cert_desc',
          ),
          DocumentItem(
            id: 'completion_cert',
            titleKey: 'doc_completion_cert',
            descriptionKey: 'doc_completion_cert_desc',
          ),
        ],
      ),
    ];
    _updateCounts();
  }

  void _loadSavedState() {
    final saved = _storage.read<Map<String, dynamic>>(_storageKey);
    if (saved != null) {
      for (final category in categories) {
        for (final item in category.items) {
          item.isChecked = saved[item.id] ?? false;
        }
      }
      _updateCounts();
      categories.refresh();
    }
  }

  void _saveState() {
    final Map<String, dynamic> state = {};
    for (final category in categories) {
      for (final item in category.items) {
        state[item.id] = item.isChecked;
      }
    }
    _storage.write(_storageKey, state);
  }

  void _updateCounts() {
    int total = 0;
    int checked = 0;
    for (final category in categories) {
      for (final item in category.items) {
        total++;
        if (item.isChecked) checked++;
      }
    }
    totalItems.value = total;
    checkedItems.value = checked;
  }

  void toggleItem(String itemId) {
    for (final category in categories) {
      for (final item in category.items) {
        if (item.id == itemId) {
          item.isChecked = !item.isChecked;
          _updateCounts();
          _saveState();
          categories.refresh();
          return;
        }
      }
    }
  }

  void resetAll() {
    for (final category in categories) {
      for (final item in category.items) {
        item.isChecked = false;
      }
    }
    _updateCounts();
    _saveState();
    categories.refresh();
  }

  double get progress {
    if (totalItems.value == 0) return 0;
    return checkedItems.value / totalItems.value;
  }
}
