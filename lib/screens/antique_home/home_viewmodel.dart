import 'package:flutter/material.dart';
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

  final List<String> _popularQuestions = [
    'How to identify antique furniture?',
    'What makes an item valuable?',
    'How to spot fake antiques?',
    'Best way to preserve antiques?',
    'How to date antique items?',
  ];

  List<AntiqueModel> get featuredAntiques => _featuredAntiques;
  bool get isLoadingAntiques => _isLoadingAntiques;
  String? get antiqueError => _antiqueError;
  bool get hasAntiqueError => _antiqueError != null;
  bool get isAntiquesEmpty => _featuredAntiques.isEmpty && !_isLoadingAntiques && !hasAntiqueError;
  List<String> get popularQuestions => _popularQuestions;

  Future<void> loadFeaturedAntiques() async {
    if (_isLoadingAntiques) return;

    _isLoadingAntiques = true;
    _antiqueError = null;
    notifyListeners();

    try {
      _featuredAntiques = [
        AntiqueModel(
          id: '1',
          name: 'Ming Dynasty Vase',
          description: '18th century Chinese porcelain',
          imageUrl: 'assets/antique_featured/ming_dynasty.png',
          price: '\$10 million',
          era: '1700s',
          origin: 'China',
        ),
        AntiqueModel(
          id: '2',
          name: 'Victorian Emerald Ring',
          description: 'Rare Victorian era emerald and gold ring',
          imageUrl: 'assets/antique_featured/victorian_emerald.png',
          price: '\$250,000',
          era: '1850s',
          origin: 'England',
        ),
        AntiqueModel(
          id: '3',
          name: 'Napoleon\'s Sword',
          description: 'Gold-encrusted ceremonial sword',
          imageUrl: 'assets/antique_featured/napoleon_sword.png',
          price: '\$5.2 million',
          era: '1800s',
          origin: 'France',
        ),
        AntiqueModel(
          id: '4',
          name: 'Roman Mosaic Tile',
          description: 'Ancient Roman decorative mosaic artwork',
          imageUrl: 'assets/antique_featured/roman_mosaic.png',
          price: '\$500,000',
          era: '100 AD',
          origin: 'Italy',
        ),
      ];
    } catch (e) {
      _antiqueError = 'Error loading featured antiques';
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
                const Text(
                  'Premium Active!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You have unlimited access to:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFeatureItem('🏺', 'Unlimited Antique Scanning'),
                const SizedBox(height: 8),
                _buildFeatureItem('🔍', 'Advanced AI Recognition'),
                const SizedBox(height: 8),
                _buildFeatureItem('🏛️', 'Premium Collections'),
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
                  child: const Text(
                    'Great!',
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
