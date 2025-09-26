import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/antique_model.dart';
import '../antique_maintab/maintab_viewmodel.dart';
import '../antique_premium/antique_premium_view.dart';

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
          price: '\$80.2 million',
          era: '1700s',
          origin: 'China',
        ),
        AntiqueModel(
          id: '2',
          name: 'Victorian Emerald Ring',
          description: 'Rare Victorian era emerald and gold ring',
          imageUrl: 'assets/antique_featured/victorian_emerald.png',
          price: '\$2.5 million',
          era: '1850s',
          origin: 'England',
        ),
        AntiqueModel(
          id: '3',
          name: 'Napoleon\'s Sword',
          description: 'Gold-encrusted ceremonial sword',
          imageUrl: 'assets/antique_featured/napoleon_sword.png',
          price: '\$6.4 million',
          era: '1800s',
          origin: 'France',
        ),
        AntiqueModel(
          id: '4',
          name: 'Roman Mosaic Tile',
          description: 'Ancient Roman decorative mosaic artwork',
          imageUrl: 'assets/antique_featured/roman_mosaic.png',
          price: '\$1.2 million',
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AntiquePremiumView(fromOnboarding: false),
      ),
    );
  }

  void onScanAntiqueIdentifierTapped(BuildContext context) {
    debugPrint('Scan Antique Identifier tapped');
    final mainTabViewModel = Provider.of<MainTabViewModel>(context, listen: false);
    mainTabViewModel.selectFloatingActionButton();
  }

  void onQuestionTapped(String question) {
    debugPrint('Question tapped: $question');
  }

  void onAntiqueTapped(BuildContext context, AntiqueModel antique) {
    debugPrint('Antique tapped: ${antique.name}');
  }

}