import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/appactor_helper.dart';
import '../../helpers/intro_offer_helper.dart';
import 'antique_premium_view.dart';

class PremiumEntryView extends StatefulWidget {
  final bool fromOnboarding;

  const PremiumEntryView({super.key, this.fromOnboarding = true});

  @override
  State<PremiumEntryView> createState() => _PremiumEntryViewState();
}

class _PremiumEntryViewState extends State<PremiumEntryView> {
  bool? _showActivation;
  bool _isOpeningPaywall = false;

  @override
  void initState() {
    super.initState();
    _loadEntryConfig();
  }

  Future<void> _loadEntryConfig() async {
    final showActivation = await AppactorHelper.shared
        .isThreeDayActivationEnabled();
    if (!mounted) return;
    setState(() => _showActivation = showActivation);

    if (!showActivation) {
      _openPaywall();
    }
  }

  void _openPaywall() {
    if (!mounted || _isOpeningPaywall) return;
    _isOpeningPaywall = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, __) =>
            AntiquePremiumView(fromOnboarding: widget.fromOnboarding),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showActivation == true) {
      return ThreeDayActivationView(onComplete: _openPaywall);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE5),
      body: const Center(
        child: CircularProgressIndicator(color: Color(0xFFC28B52)),
      ),
    );
  }
}

class ThreeDayActivationView extends StatefulWidget {
  final VoidCallback onComplete;

  const ThreeDayActivationView({super.key, required this.onComplete});

  @override
  State<ThreeDayActivationView> createState() => _ThreeDayActivationViewState();
}

class _ThreeDayActivationViewState extends State<ThreeDayActivationView>
    with SingleTickerProviderStateMixin {
  static const accent = Color(0xFFC28B52);
  static const ink = Color(0xFF3E2723);
  static const surface = Color(0xFFF6EFE5);
  late final AnimationController _controller;
  Timer? _animationStartTimer;
  Timer? _completionTimer;
  bool _didComplete = false;

  /// Starts on a neutral introductory offer wording and is updated the moment
  /// StoreKit answers. The screen animates for well over a second before either
  /// line is legible, so the swap lands long before anyone can read the wrong one.
  String _offerLine = 'entry_offer_unlocked'.tr();

  Future<void> _loadOfferLine() async {
    final productId = AppactorHelper.shared.weeklyPackage?.productId;
    if (productId == null || productId.isEmpty) return;
    final offer = await IntroOfferHelper.forProduct(productId);
    if (offer == null || !mounted) return;
    final days = offer.totalDays;
    final isWeeks = days >= 7 && days % 7 == 0;
    final span = days <= 0
        ? ''
        : isWeeks
            ? (days ~/ 7 == 1
                ? 'entry_span_first_week'.tr()
                : 'paywall_span_weeks'.tr(namedArgs: {'count': '${days ~/ 7}'}))
            : 'paywall_span_days'.tr(namedArgs: {'count': '$days'});
    setState(() {
      if (offer.isFree) {
        _offerLine = span.isNotEmpty
            ? 'entry_free_trial_unlocked'.tr(namedArgs: {'span': span})
            : 'entry_free_trial_unlocked_generic'.tr();
      } else {
        _offerLine = span.isNotEmpty
            ? 'entry_paid_offer'.tr(namedArgs: {'span': span, 'price': offer.displayPrice})
            : offer.displayPrice;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadOfferLine();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
      value: 0,
    );
    _animationStartTimer = Timer(const Duration(milliseconds: 380), () {
      if (mounted) _controller.forward();
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.selectionClick();
      }
    });
    _completionTimer = Timer(const Duration(milliseconds: 3800), () {
      _complete();
    });
  }

  void _complete() {
    if (!mounted || _didComplete) return;
    _didComplete = true;
    _completionTimer?.cancel();
    widget.onComplete();
  }

  @override
  void dispose() {
    _animationStartTimer?.cancel();
    _completionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: surface,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _complete,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final progress = Curves.easeOutCubic.transform(
                      _controller.value,
                    );
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUnlockMark(progress),
                        SizedBox(height: 30.h),
                        Opacity(
                          opacity: 0.72 + (progress * 0.28),
                          child: Text(
                            'entry_offer_ready'.tr(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w600,
                              color: ink,
                              height: 1.15,
                            ),
                          ),
                        ),
                        SizedBox(height: 7.h),
                        Text(
                          _offerLine,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        AnimatedOpacity(
                          opacity: progress,
                          duration: const Duration(milliseconds: 180),
                          child: _buildDivider(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockMark(double progress) {
    return SizedBox(
      width: 196.w,
      height: 196.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(196.w),
            painter: _UnlockRaysPainter(color: accent, progress: progress),
          ),
          Container(
            width: 156.w,
            height: 156.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.22 + (progress * 0.2)),
              ),
            ),
          ),
          Container(
            width: 132.w,
            height: 132.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.32),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.05 + (progress * 0.1)),
                  blurRadius: 24,
                  spreadRadius: progress * 2,
                ),
              ],
            ),
          ),
          _buildToggle(progress),
        ],
      ),
    );
  }

  Widget _buildToggle(double progress) {
    return Container(
      width: 122.w,
      height: 64.h,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFF8B7C6D), accent, progress),
        borderRadius: BorderRadius.circular(36.r),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08 + (progress * 0.16)),
            blurRadius: 14,
            spreadRadius: progress,
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.lerp(
          Alignment.centerLeft,
          Alignment.centerRight,
          progress,
        )!,
        child: Container(
          width: 54.w,
          height: 54.h,
          decoration: BoxDecoration(
            color: Color.lerp(const Color(0xFFE4D9CB), Colors.white, progress),
            shape: BoxShape.circle,
          ),
          child: Icon(
            progress > 0.55
                ? Icons.lock_open_rounded
                : Icons.lock_outline_rounded,
            color: progress > 0.55 ? accent : ink.withValues(alpha: 0.6),
            size: 21.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 34.w,
          child: Divider(color: accent.withValues(alpha: 0.4)),
        ),
        Container(
          width: 5.w,
          height: 5.w,
          margin: EdgeInsets.symmetric(horizontal: 9.w),
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        SizedBox(
          width: 34.w,
          child: Divider(color: accent.withValues(alpha: 0.4)),
        ),
      ],
    );
  }
}

class _UnlockRaysPainter extends CustomPainter {
  final Color color;
  final double progress;

  const _UnlockRaysPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08 + (progress * 0.3))
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < 8; index++) {
      final angle = (index * 3.141592653589793 * 2) / 8;
      final startRadius = radius * 0.85;
      final endRadius = startRadius + (radius * 0.12 * progress);
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + (direction * startRadius),
        center + (direction * endRadius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UnlockRaysPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}
