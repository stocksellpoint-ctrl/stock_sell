


class InventoryReportModel {
  final InventoryTotals totals;
  final List<CategoryBreakdown> categories;
  final List<LowStockItem> lowStock;

  const InventoryReportModel({
    required this.totals,
    required this.categories,
    required this.lowStock,
  });

  factory InventoryReportModel.fromJson(Map<String, dynamic> json) =>
      InventoryReportModel(
        totals: InventoryTotals.fromJson(
            json['totals'] as Map<String, dynamic>? ?? {}),
        categories: (json['categories'] as List? ?? [])
            .map((c) => CategoryBreakdown.fromJson(c as Map<String, dynamic>))
            .toList(),
        lowStock: (json['lowStock'] as List? ?? [])
            .map((l) => LowStockItem.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}

class InventoryTotals {
  final int products;
  final int items;
  final double costValue;
  final int lowStockCount;

  const InventoryTotals({
    required this.products,
    required this.items,
    required this.costValue,
    required this.lowStockCount,
  });

  factory InventoryTotals.fromJson(Map<String, dynamic> json) =>
      InventoryTotals(
        products: (json['products'] as num?)?.toInt() ?? 0,
        items: (json['items'] as num?)?.toInt() ?? 0,
        costValue: (json['costValue'] as num?)?.toDouble() ?? 0,
        lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      );
}

class CategoryBreakdown {
  final String categoryName;
  final int products;
  final int quantity;
  final double costValue;

  const CategoryBreakdown({
    required this.categoryName,
    required this.products,
    required this.quantity,
    required this.costValue,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      CategoryBreakdown(
        categoryName: json['categoryName'] as String? ?? 'Uncategorized',
        products: (json['products'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        costValue: (json['costValue'] as num?)?.toDouble() ?? 0,
      );
}

class LowStockItem {
  final String id;
  final String name;
  final String sku;
  final int quantity;
  final int lowStockThreshold;

  const LowStockItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.lowStockThreshold,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) => LowStockItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 0,
      );
}