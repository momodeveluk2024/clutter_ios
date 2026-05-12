class CategorySummary {
  const CategorySummary({
    required this.slug,
    required this.name,
    required this.displayOrder,
    required this.foodCount,
    this.imageUrl,
  });

  final String slug;
  final String name;
  final int displayOrder;
  final int foodCount;
  final String? imageUrl;

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    final raw = json['imageUrl'];
    final image = raw is String && raw.trim().isNotEmpty ? raw : null;
    return CategorySummary(
      slug: (json['slug'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      foodCount: (json['foodCount'] as num?)?.toInt() ?? 0,
      imageUrl: image,
    );
  }
}
