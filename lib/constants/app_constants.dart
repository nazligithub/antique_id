import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  static const Color primary = Color(0xFF8B6F47);
  static const Color secondary = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF5E9D3);
  static const Color cardBg = Color(0xFFFAF5ED);
  static const Color textPrimary = Color(0xFF3E2723);
  static const Color textSecondary = Color(0xFF6D4C41);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color error = Color(0xFFB71C1C);
  static const Color success = Color(0xFF1B5E20);

  static const Color premiumGold = Color(0xFFD4AF37);
  static const Color tabBarBg = Color(0xFF3E2723);
  static const Color tabBarSelected = Color(0xFF8B6F47);
  static const Color tabBarUnselected = Color(0xFF9E9E9E);
}

class AppTextStyles {
  static TextStyle get playfair => GoogleFonts.playfairDisplay();

  static TextStyle get h1 => playfair.copyWith(
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle get h2 => playfair.copyWith(
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get h3 => playfair.copyWith(
    fontSize: 20.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get body1 => playfair.copyWith(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle get body2 => playfair.copyWith(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => playfair.copyWith(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.grey,
  );

  static TextStyle get button => playfair.copyWith(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}

class AppRoutes {
  static const String splash = '/splash';
  static const String onboard = '/onboard';
  static const String maintab = '/maintab';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String collection = '/collection';
  static const String antiqueDetail = '/antique-detail';
  static const String settings = '/settings';
}

class AppStrings {
  // Every string here is read through easy_localization, so they are getters
  // rather than constants: the value depends on the locale at call time.
  static const String appName = 'Antique Identifier';

  // Premium Card
  static String get upgradePremium => 'home_upgrade_premium'.tr();
  static String get unlockFeatures => 'home_unlock_features'.tr();
  static String get upgradeNow => 'home_upgrade_now'.tr();

  // Home Screen
  static String get scanAntiqueIdentifier => 'home_scan_title'.tr();
  static String get identifyAntiques => 'home_scan_subtitle'.tr();
  static String get chatWithAI => 'home_chat_with_ai'.tr();
  static String get viewAll => 'home_view_all'.tr();
  static String get featuredAntiques => 'home_featured_antiques'.tr();

  // Tab Bar
  static String get home => 'tab_home'.tr();
  static String get discover => 'tab_discover'.tr();
  static String get scan => 'tab_scan'.tr();
  static String get collection => 'tab_collection'.tr();
  static String get settings => 'tab_settings'.tr();
}

class AppSizes {
  static double get paddingXS => 4.0.w;
  static double get paddingS => 8.0.w;
  static double get paddingM => 16.0.w;
  static double get paddingL => 24.0.w;
  static double get paddingXL => 32.0.w;

  static double get radiusS => 8.0.r;
  static double get radiusM => 12.0.r;
  static double get radiusL => 16.0.r;
}

class AppImages {
  static const String antiqueBackground =
      'assets/background/antique_background.png';
}

class AppDecorations {
  static const BoxDecoration antiqueBackground = BoxDecoration(
    image: DecorationImage(
      image: AssetImage(AppImages.antiqueBackground),
      fit: BoxFit.cover,
    ),
  );
}
