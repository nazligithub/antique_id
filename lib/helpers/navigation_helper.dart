import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class NavigationHelper {
  static final NavigationHelper _instance = NavigationHelper._internal();
  factory NavigationHelper() => _instance;
  NavigationHelper._internal();

  static Future<dynamic> navigateTo(BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static Future<dynamic> navigateAndReplace(
      BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushReplacementNamed(context, routeName,
        arguments: arguments);
  }

  static void navigateBack(BuildContext context, {dynamic result}) {
    Navigator.pop(context, result);
  }

  static Future<dynamic> navigateAndRemoveUntil(
      BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil(
        context, routeName, (route) => false,
        arguments: arguments);
  }

  static void goToMainTabAndClearStack(BuildContext context) {
    navigateAndRemoveUntil(context, AppRoutes.maintab);
  }

  static void goToOnboardingAndClearStack(BuildContext context) {
    navigateAndRemoveUntil(context, AppRoutes.onboard);
  }

  static void goToSplashAndClearStack(BuildContext context) {
    navigateAndRemoveUntil(context, AppRoutes.splash);
  }

  static void goToHome(BuildContext context, {Object? arguments}) {
    navigateTo(context, AppRoutes.home, arguments: arguments);
  }

  static void goToScan(BuildContext context, {Object? arguments}) {
    navigateTo(context, AppRoutes.scan, arguments: arguments);
  }

  static void goToCollection(BuildContext context, {Object? arguments}) {
    navigateTo(context, AppRoutes.collection, arguments: arguments);
  }

  static void goToAntiqueDetail(BuildContext context, {Object? arguments}) {
    navigateTo(context, AppRoutes.antiqueDetail, arguments: arguments);
  }
}