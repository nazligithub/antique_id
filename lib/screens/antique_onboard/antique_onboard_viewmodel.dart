import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class AntiqueOnboardViewModel extends ChangeNotifier {
  final PageController pageController = PageController();
  int _currentPage = 0;

  VideoPlayerController? scanVideoController;
  VideoPlayerController? identifyVideoController;

  int get currentPage => _currentPage;
  int get totalPages => 2;

  String get buttonTitle {
    return _currentPage < totalPages - 1 ? 'Continue' : 'Start Collecting';
  }

  String getTitleForPage(int index) {
    switch (index) {
      case 0:
        return 'Scan & Discover';
      case 1:
        return 'Build Your Collection';
      default:
        return 'Scan & Discover';
    }
  }

  String getSubtitleForPage(int index) {
    switch (index) {
      case 0:
        return 'Point your camera at any antique and get instant identification with detailed history';
      case 1:
        return 'Save your discoveries and build your personal antique collection with expert valuations';
      default:
        return 'Point your camera at any antique and get instant identification with detailed history';
    }
  }

  void initializeVideos() async {
    try {
      // Initialize both videos
      scanVideoController = VideoPlayerController.asset(
        'assets/antique_onboards/antique_onboard_1.mp4',
      );

      identifyVideoController = VideoPlayerController.asset(
        'assets/antique_onboards/antique_onboard_2.mp4',
      );

      // Initialize first video with priority
      await scanVideoController!.initialize();
      scanVideoController!.setLooping(true);
      scanVideoController!.setVolume(0.0);

      // Start playing immediately for instant display
      await scanVideoController!.play();

      // Notify immediately after first video is ready and playing
      notifyListeners();

      // Initialize second video in background
      identifyVideoController!.initialize().then((_) {
        identifyVideoController!.setLooping(true);
        identifyVideoController!.setVolume(0.0);
        // Pre-buffer by playing briefly
        identifyVideoController!.play().then((_) {
          Future.delayed(const Duration(milliseconds: 50), () {
            identifyVideoController!.pause();
          });
        });
      });
    } catch (e) {
      debugPrint('Error initializing videos: $e');
    }
  }

  void onPageChanged(int page) {
    _currentPage = page;

    // Play target video immediately for instant transition
    switch (page) {
      case 0:
        if (scanVideoController != null &&
            scanVideoController!.value.isInitialized) {
          scanVideoController!.play();
          identifyVideoController?.pause();
        }
        break;
      case 1:
        if (identifyVideoController != null &&
            identifyVideoController!.value.isInitialized) {
          identifyVideoController!.play();
          scanVideoController?.pause();
        }
        break;
    }

    notifyListeners();
  }

  void onContinue() {
    HapticFeedback.mediumImpact();

    if (_currentPage < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      completeOnboarding();
    }
  }

  Future<void> completeOnboarding() async {
    // Pause all videos before navigation
    scanVideoController?.pause();
    identifyVideoController?.pause();

    // Don't save onboarding completion yet - this will be done after paywall
    // Navigation to paywall will be handled by the view
  }

  @override
  void dispose() {
    pageController.dispose();
    scanVideoController?.dispose();
    identifyVideoController?.dispose();
    super.dispose();
  }
}