import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
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
  final AntiquePremiumViewModel? viewModelForTesting;

  const AntiquePremiumView({
    super.key,
    this.fromOnboarding =
        true, // Default to true since it's usually from onboard/splash
    this.viewModelForTesting,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildBody(BuildContext context, AntiquePremiumViewModel viewModel, Widget? child) {
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
                                  'paywall_title'.tr(),
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
                                      'paywall_feature_scanning'.tr(),
                                    ),
                                    SizedBox(height: 8.h),
                                    _buildFeatureItem(
                                      '🔍',
                                      'paywall_feature_recognition'.tr(),
                                    ),
                                    SizedBox(height: 8.h),
                                    _buildFeatureItem(
                                      '🏛️',
                                      'paywall_feature_collections'.tr(),
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
                                        title: 'paywall_weekly'.tr(),
                                        subtitle: viewModel.weeklySubtitle,
                                        price: viewModel.weeklyDisplayPrice,
                                        isSelected: viewModel.isWeeklySelected,
                                        isWeekly: true,
                                        badgeLabel: viewModel.weeklyBadgeLabel,
                                        onTap: () => viewModel.selectWeekly(),
                                      ),
                                      SizedBox(height: 12.h),
                                      _buildPricingOption(
                                        title: 'paywall_yearly'.tr(),
                                        subtitle: 'paywall_yearly_subtitle'.tr(),
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
                              ctaLabel: viewModel.primaryCtaLabel,
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
                                    ? 'paywall_secured_app_store'.tr()
                                    : 'paywall_secured_google_play'.tr(),
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
                                  'paywall_terms'.tr(),
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
                                  'paywall_privacy'.tr(),
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
                                  'common_restore'.tr(),
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
        }

    if (viewModelForTesting != null) {
      return ChangeNotifierProvider<AntiquePremiumViewModel>.value(
        value: viewModelForTesting!,
        child: Consumer<AntiquePremiumViewModel>(builder: buildBody),
      );
    }
    return ChangeNotifierProvider(
      create: (_) => AntiquePremiumViewModel()..initialize(),
      child: Consumer<AntiquePremiumViewModel>(builder: buildBody),
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
    String? badgeLabel,
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
          if (isWeekly && badgeLabel != null)
            Positioned(
              top: -11.h,
              right: 12.w,
              child: _OfferBadge(label: badgeLabel),
            ),
        ],
      ),
    );
  }
}

class _AnimatedPremiumButton extends StatefulWidget {
  final bool isLoading;
  final String ctaLabel;
  final Future<void> Function() onPressed;

  const _AnimatedPremiumButton({
    required this.isLoading,
    required this.ctaLabel,
    required this.onPressed,
  });

  @override
  State<_AnimatedPremiumButton> createState() => _AnimatedPremiumButtonState();
}

class _AnimatedPremiumButtonState extends State<_AnimatedPremiumButton>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  /// Runs one way, unlike the pulse: a band of light crosses the button
  /// during the first two thirds of each cycle and the rest is a rest.
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _sweep]),
      builder: (context, child) {
        final pulse = Curves.easeInOut.transform(_controller.value);
        // -1 parks the band off the left edge, 1 off the right; the extra
        // reach past 1 is the pause between sweeps.
        final slide = -1 + (_sweep.value * 3);
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
              child: Stack(
                children: [
                  Center(
                    child: widget.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Padding(
                            // A store price can be long ('Rp 15.000'), and
                            // the label shrinks to fit rather than wrapping
                            // in a pill this short.
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.ctaLabel,
                                maxLines: 1,
                                style: GoogleFonts.lato(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (!widget.isLoading)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28.r),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: const Alignment(-1, -0.4),
                                end: const Alignment(1, 0.4),
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.34),
                                  Colors.white.withValues(alpha: 0),
                                ],
                                stops: const [0.38, 0.5, 0.62],
                                transform: _SlidingGradientTransform(slide),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shifts a gradient sideways by a fraction of its box, which is all a
/// shimmer is: the same gradient, drawn a little further along each frame.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
}

/// The offer pill above the weekly card. The lettering is a warm gradient
/// that keeps sliding through the text, on a dark capsule so the colours
/// read against the card's own accent border.
class _OfferBadge extends StatefulWidget {
  const _OfferBadge({required this.label});

  final String label;

  @override
  State<_OfferBadge> createState() => _OfferBadgeState();
}

class _OfferBadgeState extends State<_OfferBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  // First and last match so the repeated gradient loops without a seam.
  static const _lettering = [
    Color(0xFFFFC857),
    Color(0xFFFFF3D0),
    Color(0xFFFF8A5B),
    Color(0xFFFFC857),
  ];

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
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1C14),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _premiumAccent, width: 1.w),
            boxShadow: [
              BoxShadow(
                color: _lettering.first.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              colors: _lettering,
              tileMode: TileMode.repeated,
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds),
            child: child,
          ),
        );
      },
      child: Text(
        widget.label,
        style: GoogleFonts.lato(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
