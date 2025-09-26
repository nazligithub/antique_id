import 'package:flutter/material.dart';
import '../../models/antique_model.dart';
import '../../services/collection_service.dart';

class CollectionViewModel extends ChangeNotifier {

  Map<String, List<AntiqueModel>> _collections = {};
  bool _isLoading = false;
  String? _error;

  Map<String, List<AntiqueModel>> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _collections.isEmpty && !_isLoading && !hasError;

  Future<void> loadCollection() async {
    if (_isLoading) return;

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

  void onItemTapped(BuildContext context, AntiqueModel antique) {
    debugPrint('Collection item tapped: ${antique.name}');
  }

  void createNewCollection() {
    // Yeni koleksiyon oluşturma işlemi
    debugPrint('Create new collection');
  }

}