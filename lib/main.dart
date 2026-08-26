import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'constants/app_constants.dart';
import 'helpers/storage_helper.dart';
import 'helpers/appactor_helper.dart';
import 'services/supabase_service.dart';

import 'providers/app_provider.dart';
import 'screens/antique_splash/splash_viewmodel.dart';
import 'screens/antique_splash/splash_view.dart';
import 'screens/antique_maintab/maintab_viewmodel.dart';
import 'screens/antique_maintab/maintab_view.dart';
import 'screens/antique_home/home_viewmodel.dart';
import 'screens/antique_scan/scan_viewmodel.dart';
import 'screens/antique_collection/collection_viewmodel.dart';
import 'screens/antique_premium/antique_premium_view.dart';
import 'screens/antique_onboard/antique_onboard_view.dart';
import 'screens/settings_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageHelper().init();
  await AppactorHelper.shared.initialize();
  await SupabaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()),
            ChangeNotifierProvider(create: (_) => SplashViewModel()),
            ChangeNotifierProvider(create: (_) => MainTabViewModel()),
            ChangeNotifierProvider(create: (_) => HomeViewModel()),
            ChangeNotifierProvider(create: (_) => ScanViewModel()),
            ChangeNotifierProvider(create: (_) => CollectionViewModel()),
          ],
          child: Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return MaterialApp(
                title: AppStrings.appName,
                debugShowCheckedModeBanner: false,
                theme: _buildTheme(),
                initialRoute: AppRoutes.splash,
                routes: _buildRoutes(),
              );
            },
          ),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.playfairDisplayTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h2,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.paddingL,
            vertical: AppSizes.paddingM,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingM,
        ),
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      AppRoutes.splash: (context) => const SplashView(),
      AppRoutes.maintab: (context) => const MainTabView(),
      '/onboard': (context) => const AntiqueOnboardView(),
      '/paywall': (context) => const AntiquePremiumView(),
      AppRoutes.settings: (context) => const SettingsScreen(),
    };
  }
}