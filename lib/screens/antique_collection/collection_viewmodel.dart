import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/antique_model.dart';
import '../../services/collection_service.dart';
import '../antique_solution_screen.dart';

class CollectionViewModel extends ChangeNotifier {

  Map<String, List<AntiqueModel>> _collections = {};
  bool _isLoading = false;
  String? _error;
  String? _selectedCollection;

  Map<String, List<AntiqueModel>> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _collections.isEmpty && !_isLoading && !hasError;
  String? get selectedCollection => _selectedCollection;

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

      List<String> savedCollection = prefs.getStringList(userCollectionKey) ?? [];
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
        final analysisResult = itemData['original_analysis'] as Map<String, dynamic>;
        debugPrint('Analysis result found, navigating...');

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
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF8B4513)),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D1810),
                  ),
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
                              await CollectionService().createEmptyCollection(controller.text.trim());
                              await loadCollection(); // Refresh collections
                              Navigator.pop(context);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Collection "${controller.text.trim()}" created!'),
                                    backgroundColor: Color(0xFF8B4513),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to create collection: ${e.toString()}'),
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
      throw e;
    }
  }

}