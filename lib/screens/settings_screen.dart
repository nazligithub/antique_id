import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../helpers/appactor_helper.dart';
import '../providers/app_provider.dart';
import 'antique_premium/premium_entry_view.dart';

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
                      _buildUpgradeCard(context),
                      SizedBox(height: 24.h),
                      _buildSection('LEGAL', [
                        _buildMenuItem(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          isFirst: true,
                          onTap: () => _launchUrl(
                            'https://mobinaz.com/terms-antique-identifier',
                          ),
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          isLast: true,
                          onTap: () => _launchUrl(
                            'https://mobinaz.com/privacy-antique-identifier',
                          ),
                        ),
                      ]),
                      SizedBox(height: 18.h),
                      _buildSection('ACCOUNT', [
                        _buildMenuItem(
                          icon: Icons.support_agent_outlined,
                          title: 'Support',
                          isFirst: true,
                          onTap: () =>
                              _launchUrl('https://mobinaz.com/support'),
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.restore_outlined,
                          title: 'Restore Purchases',
                          isLast: true,
                          onTap: () => _showRestoreDialog(context),
                        ),
                      ]),
                      SizedBox(height: 34.h),
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
              child: const Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
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

  /// The subscription state, in the same dark-and-gold the home card uses.
  /// It was green here and gold-on-gold there, so the one thing a subscriber
  /// looks for said something different on each screen.
  Widget _buildUpgradeCard(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isPremium = appProvider.isPremiumUser;

        final card = Container(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 14.w, 16.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3E2723), Color(0xFF5D4037)],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.premiumGold.withValues(alpha: 0.42),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3E2723).withValues(alpha: 0.30),
                blurRadius: 18,
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
                  isPremium
                      ? Icons.workspace_premium_outlined
                      : Icons.lock_open_rounded,
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
                      isPremium ? 'PREMIUM ACTIVE' : 'UPGRADE TO PRO',
                      style: GoogleFonts.lato(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.premiumGold,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      isPremium
                          ? 'Unlimited scans, full reports and expert chat'
                          : 'Unlock unlimited scans and full valuations',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              // Only the upgrade state leads anywhere, so only it gets an arrow.
              if (!isPremium)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.premiumGold.withValues(alpha: 0.85),
                  size: 24.sp,
                ),
            ],
          ),
        );

        if (isPremium) return card;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PremiumEntryView(fromOnboarding: false),
              ),
            ),
            child: card,
          ),
        );
      },
    );
  }

  /// Two short groups under headings rather than one undifferentiated stack of
  /// four rows, so the legal links and the things that act on the account are
  /// visibly not the same kind of thing.
  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.13)),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isFirst ? 16.r : 0),
          bottom: Radius.circular(isLast ? 16.r : 0),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18.sp),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary.withValues(alpha: 0.45),
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.primary.withValues(alpha: 0.11),
      height: 1.h,
      indent: 61.w,
      endIndent: 14.w,
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        Container(
          width: 34.w,
          height: 1.h,
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
        SizedBox(height: 14.h),
        Text(
          'Antique Id  ·  Version 1.2.0',
          style: GoogleFonts.lato(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.75),
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          '© ${DateTime.now().year} Mobinaz. All rights reserved.',
          style: GoogleFonts.lato(
            fontSize: 11.sp,
            color: AppColors.textSecondary.withValues(alpha: 0.55),
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
    var isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.lora(
                      fontSize: 14.sp,
                      color: const Color(0xFF8B8B8B),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() {
                            isLoading = true;
                          });

                          try {
                            final customerInfo = await AppactorHelper.shared
                                .restorePurchases();

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);

                              if (customerInfo != null &&
                                  AppactorHelper.shared.isActive) {
                                final appProvider = Provider.of<AppProvider>(
                                  context,
                                  listen: false,
                                );
                                await appProvider.refreshPremiumStatus();
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Purchases restored successfully! Premium features unlocked.',
                                      style: GoogleFonts.lora(
                                        color: Colors.white,
                                      ),
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
                                      style: GoogleFonts.lora(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF8B4513),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to restore purchases. Please try again.',
                                    style: GoogleFonts.lora(
                                      color: Colors.white,
                                    ),
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
