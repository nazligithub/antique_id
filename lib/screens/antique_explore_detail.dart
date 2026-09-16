import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_constants.dart';
import '../models/antique_model.dart';

class AntiqueExploreDetail extends StatefulWidget {
  final AntiqueModel antique;

  const AntiqueExploreDetail({
    super.key,
    required this.antique,
  });

  @override
  State<AntiqueExploreDetail> createState() => _AntiqueExploreDetailState();
}

class _AntiqueExploreDetailState extends State<AntiqueExploreDetail> {

  /// The four showcase pieces on the home screen ship with full write-ups;
  /// anything else only has what its model carries, and the missing fields
  /// stay null so the cards below can simply be left out.
  static const _showcaseIds = {'1', '2', '3', '4'};

  Map<String, String?> _getAntiqueDetails(String antiqueId) {
    if (_showcaseIds.contains(antiqueId)) {
      String field(String name) => 'featured_${antiqueId}_$name'.tr();
      return {
        'referencePrice': field('reference_price'),
        'priceRange': field('price_range'),
        'period': field('period'),
        'origin': field('origin'),
        'material': field('material'),
        'condition': field('condition'),
        'rarityScore': field('rarity_score'),
        'authenticity': field('authenticity'),
        'description': field('description'),
        'historicalBackground': field('historical_background'),
        'culturalImpact': field('cultural_impact'),
        'culturalContext': field('cultural_context'),
        'careTip': field('care_tip'),
      };
    }
    return {
      'referencePrice': widget.antique.price,
      'priceRange': 'explore_price_range_unavailable'.tr(),
      'period': widget.antique.era,
      'origin': widget.antique.origin,
      'material': 'explore_material_unavailable'.tr(),
      'condition': 'explore_condition_unavailable'.tr(),
      'rarityScore': null,
      'authenticity': null,
      'description': widget.antique.description,
      'historicalBackground': null,
      'culturalImpact': null,
      'culturalContext': null,
      'careTip': null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final details = _getAntiqueDetails(widget.antique.id);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          slivers: [
            // Background image as sliver app bar
            SliverAppBar(
              expandedHeight: 300.h,
              pinned: false,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(widget.antique.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusL),
                    topRight: Radius.circular(AppSizes.radiusL),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: AppSizes.paddingM),

                    // Top card with price information
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.all(AppSizes.paddingM),
                      padding: EdgeInsets.all(AppSizes.paddingL),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppSizes.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.2),
                            blurRadius: 10.r,
                            offset: Offset(0, 5.h),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'explore_reference_price'.tr(),
                            style: AppTextStyles.body1.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: AppSizes.paddingS),
                          Text(
                            details['referencePrice'] ?? '',
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSizes.paddingM),
                          Text(
                            'explore_price_range'.tr(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: AppSizes.paddingXS),
                          Text(
                            details['priceRange'] ?? '',
                            style: AppTextStyles.body1.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Individual detail cards
                    _buildDetailCard('explore_period'.tr(), details['period'] ?? ''),
                    _buildDetailCard('explore_origin'.tr(), details['origin'] ?? ''),
                    _buildDetailCard('explore_material'.tr(), details['material'] ?? ''),
                    _buildDetailCard('explore_condition'.tr(), details['condition'] ?? ''),

                    if (details['rarityScore'] != null) ...[
                      _buildRarityAndAuthenticityCard(details['rarityScore']!, details['authenticity'] ?? ''),
                      if (details['description'] != widget.antique.description)
                        _buildDetailCard('', details['description'] ?? ''),
                    ],

                    if (details['historicalBackground'] != null)
                      _buildDetailCard('explore_historical_background'.tr(), details['historicalBackground']!),
                    if (details['culturalImpact'] != null)
                      _buildDetailCard('explore_cultural_impact'.tr(), details['culturalImpact']!),
                    if (details['culturalContext'] != null)
                      _buildDetailCard('explore_cultural_context'.tr(), details['culturalContext']!),
                    if (details['careTip'] != null)
                      _buildDetailCard('explore_care_tip'.tr(), details['careTip']!),

                    SizedBox(height: AppSizes.paddingXL),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Back button overlay
        floatingActionButton: Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10.h,
            left: AppSizes.paddingM,
          ),
          child: FloatingActionButton.small(
            heroTag: "back_button",
            onPressed: () => Navigator.pop(context),
            backgroundColor: AppColors.black.withValues(alpha: 0.5),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: 20.sp,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      ),
    );
  }

  Widget _buildDetailCard(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      padding: EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
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
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSizes.paddingS),
          ],
          Text(
            content,
            style: AppTextStyles.body2.copyWith(
              color: title.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRarityAndAuthenticityCard(String rarityScore, String authenticity) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      padding: EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'explore_rarity_score'.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSizes.paddingXS),
                Text(
                  rarityScore,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'explore_authenticity_confidence'.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSizes.paddingXS),
                Text(
                  authenticity,
                  style: AppTextStyles.body1.copyWith(
                    color: authenticity == 'analysis_authenticity_high'.tr()
                        ? AppColors.success
                        : authenticity == 'analysis_authenticity_low'.tr()
                        ? AppColors.error
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}