import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Checks the installed iOS build against the version currently available on
/// the App Store. A failed lookup is intentionally treated as unknown so a
/// network problem can never block app startup.
class VersionCheck {
  const VersionCheck._();

  static Future<StoreInfo?> storeInfo({
    http.Client? client,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // The iTunes Lookup endpoint is iOS-specific. Android can get an
    // equivalent Play Store check later without guessing a store URL here.
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;

    final httpClient = client ?? http.Client();
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final lookupUri = Uri.https('itunes.apple.com', '/lookup', {
        'bundleId': packageInfo.packageName,
      });
      final response = await httpClient.get(lookupUri).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Version check skipped: App Store lookup returned '
          '${response.statusCode}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final payload = Map<String, dynamic>.from(decoded);
      final results = payload['results'];
      if (results is! List || results.isEmpty || results.first is! Map) {
        debugPrint(
          'Version check skipped: app is not available on the App Store',
        );
        return null;
      }

      final result = Map<String, dynamic>.from(results.first as Map);
      final storeVersion = result['version']?.toString().trim();
      if (storeVersion == null || storeVersion.isEmpty) return null;

      final storeUrl = _storeUrl(result);
      if (storeUrl == null) return null;

      final updateAvailable =
          _compareVersions(storeVersion, packageInfo.version) > 0;

      debugPrint(
        'Version check: installed=${packageInfo.version}, '
        'store=$storeVersion, updateAvailable=$updateAvailable',
      );

      return StoreInfo(
        updateAvailable: updateAvailable,
        appStoreUrl: storeUrl,
        currentVersion: packageInfo.version,
        storeVersion: storeVersion,
      );
    } catch (error) {
      debugPrint('Version check skipped: $error');
      return null;
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Uri? _storeUrl(Map<String, dynamic> result) {
    final trackViewUrl = result['trackViewUrl']?.toString();
    if (trackViewUrl != null && trackViewUrl.isNotEmpty) {
      return Uri.tryParse(trackViewUrl);
    }

    final trackId = result['trackId'];
    if (trackId is num) {
      return Uri.tryParse(
        'itms-apps://apps.apple.com/app/id${trackId.toInt()}',
      );
    }
    return null;
  }

  /// Numeric comparison prevents lexicographic errors such as 1.10.0 < 1.9.0.
  static int _compareVersions(String first, String second) {
    final firstParts = _versionParts(first);
    final secondParts = _versionParts(second);
    final length = firstParts.length > secondParts.length
        ? firstParts.length
        : secondParts.length;

    for (var index = 0; index < length; index++) {
      final firstPart = index < firstParts.length ? firstParts[index] : 0;
      final secondPart = index < secondParts.length ? secondParts[index] : 0;
      if (firstPart != secondPart) return firstPart.compareTo(secondPart);
    }
    return 0;
  }

  static List<int> _versionParts(String version) {
    final parts = RegExp(r'\d+')
        .allMatches(version)
        .map((match) => int.tryParse(match.group(0)!) ?? 0)
        .toList();
    return parts.isEmpty ? [0] : parts;
  }
}

class StoreInfo {
  final bool updateAvailable;
  final Uri appStoreUrl;
  final String currentVersion;
  final String storeVersion;

  const StoreInfo({
    required this.updateAvailable,
    required this.appStoreUrl,
    required this.currentVersion,
    required this.storeVersion,
  });
}
