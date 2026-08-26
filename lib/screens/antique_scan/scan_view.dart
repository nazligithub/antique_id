import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_constants.dart';
import 'scan_viewmodel.dart';
import '../antique_detail_screen.dart';
import 'dart:io';

class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isFlashOn = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      setState(() {
        _isInitialized = false;
      });
    } else if (state == AppLifecycleState.resumed && _isInitialized) {
      _initializeCamera();
    }
  }


  Future<void> _initializeCamera() async {
    try {
      if (_cameras == null || _cameras!.isEmpty) {
        _cameras = await availableCameras();
      }

      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile photo = await _controller!.takePicture();
      _processImage(File(photo.path));
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _processImage(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _processImage(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AntiqueDetailScreen(
          imagePath: imageFile.path,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanViewModel>(
      builder: (context, viewModel, child) {
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
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: viewModel.isScanning
                        ? _buildScanningView()
                        : viewModel.hasResult
                            ? _buildResultView(viewModel)
                            : _buildCameraView(viewModel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.primary,
              size: 28.sp,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Scan Antique',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.paddingS),
                Text(
                  'Capture or upload an image to identify',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 40.w),
        ],
      ),
    );
  }

  Widget _buildCameraView(ScanViewModel viewModel) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 30.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: _isInitialized && _controller != null
                      ? AspectRatio(
                          aspectRatio: 1 / _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        )
                      : Container(
                          color: Colors.black,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2.w,
                            ),
                          ),
                        ),
                ),
              ),

              if (_isInitialized && _controller != null)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 30.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 2.w,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _buildCornerBracket(true, true),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildCornerBracket(true, false),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _buildCornerBracket(false, true),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _buildCornerBracket(false, false),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        SizedBox(height: AppSizes.paddingXL),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.photo_library,
                onTap: _pickFromGallery,
              ),
              _buildCameraButton(),
              _buildControlButton(
                icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                onTap: _toggleFlash,
                isFlash: true,
              ),
            ],
          ),
        ),

        if (viewModel.hasScanError)
          Padding(
            padding: EdgeInsets.all(AppSizes.paddingM),
            child: Text(
              viewModel.scanError!,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.error,
              ),
            ),
          ),

        SizedBox(height: AppSizes.paddingXL),
      ],
    );
  }

  Widget _buildCornerBracket(bool isTop, bool isLeft) {
    return Container(
      width: 30.w,
      height: 30.h,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: AppColors.primary, width: 3.w) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: AppColors.primary, width: 3.w) : BorderSide.none,
          left: isLeft ? BorderSide(color: AppColors.primary, width: 3.w) : BorderSide.none,
          right: !isLeft ? BorderSide(color: AppColors.primary, width: 3.w) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? Radius.circular(20.r) : Radius.zero,
          topRight: isTop && !isLeft ? Radius.circular(20.r) : Radius.zero,
          bottomLeft: !isTop && isLeft ? Radius.circular(20.r) : Radius.zero,
          bottomRight: !isTop && !isLeft ? Radius.circular(20.r) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isFlash = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60.w,
        height: 60.h,
        decoration: BoxDecoration(
          color: (isFlash && _isFlashOn) ? AppColors.primary : AppColors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.2),
              blurRadius: 8.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: (isFlash && _isFlashOn) ? AppColors.white : AppColors.primary,
          size: 28.sp,
        ),
      ),
    );
  }

  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: _takePicture,
      child: Container(
        width: 80.w,
        height: 80.h,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.white,
            width: 4.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.3),
              blurRadius: 12.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Icon(
          Icons.camera_alt,
          color: AppColors.white,
          size: 36.sp,
        ),
      ),
    );
  }

  Widget _buildScanningView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          strokeWidth: 3.w,
        ),
        SizedBox(height: AppSizes.paddingL),
        Text(
          'Scanning...',
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSizes.paddingS),
        Text(
          'Analyzing the antique item',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildResultView(ScanViewModel viewModel) {
    final antique = viewModel.scannedAntique!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        children: [
          Container(
            height: 250.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            child: viewModel.scannedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    child: Image.file(
                      viewModel.scannedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.image,
                      size: 60.sp,
                      color: AppColors.grey,
                    ),
                  ),
          ),
          SizedBox(height: AppSizes.paddingL),
          Container(
            padding: EdgeInsets.all(AppSizes.paddingL),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 10.r,
                  offset: Offset(0, 5.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    antique.name,
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: AppSizes.paddingM),
                _buildInfoRow('Description', antique.description),
                _buildInfoRow('Era', antique.era),
                _buildInfoRow('Origin', antique.origin),
                _buildInfoRow('Estimated Value', antique.price),
                SizedBox(height: AppSizes.paddingL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: AppSizes.paddingS),
                        child: _buildActionButton(
                          label: 'Scan Again',
                          icon: Icons.refresh,
                          onTap: () => viewModel.clearResult(),
                          isPrimary: false,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: AppSizes.paddingS),
                        child: _buildActionButton(
                          label: 'Add to Collection',
                          icon: Icons.add_circle,
                          onTap: () => viewModel.addToCollection(),
                          isPrimary: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSizes.paddingM,
          horizontal: AppSizes.paddingL,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.cardBg,
          border: isPrimary
              ? null
              : Border.all(color: AppColors.primary, width: 1.5.w),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? AppColors.white : AppColors.primary,
              size: 20.sp,
            ),
            SizedBox(width: AppSizes.paddingS),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: isPrimary ? AppColors.white : AppColors.primary,
                  fontSize: 14.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}