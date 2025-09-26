import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/antique_model.dart';

class CollectionService {
  static const String _collectionKey = 'saved_collection';

  Future<String> _getUserId() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.originalAppUserId;
    } catch (e) {
      return 'guest_user_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> saveToCollection(
    Map<String, dynamic> analysisResult,
    String imagePath, {
    String collectionName = 'My Collection',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _getUserId();
      final userCollectionKey = '${_collectionKey}_$userId';

      final data = analysisResult['data'] ?? analysisResult;
      final antiqueId = DateTime.now().millisecondsSinceEpoch.toString();

      final antique = AntiqueModel(
        id: antiqueId,
        name: data['antique_name'] ?? data['name'] ?? 'Unknown Antique',
        description: data['description'] ?? 'No description available',
        imageUrl: data['image_url'] ?? data['imageUrl'] ?? '',
        price: data['reference_price'] ?? data['price'] ?? data['estimatedValue'] ?? 'Value not determined',
        era: data['era'] ?? data['period'] ?? data['estimatedAge'] ?? 'Unknown era',
        origin: data['origin'] ?? 'Unknown origin',
        isPremium: false,
      );

      // Koleksiyon bilgisini de kaydet
      final antiqueWithCollection = antique.toJson();
      antiqueWithCollection['collection_name'] = collectionName;

      List<String> savedCollection = prefs.getStringList(userCollectionKey) ?? [];
      savedCollection.add(jsonEncode(antiqueWithCollection));

      await prefs.setStringList(userCollectionKey, savedCollection);
    } catch (e) {
      throw Exception('Failed to save to collection: $e');
    }
  }

  Future<List<AntiqueModel>> loadCollection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _getUserId();
      final userCollectionKey = '${_collectionKey}_$userId';

      List<String> savedCollection = prefs.getStringList(userCollectionKey) ?? [];

      return savedCollection.map((item) {
        final json = jsonDecode(item) as Map<String, dynamic>;
        return AntiqueModel.fromJson(json);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> removeFromCollection(String antiqueId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _getUserId();
      final userCollectionKey = '${_collectionKey}_$userId';

      List<String> savedCollection = prefs.getStringList(userCollectionKey) ?? [];

      savedCollection.removeWhere((item) {
        final json = jsonDecode(item) as Map<String, dynamic>;
        return json['id'] == antiqueId;
      });

      await prefs.setStringList(userCollectionKey, savedCollection);
    } catch (e) {
      throw Exception('Failed to remove from collection: $e');
    }
  }

  Future<bool> isInCollection(String antiqueId) async {
    try {
      final collection = await loadCollection();
      return collection.any((item) => item.id == antiqueId);
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getCollectionNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _getUserId();
      final userCollectionKey = '${_collectionKey}_$userId';

      List<String> savedCollection = prefs.getStringList(userCollectionKey) ?? [];

      Set<String> collectionNames = {};

      for (String item in savedCollection) {
        final json = jsonDecode(item) as Map<String, dynamic>;
        final collectionName = json['collection_name'] as String? ?? 'My Collection';
        collectionNames.add(collectionName);
      }

      return collectionNames.toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, List<AntiqueModel>>> getCollectionsByName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _getUserId();
      final userCollectionKey = '${_collectionKey}_$userId';

      List<String> savedCollection = prefs.getStringList(userCollectionKey) ?? [];

      Map<String, List<AntiqueModel>> collections = {};

      for (String item in savedCollection) {
        final json = jsonDecode(item) as Map<String, dynamic>;
        final collectionName = json['collection_name'] as String? ?? 'My Collection';

        // collection_name field'ını kaldırarak AntiqueModel oluştur
        json.remove('collection_name');
        final antique = AntiqueModel.fromJson(json);

        if (collections[collectionName] == null) {
          collections[collectionName] = [];
        }
        collections[collectionName]!.add(antique);
      }

      return collections;
    } catch (e) {
      return {};
    }
  }
}