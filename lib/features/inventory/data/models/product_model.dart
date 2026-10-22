import '../../../categories/data/models/category_model.dart';

class ProductModel {
  final String? id;
  final String name;
  final String sku;
  final String categoryId;
  final CategoryModel? category;

  // ★ REMOVED: price
  final double costPrice;
  final int quantity;
  final int lowStockThreshold;
  final String? imageUrl;
  final String? imagePublicId;
  final String? description;

  const ProductModel({
    this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    this.category,
    this.costPrice = 0,
    required this.quantity,
    this.lowStockThreshold = 10,
    this.imageUrl,
    this.imagePublicId,
    this.description,
  });

  bool get isLowStock => quantity <= lowStockThreshold;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// True when this product actually has a user-entered SKU.
  bool get hasSku => sku.isNotEmpty;

  ProductModel copyWith({
    String? id,
    String? name,
    String? sku,
    String? categoryId,
    CategoryModel? category,
    double? costPrice,
    int? quantity,
    int? lowStockThreshold,
    String? imageUrl,
    String? imagePublicId,
    String? description,
  }) => ProductModel(
    id: id ?? this.id,
    name: name ?? this.name,
    sku: sku ?? this.sku,
    categoryId: categoryId ?? this.categoryId,
    category: category ?? this.category,
    costPrice: costPrice ?? this.costPrice,
    quantity: quantity ?? this.quantity,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    imageUrl: imageUrl ?? this.imageUrl,
    imagePublicId: imagePublicId ?? this.imagePublicId,
    description: description ?? this.description,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'categoryId': categoryId,
    'costPrice': costPrice,
    'quantity': quantity,
    'lowStockThreshold': lowStockThreshold,
    'imageUrl': imageUrl,
    'imagePublicId': imagePublicId,
    'description': description,
  };

  Map<String, dynamic> toApiJson() => {
    if (id != null) 'id': id,
    'name': name,
    'sku': sku.isEmpty ? null : sku,
    'categoryId': categoryId,
    'costPrice': costPrice,
    'quantity': quantity,
    'lowStockThreshold': lowStockThreshold,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (imagePublicId != null) 'imagePublicId': imagePublicId,
    'description': description,
  };

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id']?.toString(),
    name: json['name'] as String,
    sku: json['sku'] as String? ?? '',
    categoryId: json['categoryId']?.toString() ?? '',
    category: json['category'] != null
        ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
        : null,
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num).toInt(),
    lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 10,
    imageUrl: json['imageUrl'] as String?,
    imagePublicId: json['imagePublicId'] as String?,
    description: json['description'] as String?,
  );

  factory ProductModel.fromApiJson(Map<String, dynamic> json) => ProductModel(
    id: json['id']?.toString() ?? json['_id']?.toString(),
    name: json['name'] as String,
    sku: json['sku'] as String? ?? '',
    categoryId: json['categoryId']?.toString() ?? '',
    category: json['category'] != null
        ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
        : null,
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num).toInt(),
    lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 10,
    imageUrl: json['imageUrl'] as String?,
    imagePublicId: json['imagePublicId'] as String?,
    description: json['description'] as String?,
  );
}
