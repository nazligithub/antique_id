import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';
import 'antique_solution_screen.dart';

class LoadingScreen extends StatefulWidget {
  final String imagePath;

  const LoadingScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  Timer? _tipTimer;
  Timer? _progressTimer;
  int currentTipIndex = 0;
  double progress = 0.0;
  bool isAnalyzing = true;

  final List<String> tips = [
    "Did you know? The oldest known antique is over 4,000 years old!",
    "Tip: Look for maker's marks or signatures on your antiques.",
    "Fun fact: Some antiques increase in value by 10-15% annually.",
    "Remember: Age doesn't always determine an antique's value.",
    "Interesting: Antiques are items that are at least 100 years old.",
    "Tip: Original condition often matters more than restoration.",
    "Did you know? Provenance can significantly increase an item's value.",
    "Fun fact: Some modern items are already considered collectibles!"
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

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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

  void _startProgressAnimation() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && isAnalyzing) {
        setState(() {
          progress = min(0.95, progress + (Random().nextDouble() * 0.02));
        });
      }
    });
  }

  Future<void> _analyzeAntique() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      final result = await ApiService().scanAntique(
        widget.imagePath,
        additionalInfo: "Scanned from mobile app",
      );

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
    } catch (e) {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tipTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: SafeArea(
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
              Text(
                'This may take 10-15 seconds',
                style: GoogleFonts.lora(
                  fontSize: 16.sp,
                  color: const Color(0xFF2D1810).withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
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
                      backgroundColor: Colors.grey.withOpacity(0.3),
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
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                'Please wait while we identify your antique...',
                style: GoogleFonts.lora(
                  fontSize: 14.sp,
                  color: const Color(0xFF2D1810).withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}