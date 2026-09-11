import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import 'antique_solution_screen.dart';

class LoadingScreen extends StatefulWidget {
  final String imagePath;

  const LoadingScreen({super.key, required this.imagePath});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _tipTimer;
  Timer? _progressTimer;
  final CancelToken _cancelToken = CancelToken();
  int currentTipIndex = 0;
  double progress = 0.0;
  double _targetProgress = 0.12;
  String _stepLabel = 'Processing image';
  bool isAnalyzing = true;

  // How full the bar should be once each server-reported step is reached.
  static const Map<int, double> _stepTargets = {1: 0.18, 2: 0.65, 3: 0.92};

  final List<String> tips = [
    "Did you know? The oldest known antique is over 4,000 years old!",
    "Tip: Look for maker's marks or signatures on your antiques.",
    "Fun fact: Some antiques increase in value by 10-15% annually.",
    "Remember: Age doesn't always determine an antique's value.",
    "Interesting: Antiques are items that are at least 100 years old.",
    "Tip: Original condition often matters more than restoration.",
    "Did you know? Provenance can significantly increase an item's value.",
    "Fun fact: Some modern items are already considered collectibles!",
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startTipRotation();
    _startProgressAnimation();
    _analyzeAntique();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _startTipRotation() {
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && isAnalyzing) {
        setState(() {
          currentTipIndex = (currentTipIndex + 1) % tips.length;
        });
      }
    });
  }

  /// Eases the bar toward the step the server last reported, so it keeps
  /// moving during a long step without ever running ahead of the real work.
  void _startProgressAnimation() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted || !isAnalyzing) return;
      if (progress >= _targetProgress) return;
      setState(() {
        progress = min(_targetProgress, progress + (_targetProgress - progress) * 0.03 + 0.0009);
      });
    });
  }

  void _applyStatus(Map<String, dynamic> status) {
    final step = status['step'];
    final label = status['step_label'];
    if (!mounted) return;
    setState(() {
      if (label is String && label.isNotEmpty) _stepLabel = label;
      if (step is int) _targetProgress = _stepTargets[step] ?? _targetProgress;
    });
  }

  Future<void> _analyzeAntique() async {
    try {
      final accepted = await ApiService().startScan(
        widget.imagePath,
        additionalInfo: "Scanned from mobile app",
        cancelToken: _cancelToken,
      );

      final accData = accepted['data'];
      final started = accData is Map<String, dynamic> ? accData : const <String, dynamic>{};

      // A server without the async migration answers with the finished scan.
      final result = started['status'] == 'processing'
          ? await _awaitResult(started['scan_id'])
          : accepted;

      if (mounted) {
        setState(() {
          progress = 1.0;
          isAnalyzing = false;
        });

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AntiqueSolutionScreen(
                analysisResult: result,
                imagePath: widget.imagePath,
              ),
            ),
          );
        }
      }
    } on ApiException catch (error) {
      // Leaving the screen cancels the request; that is not a failure to
      // report back to someone who has already walked away.
      if (!mounted || error.wasCancelled) return;
      _failWith(error.message);
    } catch (e) {
      debugPrint('Analysis failed: $e');
      if (!mounted) return;
      // Raw exception text used to reach the reader here, stack noise and all.
      _failWith('Analysis failed. Please try again.');
    }
  }

  void _failWith(String message) {
    setState(() {
      isAnalyzing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );

    Navigator.pop(context);
  }

  /// Polls until the scan finishes, then returns it in the same envelope a
  /// synchronous scan uses.
  Future<Map<String, dynamic>> _awaitResult(dynamic scanId) async {
    final deadline = DateTime.now().add(const Duration(minutes: 5));
    var consecutiveFailures = 0;
    const maxConsecutiveFailures = 4;

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) throw ApiException('Scan cancelled', null);

      final Map<String, dynamic> response;
      try {
        response = await ApiService().getScanStatus(
          scanId,
          cancelToken: _cancelToken,
        );
        consecutiveFailures = 0;
      } on ApiException catch (error) {
        if (error.wasCancelled) rethrow;

        // The server is still working on the scan; a dropped poll is no
        // reason to throw away a report the reader has paid for. Only give up
        // once the connection has failed repeatedly.
        consecutiveFailures++;
        debugPrint('Scan poll failed ($consecutiveFailures): ${error.message}');
        if (consecutiveFailures >= maxConsecutiveFailures) rethrow;
        continue;
      }

      final raw = response['data'];
      final status = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
      _applyStatus(status);

      if (status['status'] == 'complete') {
        return {'success': true, 'data': status['result']};
      }
      if (status['status'] == 'failed') {
        throw ApiException(
          status['error'] as String? ?? 'Analysis failed',
          null,
        );
      }
    }

    throw ApiException(
      'This is taking longer than usual. Your scan is still saved — check your history in a moment.',
      null,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tipTimer?.cancel();
    _progressTimer?.cancel();
    // Stops the upload or the in-flight poll instead of letting it run on
    // against a screen that no longer exists.
    _cancelToken.cancel('Loading screen dismissed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false, // Disable back navigation
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F1E8),
          body: Container(
            decoration: AppDecorations.antiqueBackground,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    SizedBox(height: 40.h),
                    Text(
                      'Analyzing Your Antique',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D1810),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _stepLabel,
                        key: ValueKey(_stepLabel),
                        style: GoogleFonts.lora(
                          fontSize: 16.sp,
                          color: const Color(0xFF2D1810).withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 60.h),
                    SizedBox(
                      height: 200.h,
                      child: Lottie.asset(
                        'assets/antique_loading.json',
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF8B4513),
                            ),
                            minHeight: 8.h,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: GoogleFonts.lora(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B4513),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 60.h),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8B4513),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: Text(
                                    tips[currentTipIndex],
                                    key: ValueKey(currentTipIndex),
                                    style: GoogleFonts.lora(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF2D1810),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Text(
                      'A detailed appraisal can take up to a minute.',
                      style: GoogleFonts.lora(
                        fontSize: 14.sp,
                        color: const Color(0xFF2D1810).withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
