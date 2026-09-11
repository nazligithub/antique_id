import 'dart:convert';

/// A presentation-friendly snapshot of an analysis response.
///
/// The API is intentionally kept out of this model. It accepts the current
/// response shape (including nested `data`/`result` maps) and gives the UI a
/// stable set of fields while the API contract is being refined.
class AntiqueAnalysis {
  final String id;
  final String imagePath;
  final DateTime createdAt;
  final Map<String, dynamic> rawResponse;

  const AntiqueAnalysis({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    required this.rawResponse,
  });

  factory AntiqueAnalysis.fromResponse(
    Map<String, dynamic> response, {
    required String imagePath,
    String? id,
    DateTime? createdAt,
  }) {
    return AntiqueAnalysis(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      imagePath: imagePath,
      createdAt: createdAt ?? DateTime.now(),
      rawResponse: Map<String, dynamic>.from(response),
    );
  }

  factory AntiqueAnalysis.fromJson(Map<String, dynamic> json) {
    final raw = json['raw_response'];
    return AntiqueAnalysis(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      imagePath: json['image_path']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      rawResponse: raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'raw_response': rawResponse,
    };
  }

  Map<String, dynamic> get _data => _asMap(rawResponse['data']) ?? rawResponse;
  Map<String, dynamic>? get _result => _asMap(rawResponse['result']);
  Map<String, dynamic>? get _analysisData => _asMap(_data['analysis_data']);

  dynamic _read(List<String> keys) {
    final sources = <Map<String, dynamic>>[
      _data,
      if (_result != null) _result!,
      if (_analysisData != null) _analysisData!,
      rawResponse,
    ];

    for (final source in sources) {
      for (final key in keys) {
        final value = source[key];
        if (value != null &&
            value.toString().trim().isNotEmpty &&
            value.toString() != 'null') {
          return value;
        }
      }
    }
    return null;
  }

  String _text(List<String> keys, {String fallback = 'Not available'}) {
    final value = _read(keys);
    if (value == null) return fallback;
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString().trim();
  }

  String get name => _text([
    'antique_name',
    'name',
    'title',
    'item_name',
    'object_name',
  ], fallback: 'Unknown antique');

  /// The report's prose. The analysis returns this as historical_background;
  /// looking only for 'description' left every report saying it had none.
  String get description => _text([
    'description',
    'summary',
    'historical_background',
    'historical_context',
    'history',
    'cultural_context',
    'cultural_impact',
  ], fallback: 'No description available yet.');

  String get period =>
      _text(['era', 'period', 'estimated_age', 'estimatedAge', 'time_period']);

  String get origin =>
      _text(['origin', 'country_of_origin', 'country', 'made_in']);

  String get material => _text(['material', 'materials', 'medium']);

  String get category => _text(['category', 'type', 'object_type']);

  String get condition => _text(['condition', 'grading', 'grade']);

  /// Rarity arrives as a 1-10 score, not a word, so a text-only lookup always
  /// came back empty and the tile read "Not available" on every scan.
  String get rarity {
    final score = _read(['rarity_score', 'rarityScore']);
    final parsed = score is num
        ? score.round()
        : int.tryParse(score?.toString().trim() ?? '');
    if (parsed != null) return '$parsed/10';

    return _text(['rarity', 'rarity_level', 'scarcity']);
  }

  /// The band around the headline figure. The analysis has always returned it
  /// and the report has never shown it, which left a single number standing
  /// for a range the model itself would not commit to.
  String? get priceRange {
    final range = _text(['price_range', 'priceRange', 'value_range'],
        fallback: '');
    if (range.isEmpty || range.startsWith(r'$0')) return null;
    return range;
  }

  /// High, Medium or Low, as returned. Shown because a valuation the model is
  /// unsure of should not look the same as one it is confident about.
  String? get authenticity {
    final value = _text(
      ['authenticity', 'authenticity_confidence', 'authenticityConfidence'],
      fallback: '',
    );
    return value.isEmpty ? null : value;
  }

  String? get careTip {
    final tip = _text(['care_tip', 'careTip', 'care_instructions'],
        fallback: '');
    return tip.isEmpty || tip == 'Handle with care' ? null : tip;
  }

  String get valueLabel {
    final value = _read([
      'reference_price',
      'antique_price',
      'estimated_value',
      'estimatedValue',
      'value',
      'price',
    ]);

    if (value == null) return 'Value not determined';
    if (value is Map) {
      final minimum = value['min'] ?? value['minimum'] ?? value['low'];
      final maximum = value['max'] ?? value['maximum'] ?? value['high'];
      if (minimum != null && maximum != null) {
        return '\$${_cleanNumber(minimum)} - \$${_cleanNumber(maximum)}';
      }
    }
    if (value is num) return '\$${_cleanNumber(value)}';

    final text = value.toString().trim();
    return text.startsWith('\$') ? text : '\$$text';
  }

  double get valueAmount {
    final matches = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*([kKmM])?',
    ).allMatches(valueLabel);
    var highest = 0.0;
    for (final match in matches) {
      final parsed = double.tryParse(match.group(1)!.replaceAll(',', ''));
      if (parsed == null) continue;
      final suffix = match.group(2)?.toLowerCase();
      final multiplier = suffix == 'm'
          ? 1000000
          : suffix == 'k'
          ? 1000
          : 1;
      highest = (parsed * multiplier) > highest ? parsed * multiplier : highest;
    }
    return highest;
  }

  double? get confidence {
    final value = _read(['confidence', 'confidence_score', 'confidenceScore']);
    if (value == null) return null;
    final parsed = double.tryParse(value.toString().replaceAll('%', '').trim());
    if (parsed == null) return null;
    return parsed <= 1 ? parsed : parsed / 100;
  }

  String? get imageUrl {
    final value = _read(['image_url', 'imageUrl', 'result_image', 'photo_url']);
    return value?.toString();
  }

  List<SimilarAntique> get similarAntiques {
    final raw = _read([
      'similar_items',
      'similarItems',
      'similar_listings',
      'similarListings',
      'comparables',
    ]);
    if (raw is! List) return const [];

    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return SimilarAntique(
        name:
            map['name']?.toString() ??
            map['title']?.toString() ??
            'Similar antique',
        price:
            map['price']?.toString() ??
            map['value']?.toString() ??
            'Price unavailable',
        source: map['source']?.toString() ?? map['marketplace']?.toString(),
        imageUrl: map['image_url']?.toString() ?? map['imageUrl']?.toString(),
        url:
            map['url']?.toString() ??
            map['link']?.toString() ??
            map['item_url']?.toString(),
      );
    }).toList();
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _cleanNumber(dynamic value) {
    if (value is num && value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString().replaceAll('\$', '').trim();
  }
}

class SimilarAntique {
  final String name;
  final String price;
  final String? source;
  final String? imageUrl;

  /// The listing itself, so a card can open what it is quoting.
  final String? url;

  const SimilarAntique({
    required this.name,
    required this.price,
    this.source,
    this.imageUrl,
    this.url,
  });
}
