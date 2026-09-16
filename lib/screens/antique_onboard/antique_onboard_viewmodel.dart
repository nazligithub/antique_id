import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class AntiqueOnboardViewModel extends ChangeNotifier {
  final PageController pageController = PageController();
  int _currentPage = 0;

  VideoPlayerController? scanVideoController;
  VideoPlayerController? identifyVideoController;

  int get currentPage => _currentPage;
  int get totalPages => _pages.length;

  OnboardPage pageAt(int index) => _pages[index.clamp(0, _pages.length - 1)];

  String get buttonTitle {
    return _currentPage < totalPages - 1
        ? 'common_continue'.tr()
        : 'onboard_start'.tr();
  }

  String getTitleForPage(int index) => pageAt(index).title.tr();

  String getSubtitleForPage(int index) => pageAt(index).subtitle.tr();

  /// Four steps that walk through what actually happens to a photo, in the
  /// order it happens. The two middle ones are drawn rather than filmed --
  /// they show the report and the market comparison, which is the part a
  /// reader cannot guess at from a video of someone holding up a camera.
  /// Titles and subtitles are translation keys, resolved when read.
  static const List<OnboardPage> _pages = [
    OnboardPage(
      media: OnboardMedia.scanVideo,
      title: 'onboard_title_1',
      subtitle: 'onboard_subtitle_1',
    ),
    OnboardPage(
      media: OnboardMedia.identification,
      title: 'onboard_title_2',
      subtitle: 'onboard_subtitle_2',
    ),
    OnboardPage(
      media: OnboardMedia.marketPrices,
      title: 'onboard_title_3',
      subtitle: 'onboard_subtitle_3',
    ),
    OnboardPage(
      media: OnboardMedia.collectionVideo,
      title: 'onboard_title_4',
      subtitle: 'onboard_subtitle_4',
    ),
  ];

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
        // Warm the decoder so the video appears the instant its page does,
        // then settle to whatever page the reader is actually on -- they may
        // already have walked past it while this was still loading.
        identifyVideoController!.play().then((_) {
          Future.delayed(const Duration(milliseconds: 50), () {
            _syncVideoPlayback();
            notifyListeners();
          });
        });
      });
    } catch (e) {
      debugPrint('Error initializing videos: $e');
    }
  }

  void onPageChanged(int page) {
    _currentPage = page;
    _syncVideoPlayback();
    notifyListeners();
  }

  /// Plays whichever video the current page shows and pauses the other.
  /// Driven by the page's media rather than its index: the drawn pages sit
  /// between the filmed ones, so an index-based switch left the collection
  /// video playing off-screen and never started it on the page that shows it.
  void _syncVideoPlayback() {
    final media = pageAt(_currentPage).media;

    _setPlaying(scanVideoController, media == OnboardMedia.scanVideo);
    _setPlaying(
      identifyVideoController,
      media == OnboardMedia.collectionVideo,
    );
  }

  void _setPlaying(VideoPlayerController? controller, bool shouldPlay) {
    if (controller == null || !controller.value.isInitialized) return;
    shouldPlay ? controller.play() : controller.pause();
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
enum OnboardMedia { scanVideo, identification, marketPrices, collectionVideo }

class OnboardPage {
  final OnboardMedia media;
  final String title;
  final String subtitle;

  const OnboardPage({
    required this.media,
    required this.title,
    required this.subtitle,
  });
}
