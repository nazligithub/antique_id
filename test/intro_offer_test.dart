import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:antique_id/helpers/intro_offer_helper.dart';
import 'package:antique_id/screens/antique_premium/antique_premium_viewmodel.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
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
  // The copy under test is read through easy_localization, so hand it the
  // English file the app ships with rather than asserting on raw keys.
  setUpAll(() {
    final english = jsonDecode(
      File('assets/translations/en.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    Localization.load(const Locale('en'), translations: Translations(english));
  });

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

    test('reads a 1-week pay-as-you-go introductory offer', () {
      final weeklyOffer = offer(
        mode: 'pay_as_you_go',
        price: r'$0.99',
        unit: 'week',
        value: 1,
      );
      expect(weeklyOffer.isFree, isFalse);
      expect(weeklyOffer.mode, IntroOfferMode.payAsYouGo);
      expect(weeklyOffer.totalDays, 7);
      expect(weeklyOffer.durationLabel, '1-Week');
      expect(weeklyOffer.displayPrice, r'$0.99');
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

  group('AntiquePremiumViewModel copy formatting', () {
    test('formats 1-week pay-as-you-go introductory offer', () {
      final vm = AntiquePremiumViewModel();
      vm.introOfferForTesting = offer(
        mode: 'pay_as_you_go',
        price: r'$0.99',
        unit: 'week',
        value: 1,
      );

      expect(vm.weeklyBadgeLabel, 'SPECIAL OFFER');
      expect(vm.weeklyPrice, '\$0.99');
      expect(vm.weeklyDisplayPrice, '\$0.99');
      expect(vm.weeklyRenewalPrice, '\$4.99');
      expect(vm.primaryCtaLabel, 'Start Trial for \$0.99');
      expect(vm.weeklySubtitle, 'Then \$4.99/week, cancel anytime');
    });

    test('formats 3-day paid introductory offer', () {
      final vm = AntiquePremiumViewModel();
      vm.introOfferForTesting = offer(
        mode: 'pay_up_front',
        price: r'$0.99',
        unit: 'day',
        value: 3,
      );

      expect(vm.weeklyBadgeLabel, 'SPECIAL OFFER');
      expect(vm.weeklyPrice, '\$0.99');
      expect(vm.weeklyDisplayPrice, '\$0.99');
      expect(vm.weeklyRenewalPrice, '\$4.99');
      expect(vm.primaryCtaLabel, 'Start Trial for \$0.99');
      expect(vm.weeklySubtitle, 'Then \$4.99/week, cancel anytime');
    });

    test('formats 1-week free trial offer', () {
      final vm = AntiquePremiumViewModel();
      vm.introOfferForTesting = offer(
        mode: 'free_trial',
        unit: 'week',
        value: 1,
      );

      expect(vm.weeklyBadgeLabel, '1-WEEK FREE');
      expect(vm.weeklyPrice, '\$4.99');
      expect(vm.weeklyDisplayPrice, '\$4.99');
      expect(vm.primaryCtaLabel, 'Start 1-Week Free Trial');
      expect(vm.weeklySubtitle, '1 week free, then cancel anytime');
    });

    test('formats 3-day free trial offer', () {
      final vm = AntiquePremiumViewModel();
      vm.introOfferForTesting = offer(
        mode: 'free_trial',
        unit: 'day',
        value: 3,
      );

      expect(vm.weeklyBadgeLabel, '3 DAYS FREE');
      expect(vm.weeklyPrice, '\$4.99');
      expect(vm.weeklyDisplayPrice, '\$4.99');
      expect(vm.primaryCtaLabel, 'Start 3-Day Free Trial');
      expect(vm.weeklySubtitle, '3 days free, then cancel anytime');
    });

    test('formats fallback when no offer is available', () {
      final vm = AntiquePremiumViewModel();
      vm.introOfferForTesting = null;

      expect(vm.weeklyBadgeLabel, isNull);
      expect(vm.weeklyPrice, '\$4.99');
      expect(vm.weeklyDisplayPrice, '\$4.99');
      expect(vm.primaryCtaLabel, 'Continue');
      expect(vm.weeklySubtitle, 'Cancel anytime');
    });

    test('handles paid intro offer with empty displayPrice defensively', () {
      final vm = AntiquePremiumViewModel();
      vm.introOfferForTesting = offer(
        mode: 'pay_as_you_go',
        price: '',
        unit: 'week',
        value: 1,
      );

      expect(vm.weeklyBadgeLabel, isNull);
      expect(vm.weeklyPrice, '\$4.99');
      expect(vm.primaryCtaLabel, 'Continue');
      expect(vm.weeklySubtitle, 'Cancel anytime');
    });

    test('formats paid offer with non-dollar store currency', () {
      final vm = AntiquePremiumViewModel();
      vm.introOfferForTesting = offer(
        mode: 'pay_as_you_go',
        price: '₺9,99',
        unit: 'week',
        value: 1,
      );

      expect(vm.weeklyBadgeLabel, 'SPECIAL OFFER');
      expect(vm.weeklyPrice, '₺9,99');
      expect(vm.weeklyDisplayPrice, '₺9,99');
      expect(vm.primaryCtaLabel, 'Start Trial for ₺9,99');
      expect(vm.weeklySubtitle, 'Then \$4.99/week, cancel anytime');
    });

    test('returns Continue for primaryCtaLabel when yearly plan is selected', () {
      final vm = AntiquePremiumViewModel();
      vm.introOfferForTesting = offer(
        mode: 'pay_as_you_go',
        price: r'$0.99',
        unit: 'week',
        value: 1,
      );
      vm.selectYearly();

      expect(vm.primaryCtaLabel, 'Continue');

      vm.selectWeekly();
      expect(vm.primaryCtaLabel, 'Start Trial for \$0.99');
    });
  });
}
