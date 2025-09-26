import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import 'antique_onboard_viewmodel.dart';

class AntiqueOnboardView extends StatefulWidget {
  const AntiqueOnboardView({super.key});

  @override
  State<AntiqueOnboardView> createState() => _AntiqueOnboardViewState();
}

class _AntiqueOnboardViewState extends State<AntiqueOnboardView> {
  @override
  void initState() {
    super.initState();
    // Keep status bar visible but allow content to go under it
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AntiqueOnboardViewModel()..initializeVideos(),
      child: Consumer<AntiqueOnboardViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: AppColors.background,
            extendBodyBehindAppBar: true,
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background/antique_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: PageView.builder(
                controller: viewModel.pageController,
                onPageChanged: viewModel.onPageChanged,
                physics: const NeverScrollableScrollPhysics(), // Disable user swipe
                itemCount: viewModel.totalPages,
                itemBuilder: (context, index) {
                  return _buildPage(context, viewModel, index);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    AntiqueOnboardViewModel viewModel,
    int index,
  ) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // Video section - expanded to fill most space, extends to top
        Expanded(child: _buildVideoPlayer(viewModel, index)),

        // Bottom section with title, subtitle, indicators and button
        Container(
          color: AppColors.background.withValues(alpha: 0.95),
          padding: EdgeInsets.fromLTRB(40.w, 20.h, 40.w, bottomPadding + 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title and subtitle
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildContent(index, viewModel),
              ),

              SizedBox(height: 20.h),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  viewModel.totalPages,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: viewModel.currentPage == i ? 20.w : 6.w,
                    height: 6.h,
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    decoration: BoxDecoration(
                      color: viewModel.currentPage == i
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Continue button
              Container(
                width: double.infinity,
                height: 60.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 15.r,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28.r),
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      if (viewModel.currentPage < viewModel.totalPages - 1) {
                        viewModel.onContinue();
                      } else {
                        await viewModel.completeOnboarding();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/paywall');
                        }
                      }
                    },
                    child: Center(
                      child: Text(
                        viewModel.buttonTitle,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer(AntiqueOnboardViewModel viewModel, int index) {
    VideoPlayerController? controller;
    switch (index) {
      case 0:
        controller = viewModel.scanVideoController;
        break;
      case 1:
        controller = viewModel.identifyVideoController;
        break;
    }

    if (controller == null || !controller.value.isInitialized) {
      // Show background with loading indicator
      return Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/antique_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    // Fill the entire area with video
    return Container(
      color: Colors.black,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildContent(int index, AntiqueOnboardViewModel viewModel) {
    return Column(
      key: ValueKey(index),
      children: [
        // Title - short and bold
        Text(
          viewModel.getTitleForPage(index),
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 16.h),

        // Subtitle - impactful and concise
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Text(
            viewModel.getSubtitleForPage(index),
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}