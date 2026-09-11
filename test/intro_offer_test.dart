import 'package:antique_id/helpers/intro_offer_helper.dart';
import 'package:flutter_test/flutter_test.dart';

IntroOffer offer({
  required String mode,
  String price = '',
  String unit = 'day',
  int value = 3,
  int count = 1,
}) {
  return IntroOffer.fromMap({
    'mode': mode,
    'displayPrice': price,
    'periodUnit': unit,
    'periodValue': value,
    'periodCount': count,
  })!;
}

void main() {
  group('IntroOffer', () {
    test('reads a three day free trial', () {
      final trial = offer(mode: 'free_trial');
      expect(trial.isFree, isTrue);
      expect(trial.totalDays, 3);
      expect(trial.durationLabel, '3-Day');
    });

    test('reads a paid three day trial and keeps the store price verbatim', () {
      final paid = offer(mode: 'pay_up_front', price: '₺9,00');
      expect(paid.isFree, isFalse);
      expect(paid.totalDays, 3);
      // The currency is whatever the store said. Formatting it here is how a
      // paywall ends up promising dollars to someone paying in lira.
      expect(paid.displayPrice, '₺9,00');
    });

    test('multiplies the period by its count', () {
      final threeMonths = offer(mode: 'pay_as_you_go', unit: 'month', value: 1, count: 3);
      expect(threeMonths.totalDays, 90);
    });

    test('says weeks when the span divides evenly', () {
      expect(offer(mode: 'free_trial', unit: 'week', value: 1).durationLabel, '1-Week');
      expect(offer(mode: 'free_trial', unit: 'day', value: 14).durationLabel, '2-Week');
      expect(offer(mode: 'free_trial', unit: 'day', value: 3).durationLabel, '3-Day');
    });

    test('rejects a mode it does not understand rather than guessing', () {
      expect(IntroOffer.fromMap({'mode': 'something_new'}), isNull);
    });

    test('survives a payload missing every optional field', () {
      final sparse = IntroOffer.fromMap({'mode': 'free_trial'});
      expect(sparse, isNotNull);
      expect(sparse!.displayPrice, '');
      expect(sparse.totalDays, 0);
      expect(sparse.durationLabel, '');
    });
  });
}
