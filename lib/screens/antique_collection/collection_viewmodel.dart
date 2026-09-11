import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/antique_model.dart';
import '../../services/collection_service.dart';
import '../antique_solution_screen.dart';

enum CollectionValueFilter { all, valued, needsReview }

enum CollectionSort { newest, oldest, highestValue, alphabetical }

class CollectionViewModel extends ChangeNotifier {
  Map<String, List<AntiqueModel>> _collections = {};
  bool _isLoading = false;
  String? _error;
  String? _selectedCollection;
  String _searchQuery = '';
  CollectionValueFilter _valueFilter = CollectionValueFilter.all;
  CollectionSort _sort = CollectionSort.newest;

  Map<String, List<AntiqueModel>> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _collections.isEmpty && !_isLoading && !hasError;
  String? get selectedCollection => _selectedCollection;
  String get searchQuery => _searchQuery;
  CollectionValueFilter get valueFilter => _valueFilter;
  CollectionSort get sort => _sort;
  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _valueFilter != CollectionValueFilter.all;

  List<String> get collectionNames => _collections.keys.toList();

  Map<String, List<AntiqueModel>> get filteredCollections {
    if (_selectedCollection == null || _selectedCollection!.isEmpty) {
      return _collections;
    }
    if (_collections.containsKey(_selectedCollection)) {
      return {_selectedCollection!: _collections[_selectedCollection!]!};
    }
    return {};
  }

  Map<String, List<AntiqueModel>> get visibleCollections {
    final result = <String, List<AntiqueModel>>{};
    for (final entry in filteredCollections.entries) {
      final items =
          entry.value.where(_matchesSearch).where(_matchesValueFilter).toList()
            ..sort(_compareItems);
      if (items.isNotEmpty) {
        result[entry.key] = items;
      }
    }
    return result;
  }

  void setSearchQuery(String value) {
    final normalized = value.trimLeft();
    if (_searchQuery == normalized) return;
    _searchQuery = normalized;
    notifyListeners();
  }

  void setValueFilter(CollectionValueFilter filter) {
    if (_valueFilter == filter) return;
    _valueFilter = filter;
    notifyListeners();
  }

  void setSort(CollectionSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  void clearFilters() {
    if (_searchQuery.isEmpty &&
        _valueFilter == CollectionValueFilter.all &&
        _sort == CollectionSort.newest) {
      return;
    }
    _searchQuery = '';
    _valueFilter = CollectionValueFilter.all;
    _sort = CollectionSort.newest;
    notifyListeners();
  }

  bool _matchesSearch(AntiqueModel antique) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final searchable = [
      antique.name,
      antique.description,
      antique.era,
      antique.origin,
      antique.price,
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }

  bool _matchesValueFilter(AntiqueModel antique) {
    switch (_valueFilter) {
      case CollectionValueFilter.all:
        return true;
      case CollectionValueFilter.valued:
        return _hasEstimatedValue(antique.price);
      case CollectionValueFilter.needsReview:
        return !_hasEstimatedValue(antique.price);
    }
  }

  int _compareItems(AntiqueModel first, AntiqueModel second) {
    switch (_sort) {
      case CollectionSort.newest:
        return _timestamp(second.id).compareTo(_timestamp(first.id));
      case CollectionSort.oldest:
        return _timestamp(first.id).compareTo(_timestamp(second.id));
      case CollectionSort.highestValue:
        return _numericValue(
          second.price,
        ).compareTo(_numericValue(first.price));
      case CollectionSort.alphabetical:
        return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    }
  }

  bool _hasEstimatedValue(String price) {
    final normalized = price.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    const unavailableLabels = [
      'not determined',
      'unknown',
      'unavailable',
      'n/a',
      'none',
      'null',
    ];
    if (unavailableLabels.any(normalized.contains)) return false;
    return RegExp(r'\d').hasMatch(normalized);
  }

  double _numericValue(String price) {
    final normalized = price.replaceAll(',', '').toLowerCase();
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*([km])?').firstMatch(normalized);
    if (match == null) return 0;
    final value = double.tryParse(match.group(1)!) ?? 0;
    switch (match.group(2)) {
      case 'k':
        return value * 1000;
      case 'm':
        return value * 1000000;
      default:
        return value;
    }
  }

  /// What everything currently listed is estimated to be worth.
  ///
  /// Deliberately conservative: a price given as a range contributes its low
  /// end (that is the first number [_numericValue] finds), and a piece with no
  /// figure at all contributes nothing rather than a guess.
  double get visibleEstimatedTotal {
    var total = 0.0;
    for (final items in visibleCollections.values) {
      for (final item in items) {
        if (_hasEstimatedValue(item.price)) {
          total += _numericValue(item.price);
        }
      }
    }
    return total;
  }

  /// Null when nothing on screen carries a figure, so the header can leave the
  /// line out rather than announce that a collection is worth nothing.
  String? get visibleEstimatedTotalLabel {
    final total = visibleEstimatedTotal;
    if (total <= 0) return null;
    if (total >= 1000000) {
      final millions = total / 1000000;
      return '\$${millions.toStringAsFixed(millions >= 10 ? 0 : 1)}M';
    }
    if (total >= 1000) {
      final thousands = total / 1000;
      return '\$${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}K';
    }
    return '\$${total.toStringAsFixed(0)}';
  }

  int _timestamp(String id) => int.tryParse(id) ?? 0;

  Future<void> loadCollection({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _collections = await CollectionService().getCollectionsByName();
    } catch (e) {
      _error = 'Error loading collections';
      debugPrint('Error loading collections: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromCollection(String id) async {
    try {
      await CollectionService().removeFromCollection(id);
      // Koleksiyonları yeniden yükle
      await loadCollection();
    } catch (e) {
      _error = 'Error removing from collection';
      debugPrint('Error removing from collection: $e');
      notifyListeners();
    }
  }

  Future<void> onItemTapped(BuildContext context, AntiqueModel antique) async {
    try {
      debugPrint('=== Collection Item Tapped ===');
      debugPrint('Antique ID: ${antique.id}');
      debugPrint('Antique Name: ${antique.name}');

      // Koleksiyondan full data'yı al (HTML content ile birlikte)
      final prefs = await SharedPreferences.getInstance();
      final userId = await CollectionService().getUserId();
      final userCollectionKey = 'saved_collection_$userId';

      debugPrint('User ID: $userId');
      debugPrint('Collection Key: $userCollectionKey');

      List<String> savedCollection =
          prefs.getStringList(userCollectionKey) ?? [];
      debugPrint('Total saved items: ${savedCollection.length}');

      Map<String, dynamic>? itemData;
      for (String item in savedCollection) {
        final json = jsonDecode(item) as Map<String, dynamic>;
        debugPrint('Checking item ID: ${json['id']} vs ${antique.id}');
        if (json['id'] == antique.id) {
          itemData = json;
          debugPrint('Found matching item!');
          break;
        }
      }

      if (itemData != null && itemData['original_analysis'] != null) {
        final analysisResult =
            itemData['original_analysis'] as Map<String, dynamic>;
        debugPrint('Analysis result found, navigating...');

        if (!context.mounted) return;

        // Solution screen'e navigate et
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AntiqueSolutionScreen(
              analysisResult: analysisResult,
              imagePath: '', // Collection'dan geliyorsa image path gerekmiyor
            ),
          ),
        );
      } else {
        debugPrint('No analysis data found for this item');
        debugPrint('Item data: $itemData');
      }
    } catch (e) {
      debugPrint('Error opening item details: $e');
    }
  }

  void selectCollection(String? collectionName) {
    _selectedCollection = collectionName;
    notifyListeners();
  }

  void createNewCollection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Collection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1810),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Collection Name...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF8B4513)),
                    ),
                  ),
                  style: TextStyle(fontSize: 16, color: Color(0xFF2D1810)),
                  autofocus: true,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          controller.clear();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (controller.text.trim().isNotEmpty) {
                            try {
                              await CollectionService().createEmptyCollection(
                                controller.text.trim(),
                              );
                              await loadCollection(); // Refresh collections
                              if (!context.mounted) return;
                              Navigator.pop(context);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Collection "${controller.text.trim()}" created!',
                                    ),
                                    backgroundColor: Color(0xFF8B4513),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to create collection: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8B4513),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Create',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> renameCollection(String oldName, String newName) async {
    try {
      await CollectionService().renameCollection(oldName, newName);
      await loadCollection(forceRefresh: true);
    } catch (e) {
      _error = 'Error renaming collection';
      debugPrint('Error renaming collection: $e');
      notifyListeners();
      rethrow;
    }
  }
}
