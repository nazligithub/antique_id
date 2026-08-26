import 'package:flutter/material.dart';
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
  static const String appName = 'Antique Identifier';

  // Premium Card
  static const String upgradePremium = 'Upgrade Premium';
  static const String unlockFeatures = 'Unlock to get premium features!';
  static const String upgradeNow = 'Upgrade now';

  // Home Screen
  static const String scanAntiqueIdentifier = 'Scan Antique Identifier';
  static const String identifyAntiques = 'Identify antiques and collectibles';
  static const String chatWithAI = 'Chat with AI Expert';
  static const String viewAll = 'View All';
  static const String featuredAntiques = 'Featured Antiques';

  // Tab Bar
  static const String home = 'Home';
  static const String discover = 'Discover';
  static const String scan = 'Scan';
  static const String collection = 'Collection';
  static const String settings = 'Settings';

  // Popular Questions
  static const String q1 = 'How to identify antique furniture?';
  static const String q2 = 'What makes an item valuable?';
  static const String q3 = 'How to spot fake antiques?';
  static const String q4 = 'Best way to preserve antiques?';
  static const String q5 = 'How to date antique items?';
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
  static const String antiqueBackground = 'assets/background/antique_background.png';
}

class AppDecorations {
  static const BoxDecoration antiqueBackground = BoxDecoration(
    image: DecorationImage(
      image: AssetImage(AppImages.antiqueBackground),
      fit: BoxFit.cover,
    ),
  );
}