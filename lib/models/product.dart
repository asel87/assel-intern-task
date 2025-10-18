class Product {
  final String name;
  final String gtin;
  final double price;
  final DateTime createdAt;
  final DateTime? lastModified;
  final String? imagePath;
  final String? description;
  final String? category;
  final List<String>? tags;
  final Map<String, String>? specs;

  Product({
    required this.name,
    required this.gtin,
    required this.price,
    required this.createdAt,
    this.lastModified,
    this.imagePath,
    this.description,
    this.category,
    this.tags,
    this.specs,
  });

  Product copyWith({
    String? name,
    double? price,
    String? imagePath,
    String? description,
    String? category,
    List<String>? tags,
    Map<String, String>? specs,
  }) =>
      Product(
        name: name ?? this.name,
        gtin: gtin,
        price: price ?? this.price,
        createdAt: createdAt,
        lastModified: DateTime.now(),
        imagePath: imagePath ?? this.imagePath,
        description: description ?? this.description,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        specs: specs ?? this.specs,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'gtin': gtin,
        'price': price,
        'createdAt': createdAt.toIso8601String(),
        'lastModified': (lastModified ?? createdAt).toIso8601String(),
        'imagePath': imagePath,
        'description': description,
        'category': category,
        'tags': tags,
        'specs': specs,
      };

  factory Product.fromMap(Map data) => Product(
        name: data['name'] ?? '',
        gtin: data['gtin'] ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.tryParse(data['createdAt'] ?? data['date'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        lastModified: data['lastModified'] != null
            ? DateTime.tryParse(data['lastModified'])
            : null,
        imagePath: data['imagePath'],
        description: data['description'],
        category: data['category'],
        tags: (data['tags'] as List?)?.map((e) => e.toString()).toList(),
        specs: (data['specs'] as Map?)?.map((k, v) => MapEntry('$k', '$v')),
      );
}
