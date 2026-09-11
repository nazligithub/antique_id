import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'appactor_helper.dart';

/// Asks for an App Store rating at the two moments the app has earned one:
/// the end of onboarding, and a report the reader has just read.
///
/// Each moment is asked at most once ever, because iOS caps how often the
/// system prompt may appear and a wasted ask is gone for the year. The short
/// alert shown first exists to spend that budget well -- it only reaches the
/// system prompt for readers who say yes, so the cap is not spent on someone
/// who was going to decline.
class RatingHelper {
  RatingHelper._();
  static final RatingHelper shared = RatingHelper._();

  final InAppReview _review = InAppReview.instance;

  /// On the last onboarding page, while the reader is still on it. Behind the
  /// `onboard_rating` remote config flag so the ask can be turned off without
  /// shipping a build.
  ///
  /// This carries most of the app's rating weight: scanning is gated behind
  /// the paywall, so a reader who never subscribes never reaches a report and
  /// never sees [promptAfterResult].
  Future<void> promptAfterOnboarding(BuildContext context) async {
    if (!await AppactorHelper.shared.isOnboardRatingEnabled()) {
      debugPrint('Rating: onboard_rating disabled remotely');
      return;
    }

    if (!context.mounted) return;

    await _ask(
      context,
      key: 'rating_asked_onboarding',
      title: 'Enjoying Antique Id so far?',
      message:
          'We are a small team building this for collectors. A rating helps '
          'other collectors find us ❤️',
      cta: 'Rate Us',
    );
  }

  /// After a report the reader has actually read.
  Future<void> promptAfterResult(BuildContext context) => _ask(
        context,
        key: 'rating_asked_result',
        title: 'Enjoying Antique Id?',
        message:
            'A quick rating helps other collectors find us and keeps the app '
            'improving ❤️',
        cta: 'Rate Us',
      );

  Future<void> _ask(
    BuildContext context, {
    required String key,
    required String title,
    required String message,
    required String cta,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) return;

    if (!await _review.isAvailable()) {
      debugPrint('Rating: store review is unavailable on this device');
      return;
    }

    if (!context.mounted) return;
    final accepted = await _showAlert(context, title, message, cta);
    if (accepted == null) return;

    // Mark it spent on the answer, not on the outcome: iOS may silently
    // decline to show the system sheet, and asking again would only repeat the
    // alert. A reader who said no has answered too -- re-asking them on the
    // next report is nagging, not persuasion.
    await prefs.setBool(key, true);
    if (!accepted) return;

    await _review.requestReview();

    // requestReview returns as soon as the request is filed, not when the
    // system sheet closes -- and iOS offers no callback for that. Without this
    // pause the caller carries straight on, so the sheet finished appearing on
    // top of the paywall the reader had already been pushed to. Holding here
    // keeps it over the screen that asked for it.
    await Future.delayed(const Duration(seconds: 3));
  }

  /// Always offers a way out. A single-action alert that cannot be dismissed
  /// leaves the reader no answer but yes, which is what App Store guideline
  /// 1.1.7 means by manipulating reviews -- and it buys ratings from people
  /// who were cornered rather than persuaded.
  Future<bool?> _showAlert(
    BuildContext context,
    String title,
    String message,
    String cta,
  ) {
    const declineLabel = 'Not now';

    if (Platform.isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(declineLabel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(cta),
            ),
          ],
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(declineLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(cta),
          ),
        ],
      ),
    );
  }
}
