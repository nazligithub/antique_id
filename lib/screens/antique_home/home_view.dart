import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_constants.dart';
import '../../providers/app_provider.dart';
import 'home_viewmodel.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeViewModel>(context, listen: false).loadFeaturedAntiques();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeViewModel, AppProvider>(
      builder: (context, viewModel, appProvider, child) {
        if (appProvider.homeScrollToTopRequested) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background/antique_background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPremiumCard(context, viewModel),
                        _buildScanIdentifierCard(context, viewModel),
                        _buildChatSection(viewModel),
                        _buildFeaturedAntiques(context, viewModel),
                        SizedBox(height: AppSizes.paddingXL),
                      ],
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

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80.h,
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        AppStrings.appName,
        style: AppTextStyles.h2.copyWith(color: AppColors.primary),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.settings);
          },
          icon: Icon(Icons.settings, color: AppColors.primary, size: 24.sp),
        ),
      ],
    );
  }

  Widget _buildPremiumCard(BuildContext context, HomeViewModel viewModel) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isPremiumUser) {
          // Premium user card
          //
          // Dark with gold rather than gold on gold: a bright gradient with
          // white text on it read as a promotion, which is the opposite of
          // what a subscriber should see. The state is a quiet confirmation.
          return GestureDetector(
            onTap: () => viewModel.onPremiumCardTapped(context),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 12.w, 16.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3E2723), Color(0xFF5D4037)],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                border: Border.all(
                  color: AppColors.premiumGold.withValues(alpha: 0.42),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3E2723).withValues(alpha: 0.34),
                    blurRadius: 18.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.premiumGold.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.premiumGold.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      color: AppColors.premiumGold,
                      size: 23.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PREMIUM ACTIVE',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.premiumGold,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            fontSize: 10.sp,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          'Unlimited scans, full reports and expert chat',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.white.withValues(alpha: 0.88),
                            fontSize: 13.sp,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.premiumGold.withValues(alpha: 0.8),
                    size: 22.sp,
                  ),
                ],
              ),
            ),
          );
        } else {
          // Non-premium user card
          return GestureDetector(
            onTap: () => viewModel.onPremiumCardTapped(context),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
              constraints: BoxConstraints(minHeight: 120.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.2),
                    blurRadius: 10.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppStrings.upgradePremium,
                                  style: AppTextStyles.h3.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: AppSizes.paddingXS),
                                Text(
                                  AppStrings.unlockFeatures,
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.white.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingM,
                              vertical: AppSizes.paddingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusS,
                              ),
                            ),
                            child: Text(
                              AppStrings.upgradeNow,
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.primary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 100.w,
                    height: 100.h,
                    margin: EdgeInsets.only(right: AppSizes.paddingM),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/antique_pro.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildScanIdentifierCard(
    BuildContext context,
    HomeViewModel viewModel,
  ) {
    return GestureDetector(
      onTap: () => viewModel.onScanAntiqueIdentifierTapped(context),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingM,
        ),
        height: 120.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.15),
              blurRadius: 8.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/scan_antique.png'),
                  fit: BoxFit.contain,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusL),
                  bottomLeft: Radius.circular(AppSizes.radiusL),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        AppStrings.scanAntiqueIdentifier,
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: AppSizes.paddingXS),
                    Flexible(
                      child: Text(
                        AppStrings.identifyAntiques,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: AppSizes.paddingM),
              child: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 20.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSection(HomeViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.chatWithAI,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => viewModel.onChatTapped(context),
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            itemCount: viewModel.popularQuestions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(
                viewModel.popularQuestions[index],
                () => viewModel.onQuestionTapped(
                  context,
                  viewModel.popularQuestions[index],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(String question, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200.w,
        margin: EdgeInsets.only(right: AppSizes.paddingM),
        padding: EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                question,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: AppSizes.paddingXS),
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward,
                color: AppColors.primary,
                size: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedAntiques(BuildContext context, HomeViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(AppSizes.paddingM),
          child: Text(
            AppStrings.featuredAntiques,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (viewModel.isLoadingAntiques)
          Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.paddingXL),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          )
        else if (viewModel.hasAntiqueError)
          Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.paddingXL),
              child: Text(
                viewModel.antiqueError!,
                style: AppTextStyles.body1.copyWith(color: AppColors.error),
              ),
            ),
          )
        else if (viewModel.isAntiquesEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.paddingXL),
              child: Text(
                'No featured antiques available',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 280.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
              itemCount: viewModel.featuredAntiques.length,
              itemBuilder: (context, index) {
                final antique = viewModel.featuredAntiques[index];
                return Container(
                  width: 200.w,
                  margin: EdgeInsets.only(
                    right: index == viewModel.featuredAntiques.length - 1
                        ? 0
                        : AppSizes.paddingM,
                  ),
                  child: _buildAntiqueCard(
                    context,
                    antique,
                    () => viewModel.onAntiqueTapped(context, antique),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAntiqueCard(
    BuildContext context,
    dynamic antique,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 8.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120.h,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusM),
                  topRight: Radius.circular(AppSizes.radiusM),
                ),
              ),
              child: antique.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppSizes.radiusM),
                        topRight: Radius.circular(AppSizes.radiusM),
                      ),
                      child: Image.asset(
                        antique.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.image,
                        size: 40.sp,
                        color: AppColors.grey,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.paddingS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          antique.name,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSizes.paddingXS),
                        Text(
                          antique.description,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            antique.price,
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          antique.era,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
