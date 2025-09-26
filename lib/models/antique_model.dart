class AntiqueModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String price;
  final String era;
  final String origin;
  final bool isPremium;

  AntiqueModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.era,
    required this.origin,
    this.isPremium = false,
  });

  factory AntiqueModel.fromJson(Map<String, dynamic> json) {
    return AntiqueModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      price: json['price'] as String,
      era: json['era'] as String,
      origin: json['origin'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'era': era,
      'origin': origin,
      'is_premium': isPremium,
    };
  }

  AntiqueModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? price,
    String? era,
    String? origin,
    bool? isPremium,
  }) {
    return AntiqueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      era: era ?? this.era,
      origin: origin ?? this.origin,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}