import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import 'antique_premium_viewmodel.dart';

const _premiumAccent = Color(0xFFC28B52);

class AntiquePremiumView extends StatelessWidget {
  final bool fromOnboarding;

  const AntiquePremiumView({
    super.key,
    this.fromOnboarding =
        true, // Default to true since it's usually from onboard/splash
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
            child: PopScope(
              canPop: false, // Disable swipe back gesture
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
                                    const Color(
                                      0xFF030712,
                                    ).withValues(alpha: 0),
                                    const Color(
                                      0xFF030712,
                                    ).withValues(alpha: 1),
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
                                        (route) => false,
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
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 30.sp,
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
                                    _buildFeatureItem(
                                      '🏛️',
                                      'Premium Collections',
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
                            child: viewModel.configLoaded
                                ? Column(
                                    children: [
                                      _buildPricingOption(
                                        title: 'Weekly Access',
                                        subtitle:
                                            '3 days free, then cancel anytime',
                                        price: viewModel.weeklyPrice,
                                        isSelected: viewModel.isWeeklySelected,
                                        isWeekly: true,
                                        onTap: () => viewModel.selectWeekly(),
                                      ),
                                      SizedBox(height: 12.h),
                                      _buildPricingOption(
                                        title: 'Yearly Access',
                                        subtitle: 'Billed once a year',
                                        price: viewModel.yearlyPrice,
                                        isSelected: viewModel.isYearlySelected,
                                        isWeekly: false,
                                        onTap: () => viewModel.selectYearly(),
                                      ),
                                    ],
                                  )
                                : SizedBox(
                                    height: 140.h,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                          ),

                          SizedBox(height: 24.h),

                          // Start button at the bottom
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: _AnimatedPremiumButton(
                              isLoading: viewModel.isLoading,
                              isWeeklySelected: viewModel.isWeeklySelected,
                              onPressed: () async {
                                final purchased = await viewModel.purchase(
                                  context,
                                );
                                if (!purchased || !context.mounted) return;

                                if (!fromOnboarding) {
                                  // Opened as a gate part-way through something
                                  // the reader was doing. Clearing the stack
                                  // here dropped them on the home tab and threw
                                  // away the scan they had just paid to run.
                                  Navigator.pop(context, true);
                                  return;
                                }

                                await viewModel.saveOnboardingCompletion();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.maintab,
                                    (route) => false,
                                  );
                                }
                              },
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
                                style: GoogleFonts.lato(
                                  fontSize: 14.sp,
                                  color: Colors.white.withValues(alpha: 0.72),
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
                                  style: GoogleFonts.lato(
                                    fontSize: 13.sp,
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 16.w),
                                width: 1.w,
                                height: 14.h,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              GestureDetector(
                                onTap: viewModel.openPrivacy,
                                child: Text(
                                  'Privacy',
                                  style: GoogleFonts.lato(
                                    fontSize: 13.sp,
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 16.w),
                                width: 1.w,
                                height: 14.h,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final restored = await viewModel.restore(
                                    context,
                                  );
                                  if (restored && context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                },
                                child: Text(
                                  'Restore',
                                  style: GoogleFonts.lato(
                                    fontSize: 13.sp,
                                    color: Colors.white.withValues(alpha: 0.72),
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
          style: GoogleFonts.lato(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingOption({
    required String title,
    required String subtitle,
    required String price,
    required bool isSelected,
    required bool isWeekly,
    required VoidCallback onTap,
  }) {
    const accentColor = _premiumAccent;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 68.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3A2A21)
                  : const Color(0xFF000000).withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 2.w : 1.w,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.24),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
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
                          ? accentColor
                          : Colors.white.withValues(alpha: 0.5),
                      width: 2.w,
                    ),
                    color: isSelected ? accentColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.black, size: 16.sp)
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
                        style: GoogleFonts.lato(
                          fontSize: 16.sp,
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  price,
                  style: GoogleFonts.lato(
                    fontSize: 17.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isWeekly)
            Positioned(
              top: -11.h,
              right: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '3 DAYS FREE',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E211A),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedPremiumButton extends StatefulWidget {
  final bool isLoading;
  final bool isWeeklySelected;
  final Future<void> Function() onPressed;

  const _AnimatedPremiumButton({
    required this.isLoading,
    required this.isWeeklySelected,
    required this.onPressed,
  });

  @override
  State<_AnimatedPremiumButton> createState() => _AnimatedPremiumButtonState();
}

class _AnimatedPremiumButtonState extends State<_AnimatedPremiumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = Curves.easeInOut.transform(_controller.value);
        return Transform.scale(
          scale: 1 + (pulse * 0.012),
          child: GestureDetector(
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Container(
              width: double.infinity,
              height: 56.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_premiumAccent, Color(0xFFA66D3D)],
                ),
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(
                    color: _premiumAccent.withValues(
                      alpha: 0.22 + (pulse * 0.12),
                    ),
                    blurRadius: 14 + (pulse * 5),
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.isWeeklySelected
                            ? 'Start 3-Day Free Trial'
                            : 'Continue',
                        style: GoogleFonts.lato(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
