import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../models/antique_model.dart';
import '../../providers/app_provider.dart';
import '../antique_premium/premium_entry_view.dart';
import '../antique_chat_screen.dart';
import '../antique_explore_detail.dart';
import '../antique_scan/scan_view.dart';

class HomeViewModel extends ChangeNotifier {

  List<AntiqueModel> _featuredAntiques = [];
  bool _isLoadingAntiques = false;
  String? _antiqueError;

  static const _popularQuestionKeys = [
    'home_question_1',
    'home_question_2',
    'home_question_3',
    'home_question_4',
    'home_question_5',
  ];

  List<AntiqueModel> get featuredAntiques => _featuredAntiques;
  bool get isLoadingAntiques => _isLoadingAntiques;
  String? get antiqueError => _antiqueError;
  bool get hasAntiqueError => _antiqueError != null;
  bool get isAntiquesEmpty => _featuredAntiques.isEmpty && !_isLoadingAntiques && !hasAntiqueError;
  List<String> get popularQuestions =>
      _popularQuestionKeys.map((key) => key.tr()).toList();

  Future<void> loadFeaturedAntiques() async {
    if (_isLoadingAntiques) return;

    _isLoadingAntiques = true;
    _antiqueError = null;
    notifyListeners();

    try {
      _featuredAntiques = [
        AntiqueModel(
          id: '1',
          name: 'featured_1_name'.tr(),
          description: 'featured_1_summary'.tr(),
          imageUrl: 'assets/antique_featured/ming_dynasty.png',
          price: '\$10 million',
          era: 'featured_1_era'.tr(),
          origin: 'featured_1_origin_short'.tr(),
        ),
        AntiqueModel(
          id: '2',
          name: 'featured_2_name'.tr(),
          description: 'featured_2_summary'.tr(),
          imageUrl: 'assets/antique_featured/victorian_emerald.png',
          price: '\$250,000',
          era: 'featured_2_era'.tr(),
          origin: 'featured_2_origin_short'.tr(),
        ),
        AntiqueModel(
          id: '3',
          name: 'featured_3_name'.tr(),
          description: 'featured_3_summary'.tr(),
          imageUrl: 'assets/antique_featured/napoleon_sword.png',
          price: '\$5.2 million',
          era: 'featured_3_era'.tr(),
          origin: 'featured_3_origin_short'.tr(),
        ),
        AntiqueModel(
          id: '4',
          name: 'featured_4_name'.tr(),
          description: 'featured_4_summary'.tr(),
          imageUrl: 'assets/antique_featured/roman_mosaic.png',
          price: '\$500,000',
          era: 'featured_4_era'.tr(),
          origin: 'featured_4_origin_short'.tr(),
        ),
      ];
    } catch (e) {
      _antiqueError = 'home_featured_error'.tr();
      debugPrint('Error loading antiques: $e');
    } finally {
      _isLoadingAntiques = false;
      notifyListeners();
    }
  }

  void onPremiumCardTapped(BuildContext context) {
    debugPrint('Premium card tapped');

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    if (appProvider.isPremiumUser) {
      _showPremiumFeaturesDialog(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PremiumEntryView(fromOnboarding: false),
        ),
      );
    }
  }

  void _showPremiumFeaturesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD4AF37), Color(0xFFC19A6B)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'premium_active_title'.tr(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'premium_active_subtitle'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFeatureItem('🏺', 'paywall_feature_scanning'.tr()),
                const SizedBox(height: 8),
                _buildFeatureItem('🔍', 'paywall_feature_recognition'.tr()),
                const SizedBox(height: 8),
                _buildFeatureItem('🏛️', 'paywall_feature_collections'.tr()),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'premium_active_cta'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void onScanAntiqueIdentifierTapped(BuildContext context) {
    debugPrint('Scan Antique Identifier tapped');
    ScanSheet.open(context);
  }

  void onQuestionTapped(BuildContext context, String question) {
    debugPrint('Question tapped: $question');
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Check if user is premium
    if (!appProvider.isPremiumUser) {
      // Show premium paywall
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PremiumEntryView(fromOnboarding: false),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AntiqueChatScreen(initialMessage: question),
      ),
    );
  }

  void onChatTapped(BuildContext context) {
    debugPrint('Chat tapped');
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Check if user is premium
    if (!appProvider.isPremiumUser) {
      // Show premium paywall
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PremiumEntryView(fromOnboarding: false),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AntiqueChatScreen(),
      ),
    );
  }

  void onAntiqueTapped(BuildContext context, AntiqueModel antique) {
    debugPrint('Antique tapped: ${antique.name}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AntiqueExploreDetail(antique: antique),
      ),
    );
  }

}
