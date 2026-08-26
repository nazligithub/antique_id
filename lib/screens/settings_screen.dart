import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../helpers/appactor_helper.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: Container(
        decoration: AppDecorations.antiqueBackground,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      _buildAboutSection(context),
                      SizedBox(height: 24.h),
                      _buildMenuItems(context),
                      SizedBox(height: 40.h),
                      _buildAppInfo(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
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
            'Settings',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D1810),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/antique_float.png',
                width: 60.w,
                height: 60.w,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Antique Identifier',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D1810),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Discover the history and value of your antiques with AI-powered identification',
            style: GoogleFonts.lora(
              fontSize: 14.sp,
              color: const Color(0xFF6B5B73),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _launchUrl('https://mobinaz.com/terms-antique-identifier'),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _launchUrl('https://mobinaz.com/privacy-antique-identifier'),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.support_agent_outlined,
            title: 'Support',
            onTap: () => _launchUrl('https://mobinaz.com/support'),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.restore_outlined,
            title: 'Restore Purchases',
            onTap: () => _showRestoreDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF8B4513),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lora(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2D1810),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: const Color(0xFF8B8B8B),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: const Color(0xFFE0E0E0),
      height: 1.h,
      indent: 76.w,
      endIndent: 20.w,
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        Text(
          'Version 1.0.0',
          style: GoogleFonts.lora(
            fontSize: 14.sp,
            color: const Color(0xFF8B8B8B),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '© 2024 Mobinaz. All rights reserved.',
          style: GoogleFonts.lora(
            fontSize: 12.sp,
            color: const Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Text(
                'Restore Purchases',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1810),
                ),
              ),
              content: Text(
                'This will restore any previous premium purchases made with this Apple ID.',
                style: GoogleFonts.lora(
                  fontSize: 14.sp,
                  color: const Color(0xFF6B5B73),
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.lora(
                      fontSize: 14.sp,
                      color: const Color(0xFF8B8B8B),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setState(() {
                      isLoading = true;
                    });

                    try {
                      final customerInfo = await AppactorHelper.shared.restorePurchases();

                      if (context.mounted) {
                        Navigator.pop(context);

                        if (customerInfo != null && AppactorHelper.shared.isActive) {
                          // Update AppProvider
                          final appProvider = Provider.of<AppProvider>(context, listen: false);
                          await appProvider.refreshPremiumStatus();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Purchases restored successfully! Premium features unlocked.',
                                style: GoogleFonts.lora(color: Colors.white),
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'No previous purchases found for this account.',
                                style: GoogleFonts.lora(color: Colors.white),
                              ),
                              backgroundColor: const Color(0xFF8B4513),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to restore purchases. Please try again.',
                              style: GoogleFonts.lora(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Restore',
                          style: GoogleFonts.lora(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}