import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:antique_id/models/antique_analysis.dart';
import 'package:antique_id/services/api_service.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter_test/flutter_test.dart';

void loadLocale(String code) {
  final strings = jsonDecode(
    File('assets/translations/$code.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  Localization.load(Locale(code), translations: Translations(strings));
}

AntiqueAnalysis analysis(Map<String, dynamic> analysisData) {
  return AntiqueAnalysis.fromResponse(
    {
      'success': true,
      'data': {'antique_name': 'Vase', 'analysis_data': analysisData},
    },
    imagePath: '',
  );
}

void main() {
  // The server grades condition and authenticity in English no matter what
  // language the rest of the report is in; the app has to translate them.
  group('AntiqueAnalysis grades', () {
    setUp(() => loadLocale('tr'));

    test('translates the condition grade', () {
      expect(analysis({'condition': 'Excellent'}).condition, 'Mükemmel');
      expect(analysis({'condition': 'good'}).condition, 'İyi');
      expect(analysis({'condition': 'Fair'}).condition, 'Orta');
      expect(analysis({'condition': 'Poor'}).condition, 'Kötü');
    });

    test('translates the authenticity confidence', () {
      expect(analysis({'authenticity': 'High'}).authenticity, 'Yüksek');
      expect(analysis({'authenticity': 'Medium'}).authenticity, 'Orta');
      expect(analysis({'authenticity': 'low'}).authenticity, 'Düşük');
      expect(analysis({}).authenticity, isNull);
    });

    test('treats an unknown grade as missing', () {
      expect(analysis({'condition': 'Unknown'}).condition, 'Bilgi yok');
      expect(analysis({}).condition, 'Bilgi yok');
    });

    test('leaves prices exactly as the server sent them', () {
      final report = analysis({
        'reference_price': r'$1,450',
        'price_range': r'$1,200 - $1,800',
      });
      expect(report.valueLabel, r'$1,450');
      expect(report.priceRange, r'$1,200 - $1,800');
    });

    test('reads the search name and report language', () {
      final report = analysis({'search_name': 'Meissen vase', 'language': 'tr'});
      expect(report.searchName, 'Meissen vase');
      expect(report.language, 'tr');
      expect(analysis({}).searchName, isNull);
      expect(analysis({}).language, isNull);
    });
  });

  group('ApiService.scanFailureMessage', () {
    setUp(() => loadLocale('tr'));

    test('tells a photo without an antique apart from other failures', () {
      expect(
        ApiService.scanFailureMessage('Please upload antique image.'),
        'Bu fotoğrafta bir antika bulamadık. Lütfen başka bir fotoğraf dene.',
      );
      expect(
        ApiService.scanFailureMessage('Analysis was interrupted. Please scan again.'),
        'Antika taranamadı',
      );
      expect(ApiService.scanFailureMessage(null), 'Antika taranamadı');
    });
  });
}
