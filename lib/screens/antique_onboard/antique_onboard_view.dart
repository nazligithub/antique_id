import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../helpers/rating_helper.dart';
import 'antique_onboard_viewmodel.dart';

class AntiqueOnboardView extends StatefulWidget {
  const AntiqueOnboardView({super.key});

  @override
  State<AntiqueOnboardView> createState() => _AntiqueOnboardViewState();
}

class _AntiqueOnboardViewState extends State<AntiqueOnboardView> {
  bool _ratingAsked = false;

  /// Asked once, when the reader reaches the final page. Tying it to the
  /// button instead put the alert between "Start Collecting" and the paywall,
  /// which read as an obstacle; here it sits on a page they are still on and
  /// the button keeps meaning what it says.
  void _askForRating() {
    if (_ratingAsked) return;
    _ratingAsked = true;
    RatingHelper.shared.promptAfterOnboarding(context);
  }

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
                onPageChanged: (index) {
                  viewModel.onPageChanged(index);
                  if (index == viewModel.totalPages - 1) {
                    _askForRating();
                  }
                },
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
        Expanded(child: _buildMedia(viewModel, index)),

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

  Widget _buildMedia(AntiqueOnboardViewModel viewModel, int index) {
    switch (viewModel.pageAt(index).media) {
      case OnboardMedia.scanVideo:
        return _buildVideoPlayer(viewModel.scanVideoController);
      case OnboardMedia.collectionVideo:
        return _buildVideoPlayer(viewModel.identifyVideoController);
      case OnboardMedia.identification:
        return _buildIdentificationPreview();
      case OnboardMedia.marketPrices:
        return _buildMarketPreview();
    }
  }

  /// The report itself, laid out the way the app lays it out. A photograph
  /// with a caption underneath would only promise "we identify things"; this
  /// shows the reader the fields they are actually going to get back.
  Widget _buildIdentificationPreview() {
    return _previewCanvas(
      image: 'assets/antique_onboards/onboard_identify.jpg',
      overlay: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.fromLTRB(18.w, 0, 18.w, 18.h),
          padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 16.h),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _badge('onboard_mock_identified'.tr(), Icons.verified_outlined),
              SizedBox(height: 10.h),
              Text(
                'onboard_mock_name'.tr(),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(child: _fact('explore_period'.tr(), 'onboard_mock_period'.tr())),
                  Expanded(child: _fact('explore_origin'.tr(), 'onboard_mock_origin'.tr())),
                ],
              ),
              SizedBox(height: 11.h),
              Row(
                children: [
                  Expanded(child: _fact('explore_material'.tr(), 'onboard_mock_material'.tr())),
                  Expanded(child: _fact('explore_condition'.tr(), 'onboard_mock_condition'.tr())),
                ],
              ),
              SizedBox(height: 14.h),
              Container(height: 1, color: AppColors.primary.withValues(alpha: 0.13)),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _pill('${'result_authenticity'.tr()}  ${'onboard_mock_authenticity'.tr()}'),
                  SizedBox(width: 8.w),
                  _pill('${'result_rarity'.tr()}  8/10'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The market comparison. The floating prices are what real listings looked
  /// like beside this kind of piece, and the card underneath is the number the
  /// reader came for -- shown together, because seeing one without the other
  /// is exactly the problem this screen exists to solve.
  Widget _buildMarketPreview() {
    return _previewCanvas(
      image: 'assets/antique_onboards/onboard_market.jpg',
      overlay: Stack(
        children: [
          Positioned(top: 34.h, left: 16.w, child: _listingChip('\$1,450')),
          Positioned(top: 116.h, right: 14.w, child: _listingChip('\$980')),
          Positioned(top: 198.h, left: 30.w, child: _listingChip('\$2,240')),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.fromLTRB(18.w, 0, 18.w, 18.h),
              padding: EdgeInsets.fromLTRB(18.w, 15.h, 18.w, 15.h),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'onboard_mock_estimated_value'.tr(),
                          style: GoogleFonts.lato(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '\$1,850',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 27.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'onboard_mock_listings'.tr(),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
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

  /// The photograph fills the media area the way the videos on the other two
  /// pages do, so the four pages read as one sequence rather than two filmed
  /// ones with drawings wedged between them. The scrim keeps white cards
  /// legible over whatever the photograph happens to be doing underneath.
  Widget _previewCanvas({required String image, required Widget overlay}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(image, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.textPrimary.withValues(alpha: 0.10),
                AppColors.textPrimary.withValues(alpha: 0.28),
              ],
              stops: const [0.45, 0.72, 1.0],
            ),
          ),
        ),
        overlay,
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.cardBg.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      boxShadow: [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.22),
          blurRadius: 26.r,
          offset: Offset(0, 10.h),
        ),
      ],
    );
  }

  Widget _badge(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: AppColors.primary),
          SizedBox(width: 5.w),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 9.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fact(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.lato(
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary.withValues(alpha: 0.75),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lato(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.lato(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _listingChip(String price) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.24),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.w,
            height: 5.w,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 7.w),
          Text(
            'eBay',
            style: GoogleFonts.lato(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            price,
            style: GoogleFonts.lato(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(VideoPlayerController? controller) {
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