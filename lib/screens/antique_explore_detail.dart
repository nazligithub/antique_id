import 'package:flutter/material.dart';
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

  Map<String, dynamic> _getAntiqueDetails(String antiqueId) {
    switch (antiqueId) {
      case '1': // Ming Dynasty Vase
        return {
          'referencePrice': '\$10 million',
          'priceRange': '\$5M – \$20M',
          'period': 'Late 17th–18th Century (Qing dynasty, Ming-style blue-and-white)',
          'origin': 'Jingdezhen kilns, China',
          'material': 'High-fired porcelain with underglaze cobalt-blue painting; transparent glaze; dragon roundel motif.',
          'condition': 'Overall grade: Excellent\nNo visible cracks or hairlines; minor age wear to rim/foot; cobalt painting remains crisp.',
          'rarityScore': '8 / 10',
          'authenticity': 'High',
          'description': 'Imperial-quality blue-and-white vases from this period are scarce and highly collected.',
          'historicalBackground': 'Kangxi–Qianlong era kilns refined cobalt and firing control, making luminous blues and strong bodies. Dragon imagery signified imperial authority and auspicious power.',
          'culturalImpact': 'Inspired Delftware and Meissen; remains a global icon of Chinese craftsmanship and museum centerpiece.',
          'culturalContext': 'Likely displayed in elite or imperial interiors, signaling rank and scholarly refinement.',
          'careTip': 'Handle by the body/base, not rim/neck.\n\nDust with microfiber; avoid abrasives.\n\nAvoid immersion; if needed, wipe with distilled water and dry.\n\nKeep away from direct sun and rapid climate changes.\n\nDisplay on padded, stable surface (museum gel if needed).',
        };
      case '2': // Victorian Emerald Ring
        return {
          'referencePrice': '\$250,000',
          'priceRange': '\$100,000 – \$500,000',
          'period': 'Victorian Era, mid–late 19th century',
          'origin': 'England',
          'material': '18k gold mount with natural emerald (oval), likely closed-back or foil-back typical of the era; delicate scrollwork shoulders.',
          'condition': 'Overall grade: Very Good\nLight wear to gold; stone secure; facet junctions show mild age wear under magnification.',
          'rarityScore': '6 / 10',
          'authenticity': 'High',
          'description': 'High-grade emerald examples with original mounts are sought after, though not ultra-rare.',
          'historicalBackground': 'Victorian jewelry favored symbolic gems; emerald signified renewal and status. Industrial advances broadened access yet fine handwork remained prized.',
          'culturalImpact': 'Served as love tokens and markers of social standing; continues to anchor antique jewelry collections.',
          'culturalContext': 'Likely owned by upper-middle-class or aristocratic patrons; worn on formal occasions and passed as heirlooms.',
          'careTip': 'Keep away from heat/chemicals (emeralds often oiled).\n\nClean with soft dry cloth—no ultrasonic/steam.\n\nStore separately in padded box.\n\nHave settings checked periodically.\n\nAvoid hard knocks; emeralds can cleave.',
        };
      case '3': // Napoleon's Sword
        return {
          'referencePrice': '\$5.2 million',
          'priceRange': '\$3M – \$7M',
          'period': 'Early 19th Century (c. 1800–1815)',
          'origin': 'France',
          'material': 'Steel blade; gilt bronze/hilt with ornate guard; leather/scabbard fittings where present.',
          'condition': 'Overall grade: Very Good\nLight tarnish and expected age patina; engravings and gilding remain clear; fittings sound.',
          'rarityScore': '8 / 10',
          'authenticity': 'High',
          'description': 'Documented Napoleonic ceremonial arms are rare and command major premiums.',
          'historicalBackground': 'Presentation/ceremonial swords signified command and prestige across Napoleonic campaigns and court ceremonies.',
          'culturalImpact': 'Objects tied to Napoleon embody themes of power and statecraft; top museum and auction highlights.',
          'culturalContext': 'Commissioned for high-rank ceremonies; displayed in salons or arsenals as symbols of honor.',
          'careTip': 'Store in low-humidity case.\n\nHandle with cotton/nitrile gloves.\n\nLight oil on blade (acid-free) if conserving; avoid over-polish.\n\nKeep gilt surfaces dry; no abrasives.\n\nSupport scabbard and hilt when moving.',
        };
      case '4': // Roman Mosaic Tile
        return {
          'referencePrice': '\$500,000',
          'priceRange': '\$200,000 – \$1.2M',
          'period': '1st–3rd Century AD',
          'origin': 'Roman Empire, likely Italy',
          'material': 'Stone tesserae set in mortar/plaster; avian motif panel fragment.',
          'condition': 'Overall grade: Good\nSome tesserae losses and surface wear; stable mounting; colors retain contrast.',
          'rarityScore': '6 / 10',
          'authenticity': 'High',
          'description': 'Single-panel fragments are collectible; size, subject, and preservation drive price.',
          'historicalBackground': 'Mosaics decorated villas, baths, and temples; subjects ranged from myth to nature. Craft guilds perfected durable floors and walls.',
          'culturalImpact': 'Became hallmarks of Roman domestic culture and luxury; informed Renaissance and modern restorations of classical taste.',
          'culturalContext': 'Likely installed in a wealthy domus or bath complex; served both decorative and symbolic purposes.',
          'careTip': 'Keep in stable, low-humidity environment.\n\nAvoid water cleaning—dry dust only.\n\nSupport from beneath; do not flex panel.\n\nProtect edges; no pressure on loose tesserae.\n\nProfessional conservation for consolidation/grout work.',
        };
      default:
        return {
          'referencePrice': widget.antique.price,
          'priceRange': 'Price range not available',
          'period': widget.antique.era,
          'origin': widget.antique.origin,
          'material': 'Material information not available',
          'condition': 'Condition information not available',
          'rarityScore': 'Not rated',
          'authenticity': 'Not assessed',
          'description': widget.antique.description,
          'historicalBackground': 'Historical background not available',
          'culturalImpact': 'Cultural impact information not available',
          'culturalContext': 'Cultural context not available',
          'careTip': 'General care recommendations not available',
        };
    }
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
                            'Reference Price',
                            style: AppTextStyles.body1.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: AppSizes.paddingS),
                          Text(
                            details['referencePrice'],
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSizes.paddingM),
                          Text(
                            'Price Range',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: AppSizes.paddingXS),
                          Text(
                            details['priceRange'],
                            style: AppTextStyles.body1.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Individual detail cards
                    _buildDetailCard('Period', details['period']),
                    _buildDetailCard('Origin', details['origin']),
                    _buildDetailCard('Material', details['material']),
                    _buildDetailCard('Condition', details['condition']),

                    if (details['rarityScore'] != 'Not rated') ...[
                      _buildRarityAndAuthenticityCard(details['rarityScore'], details['authenticity']),
                      if (details['description'] != widget.antique.description)
                        _buildDetailCard('', details['description']),
                    ],

                    if (details['historicalBackground'] != 'Historical background not available')
                      _buildDetailCard('Historical background', details['historicalBackground']),
                    if (details['culturalImpact'] != 'Cultural impact information not available')
                      _buildDetailCard('Cultural impact', details['culturalImpact']),
                    if (details['culturalContext'] != 'Cultural context not available')
                      _buildDetailCard('Cultural context', details['culturalContext']),
                    if (details['careTip'] != 'General care recommendations not available')
                      _buildDetailCard('Care tip', details['careTip']),

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
                  'Rarity score',
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
                  'Authenticity confidence',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSizes.paddingXS),
                Text(
                  authenticity,
                  style: AppTextStyles.body1.copyWith(
                    color: authenticity.toLowerCase() == 'high'
                        ? AppColors.success
                        : authenticity.toLowerCase() == 'low'
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