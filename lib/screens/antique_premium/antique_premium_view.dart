import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import 'antique_premium_viewmodel.dart';

class AntiquePremiumView extends StatelessWidget {
  final bool fromOnboarding;

  const AntiquePremiumView({
    super.key,
    this.fromOnboarding = true, // Default to true since it's usually from onboard/splash
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AntiquePremiumViewModel()..initialize(),
      child: Consumer<AntiquePremiumViewModel>(
        builder: (context, viewModel, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.dark,
              statusBarColor: Colors.transparent,
            ),
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  // Background image with gradient
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image
                        Positioned.fill(
                          child: Image.asset(
                            'assets/antique_paywall.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF030712).withValues(alpha: 0),
                                  const Color(0xFF030712).withValues(alpha: 1),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  SafeArea(
                    child: Column(
                      children: [
                        // Close button
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: IconButton(
                              icon: Container(
                                width: 36.w,
                                height: 36.h,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                              onPressed: () async {
                                if (fromOnboarding) {
                                  // Coming from onboard or splash, save onboarding completion and go to MainTab
                                  await viewModel.saveOnboardingCompletion();
                                  if (context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      AppRoutes.maintab,
                                      (route) => false
                                    );
                                  }
                                } else {
                                  // Coming from inside the app, just close
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        ),

                        // Expanded to push content to bottom
                        const Spacer(),

                        // Title and subtitle
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            children: [
                              Text(
                                'Unlock Premium Antiques',
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20.h),
                              // Features list
                              Column(
                                children: [
                                  _buildFeatureItem(
                                    '🏺',
                                    'Unlimited Antique Scanning',
                                  ),
                                  SizedBox(height: 8.h),
                                  _buildFeatureItem(
                                    '🔍',
                                    'Advanced AI Recognition',
                                  ),
                                  SizedBox(height: 8.h),
                                  _buildFeatureItem('🏛️', 'Premium Collections'),
                                  SizedBox(height: 8.h),
                                  _buildFeatureItem(
                                    '🤖',
                                    'AI Chat Expert',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Pricing options
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            children: [
                              _buildPricingOption(
                                index: 0,
                                title: 'Weekly Access',
                                subtitle: 'Cancel anytime',
                                price: viewModel.weeklyPrice,
                                isSelected: viewModel.isWeeklySelected,
                                isWeekly: true,
                                onTap: () => viewModel.selectWeekly(),
                              ),
                              SizedBox(height: 12.h),
                              _buildPricingOption(
                                index: 1,
                                title: 'Yearly Access',
                                subtitle: '${viewModel.yearlyPrice} / year',
                                price: viewModel.yearlyWeeklyPrice,
                                isSelected: viewModel.isYearlySelected,
                                isWeekly: false,
                                onTap: () => viewModel.selectYearly(),
                                savingsPercentage: viewModel.savingsPercentage,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Start button at the bottom
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: GestureDetector(
                            onTap: viewModel.isLoading
                                ? null
                                : () async {
                                    final purchased = await viewModel
                                        .purchase();
                                    if (purchased) {
                                      // Save onboarding completion and navigate to main tab
                                      await viewModel.saveOnboardingCompletion();
                                      if (context.mounted) {
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          AppRoutes.maintab,
                                          (route) => false
                                        );
                                      }
                                    }
                                  },
                            child: Container(
                              width: double.infinity,
                              height: 56.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(28.r),
                              ),
                              child: Center(
                                child: viewModel.isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Security badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 16.sp,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              Platform.isIOS
                                  ? 'Secured by App Store'
                                  : 'Secured by Google Play',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),

                        // Footer links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: viewModel.openTerms,
                              child: Text(
                                'Terms',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: 16.w,
                              ),
                              width: 1.w,
                              height: 14.h,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            GestureDetector(
                              onTap: viewModel.openPrivacy,
                              child: Text(
                                'Privacy',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: 16.w,
                              ),
                              width: 1.w,
                              height: 14.h,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final restored = await viewModel.restore();
                                if (restored && context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              },
                              child: Text(
                                'Restore',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: TextStyle(fontSize: 16.sp)),
        SizedBox(width: 8.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingOption({
    required int index,
    required String title,
    required String subtitle,
    required String price,
    required bool isSelected,
    required bool isWeekly,
    required VoidCallback onTap,
    int? savingsPercentage,
  }) {
    final isYearly = !isWeekly;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 64.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : const Color(0xFF000000).withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 2.w : 1.w,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.5),
                      width: 2.w,
                    ),
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 16.sp)
                      : null,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.normal,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Discount badge for yearly plan
          if (isYearly)
            Positioned(
              top: -10.h,
              right: 10.w,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 12.sp),
                    SizedBox(width: 3.w),
                    Text(
                      'SAVE ${savingsPercentage ?? 70}%',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}