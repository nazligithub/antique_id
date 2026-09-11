import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appactor_flutter/appactor_flutter.dart';
import '../models/antique_model.dart';

class CollectionService {
  static const String _collectionKey = 'saved_collection';
  static const String _userIdKey = 'collection_user_id';
  static const String _guestPrefix = 'guest_user_';

  String _extractPrice(Map<String, dynamic> data) {
    // Önce analysis_data içindeki reference_price'ı kontrol et
    if (data['analysis_data'] != null) {
      final analysisData = data['analysis_data'] as Map<String, dynamic>;

      if (analysisData['reference_price'] != null && analysisData['reference_price'].toString().isNotEmpty && analysisData['reference_price'].toString() != 'null') {
        final refPrice = analysisData['reference_price'].toString().replaceAll('\$', '');
        return '\$$refPrice';
      }
    }

    // API'den gelen price değerlerini kontrol et
    if (data['antique_price'] != null && data['antique_price'].toString().isNotEmpty && data['antique_price'].toString() != 'null') {
      return '\$${data['antique_price']}';
    }
    if (data['reference_price'] != null && data['reference_price'].toString().isNotEmpty && data['reference_price'].toString() != 'null') {
      return '\$${data['reference_price']}';
    }
    if (data['price'] != null && data['price'].toString().isNotEmpty && data['price'].toString() != 'null') {
      return '\$${data['price']}';
    }
    if (data['estimatedValue'] != null && data['estimatedValue'].toString().isNotEmpty && data['estimatedValue'].toString() != 'null') {
      return '\$${data['estimatedValue']}';
    }
    if (data['value'] != null && data['value'].toString().isNotEmpty && data['value'].toString() != 'null') {
      return '\$${data['value']}';
    }

    return 'Value not determined';
  }

  /// A stable identity for the on-device collection.
  ///
  /// Every collection read and write is keyed on this. The previous version
  /// minted `guest_user_<timestamp>` whenever AppActor was slow or offline,
  /// which meant a single hiccup wrote items under an id that would never be
  /// produced again: the collection came back empty and the entries were
  /// stranded for good. The resolved id is now persisted, and anything left
  /// under an earlier guest id is folded back in.
  Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_userIdKey);

    String? resolved;
    try {
      final appUserId = (await AppActor.instance.getCustomerInfo()).appUserId;
      if (appUserId != null && appUserId.isNotEmpty) resolved = appUserId;
    } catch (e) {
      debugPrint('Error getting user ID: $e');
    }

    // Falling back to the last known id -- rather than a fresh one -- is the
    // whole point: an unreachable AppActor must not cost anyone their items.
    resolved ??= stored;
    resolved ??= '$_guestPrefix${DateTime.now().millisecondsSinceEpoch}';

    if (resolved != stored) {
      await prefs.setString(_userIdKey, resolved);
      await _adoptStrandedCollections(prefs, resolved);
    }
    return resolved;
  }

  /// Moves anything saved under a previous guest id into the current one.
  ///
  /// Only guest keys are adopted. A real AppActor id belongs to a specific
  /// person, and merging two of those would hand one reader another's items.
  Future<void> _adoptStrandedCollections(
    SharedPreferences prefs,
    String userId,
  ) async {
    final currentKey = '${_collectionKey}_$userId';
    final stranded = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith('${_collectionKey}_$_guestPrefix') &&
              key != currentKey,
        )
        .toList();
    if (stranded.isEmpty) return;

    final merged = prefs.getStringList(currentKey) ?? <String>[];
    final seen = merged.map(_entryId).whereType<String>().toSet();

    for (final key in stranded) {
      for (final entry in prefs.getStringList(key) ?? const <String>[]) {
        final id = _entryId(entry);
        if (id != null && !seen.add(id)) continue;
        merged.add(entry);
      }
      await prefs.remove(key);
    }

    await prefs.setStringList(currentKey, merged);
    debugPrint(
      'Collection: recovered ${stranded.length} stranded key(s) into $currentKey',
    );
  }

  String? _entryId(String entry) {
    try {
      final decoded = jsonDecode(entry);
      if (decoded is Map<String, dynamic>) return decoded['id']?.toString();
    } catch (_) {
      // A malformed entry keeps its place in the list; it just cannot be
      // matched for duplicates.
    }
    return null;
  }

  Future<void> saveToCollection(
    Map<String, dynamic> analysisResult,
    String imagePath, {
    String collectionName = 'My Collection',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getUserId();
      final userCollectionKey = '${_collectionKey}_$userId';

      final data = analysisResult['data'] ?? analysisResult;
      final antiqueId = DateTime.now().millisecondsSinceEpoch.toString();


      final antique = AntiqueModel(
        id: antiqueId,
        name: data['antique_name'] ?? data['name'] ?? 'Unknown Antique',
        description: data['description'] ?? 'No description available',
        imageUrl: data['image_url'] ?? data['imageUrl'] ?? '',
        price: _extractPrice(data),
        era: data['era'] ?? data['period'] ?? data['estimatedAge'] ?? 'Unknown era',
        origin: data['origin'] ?? 'Unknown origin',
        isPremium: false,
      );

      // Koleksiyon bilgisini ve HTML content'i kaydet
      final antiqueWithCollection = antique.toJson();
      antiqueWithCollection['collection_name'] = collectionName;
      antiqueWithCollection['html_content'] = data['html_content'] ?? '';
      antiqueWithCollection['original_analysis'] = analysisResult;

      List<String> savedCollection = prefs.getStringList(userCollectionKey) ?? [];
      savedCollection.add(jsonEncode(antiqueWithCollection));

      await prefs.setStringList(userCollectionKey, savedCollection);

      // Eğer bu collection boş collection listesinde varsa çıkar
      await removeEmptyCollection(collectionName);
    } catch (e) {
      throw Exception('Failed to save to collection: $e');
    }
  }

  Future<List<AntiqueModel>> loadCollection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getUserId();
      final userCollectionKey = '${_collectionKey}_$userId';

      List<String> savedCollection = prefs.getStringList(userCollectionKey) ?? [];

      return savedCollection.map((item) {
        final json = jsonDecode(item) as Map<String, dynamic>;

        // Original analysis'tan doğru price'ı çek
        if (json['original_analysis'] != null) {
          // Entire analysis result'ı geç ki analysis_data'ya erişebilsin
          json['price'] = _extractPrice(json['original_analysis']);
        }

        return AntiqueModel.fromJson(json);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> removeFromCollection(String antiqueId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getUserId();
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
      final userId = await getUserId();
      final userCollectionKey = '${_collectionKey}_$userId';

      List<String> savedCollection = prefs.getStringList(userCollectionKey) ?? [];

      Set<String> collectionNames = {};

      // Boş koleksiyonları ekle
      final emptyCollections = await getEmptyCollections();
      collectionNames.addAll(emptyCollections);

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
      final userId = await getUserId();
      final userCollectionKey = '${_collectionKey}_$userId';

      List<String> savedCollection = prefs.getStringList(userCollectionKey) ?? [];

      // Boş koleksiyonları da dahil et
      final emptyCollections = await getEmptyCollections();

      Map<String, List<AntiqueModel>> collections = {};

      // Önce boş koleksiyonları ekle
      for (String collectionName in emptyCollections) {
        collections[collectionName] = [];
      }

      for (String item in savedCollection) {
        final json = jsonDecode(item) as Map<String, dynamic>;
        final collectionName = json['collection_name'] as String? ?? 'My Collection';

        // Original analysis'tan doğru price'ı çek
        if (json['original_analysis'] != null) {
          // Entire analysis result'ı geç ki analysis_data'ya erişebilsin
          json['price'] = _extractPrice(json['original_analysis']);
        }

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

  Future<void> createEmptyCollection(String collectionName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getUserId();
      final emptyCollectionsKey = 'empty_collections_$userId';

      List<String> emptyCollections = prefs.getStringList(emptyCollectionsKey) ?? [];

      if (!emptyCollections.contains(collectionName)) {
        emptyCollections.add(collectionName);
        await prefs.setStringList(emptyCollectionsKey, emptyCollections);
      }
    } catch (e) {
      throw Exception('Failed to create collection: $e');
    }
  }

  Future<List<String>> getEmptyCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getUserId();
      final emptyCollectionsKey = 'empty_collections_$userId';

      return prefs.getStringList(emptyCollectionsKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<void> removeEmptyCollection(String collectionName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getUserId();
      final emptyCollectionsKey = 'empty_collections_$userId';

      List<String> emptyCollections = prefs.getStringList(emptyCollectionsKey) ?? [];
      emptyCollections.remove(collectionName);
      await prefs.setStringList(emptyCollectionsKey, emptyCollections);
    } catch (e) {
      debugPrint('Failed to remove empty collection: $e');
    }
  }

  Future<void> renameCollection(String oldName, String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getUserId();
      final userCollectionKey = '${_collectionKey}_$userId';
      final emptyCollectionsKey = 'empty_collections_$userId';

      // Update items in collections
      List<String> savedCollection = prefs.getStringList(userCollectionKey) ?? [];
      List<String> updatedCollection = [];

      for (String item in savedCollection) {
        final json = jsonDecode(item) as Map<String, dynamic>;
        if (json['collection_name'] == oldName) {
          json['collection_name'] = newName;
        }
        updatedCollection.add(jsonEncode(json));
      }

      await prefs.setStringList(userCollectionKey, updatedCollection);

      // Update empty collections list
      List<String> emptyCollections = prefs.getStringList(emptyCollectionsKey) ?? [];
      if (emptyCollections.contains(oldName)) {
        emptyCollections.remove(oldName);
        emptyCollections.add(newName);
        await prefs.setStringList(emptyCollectionsKey, emptyCollections);
      }
    } catch (e) {
      throw Exception('Failed to rename collection: $e');
    }
  }
}