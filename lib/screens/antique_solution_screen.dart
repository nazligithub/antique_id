import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../models/antique_analysis.dart';
import '../providers/app_provider.dart';
import '../services/collection_service.dart';
import '../widgets/collection_selection_bottom_sheet.dart';
import 'antique_chat_screen.dart';
import 'antique_collection/collection_viewmodel.dart';

class AntiqueSolutionScreen extends StatefulWidget {
  final Map<String, dynamic> analysisResult;
  final String imagePath;

  const AntiqueSolutionScreen({
    super.key,
    required this.analysisResult,
    required this.imagePath,
  });

  @override
  State<AntiqueSolutionScreen> createState() => _AntiqueSolutionScreenState();
}

class _AntiqueSolutionScreenState extends State<AntiqueSolutionScreen> {
  static const _ink = Color(0xFF2D211C);
  static const _mutedInk = Color(0xFF76655B);
  static const _accent = Color(0xFF9A6339);
  static const _success = Color(0xFF35734B);

  late final AntiqueAnalysis _analysis;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _analysis = AntiqueAnalysis.fromResponse(
      widget.analysisResult,
      imagePath: widget.imagePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: AppDecorations.antiqueBackground,
          child: CustomScrollView(
            slivers: [
              _buildHeroSliver(),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 120.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildIdentitySection(),
                    SizedBox(height: 14.h),
                    _buildValueCard(),
                    SizedBox(height: 14.h),
                    _buildDetailsCard(),
                    SizedBox(height: 14.h),
                    _buildDescriptionCard(),
                    if (_analysis.similarAntiques.isNotEmpty) ...[
                      SizedBox(height: 14.h),
                      _buildSimilarSection(),
                    ],
                    SizedBox(height: 14.h),
                    _buildDisclaimer(),
                  ]),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomActions(),
      ),
    );
  }

  Widget _buildHeroSliver() {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      elevation: 0,
      backgroundColor: _ink,
      automaticallyImplyLeading: false,
      title: Text(
        _analysis.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.lato(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: _buildHeroAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.maybePop(context),
      ),
      actions: [
        _buildHeroAction(icon: Icons.ios_share_rounded, onTap: _shareResult),
        SizedBox(width: 8.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroImage(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.34),
                    Colors.transparent,
                    _ink.withValues(alpha: 0.78),
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
            Positioned(
              left: 18.w,
              right: 18.w,
              bottom: 18.h,
              child: Row(
                children: [
                  _buildHeroTag(Icons.auto_awesome_outlined, 'AI IDENTIFIED'),
                  const Spacer(),
                  if (_analysis.confidence != null)
                    _buildHeroTag(
                      Icons.verified_outlined,
                      '${(_analysis.confidence! * 100).round()}% MATCH',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    final localFile = _analysis.imagePath.isNotEmpty
        ? File(_analysis.imagePath)
        : null;
    if (localFile != null && localFile.existsSync()) {
      return Image.file(localFile, fit: BoxFit.cover);
    }

    final imageUrl = _analysis.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: _ink,
      alignment: Alignment.center,
      child: Icon(
        Icons.photo_camera_back_outlined,
        color: Colors.white.withValues(alpha: 0.32),
        size: 54.sp,
      ),
    );
  }

  Widget _buildHeroAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, top: 4.h),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 23.sp),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.28),
          shape: const CircleBorder(),
        ),
      ),
    );
  }

  Widget _buildHeroTag(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14.sp),
          SizedBox(width: 5.w),
          Text(
            label,
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_analysis.category != 'Not available')
          Text(
            _analysis.category.toUpperCase(),
            style: GoogleFonts.lato(
              color: _accent,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        SizedBox(height: 5.h),
        Text(
          _analysis.name,
          style: GoogleFonts.playfairDisplay(
            color: _ink,
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        SizedBox(height: 7.h),
        Text(
          _analysis.period == 'Not available'
              ? 'Analysis completed'
              : _analysis.period,
          style: GoogleFonts.lato(
            color: _mutedInk,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildValueCard() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: Offset(0, 7.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sell_outlined, color: _accent, size: 19.sp),
              SizedBox(width: 8.w),
              Text(
                'ESTIMATED MARKET VALUE',
                style: GoogleFonts.lato(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.15,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            _analysis.valueLabel,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 30.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withValues(alpha: 0.48),
                size: 14.sp,
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  'Use this as a market reference, not a formal appraisal.',
                  style: GoogleFonts.lato(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 12.sp,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final details = [
      (Icons.public_outlined, 'Origin', _analysis.origin),
      (Icons.layers_outlined, 'Material', _analysis.material),
      (Icons.fact_check_outlined, 'Condition', _analysis.condition),
      (Icons.diamond_outlined, 'Rarity', _analysis.rarity),
    ];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.menu_book_outlined, 'Object details'),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: details.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 67.h,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemBuilder: (_, index) {
              final detail = details[index];
              return Container(
                padding: EdgeInsets.all(11.w),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(detail.$1, color: _accent, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.$2,
                            style: GoogleFonts.lato(
                              color: _mutedInk,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            detail.$3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              color: _ink,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_analysis.confidence != null) ...[
            SizedBox(height: 18.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Identification confidence',
                  style: GoogleFonts.lato(
                    color: _mutedInk,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(_analysis.confidence! * 100).round()}%',
                  style: GoogleFonts.lato(
                    color: _success,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 7.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: _analysis.confidence!.clamp(0, 1),
                minHeight: 7.h,
                backgroundColor: _success.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(_success),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.history_edu_outlined, 'About this piece'),
          SizedBox(height: 12.h),
          Text(
            _analysis.description,
            style: GoogleFonts.lato(
              color: _mutedInk,
              fontSize: 14.sp,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  /// The listing's own photograph, which is most of why the card is worth
  /// looking at. Falls back to the placeholder icon when a listing has no
  /// usable image or the thumbnail fails to load.
  Widget _similarThumbnail(SimilarAntique similar) {
    final placeholder = Container(
      height: 52.h,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: Icon(Icons.inventory_2_outlined, color: _accent, size: 20.sp),
    );

    if (similar.imageUrl == null || similar.imageUrl!.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(9.r),
      child: Image.network(
        similar.imageUrl!,
        height: 52.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  Future<void> _openListing(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildSimilarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle(
                Icons.compare_arrows_outlined,
                'Similar market items',
              ),
              Text(
                'Active listings',
                style: GoogleFonts.lato(color: _mutedInk, fontSize: 10.sp),
              ),
            ],
          ),
        ),
        SizedBox(height: 11.h),
        SizedBox(
          height: 145.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _analysis.similarAntiques.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (_, index) {
              final similar = _analysis.similarAntiques[index];
              return GestureDetector(
                onTap: similar.url == null
                    ? null
                    : () => _openListing(similar.url!),
                child: Container(
                  width: 178.w,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: _accent.withValues(alpha: 0.16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _similarThumbnail(similar),
                      Text(
                        similar.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          color: _ink,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              similar.price,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                color: _success,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (similar.source != null)
                            Text(
                              similar.source!,
                              style: GoogleFonts.lato(
                                color: _mutedInk,
                                fontSize: 10.sp,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.shield_outlined,
          color: _mutedInk.withValues(alpha: 0.7),
          size: 16.sp,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'AI identification is an estimate. For insurance, sale or authentication, consult a qualified appraiser.',
            style: GoogleFonts.lato(
              color: _mutedInk.withValues(alpha: 0.78),
              fontSize: 11.sp,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _accent.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _accent, size: 19.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: _ink,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.96),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _askExpert,
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 18.sp),
                label: const Text('Ask expert'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: BorderSide(color: _ink.withValues(alpha: 0.3)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  textStyle: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveToCollection,
                icon: _isSaving
                    ? SizedBox(
                        width: 17.w,
                        height: 17.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.bookmark_add_outlined, size: 19.sp),
                label: Text(_isSaving ? 'Saving...' : 'Save to collection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  textStyle: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _askExpert() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!provider.isPremiumUser) {
      Navigator.pushNamed(context, '/paywall');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AntiqueChatScreen(
          initialMessage: 'Tell me more about ${_analysis.name}.',
        ),
      ),
    );
  }

  void _saveToCollection() {
    setState(() => _isSaving = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CollectionSelectionBottomSheet(
        onCollectionSelected: (collectionName) async {
          try {
            await CollectionService().saveToCollection(
              widget.analysisResult,
              widget.imagePath,
              collectionName: collectionName,
            );

            if (!mounted || !sheetContext.mounted) return;
            Provider.of<CollectionViewModel>(
              context,
              listen: false,
            ).loadCollection(forceRefresh: true);
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added to "$collectionName" collection!'),
                backgroundColor: _success,
              ),
            );
          } catch (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not save this antique: $error'),
                backgroundColor: AppColors.error,
              ),
            );
          } finally {
            if (mounted) setState(() => _isSaving = false);
          }
        },
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _isSaving = false);
    });
  }

  void _shareResult() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing will be available soon.')),
    );
  }
}
