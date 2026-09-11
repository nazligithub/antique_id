import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import 'loading_screen.dart';
import 'antique_premium/premium_entry_view.dart';

class AntiqueDetailScreen extends StatefulWidget {
  final String imagePath;

  const AntiqueDetailScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<AntiqueDetailScreen> createState() => _AntiqueDetailScreenState();
}

class _AntiqueDetailScreenState extends State<AntiqueDetailScreen> {
  String? croppedImagePath;

  @override
  void initState() {
    super.initState();
    _startCropping();
  }

  Future<void> _startCropping() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: widget.imagePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Antique Image',
          toolbarColor: const Color(0xFF8B4513),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF8B4513),
          backgroundColor: Colors.black,
          cropGridColor: const Color(0xFF8B4513),
          cropFrameColor: const Color(0xFF8B4513),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Antique Image',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
      ],
    );

    // The cropper is a separate activity the reader can leave the app from,
    // so this screen may already be gone by the time it returns.
    if (!mounted) return;

    if (croppedFile != null) {
      setState(() {
        croppedImagePath = croppedFile.path;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _proceedToAnalysis() async {
    if (croppedImagePath == null) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    if (!appProvider.isPremiumUser) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PremiumEntryView(fromOnboarding: false),
        ),
      );

      // Subscribing was a step towards this scan, not a destination. Anyone
      // who came back without subscribing simply stays on their photo.
      if (!mounted || !appProvider.isPremiumUser) return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(imagePath: croppedImagePath!),
      ),
    );
  }

  void _recrop() {
    setState(() {
      croppedImagePath = null;
    });
    _startCropping();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F1E8),
        body: Container(
          decoration: AppDecorations.antiqueBackground,
          child: SafeArea(
            child: Column(
              children: [
            Container(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    'Crop Your Antique',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D1810),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: croppedImagePath != null
                  ? Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.file(
                                File(croppedImagePath!),
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            children: [
                              Text(
                                'Perfect! Your antique is ready for analysis.',
                                style: GoogleFonts.lora(
                                  fontSize: 16.sp,
                                  color: const Color(0xFF2D1810),
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _recrop,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFF8B4513),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                      ),
                                      child: Text(
                                        'Re-crop',
                                        style: GoogleFonts.lora(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF8B4513),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: _proceedToAnalysis,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8B4513),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                      ),
                                      child: Text(
                                        'Analyze Antique',
                                        style: GoogleFonts.lora(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B4513),
                      ),
                    ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
