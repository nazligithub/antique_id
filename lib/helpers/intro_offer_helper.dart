import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum IntroOfferMode { freeTrial, payUpFront, payAsYouGo, unknown }

/// The introductory offer the App Store is serving for a product right now.
///
/// Everything here comes from StoreKit rather than from a constant in this
/// repository, because the offer is edited in App Store Connect and can change
/// without a release. A paywall that states its own terms is stating what was
/// true when it was written.
@immutable
class IntroOffer {
  const IntroOffer({
    required this.mode,
    required this.displayPrice,
    required this.periodUnit,
    required this.periodValue,
    required this.periodCount,
  });

  final IntroOfferMode mode;

  /// Already localised and already carrying the right currency symbol, which
  /// is the whole reason for asking the store instead of formatting a number.
  final String displayPrice;
  final String periodUnit;
  final int periodValue;
  final int periodCount;

  bool get isFree => mode == IntroOfferMode.freeTrial;

  /// Total length of the offer, in days where that reads naturally.
  int get totalDays {
    final perPeriod = switch (periodUnit) {
      'day' => 1,
      'week' => 7,
      'month' => 30,
      'year' => 365,
      _ => 0,
    };
    return perPeriod * periodValue * (periodCount <= 0 ? 1 : periodCount);
  }

  /// '3-Day', '1-Week' -- the part that goes in front of "Free Trial".
  String get durationLabel {
    final days = totalDays;
    if (days > 0 && days % 7 == 0 && days >= 7) {
      final weeks = days ~/ 7;
      return weeks == 1 ? '1-Week' : '$weeks-Week';
    }
    if (days > 0) return '$days-Day';
    return '';
  }

  static IntroOffer? fromMap(Map<Object?, Object?> map) {
    final mode = switch (map['mode']) {
      'free_trial' => IntroOfferMode.freeTrial,
      'pay_up_front' => IntroOfferMode.payUpFront,
      'pay_as_you_go' => IntroOfferMode.payAsYouGo,
      _ => IntroOfferMode.unknown,
    };
    if (mode == IntroOfferMode.unknown) return null;
    return IntroOffer(
      mode: mode,
      displayPrice: (map['displayPrice'] as String?) ?? '',
      periodUnit: (map['periodUnit'] as String?) ?? 'day',
      periodValue: (map['periodValue'] as int?) ?? 0,
      periodCount: (map['periodCount'] as int?) ?? 1,
    );
  }
}

class IntroOfferHelper {
  IntroOfferHelper._();

  static const MethodChannel _channel = MethodChannel('antique/intro_offer');

  static final Map<String, IntroOffer?> _cache = {};

  /// Returns null when there is no offer, when the platform has no bridge, or
  /// when StoreKit cannot be reached. Every caller treats null as "say nothing
  /// specific", so a failure here costs a sharper headline and nothing more.
  static Future<IntroOffer?> forProduct(String productId) async {
    if (productId.isEmpty) return null;
    if (_cache.containsKey(productId)) return _cache[productId];

    IntroOffer? offer;
    try {
      final response = await _channel.invokeMapMethod<String, Object?>(
        'fetch',
        {'productIds': [productId]},
      );
      final raw = response?[productId];
      if (raw is Map) offer = IntroOffer.fromMap(raw.cast<Object?, Object?>());
    } on MissingPluginException {
      // Android, or a build without the bridge compiled in.
    } catch (error) {
      debugPrint('Could not read the introductory offer: $error');
    }

    _cache[productId] = offer;
    return offer;
  }

  @visibleForTesting
  static void clearCache() => _cache.clear();
}
