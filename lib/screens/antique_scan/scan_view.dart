import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_constants.dart';
import '../antique_detail_screen.dart';

/// Offers the two ways into a scan and forwards the chosen image to the crop
/// and analysis flow.
///
/// This was a pushed full page, which spent a whole screen and a navigation
/// transition on a choice between two rows. Before that it opened the camera
/// the moment it appeared, which made the tab feel like a trap and left no way
/// at all to scan a photo already in the library.
class ScanSheet {
  const ScanSheet._();

  /// Opens the picker sheet and carries the chosen photo through to analysis.
  ///
  /// The sheet only reports which source was picked; the picking and the
  /// navigation run against [context], which outlives it. Doing that work from
  /// inside the sheet would open the camera on top of a sheet already closing,
  /// and would leave the detail screen pushed onto a dead route.
  static Future<void> open(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      // Without this the sheet is capped at 9/16 of the screen and clips its
      // own content rather than growing to fit it.
      isScrollControlled: true,
      builder: (_) => const _ScanSheet(),
    );

    if (source == null || !context.mounted) return;
    await _pickAndAnalyse(context, source);
  }

  static Future<void> _pickAndAnalyse(
    BuildContext context,
    ImageSource source,
  ) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 95,
      );
      if (image == null || !context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AntiqueDetailScreen(imagePath: image.path),
        ),
      );
    } catch (error) {
      debugPrint('Error picking image: $error');
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Could not open the camera.'
                : 'Could not open your photo library.',
          ),
        ),
      );
    }
  }
}

class _ScanSheet extends StatelessWidget {
  const _ScanSheet();

  @override
  Widget build(BuildContext context) {
    // The home-indicator inset is padding *inside* the sheet, not a SafeArea
    // around it: wrapping the container instead leaves the panel stopping
    // short of the screen edge with a strip of bare barrier showing beneath.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _grabber()),
          SizedBox(height: 16.h),
          Text(
            'Scan an antique',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 14.h),
          _option(
            context,
            icon: Icons.photo_camera_outlined,
            title: 'Take a photo',
            primary: true,
            source: ImageSource.camera,
          ),
          SizedBox(height: 8.h),
          _option(
            context,
            icon: Icons.photo_library_outlined,
            title: 'Choose from library',
            primary: false,
            source: ImageSource.gallery,
          ),
        ],
      ),
    );
  }

  Widget _grabber() {
    return Container(
      width: 36.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool primary,
    required ImageSource source,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, source),
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: primary
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: primary
                  ? Colors.transparent
                  : AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  icon,
                  size: 20.sp,
                  color: primary ? Colors.white : AppColors.primary,
                ),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w700,
                    color: primary ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
